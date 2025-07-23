-- Load the module
local last_session = require("custom.last_file.last_session")

-- Keymap: Save last file and force-quit all
vim.keymap.set("n", "<leader><Esc>", function()
  last_session.save()
  vim.cmd("qa!")
end, { noremap = true, silent = true, desc = "[Custom] Save last session file + quit all" })

-- :LastFileSave command
vim.api.nvim_create_user_command("LastFileSave", function()
  last_session.save()
  vim.notify("[last_session] File saved", vim.log.levels.INFO)
end, { desc = "Save last opened file and cursor position" })

-- :LastFileRestore command
vim.api.nvim_create_user_command("LastFileRestore", function()
  last_session.restore()
end, { desc = "Restore last opened file and cursor position" })

-- Clear manually
vim.api.nvim_create_user_command("LastFileClear", function()
  last_session.clear()
  vim.notify("[last_session] Session cleared", vim.log.levels.INFO)
end, { desc = "Clear saved last file session" })

-- Auto-restore only if session file is valid and no file is passed as arg
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    if vim.fn.argc() == 0 and last_session.has_saved_session() then
      last_session.restore()
    end
  end,
})
