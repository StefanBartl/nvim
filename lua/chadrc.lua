-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@class ChadrcConfig

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

return M
