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

return M
