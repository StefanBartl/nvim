---@module 'custom.open.handlers.nvim_internal'
---@brief Handlers that open files inside the current Neovim session.
---@description
--- Registered handlers: split, vsplit, tab.
--- Each resolves the context text to an existing file path and opens it via
--- the appropriate Neovim command.  URL text is rejected (not applicable).
--- If the path is a directory, a Netrw/oil split is opened instead.

local notify = require("lib.notify").create("[custom.open.handlers.nvim_internal]")

local M = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

---Resolve and validate a path from the context.
---@param ctx Custom.Open.Context
---@return string|nil resolved, string|nil err
local function resolve_file_path(ctx)
  if ctx.is_url then
    return nil, "Text looks like a URL, not a local path"
  end

  local expanded = vim.fn.expand(ctx.text)
  if expanded == "" then
    return nil, "Cannot expand path: " .. ctx.text
  end

  local stat = vim.uv.fs_stat(expanded)
  if not stat then
    return nil, "Path does not exist: " .. expanded
  end

  return expanded, nil
end

---Open a path in Neovim using the given ex-command (e.g. "split", "vsplit", "tabedit").
---@param cmd_name string  Ex command to use.
---@param label    string  Handler label for messages.
---@return fun(ctx: Custom.Open.Context): boolean
local function make_nvim_open_fn(cmd_name, label)
  return function(ctx)
    local path, err = resolve_file_path(ctx)
    if not path then
      notify.error(string.format("[custom.open.%s] %s", label, err))
      return false
    end

    local ok, run_err = pcall(vim.cmd, cmd_name .. " " .. vim.fn.fnameescape(path))
    if not ok then
      notify.error(string.format("[custom.open.%s] Failed: %s", label, tostring(run_err)))
      return false
    end

    notify.info(string.format("[custom.open.%s] Opened: %s", label, path))
    return true
  end
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---@param register_fn fun(h: Custom.Open.Handler): boolean
function M.register_all(register_fn)
  register_fn({
    key  = "split",
    desc = "Open file in a new horizontal split inside Neovim",
    run  = make_nvim_open_fn("split", "split"),
  })

  register_fn({
    key  = "vsplit",
    desc = "Open file in a new vertical split inside Neovim",
    run  = make_nvim_open_fn("vsplit", "vsplit"),
  })

  register_fn({
    key  = "tab",
    desc = "Open file in a new Neovim tab",
    run  = make_nvim_open_fn("tabedit", "tab"),
  })
end

return M
