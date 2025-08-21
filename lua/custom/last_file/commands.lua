---@module 'custom.last_file.commands'
--- User commands and startup auto-restore for the last-file session.

local last_session = require("custom.last_file.last_session")

-- Commands
vim.api.nvim_create_user_command("LastFileSave", function()
  last_session.save()
  vim.notify("[last_session] File saved", vim.log.levels.INFO)
end, { desc = "Save last opened file and cursor position" })

vim.api.nvim_create_user_command("LFS", function()
  last_session.save()
  vim.notify("[last_session] File saved", vim.log.levels.INFO)
end, { desc = "Save last opened file and cursor position" })

vim.api.nvim_create_user_command("LastFileRestore", function()
  last_session.restore()
end, { desc = "Restore last opened file and cursor position" })

vim.api.nvim_create_user_command("LastFileClear", function()
  last_session.clear()
  vim.notify("[last_session] Session cleared", vim.log.levels.INFO)
end, { desc = "Clear saved last file session" })

-- Auto-restore: war früher VimEnter; jetzt warten wir auf VeryLazy,
-- damit lspconfig und seine Autocommands sicher registriert sind.
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    if vim.fn.argc() == 0 and last_session.has_saved_session() then
      last_session.restore()
    end
  end,
})

-- Fallback für Umgebungen ohne das VeryLazy-Event (optional, notfalls auskommentieren):
-- vim.api.nvim_create_autocmd("VimEnter", {
--   once = true,
--   callback = function()
--     if vim.fn.argc() == 0 then
--       vim.defer_fn(function()
--         if last_session.has_saved_session() then last_session.restore() end
--       end, 200) -- kurze Verzögerung, damit lspconfig-Setup durchläuft
--     end
--   end,
-- })
