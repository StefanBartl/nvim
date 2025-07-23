---@module 'usrcmds.general'

vim.api.nvim_create_user_command("MDUnfatHeadings", function()
  vim.cmd([[%s/\*\*\([^*]\{-}\)\*\*/\1/g]])
end, {})

local function copy_current_path()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
  print("Copied path to clipboard")
end
vim.api.nvim_create_user_command("CopyFilepathToClipboard", copy_current_path, { desc = "Copy file path to clipboard" })

vim.api.nvim_create_user_command("UserCommands", function()
  require("usrcmds.user_commands_info").print_user_commands()
end, {
  desc = "Zeigt alle registrierten UserCommands mit Beschreibung",
})
