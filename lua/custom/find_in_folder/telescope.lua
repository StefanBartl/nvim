---@module 'custom.find_in_folders.telescope'
---@brief Telescope find_files adapter for find_in_folder.

local notify = require("lib.notify").create("[find_in_folder.telescope]")

local M = {}

---Run Telescope find_files scoped to `folder`.
---@param folder string  Absolute, validated directory path.
function M.find(folder)
  local ok, telescope_builtin = pcall(require, "telescope.builtin")
  if not ok then
    notify.error("telescope.builtin not available")
    return
  end

  telescope_builtin.find_files({
    cwd = folder,
    prompt_title = "Find in " .. vim.fn.fnamemodify(folder, ":~"),
    hidden = true,
    follow = true,
    find_command = (function()
      -- Prefer fd for speed; fall back to find
      if vim.fn.executable("fd") == 1 then
        return {
          "fd",
          "--type", "f",
          "--hidden",
          "--exclude", ".git",
          "--exclude", "node_modules",
        }
      end
      return nil -- Telescope default (find / rg)
    end)(),
  })
end

return M
