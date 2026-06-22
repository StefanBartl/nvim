---@module 'mynotes.core'
--- Central engine for directory validation, notifications and picker abstraction.

local notify = require("lib.nvim.notify").create("[custom.mynotes.core]")

local M = {}

---@param spec MyNotesSpec
---@return string|nil
function M.resolve_cwd(spec)
  local path = vim.fn.expand(spec.dir)
  local stat = vim.loop.fs_stat(path)

  if not stat or stat.type ~= "directory" then
    if spec.notify ~= false then
      notify.error(("[MyNotes] directory does not exist: %s"):format(path))
    end
    return nil
  end

  return path
end

---@nodiscard
---@return boolean
function M.has_rg()
  return vim.fn.executable("rg") == 1
end

---@nodiscard
---@return table|nil
function M.try_fzf()
  local ok, mod = pcall(require, "fzf-lua")
  return ok and mod or nil
end

---@nodiscard
---@return table|nil
function M.try_telescope()
  local ok, mod = pcall(require, "telescope.builtin")
  return ok and mod or nil
end

return M
