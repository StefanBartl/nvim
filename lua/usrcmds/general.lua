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
