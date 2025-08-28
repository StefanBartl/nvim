---@module 'usrcmds.general'

vim.api.nvim_create_user_command("CopyFilepathToClipboard", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
  print("Copied path to clipboard")
end, {
  desc = "Copy file path to clipboard",
})

vim.api.nvim_create_user_command("BufferClear", function()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
end, {
  desc = "Clear all lines in the current buffer",
})

vim.api.nvim_create_user_command("ZenIng", function()
  require("zen-mode").toggle({ window = { width = .85 } })
end, {
  desc = "Topggle Zen Mode",
})

-- BUG: Funktioniert nicht wie gewünscht
vim.api.nvim_create_user_command("MessagesWin", function()
  local msgs = vim.api.nvim_exec2("messages", { output = true }).output
  vim.cmd("new")  -- neues Fenster
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(msgs, "\n"))
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.filetype = "messages"
end, {})

