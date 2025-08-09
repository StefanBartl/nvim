---@module 'chadrc.lua'

local M = {}

M.ui = {
  statusline = {
    --theme = "vscode",
  },
}

M.base46 = {
  transparency = true,
  --theme = "default-dark",
  --theme = "github_dark",
  theme = "everforest",
  --theme = "gruvbox",
  --theme = "solarized_dark",
  --theme = "scaryforest",
  --theme = "starlight",
  --theme = "vesper",
  --theme = "tokyionight",
  --theme = "gruvbox",
  --theme = "eldritch",
  --theme = "hackthebox",
  --theme = "hackthebox2",
  --theme = "hacktivist",
}

vim.api.nvim_set_hl(0, "NotifyBackground", { bg = "#1a1a1a" })

if vim.g.is_windows and vim.g.is_pwsh then
  vim.opt.shell = "pwsh"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

return M
