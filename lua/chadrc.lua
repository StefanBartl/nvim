---@module 'chadrc.lua'

local M = {}

M.ui = {
  statusline = {
    theme = "vscode"
  },
}

M.base46 = {
   transparency = false,
  --theme = "default",
	--theme = "default-dark",
  --theme = "vim_default",
  --theme = "github_dark",
  --theme = "aylin",
  --theme = "tokyonight",
  --theme = "solarized_dark",
  --theme = "scaryforest",
  --theme = "starlight",
  --theme = "vesper",
  --theme = "eldritch",
  --theme = "gruvchad",
  --theme = "gruvbox",
  --theme = "poimandres",
  --theme = "radium",
  --theme = "rosepine",
  --theme = "flouromachine",
}

if vim.g.is_windows and vim.g.is_pwsh then
  vim.opt.shell = "pwsh"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

return M
