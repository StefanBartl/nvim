---@module 'lsp.tools.deprecated_help'
--- Utilities to augment Neovim LSP diagnostics for deprecated API usage
--- and to provide a quick mapping to open the help (:help) page for the
--- symbol under the cursor. Install and call `require('nvim.deprecated_help').setup()` from init.lua.
--- Comments in code are in English per project convention.

local notify = require("lib.notify").create("[lsp.tools.deprecated_help.__init]")

local M = {}

local api = vim.api
local fn = vim.fn

-- Default options. These are intentionally explicit so users can override.
---@type table
local defaults = {
  help_mapping = "<C-m>", -- mapping to open help for symbol under cursor
  map_opts = { noremap = true, silent = true }, -- keymap mode and options
  annotate_diagnostics = true, -- append hint to deprecated diagnostics
  diagnostic_hint = "", -- dynamically filled in setup()
  help_cmd = "belowright split | help %s", -- help command template
}

-- Helper: determine if a diagnostic is deprecated
---@param diagnostic table
---@return boolean
local function diagnostic_is_deprecated(diagnostic)
  if diagnostic.tags ~= nil then
    for _, tag in ipairs(diagnostic.tags) do
      if tag == 1 then
        return true
      end
    end
  end
  if diagnostic.message and string.match(string.lower(diagnostic.message), "deprecated") then
    return true
  end
  return false
end

-- Wrap the default LSP diagnostics handler
---@param opts table
local function wrap_publish_diagnostics(opts)
  local orig = vim.lsp.handlers["textDocument/publishDiagnostics"]
  if not orig then
    return
  end

  -- Capture the handler table once (avoids duplicate-field warning)
  local handlers = vim.lsp.handlers

  ---@cast handlers any
  handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
    if not result or not result.diagnostics then
      return orig(err, result, ctx, config)
    end

    if opts.annotate_diagnostics then
      for _, d in ipairs(result.diagnostics) do
        if diagnostic_is_deprecated(d) then
          if
            type(d.message) == "string"
            and not string.find(d.message, opts.diagnostic_hint, 1, true)
          then
            d.message = d.message .. opts.diagnostic_hint
          end
        end
      end
    end

    return orig(err, result, ctx, config)
  end
end

---@type string[]
local default_blacklist = {
  [1] = "vim.api.",
  [2] = "vim.fn.",
  [3] = "vim.uv.",
}

--- Escape Lua pattern magic characters
---@param s string
---@return string
local function escape_lua_pattern(s)
  return (s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

--- Remove all occurrences of blacklist prefixes from a string
---@param s string
---@return string
local function remove_prefix_from_string(s)
  if type(s) ~= "string" then
    return s
  end
  local out = s
  for _, prefix in ipairs(default_blacklist) do
    if prefix ~= "" then
      out = out:gsub(escape_lua_pattern(prefix), "")
    end
  end
  return out
end

--- Open help for a given symbol in a single split
---@param symbol string
---@param opts table
local function open_help_for_symbol(symbol, opts)
  if not symbol or symbol == "" then
    return
  end

  local safe_symbol = remove_prefix_from_string(symbol)

  -- Prüfen, ob bereits ein Help-Buffer existiert
  local help_buf = nil
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if vim.bo[buf].filetype == "help" then
      help_buf = buf
      break
    end
  end

  if help_buf then
    api.nvim_set_current_buf(help_buf)
    vim.cmd("normal! gg")
  else
    local cmd = string.format(opts.help_cmd, safe_symbol)
    vim.cmd(cmd)
  end

  -- Cursor auf das Symbol setzen
  vim.schedule(function()
    local esc = safe_symbol:gsub("(%W)", "%%%1")
    local found = fn.search("\\C" .. esc, "w")
    if found == 0 then
      local win = api.nvim_get_current_win()
      api.nvim_win_set_cursor(win, { 1, 0 })
      notify.info("Symbol not found in help: " .. symbol)
    end
  end)
end

--- Buffer-local mapping
---@param bufnr number
---@param opts table
local function setup_buffer_mapping(bufnr, opts)
  local lhs = opts.help_mapping
  local rhs = string.format(
    [[:lua require('lsp.tools.deprecated_help').open_help_under_cursor(%d)<CR>]],
    bufnr
  )
  api.nvim_buf_set_keymap(bufnr, "n", lhs, rhs, opts.map_opts)
end

--- Get word under cursor and open help
---@param bufnr number|nil
function M.open_help_under_cursor(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local win = api.nvim_get_current_win()
  ---@diagnostic disable-next-line: deprecated
  local _, col = unpack(api.nvim_win_get_cursor(win))
  local line = api.nvim_get_current_line()

  local s, e
  local i = col + 1
  while i > 0 do
    local c = line:sub(i, i)
    if not c:match("[_%w:%.]") then
      break
    end
    i = i - 1
  end
  s = i + 1
  i = col + 1
  while i <= #line do
    local c = line:sub(i, i)
    if not c:match("[_%w:%.]") then
      break
    end
    i = i + 1
  end
  e = i - 1

  local symbol = line:sub(s, e)
  if symbol == nil or symbol == "" then
    notify.warn("No symbol under cursor")
    return
  end

  open_help_for_symbol(symbol, defaults)
end

--- Setup function
---@param user_opts table|nil
function M.setup(user_opts)
  local opts = vim.tbl_deep_extend("force", defaults, user_opts or {})

  -- dynamischen Hint setzen
  opts.diagnostic_hint = " — press " .. opts.help_mapping .. " to open :help for this symbol"

  wrap_publish_diagnostics(opts)

  api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local bufnr = args.buf
      if not api.nvim_buf_is_valid(bufnr) then
        return
      end
      setup_buffer_mapping(bufnr, opts)
    end,
  })
end

return M
