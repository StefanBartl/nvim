---@module 'custom.open'
---@brief Unified :Open command for Neovim.
---@description
--- Provides a single :Open <target> command that dispatches the text under the
--- cursor (or the current visual selection) to a registered handler.
---
--- Available targets (registered on setup):
---   browser      Open in the system default browser
---   chrome       Open in Google Chrome
---   chromium     Open in Chromium
---   firefox      Open in Mozilla Firefox
---   edge         Open in Microsoft Edge
---   safari       Open in Safari (macOS only)
---   filemanager  Open path in the system file manager
---   notepad      Open text in the system default text editor
---   editor       Alias for notepad
---   split        Open file in a Neovim horizontal split
---   vsplit       Open file in a Neovim vertical split
---   tab          Open file in a new Neovim tab
---
--- Usage:
---   :Open browser
---   :Open chrome
---   :Open filemanager
---   :Open notepad
---   :Open split
---
--- In normal mode the WORD under the cursor is used as input.
--- Run :Open from visual mode (or directly after a visual selection) to use the
--- selected text.
---
--- @see custom.open.context   for how the text is extracted
--- @see custom.open.registry  for the handler contract

local notify = require("lib.notify").create("[custom.open]")

local M = {}

local api = vim.api

---@type Custom.Open.Config
local config = {
  default_handler = nil,
}

-- ---------------------------------------------------------------------------
-- Internal utilities
-- ---------------------------------------------------------------------------

---Wrap fn in pcall and report errors through notify.
---@param fn function
---@param ... any
---@return boolean success, any result_or_error
local function safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    notify.error(string.format("[custom.open] %s", tostring(result)))
  end
  return ok, result
end

-- ---------------------------------------------------------------------------
-- Command handlers
-- ---------------------------------------------------------------------------

---Print available handlers to notify.
local function show_usage()
  local registry = require("custom.open.registry")
  local parts    = { "Usage: :Open <target>\n\nAvailable targets:" }
  for _, h in ipairs(registry.list()) do
    parts[#parts + 1] = string.format("  %-15s %s", h.key, h.desc)
  end
  notify.info(table.concat(parts, "\n"))
end

---Main :Open handler.
---@param opts table  opts from nvim_create_user_command
local function open_handler(opts)
  local args = opts.fargs or {}

  if #args == 0 then
    if config.default_handler then
      args = { config.default_handler }
    else
      show_usage()
      return
    end
  end

  local key      = args[1]
  local registry = require("custom.open.registry")
  local handler  = registry.get(key)

  if not handler then
    notify.error(string.format(
      "[custom.open] Unknown target: '%s'\nAvailable: %s",
      key,
      table.concat(registry.list_keys(), ", ")
    ))
    return
  end

  local context = require("custom.open.context")
  local ctx, err = context.build()

  if not ctx then
    notify.error("[custom.open] " .. (err or "No context available"))
    return
  end

  safe_call(handler.run, ctx)
end

---Tab-completion for :Open.
---@param arg_lead string
---@return string[]
local function open_complete(arg_lead, _, _)
  local registry = require("custom.open.registry")
  local matches  = {}
  for _, key in ipairs(registry.list_keys()) do
    if vim.startswith(key, arg_lead) then
      matches[#matches + 1] = key
    end
  end
  return matches
end

-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------

---Register all built-in handlers.
local function register_builtin_handlers()
  local registry = require("custom.open.registry")
  local reg      = function(h) registry.register(h) end

  -- Browser handlers
  local ok_b, browser = pcall(require, "custom.open.handlers.browser")
  if ok_b then
    browser.register_all(reg)
  end

  -- File manager handler
  local ok_f, fm = pcall(require, "custom.open.handlers.filemanager")
  if ok_f then
    fm.register_all(reg)
  end

  -- Notepad / editor handler
  local ok_n, notepad = pcall(require, "custom.open.handlers.notepad")
  if ok_n then
    notepad.register_all(reg)
  end

  -- Neovim-internal handlers (split/vsplit/tab)
  local ok_nv, nvim_internal = pcall(require, "custom.open.handlers.nvim_internal")
  if ok_nv then
    nvim_internal.register_all(reg)
  end
end

---Setup the :Open command.
---@param opts Custom.Open.Config|nil
---@return nil
function M.setup(opts)
  if opts and type(opts) == "table" then
    config = vim.tbl_extend("force", config, opts)
  end

  register_builtin_handlers()

  api.nvim_create_user_command("Open", open_handler, {
    nargs    = "*",
    complete = open_complete,
    desc     = "[custom.open] Open text under cursor/selection with <target>",
  })
end

return M
