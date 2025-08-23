---@module 'chadrc.lua'

local M = {}

M.ui = {
  statusline = {
    theme = "vscode"
  },
}

M.base46 = {
  transparency = false,
  --theme = "onedark",
  --theme = "default-dark",
  --theme = "github_dark",
  --theme = "aylin",
  theme = "tokyonight",
  --theme = "solarized_dark",
  --theme = "scaryforest",
  --theme = "starlight",
  --theme = "vesper",
  --theme = "eldritch",
  --theme = "hackthebox",
  --theme = "hackthebox2", -- error
 -- theme = "hacktivist",
}

if vim.g.is_windows and vim.g.is_pwsh then
  vim.opt.shell = "pwsh"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

require("keys").setup {
    enable_on_startup = true,
    win_opts = {
        width = 50,
        focusable = false,
    },
}

return M
