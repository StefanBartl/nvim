---@module 'usrcmds.general'

local function copy_current_path()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
  print("Copied path to clipboard")
end
vim.api.nvim_create_user_command("CopyFilepathToClipboard", copy_current_path, { desc = "Copy file path to clipboard" })
