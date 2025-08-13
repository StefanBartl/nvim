---@module 'utils.debug'
--- Debug utilities for Neovim Lua:
--- - Pretty dump values to `vim.notify` or a scratch buffer
--- - Locate caller (file:line)
--- - Check extmark "leaks" across namespaces/buffers
--- - Approximate memory usage of loaded modules
--- - Inspect function upvalues
--- Includes :DbgEval, :DbgExtmarks, :DbgModules commands and leader keymaps.

---@alias MoveDirection '"up"'|'"down"'

---@class DebugDumpOpts
---@field loc? string                 -- Source location hint (defaults to caller via get_loc)
---@field title? string               -- Notification title (auto from loc)
---@field level? integer              -- vim.log.levels (defaults to INFO)
---@field method? '"notify"'|'"float"'  -- Where to show output; 'notify' or 'float' (scratch window)
---@field max_notify_lines? integer   -- If lines exceed this and method=='notify', fallback to 'float'
---@field wrap? boolean               -- Wrap long lines in float window
---@field filetype? string            -- Filetype for syntax highlighting (defaults to 'lua')
---@field on_open? fun(win:integer)   -- Optional window hook

local M = {}

----------------------------------------------------------------------
-- internals
----------------------------------------------------------------------

--- Return a readable caller location "path:line" outside this module/init.
---@return string
function M.get_loc()
  local me = debug.getinfo(1, "S")
  local level = 2
  local info = debug.getinfo(level, "S")
  while info and (info.source == me.source or info.source == "@" .. (vim.env.MYVIMRC or "") or info.what ~= "Lua") do
    level = level + 1
    info = debug.getinfo(level, "S")
  end
  info = info or me
  local source = info.source
  if source:sub(1, 1) == "@" then
    source = source:sub(2)
  end
  source = vim.loop.fs_realpath(source) or source
  return ("%s:%d"):format(source, info.linedefined or 0)
end

--- Create (or reuse) a scratch buffer + floating window to display content.
---@param lines string[]
---@param opts DebugDumpOpts
---@return integer win Window id
local function open_float(lines, opts)
  local buf = vim.api.nvim_create_buf(false, true) -- scratch, nofile
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)

  -- Size heuristics
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  local maxw = math.floor(vim.o.columns * 0.9)
  local maxh = math.floor(vim.o.lines * 0.8)
  local win_w = math.min(math.max(60, width + 2), maxw)
  local win_h = math.min(math.max(8, #lines + 2), maxh)

  local row = math.floor((vim.o.lines - win_h) / 2)
  local col = math.floor((vim.o.columns - win_w) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = win_w,
    height = win_h,
    border = "rounded",
    title = opts.title or "Debug",
    title_pos = "center",
    style = "minimal",
  })

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Apply highlighting preferences
  vim.wo[win].wrap = opts.wrap and true or false
  vim.wo[win].conceallevel = 3
  vim.wo[win].concealcursor = ""
  vim.wo[win].spell = false
  local ft = opts.filetype or "lua"
  local ok = pcall(vim.treesitter.start, buf, ft)
  if not ok then
    vim.bo[buf].filetype = ft
  end

  if type(opts.on_open) == "function" then
    pcall(opts.on_open, win)
  end

  return win
end

--- Normalize a value list to 0/1/N values.
---@param ... any
---@return any
local function normalize_values(...)
  local value = { ... }
  if vim.tbl_isempty(value) then
    return nil
  end
  if vim.tbl_islist(value) and vim.tbl_count(value) <= 1 then
    return value[1]
  end
  return value
end

----------------------------------------------------------------------
-- dump
----------------------------------------------------------------------

--- Low-level dump implementation.
---@param value any
---@param opts? DebugDumpOpts
function M._dump(value, opts)
  opts = opts or {}
  opts.loc = opts.loc or M.get_loc()
  opts.level = opts.level or vim.log.levels.INFO
  opts.method = opts.method or "notify"
  opts.max_notify_lines = opts.max_notify_lines or 200
  opts.filetype = opts.filetype or "lua"

  local function do_dump()
    local title_loc = vim.fn.fnamemodify(opts.loc or "", ":~:.")
    local msg = vim.inspect(value)

    -- decide where to render
    local lines = vim.split(msg, "\n", { plain = true })
    local too_large_for_notify = #lines > opts.max_notify_lines

    if opts.method == "float" or too_large_for_notify then
      open_float(lines, vim.tbl_extend("force", opts, { title = (opts.title or "Debug: ") .. title_loc }))
      return
    end

    vim.notify(msg, opts.level, {
      title = (opts.title or "Debug: ") .. title_loc,
      on_open = function(win)
        vim.wo[win].conceallevel = 3
        vim.wo[win].concealcursor = ""
        vim.wo[win].spell = false
        local buf = vim.api.nvim_win_get_buf(win)
        if not pcall(vim.treesitter.start, buf, "lua") then
          vim.bo[buf].filetype = "lua"
        end
        if type(opts.on_open) == "function" then
          pcall(opts.on_open, win)
        end
      end,
    })
  end

  if vim.in_fast_event() then
    return vim.schedule(do_dump)
  else
    return do_dump()
  end
end

--- Public dump helper: pretty-print any values.
---@param ... any
function M.dump(...)
  local value = normalize_values(...)
  return M._dump(value)
end

----------------------------------------------------------------------
-- extmarks
----------------------------------------------------------------------

---@class ExtmarkLeakEntry
---@field name string
---@field buf integer
---@field count integer
---@field ft string

--- List extmark counts per (namespace, buffer), sorted descending.
---@param opts? {min_count?:integer}
---@return ExtmarkLeakEntry[]
function M.extmark_leaks(opts)
  opts = opts or {}
  local min_count = opts.min_count or 1

  local nsn = vim.api.nvim_get_namespaces()
  local counts = {} ---@type ExtmarkLeakEntry[]

  for name, ns in pairs(nsn) do
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        local count = #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
        if count >= min_count then
          counts[#counts + 1] = {
            name = name,
            buf = buf,
            count = count,
            ft = vim.bo[buf].ft or "",
          }
        end
      end
    end
  end

  table.sort(counts, function(a, b)
    return a.count > b.count
  end)

  return counts
end

----------------------------------------------------------------------
-- module size estimation (heuristic!)
----------------------------------------------------------------------

--- Heuristic size estimate in bytes for a Lua value; cycle-safe.
---@param value any
---@param visited? table<any, true>
---@return integer
local function estimate_size(value, visited)
  if value == nil then
    return 0
  end
  visited = visited or {}
  if visited[value] then
    return 0
  end
  visited[value] = true

  local t = type(value)
  if t == "boolean" then
    return 4
  elseif t == "number" then
    return 8
  elseif t == "string" then
    return #value + 24
  elseif t == "function" then
    local bytes = 32
    local i = 1
    while true do
      local _, val = debug.getupvalue(value, i)
      if not _ then
        break
      end
      bytes = bytes + estimate_size(val, visited)
      i = i + 1
    end
    return bytes
  elseif t == "table" then
    local bytes = 40
    for k, v in pairs(value) do
      bytes = bytes + estimate_size(k, visited) + estimate_size(v, visited)
    end
    local mt = debug.getmetatable(value)
    if mt then
      bytes = bytes + estimate_size(mt, visited)
    end
    return bytes
  else
    -- userdata/thread/lightuserdata: assign a small placeholder size
    return 32
  end
end

---@class ModuleSizeRow
---@field mod string
---@field size number  -- size in MiB (approx)

--- Summarize sizes of loaded modules, grouped by root name.
---@param filter? string               -- Lua pattern to include, e.g. "^plugins%."
---@param top? integer                 -- only return top N (default: all)
---@return ModuleSizeRow[]
function M.module_leaks(filter, top)
  local sizes = {} ---@type table<string, ModuleSizeRow>
  for modname, mod in pairs(package.loaded) do
    if (not filter) or modname:match(filter) then
      local root = modname:match("^([^%.]+)%..*$") or modname
      sizes[root] = sizes[root] or { mod = root, size = 0 }
      sizes[root].size = sizes[root].size + (estimate_size(mod) / 1024 / 1024)
    end
  end

  local list = vim.tbl_values(sizes) ---@type ModuleSizeRow[]
  table.sort(list, function(a, b)
    return a.size > b.size
  end)

  if top and top > 0 and #list > top then
    local trimmed = {}
    for i = 1, top do
      trimmed[i] = list[i]
    end
    return trimmed
  end
  return list
end

----------------------------------------------------------------------
-- upvalues
----------------------------------------------------------------------

--- Get a function upvalue by name (if present).
---@param func function
---@param name string
---@return any
function M.get_upvalue(func, name)
  local i = 1
  while true do
    local n, v = debug.getupvalue(func, i)
    if not n then
      break
    end
    if n == name then
      return v
    end
    i = i + 1
  end
end

----------------------------------------------------------------------
-- setup: commands, keymaps, autocmds
----------------------------------------------------------------------

---@class DebugSetupOpts
---@field set_global_dd? boolean     -- if true, defines _G.dd as a thin wrapper around M.dump
---@field create_commands? boolean   -- default true
---@field create_keymaps? boolean    -- default true
---@field create_autocmds? boolean   -- default true
---@field leader? string             -- leader prefix for keymaps (default "<leader>d")
---@field default_method? '"notify"'|'"float"'

---@param opts? DebugSetupOpts
function M.setup(opts)
  opts = opts or {}
  local set_global_dd = (opts.set_global_dd ~= false)
  local create_commands = (opts.create_commands ~= false)
  local create_keymaps = (opts.create_keymaps ~= false)
  local create_autocmds = (opts.create_autocmds ~= false)
  local leader = opts.leader or "<leader>d"
  local default_method = opts.default_method or "notify"

  -- global dd helper (optional)
  if set_global_dd then
    ---@diagnostic disable-next-line: no-unknown
    _G.dd = function(...)
      return M._dump(normalize_values(...), { method = default_method })
    end
  end

  if create_commands then
    -- :DbgEval {lua_expr}  -> evaluates `return <expr>` and dumps result
    vim.api.nvim_create_user_command("DbgEval", function(c)
      local expr = c.args
      if expr == nil or expr == "" then
        return M._dump(nil, { title = "DbgEval (empty expr)", method = default_method })
      end
      local chunk, err = load("return " .. expr, "DbgEval", "t", _G)
      if not chunk then
        return M._dump({ error = err }, { title = "DbgEval error", level = vim.log.levels.ERROR, method = default_method })
      end
      local ok, res = pcall(chunk)
      if not ok then
        return M._dump({ error = res }, { title = "DbgEval runtime error", level = vim.log.levels.ERROR, method = default_method })
      end
      return M._dump(res, { title = "DbgEval: " .. expr, method = default_method })
    end, { nargs = "+", desc = "Evaluate a Lua expression and dump the result" })

    -- :DbgExtmarks[!] [min_count]
    vim.api.nvim_create_user_command("DbgExtmarks", function(c)
      local min = tonumber(c.args) or 1
      local list = M.extmark_leaks({ min_count = min })
      return M._dump(list, { title = ("Extmarks (min=%d)"):format(min), method = default_method })
    end, { nargs = "?", bang = true, desc = "List extmark counts per namespace/buffer" })

    -- :DbgModules [pattern] [top]
    vim.api.nvim_create_user_command("DbgModules", function(c)
      local args = vim.split(c.args or "", "%s+", { trimempty = true })
      local pattern = args[1]
      local top = tonumber(args[2] or "")
      local list = M.module_leaks(pattern ~= "" and pattern or nil, top)
      local title = "Modules"
      if pattern and pattern ~= "" then
        title = title .. (" filter=%s"):format(pattern)
      end
      if top and top > 0 then
        title = title .. (" top=%d"):format(top)
      end
      return M._dump(list, { title = title, method = default_method })
    end, { nargs = "*", desc = "Approximate module sizes (heuristic), optional pattern and top" })
  end

  if create_keymaps then
    local map = vim.keymap.set
    -- Evaluate expression (prompts via input), dump result
    map("n", leader .. "e", function()
      local expr = vim.fn.input("DbgEval expr: ")
      if expr and expr ~= "" then
        vim.cmd("DbgEval " .. expr)
      end
    end, { desc = "[Debug] Evaluate expression", noremap = true, silent = true })

    -- Quick extmark overview
    map("n", leader .. "x", function()
      vim.cmd("DbgExtmarks 1")
    end, { desc = "[Debug] List extmarks (min=1)", noremap = true, silent = true })

    -- Quick module overview
    map("n", leader .. "m", function()
      vim.cmd("DbgModules")
    end, { desc = "[Debug] List module sizes", noremap = true, silent = true })

    -- Dump visual selection as plain text (no eval)
    map("v", leader .. "v", function()
      local _, ls, cs = unpack(vim.fn.getpos("'<"))
      local _, le, ce = unpack(vim.fn.getpos("'>"))
      local lines = vim.api.nvim_buf_get_lines(0, ls - 1, le, false)
      if #lines == 0 then
        return M._dump("", { title = "Visual (empty)", method = default_method })
      end
      -- trim to selection columns for first/last line
      lines[1] = lines[1]:sub(cs > 0 and cs or 1)
      if #lines > 1 then
        lines[#lines] = lines[#lines]:sub(1, math.max(ce, 1))
      else
        lines[1] = lines[1]:sub(1, math.max(ce - cs + 1, 0))
      end
      return M._dump(table.concat(lines, "\n"), { title = "Visual selection", method = default_method, filetype = "text" })
    end, { desc = "[Debug] Dump visual selection", noremap = true, silent = true })
  end

  if create_autocmds then
    -- Optional: notify when an unusually large number of extmarks appears after BufEnter
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function(args)
        local list = M.extmark_leaks({ min_count = 2000 })
        if #list > 0 then
          -- Only notify, do not flood
          M._dump(list, { title = ("Extmarks warning (buf=%d)"):format(args.buf), level = vim.log.levels.WARN, method = "notify" })
        end
      end,
      desc = "Warn if buffer/extmark counts spike",
    })
  end
end

return M

