---@module 'config.lazygit.actions.badd'
--- Add a file selected in LazyGit to the buffer list of the parent Neovim,
--- without loading or focusing it (`:badd`). This is the `O` action.
---
--- See lua/config/lazygit/README.md for the full nvr/$NVIM mechanism.

local notify = require("lib.nvim.notify").create("[cfg.lazygit.badd]")
local resolve = require("config.lazygit.resolve_path")

local fn = vim.fn

local M = {}

--- @param raw string path from LazyGit (repo-root-relative or absolute)
--- @return boolean ok
function M.run(raw)
  if type(raw) ~= "string" or raw == "" then
    notify.warn("no path received from LazyGit")
    return false
  end

  local path = resolve(raw)
  if fn.filereadable(path) ~= 1 then
    notify.warn(("file not readable: %s"):format(path))
    return false
  end

  local ok, err = pcall(vim.cmd, "badd " .. fn.fnameescape(path))
  if not ok then
    notify.warn(("badd failed: %s"):format(err))
    return false
  end

  notify.info(("+buffer %s"):format(fn.fnamemodify(path, ":t")))
  return true
end

return M
