local last_session = require("custom.last_file.last_session")

--[[
---@description
--- Keymap for quickly saving the last file session and quitting all windows forcibly.
--- Maps <leader><Esc> in normal mode.
---@keymap <leader><Esc>
---@command qa!
vim.keymap.set("n", "<leader><Esc>", function()
  last_session.save()
  vim.cmd("qa!")
end, { noremap = true, silent = true, desc = "[Custom] Save last session file + quit all" })
]] --

---@description
--- Defines the custom command `:LastFileSave` to store the last opened file and cursor position.
--- Intended for session-like behavior or jump-back functionality.
---@command LastFileSave
vim.api.nvim_create_user_command("LastFileSave", function()
  last_session.save()
  vim.notify("[last_session] File saved", vim.log.levels.INFO)
end, { desc = "Save last opened file and cursor position" })
vim.api.nvim_create_user_command("LFS", function()
  last_session.save()
  vim.notify("[last_session] File saved", vim.log.levels.INFO)
end, { desc = "Save last opened file and cursor position" })


---@description
--- Defines the custom command `:LastFileRestore` to restore the last opened file and cursor.
--- Reads from saved session file.
---@command LastFileRestore
vim.api.nvim_create_user_command("LastFileRestore", function()
  last_session.restore()
end, { desc = "Restore last opened file and cursor position" })

---@description
--- Defines the custom command `:LastFileClear` to manually remove the saved session file.
---@command LastFileClear
vim.api.nvim_create_user_command("LastFileClear", function()
  last_session.clear()
  vim.notify("[last_session] Session cleared", vim.log.levels.INFO)
end, { desc = "Clear saved last file session" })

---@description
---Automatically restores the last session file (if one exists), but only
---when Neovim was launched with no file arguments (argc() == 0).
---@event VimEnter
---@once true
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    if vim.fn.argc() == 0 and last_session.has_saved_session() then
      last_session.restore()
    end
  end,
})
