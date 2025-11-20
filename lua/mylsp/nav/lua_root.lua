---@module 'mylsp.nav.lua_root'
--- Cross-file Lua table root resolver + navigator.
--- Goal:
---   From a cursor position on a Lua member (e.g. `M.cfg.highlight.enable_line`)
---   or anywhere inside a table constructor, extract the member chain, resolve the
---   table's origin (in the same file or through `require`), and return/jump to the
---   table's defining location (table constructor or module `return { ... }`).
---
--- Scope:
---   • Language: Lua
---   • Same-buffer definitions:
---       - local M = { ... }
---       - M = { ... }
---       - M.cfg = { ... } (longest matching prefix of a chain)
---   • Cross-file:
---       - local M = require('mod.path') / M = require('mod.path')
---         Resolve to a runtime file via Neovim's &runtimepath and analyze it:
---         Prefer `return { ... }`, otherwise fall back to table constructors.
---
--- Public API:
---   • M.extract_chain_at(bufnr?, row1?, col0?) -> LuaMemberChain|nil
---   • M.find_root_location(bufnr?, row1?, col0?) -> LuaOriginLocation|nil
---   • M.goto_root_at_cursor(opts?) -> boolean
---
--- Types:
---   LuaMemberChain = { segments: string[] }             -- e.g. { "M","cfg","highlight","enable_line" }
---   LuaOriginLocation = { buf: integer, path: string, start_row: integer, start_col: integer, end_row: integer, end_col: integer }
---
--- Notes:
---   • Non-destructive: does not move the cursor unless goto_* is called.
---   • Parses other files by bufadd/bufload; no windows are created.

---@class LuaMemberChain
---@field segments string[]   -- left→right chain like { "M","cfg","highlight" }

---@class LuaOriginLocation
---@field buf integer
---@field path string
---@field start_row integer   -- 1-based
---@field start_col integer   -- 0-based
---@field end_row integer     -- 1-based
---@field end_col integer     -- 0-based

local M = {}

--------------------------------------------------------------------------------
-- TS helpers
--------------------------------------------------------------------------------

--- Get node text safely.
--- @param n TSNode|nil
--- @return string
local function _txt(n)
  if not n then
    return ""
  end
  local ok, s = pcall(vim.treesitter.get_node_text, n, 0)
  return (ok and s) or ""
end

--- Get node at (buf,row1,col0). Prefers core API (Neovim ≥ 0.10), falls back to nvim-treesitter utils.
--- @param bufnr integer
--- @param row1 integer  -- 1-based
--- @param col0 integer  -- 0-based
--- @return TSNode|nil
local function _node_at(bufnr, row1, col0)
  local ts = require("vim.treesitter")
  if type(ts.get_node_at_pos) == "function" then
    return ts.get_node_at_pos(bufnr, row1 - 1, col0, { ignore_injections = false })
  end
  local ok_ts, tsu = pcall(require, "nvim-treesitter.ts_utils")
  if ok_ts and tsu and bufnr == vim.api.nvim_get_current_buf() then
    return tsu.get_node_at_cursor()
  end
  return nil
end

--- Get root node for a Lua buffer using nvim-treesitter parser.
--- @param bufnr integer
--- @return TSNode|nil
local function _root_node(bufnr)
  local ok_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok_parsers then
    return nil
  end
  local parser = parsers.get_parser(bufnr, "lua")
  if not parser then
    return nil
  end
  local tree = parser:parse()[1]
  return tree and tree:root() or nil
end

--- Climb ancestors until a type in set is found.
--- @param n TSNode|nil
--- @param set table<string, boolean>
--- @return TSNode|nil
local function _ancestor_in(n, set)
  local u = n
  while u do
    if set[u:type()] then
      return u
    end
    local p = u:parent()
    if not p or p == u then
      break
    end
    u = p
  end
  return nil
end

--------------------------------------------------------------------------------
-- Chain extraction
--------------------------------------------------------------------------------

--- Normalize Lua index key: "[ 'foo' ]" -> "foo", "[key]" -> "key"
--- @param raw string
--- @return string
local function _strip_index_key(raw)
  raw = raw or ""
  raw = raw:gsub("^%[", ""):gsub("%]$", "")
  raw = raw:gsub("^%s*", ""):gsub("%s*$", "")
  raw = raw:gsub("^(['\"])(.-)%1$", "%2")
  return raw
end

--- Extract a left→right member chain from the node under (buf,row,col).
--- Supports: identifier, dot_index_expression, method_index_expression, index_expression,
--- and cursor on a table field key inside table_constructor.
--- @param bufnr integer
--- @param row1 integer
--- @param col0 integer
--- @return LuaMemberChain|nil
local function _extract_chain(bufnr, row1, col0)
  local node = _node_at(bufnr, row1, col0)
  if not node then
    return nil
  end

  if node:type() == "field" then
    local tbl = _ancestor_in(node, { table_constructor = true })
    if tbl then
      local a = tbl
      while a do
        if a:type() == "assignment" or a:type() == "local_statement" then
          local right = a:field("right") or a:field("values") or {}
          local match_rhs = false
          for _, rv in ipairs(right) do
            if rv == tbl then
              match_rhs = true
              break
            end
          end
          if match_rhs then
            local left = a:field("left") or a:field("variables") or {}
            local lhs = left[1]
            if lhs then
              local raw = _txt(lhs):gsub("%s+", "")
              local segs ---@type string[]
              segs = {}
              for part in raw:gmatch("[A-Za-z_][A-Za-z0-9_]*") do
                table.insert(segs, part)
              end
              if #segs > 0 then
                return { segments = segs }
              end
            end
            break
          end
        end
        local p = a:parent()
        if not p or p == a then
          break
        end
        a = p
      end
    end
  end

  local want = {
    identifier = true,
    dot_index_expression = true,
    method_index_expression = true,
    index_expression = true,
  }
  local u = node
  while u and not want[u:type()] do
    local p = u:parent()
    if not p or p == u then
      break
    end
    u = p
  end
  if not u or not want[u:type()] then
    return nil
  end

  local segs ---@type string[]
  segs = {}

  while u do
    local ut = u:type()
    if ut == "identifier" then
      table.insert(segs, 1, _txt(u))
      break
    elseif ut == "dot_index_expression" or ut == "method_index_expression" then
      local field = (u:field("field") or {})[1]
      local tbl = (u:field("table") or {})[1]
      if field then
        local k = _txt(field)
        if k ~= "" then
          table.insert(segs, 1, k)
        end
      end
      u = tbl
    elseif ut == "index_expression" then
      local idx = (u:field("index") or {})[1]
      local tbl = (u:field("table") or {})[1]
      if idx then
        local k = _strip_index_key(_txt(idx))
        if k ~= "" then
          table.insert(segs, 1, k)
        end
      end
      u = tbl
    else
      break
    end
  end

  if #segs == 0 then
    return nil
  end
  return { segments = segs }
end

--------------------------------------------------------------------------------
-- Same-buffer origin resolution
--------------------------------------------------------------------------------

--- Canonicalize LHS variable text to a dotted form when possible.
--- @param n TSNode
--- @return string
local function _lhs_text(n)
  local t = n:type()
  ---@diagnostic disable-next-line Annotations specify that at most 1 return value(s) are required, found 1 to 2 returned here instead.
  if t == "identifier" then
    return _txt(n):gsub("%s+", "")
  end
  if t == "dot_index_expression" or t == "method_index_expression" or t == "index_expression" then
    local raw = _txt(n):gsub("%s+", "")
    raw = raw
      :gsub("%[(%b'')%]", function(q)
        return "." .. q:sub(2, -2)
      end)
      :gsub('%[(%b"")%]', function(q)
        return "." .. q:sub(2, -2)
      end)
      :gsub("%[([A-Za-z_][A-Za-z0-9_]*)%]", ".%1")
      :gsub(":", ".")
    return raw
  end

  ---@diagnostic disable-next-line Annotations specify that at most 1 return value(s) are required, found 1 to 2 returned here instead.
  return _txt(n):gsub("%s+", "")
end

--- Find the best matching table-constructor assignment for a chain within a buffer.
--- @param bufnr integer
--- @param chain LuaMemberChain
--- @return LuaOriginLocation|nil
local function _find_table_assignment_in_buffer(bufnr, chain)
  local root = _root_node(bufnr)
  if not root then
    return nil
  end

  local best_loc ---@type LuaOriginLocation|nil
  local best_len = 0

  local target_prefixes = {}
  do
    local acc = {}
    for i, seg in ipairs(chain.segments) do
      table.insert(acc, seg)
      target_prefixes[i] = table.concat(acc, ".")
    end
  end

  local function consider_assignment(node)
    local left = node:field("left") or node:field("variables") or {}
    local right = node:field("right") or node:field("values") or {}
    if #left == 0 or #right == 0 then
      return
    end

    local rhs_tbl = nil
    for _, rv in ipairs(right) do
      if rv:type() == "table_constructor" then
        rhs_tbl = rv
        break
      end
    end
    if not rhs_tbl then
      return
    end

    for _, lv in ipairs(left) do
      local lhs = _lhs_text(lv)
      for plen = #target_prefixes, 1, -1 do
        if lhs == target_prefixes[plen] and plen > best_len then
          local sr, sc, er, ec = rhs_tbl:range()
          best_loc = {
            buf = bufnr,
            path = vim.api.nvim_buf_get_name(bufnr),
            start_row = sr + 1,
            start_col = sc,
            end_row = er + 1,
            end_col = ec,
          }
          best_len = plen
          return
        end
      end
    end
  end

  local function dfs(n)
    if not n then
      return
    end
    local nt = n:type()
    if nt == "assignment" or nt == "local_statement" then
      consider_assignment(n)
    end
    if best_len == #chain.segments - 1 then
      return
    end
    for i = 0, n:child_count() - 1 do
      dfs(n:child(i))
      if best_len == #chain.segments - 1 then
        return
      end
    end
  end

  dfs(root)
  return best_loc
end

--- Find `local X = require('mod')` or `X = require('mod')` for the head of the chain.
--- @param bufnr integer
--- @param head string
--- @return string|nil
local function _find_require_for_head(bufnr, head)
  local root = _root_node(bufnr)
  if not root then
    return nil
  end

  local function lhs_contains_head(node)
    local left = node:field("left") or node:field("variables") or {}
    for _, lv in ipairs(left) do
      if _lhs_text(lv) == head then
        return true
      end
    end
    return false
  end

  local function rhs_is_require(node)
    local right = node:field("right") or node:field("values") or {}
    for _, rv in ipairs(right) do
      if rv:type() == "function_call" then
        local raw = _txt(rv)
        local mod = raw:match("^require%((%b'')%)") or raw:match('^require%((%b"")%)')
        if mod then
          return mod:sub(2, -2)
        end
      end
    end
    return nil
  end

  local found ---@type string|nil

  local function dfs(n)
    if not n or found then
      return
    end
    local nt = n:type()
    if nt == "assignment" or nt == "local_statement" then
      if lhs_contains_head(n) then
        local mod = rhs_is_require(n)
        if mod then
          found = mod
          return
        end
      end
    end
    for i = 0, n:child_count() - 1 do
      dfs(n:child(i))
      if found then
        return
      end
    end
  end

  dfs(root)
  return found
end

--------------------------------------------------------------------------------
-- Cross-file resolution
--------------------------------------------------------------------------------

--- Resolve a Lua module name ("a.b.c") to a file path on &runtimepath.
--- @param mod string
--- @return string|nil
local function _resolve_module_path(mod)
  local rel = mod:gsub("%.", "/")
  local cands = vim.api.nvim_get_runtime_file("lua/" .. rel .. ".lua", true)
  if #cands > 0 then
    return cands[1]
  end
  local cands2 = vim.api.nvim_get_runtime_file("lua/" .. rel .. "/init.lua", true)
  if #cands2 > 0 then
    return cands2[1]
  end
  local path = package.searchpath(mod, package.path)
  return path
end

--- Load (without showing) a buffer for a path and return its bufnr.
--- @param path string
--- @return integer|nil
local function _buf_for_path(path)
  if not path or path == "" then
    return nil
  end
  local buf = vim.fn.bufadd(path)
  if buf <= 0 then
    return nil
  end
  vim.fn.bufload(buf)
  return buf
end

--- In a module buffer, prefer `return { ... }` as the origin table; fallback to first table constructor.
--- @param bufnr integer
--- @return LuaOriginLocation|nil
local function _find_module_root_table(bufnr)
  local root = _root_node(bufnr)
  if not root then
    return nil
  end

  local function find_return_table(n)
    if not n then
      return nil
    end
    if n:type() == "return_statement" then
      local args = n:field("arguments") or {}
      for _, a in ipairs(args) do
        if a:type() == "table_constructor" then
          local sr, sc, er, ec = a:range()
          return {
            buf = bufnr,
            path = vim.api.nvim_buf_get_name(bufnr),
            start_row = sr + 1,
            start_col = sc,
            end_row = er + 1,
            end_col = ec,
          }
        end
      end
    end
    for i = 0, n:child_count() - 1 do
      local loc = find_return_table(n:child(i))
      if loc then
        return loc
      end
    end
    return nil
  end

  local loc = find_return_table(root)
  if loc then
    return loc
  end

  local best ---@type LuaOriginLocation|nil
  local function dfs(n)
    if not n then
      return
    end
    if n:type() == "assignment" or n:type() == "local_statement" then
      local right = n:field("right") or n:field("values") or {}
      for _, rv in ipairs(right) do
        if rv:type() == "table_constructor" then
          local sr, sc, er, ec = rv:range()
          best = {
            buf = bufnr,
            path = vim.api.nvim_buf_get_name(bufnr),
            start_row = sr + 1,
            start_col = sc,
            end_row = er + 1,
            end_col = ec,
          }
          return
        end
      end
    end
    for i = 0, n:child_count() - 1 do
      if best then
        return
      end
      dfs(n:child(i))
    end
  end
  dfs(root)
  return best
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Extract the Lua member chain at a given position (defaults to current cursor).
--- @param bufnr integer|nil
--- @param row1 integer|nil
--- @param col0 integer|nil
--- @return LuaMemberChain|nil
function M.extract_chain_at(bufnr, row1, col0)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not row1 or not col0 then
    local r, c = unpack(vim.api.nvim_win_get_cursor(0))
    row1, col0 = r, c
  end
  return _extract_chain(bufnr, row1, col0)
end

--- Find the origin location of the table related to the chain at position.
--- @param bufnr integer|nil
--- @param row1 integer|nil
--- @param col0 integer|nil
--- @return LuaOriginLocation|nil
function M.find_root_location(bufnr, row1, col0)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not row1 or not col0 then
    local r, c = unpack(vim.api.nvim_win_get_cursor(0))
    row1, col0 = r, c
  end

  if vim.bo[bufnr].filetype ~= "lua" then
    return nil
  end
  local chain = _extract_chain(bufnr, row1, col0)
  if not chain or not chain.segments or #chain.segments == 0 then
    local node = _node_at(bufnr, row1, col0)
    local tbl = node and _ancestor_in(node, { table_constructor = true })
    if not tbl then
      return nil
    end
    local a = tbl
    while a do
      if a:type() == "assignment" or a:type() == "local_statement" then
        local left = a:field("left") or a:field("variables") or {}
        local lhs = left[1] and _lhs_text(left[1]) or ""
        local segs ---@type string[]
        segs = {}
        for part in lhs:gmatch("[A-Za-z_][A-Za-z0-9_]*") do
          table.insert(segs, part)
        end
        if #segs > 0 then
          chain = { segments = segs }
        end
        break
      end
      local p = a:parent()
      if not p or p == a then
        break
      end
      a = p
    end
    if not chain then
      return nil
    end
  end

  local loc = _find_table_assignment_in_buffer(bufnr, chain)
  if loc then
    return loc
  end

  local head = chain.segments[1]
  local mod = _find_require_for_head(bufnr, head)
  if mod then
    local path = _resolve_module_path(mod)
    local tbuf = path and _buf_for_path(path) or nil
    if tbuf then
      local mloc = _find_module_root_table(tbuf)
      if mloc then
        return mloc
      end
    end
  end

  return nil
end

--- Jump to the resolved origin and optionally center/open folds. Prints the target.
--- @param opts { center?:boolean, open_folds?:boolean, echo?:boolean }|nil
--- @return boolean
function M.goto_root_at_cursor(opts)
  opts = opts or {}
  local loc = M.find_root_location()
  if not loc then
    if opts.echo ~= false then
      vim.notify("No Lua table root found", vim.log.levels.INFO)
    end
    return false
  end

  if loc.buf ~= vim.api.nvim_get_current_buf() then
    vim.api.nvim_set_current_buf(loc.buf)
  end
  vim.api.nvim_win_set_cursor(0, { loc.start_row, loc.start_col })
  if opts.open_folds ~= false then
    vim.cmd("silent! normal! zv")
  end
  if opts.center then
    vim.cmd("silent! normal! zz")
  end

  if opts.echo ~= false then
    local msg = ("%s:%d:%d"):format(loc.path ~= "" and loc.path or "[No Name]", loc.start_row, loc.start_col + 1)
    vim.notify(msg, vim.log.levels.INFO)
    print(msg)
  end
  return true
end

--------------------------------------------------------------------------------
-- Inline nvim-treesitter based smoke test (run via `dofile`, not on `require`)
--------------------------------------------------------------------------------

if ... == nil then
  --- Prefer nvim-treesitter helpers to locate the test token coordinates.
  local ok_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok_parsers then
    print("[find_root_location:test] nvim-treesitter not available")
  else
    local api = vim.api

    ---@type string[]
    local sample = {
      "local M = {}",
      "",
      "M.cfg = {",
      "  highlight = {",
      "    enable_line = true,",
      "  },",
      "}",
      "",
      "return M",
    }

    --- Create a scratch Lua buffer and parse it.
    ---@type integer
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, sample)
    vim.bo[buf].filetype = "lua"

    local parser = parsers.get_parser(buf, "lua")
    local tree = parser and parser:parse()[1]
    if not tree then
      print("[find_root_location:test] parse failed")
    else
      local root = tree:root()

      --- Use a TS query to find the identifier node named "enable_line".
      local query = vim.treesitter.query.parse(
        "lua",
        [[
        (identifier) @id
      ]]
      )

      ---@type integer|nil, integer|nil
      local row1, col0 = nil, nil
      for cid, node in query:iter_captures(root, buf, 0, -1) do
        if query.captures[cid] == "id" then
          local name = vim.treesitter.get_node_text(node, buf)
          if name == "enable_line" then
            local sr, sc = node:range()
            row1, col0 = sr + 1, sc
            break
          end
        end
      end

      if not row1 then
        print("[find_root_location] token 'enable_line' not found")
      else
        local ok_call, loc = pcall(M.find_root_location, buf, row1, col0)
        if ok_call and loc then
          print(
            string.format(
              "[find_root_location] %s:%d:%d..%d:%d (buf=%d)",
              (loc.path ~= "" and loc.path or "[No Name]"),
              loc.start_row,
              (loc.start_col or 0) + 1,
              loc.end_row,
              (loc.end_col or 0) + 1,
              loc.buf
            )
          )
        else
          print("[find_root_location] nil")
        end
      end
    end
  end
end

return M
