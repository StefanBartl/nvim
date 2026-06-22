---@module 'custom.find_in_folder.fzf'
---@brief fzf-lua files adapter for find_in_folder.

local notify = require("lib.nvim.notify").create("[find_in_folder.fzf]")

local M = {}

---Run fzf-lua files scoped to `folder`.
---@param folder string  Absolute, validated directory path.
function M.find(folder)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    notify.error("fzf-lua not available")
    return
  end

  fzf.files({
    cwd = folder,
    prompt = vim.fn.fnamemodify(folder, ":~") .. "> ",
    fd_opts = table.concat({
      "--type", "f",
      "--hidden",
      "--exclude", ".git",
      "--exclude", "node_modules",
      "--exclude", "dist",
    }, " "),
  })
end

return M
