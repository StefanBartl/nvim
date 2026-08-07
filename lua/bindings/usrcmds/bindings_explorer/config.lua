---@module 'bindings.usrcmds.bindings_explorer.config'
--- Wo die BINDINGS-Cheatsheets liegen. Konzept: docs/ROADMAP/personal/
--- bindings-explorer.nvim.md.

local M = {}

--- Beide BINDINGS-Wurzeln, absolut.
---@return string[]
function M.roots()
  local cfg = vim.fn.stdpath("config")
  return {
    vim.fs.joinpath(cfg, "docs", "NOTES", "PersonelPlugins", "BINDINGS"),
    vim.fs.joinpath(cfg, "docs", "NOTES", "ExternPlugins", "Bindings"),
  }
end

--- Beide Wurzeln, aber nur die `folder`-Unterkategorie (`"Keymaps"`|
--- `"Usercmds"`|`"Autocmds"`) — beide Bäume verwenden dieselben drei
--- Ordnernamen, siehe `M.roots()`.
---@param folder "Keymaps"|"Usercmds"|"Autocmds"
---@return string[]
function M.roots_for(folder)
  local out = {}
  for _, root in ipairs(M.roots()) do
    out[#out + 1] = vim.fs.joinpath(root, folder)
  end
  return out
end

return M
