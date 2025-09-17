---@module 'chadrc.lua'

local M = {}
local utl = require "ui.stl_modules.lsp_based"

M.ui = {
  statusline = {
    theme = "vscode_colored",
    order = { "mode", "git", "%=", "breadcrumbs", "%=", "diagnostics", "lsp", "cursor", "cwd" },
    modules = {
      breadcrumbs = function()
-- es zeigt bnicht immer den realtiven pfad and
				-- und auch nur den filename anstatt den pfad
				local mod = require("ui.stl_modules.lsp_based")
        local band = mod.mode_band_group()
        -- Band öffnen, Inherit-Variante rendern, NICHT schließen:
        return mod.hl_open(band) .. mod.render_breadcrumbs_inherit_lspfirst(band)
			end,
      diagnostics = function()
        local s = require("nvchad.stl.utils").diagnostics()
        return utl.hl_wrap(utl.mode_band_group(), utl.stl_strip_hl(s))
      end,

      lsp = function()
        local s = require("nvchad.stl.utils").lsp()
        return utl.hl_wrap(utl.mode_band_group(), utl.stl_strip_hl(s))
      end,

      cursor = function()
        return utl.hl_wrap(utl.mode_band_group(), " Ln %l, Col %v ")
      end,
    },
  },
}

M.base46 = {
  transparency = false,
  theme_toggle = { "tokyonight", "vim_default" },

  -- theme = "tokyonight",
  -- theme = "github_dark",
  -- theme = "aylin",
  theme = "tokyonight",
  -- theme = "solarized_dark",
  -- theme = "scaryforest",
  -- theme = "starlight",
  -- theme = "vesper",
  -- theme = "eldritch",
  -- theme = "gruvchad",
  -- theme = "gruvbox",
  -- theme = "poimandres",
  -- theme = "radium",
  -- theme = "rosepine",
  -- theme = "flouromachine",
}

-- depends on /system/env.lua
if vim.g.is_windows and vim.g.is_pwsh then
  vim.opt.shell = "pwsh"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

return M
