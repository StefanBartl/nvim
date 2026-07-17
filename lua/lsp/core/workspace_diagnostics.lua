---@module 'lsp.core.workspace_diagnostics'
---@brief Runtime-toggleable gate for workspace-diagnostics.nvim's populate on LSP attach.
---@description
--- workspace-diagnostics.nvim loads every file of the current repo into
--- buffers on LSP attach (`git ls-files`) to populate diagnostics
--- workspace-wide. That is expensive in large repos — see lsp/init.lua for
--- the incident that made this toggleable (a 60-90s startup freeze in a
--- ~600-file non-code repo). The startup default is still gated there by
--- machine role (off on the "workstation"); this module turns the gate into
--- a LIVE switch on top of that default, so it can be flipped without
--- restarting Neovim — e.g. to turn it off during a "just researching/
--- browsing" phase on a dev machine, or on briefly on the workstation for a
--- one-off deep dive into a smaller repo.
---
--- `lsp.core.attach`'s on_attach reads `enabled()` on every attach (not a
--- value captured once at startup), so a toggle takes effect for the NEXT
--- LSP attach (new buffer, `:LspRestartHere`, ...) — it does not
--- retroactively populate/depopulate buffers already attached. Use
--- `populate_now()` for an immediate one-off populate of the current
--- buffer's clients regardless of the toggle state.
---
--- User-facing commands live in lsp.usercmds.workspace_diagnostics.

local notify = require("lib.nvim.notify").create("[lsp.workspace_diagnostics]")

local M = {}

---@type boolean
local state = false
---@type boolean
local seeded = false

--- Seed the live state from the startup default (see lsp/init.lua). Only
--- takes effect once — later calls are no-ops, so a user's runtime toggle
--- can never be silently clobbered by a later re-entry into LSP setup.
---@param default boolean
---@return nil
function M.seed(default)
  if seeded then
    return
  end
  seeded = true
  state = default and true or false
end

---@return boolean
function M.enabled()
  return state
end

---@param value boolean
---@return boolean
function M.set(value)
  state = value and true or false
  notify.info("workspace diagnostics on LSP attach: " .. (state and "ON" or "OFF"))
  return state
end

---@return boolean
function M.toggle()
  return M.set(not state)
end

--- Force-populate workspace diagnostics for `bufnr`'s attached clients right
--- now, regardless of the toggle state. Useful after switching it ON without
--- wanting to restart/reattach the LSP client just to see it take effect.
---@param bufnr? integer  # 0 or nil for the current buffer
---@return boolean ok
---@return integer|string count_or_err  # number of clients populated, or an error string
function M.populate_now(bufnr)
  bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()

  local ok_wd, wd = pcall(require, "workspace-diagnostics")
  if not ok_wd or type(wd.populate_workspace_diagnostics) ~= "function" then
    return false, "workspace-diagnostics.nvim not available"
  end

  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    return false, "no LSP clients attached to this buffer"
  end

  for _, client in ipairs(clients) do
    pcall(wd.populate_workspace_diagnostics, client, bufnr)
  end
  return true, #clients
end

return M
