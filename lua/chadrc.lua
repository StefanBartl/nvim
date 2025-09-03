---@module 'chadrc.lua'

local M = {}


-- Small helpers kept local to this file ---------------------------------------

--- Escape % so user text cannot break statusline sequences.
--- @param s string
--- @return string
local function stl_escape(s)
  return (s:gsub("%%", "%%%%"))
end

--- Ellipsize in the middle to a maximum length (display width aware enough for ASCII).
--- @param s string
--- @param max integer
--- @return string
local function ellipsize_middle(s, max)
  if #s <= max then return s end
  local head = math.floor((max - 1) / 2)
  local tail = max - head - 1
  return string.sub(s, 1, head) .. "…" .. string.sub(s, #s - tail + 1, #s)
end

--- Repo-/project-relative path (fallback: path relative to cwd; final fallback: tail).
--- @param path string
--- @return string
local function repo_relative(path)
  if path == "" then return "[No Name]" end
  local dir = vim.fn.fnamemodify(path, ":h")
  local gitdir = vim.fs.find(".git", { upward = true, path = dir })[1]
  if gitdir then
    local root = vim.fn.fnamemodify(gitdir, ":h")
    local rel = vim.fn.fnamemodify(path, (":~:%s"):format(root))
    if rel == path then return vim.fn.fnamemodify(path, ":t") end
    rel = rel:gsub("^%./", ""):gsub("^/", "")
    return rel
  else
    return vim.fn.fnamemodify(path, ":~:.")
  end
end

--- Try to extract a concise symbol path near the cursor (Treesitter → LSP → nil).
--- Only keeps named semantic nodes; avoids generic "block" noise.
--- @return string|nil
local function symbol_context()
  local ok_ts = pcall(require, "vim.treesitter")
  local ok_utils, tsu = pcall(require, "nvim-treesitter.ts_utils")
  if not ok_ts or not ok_utils or not tsu then return nil end

  local node = tsu.get_node_at_cursor()
  if not node then return nil end

  local keep = {
    function_declaration = true, function_definition  = true,
    method_declaration   = true, method_definition    = true,
    class_declaration    = true, class_specifier      = true,
    struct_specifier     = true, interface_declaration= true,
    module_declaration   = true, namespace_definition = true,
    impl_item            = true, -- rust
  }

  local function ts_identifier_of(n)
    -- 1) Named field "name"
    local named = n:field("name")
    if named and named[1] then
      local t = vim.treesitter.get_node_text(named[1], 0)
      if t and #t > 0 then return t end
    end
    -- 2) Shallow search for common identifier-like node types
    local want = {
      "identifier", "property_identifier", "field_identifier",
      "type_identifier", "name",
    }
    local function in_list(x) for _, w in ipairs(want) do if x == w then return true end end end
    local function first_ident(m, depth)
      depth = depth or 0
      if depth > 2 then return nil end
      if in_list(m:type()) then
        local t = vim.treesitter.get_node_text(m, 0)
        if t and #t > 0 then return t end
      end
      for i = 0, m:child_count() - 1 do
        local r = first_ident(m:child(i), depth + 1)
        if r then return r end
      end
      return nil
    end
    local t = first_ident(n, 0)
    if t and #t > 0 then return t end
    -- 3) Final fallback: first plausible token from the line
    local raw = vim.treesitter.get_node_text(n, 0) or ""
    raw = raw:gsub("^%s+", ""):gsub("\n.*", "")
    local guess = raw:match("^%w+%s+([%w_]+)%s*%(")
               or raw:match("^%w+%s+([%w_]+)%s*[={:]")
               or raw:match("^([%w_%.:]+)%s*%(")
               or raw:match("^([%w_%.:]+)")
    return guess
  end

  local names = {}
  local u = node
  while u do
    local t = u:type()
    if keep[t] then
      local ident = ts_identifier_of(u)
      if ident and #ident > 0 then
        if t:find("function") or t:find("method") then
          if not ident:find("%)$") then ident = ident .. "()" end
        end
        table.insert(names, 1, ident)
      end
    end
    local p = u:parent()
    if not p or p == u then break end
    u = p
  end

  if #names == 0 then return nil end
  return table.concat(names, " → ")
end

--- Render the centered breadcrumbs module (no leading/trailing spaces to keep centering exact).
--- @return string
local function render_breadcrumbs()
  local utils = require "nvchad.stl.utils"
  local bufnr = utils.stbufnr()
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then return "" end

  local rel = repo_relative(path)
  local ctx = symbol_context()

  local line = ctx and (#ctx > 0) and (rel .. " ⟩ " .. ctx) or rel
  -- Optional: scale with window width (use ~40% of columns)
  local maxw = math.max(30, math.floor(vim.o.columns * 0.4))
  line = ellipsize_middle(line, maxw)
  line = stl_escape(line)

  -- IMPORTANT:
  -- * No leading or trailing spaces here – they bias the visual center.
  -- * Use %* to reset highlight after the segment.
  return line .. "%*"
end



-- NvChad statusline config -----------------------------------------------------

M.ui = {
  statusline = {
    theme = "vscode_colored",

    -- Centered: left block … %= breadcrumbs %= … right block
    order = { "mode", "git", "%=", "breadcrumbs", "%=", "diagnostics", "lsp", "cursor", "cwd" },

    -- Provide our custom module
    modules = {
      breadcrumbs = function()
        -- Optional: show only on the active window like mode() does:
        -- if not require("nvchad.stl.utils").is_activewin() then return "" end
        return render_breadcrumbs()
      end,
    },
  },
}

M.base46 = {
   transparency = true,

		-- theme = "default-light",
		-- theme = "vim_default",
		-- theme = "github_dark",
		-- theme = "aylin",
		-- theme = "tokyonight",
		-- theme = "solarized_dark",
		-- theme = "scaryforest",
		-- theme = "starlight",
		-- theme = "vesper",
		-- theme = "eldritch",
		-- theme = "gruvchad",
		-- theme = "gruvbox",
		-- theme = "poimandres",
		-- theme = "radium",
		-- theme = "rosepine",
		-- theme = "flouromachine",
}

-- depends on /system/env.lua
if vim.g.is_windows and vim.g.is_pwsh then
  vim.opt.shell = "pwsh"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

return M
