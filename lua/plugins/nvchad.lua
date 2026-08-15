---@module 'plugins.nvchad'
-- Lazy plugin spec file for your NVDash (or any plugin that should bring menu support).
-- Adapt the plugin name and event as you use lazy.nvim

local notify = require("lib.nvim.notify").create("[plugins.nvchad]")

return {
  "nvzone/menu",
  event = "VeryLazy",
  config = function()
    local ok_init, menu_init = pcall(require, "config.menu.init")
    if ok_init and menu_init and menu_init.setup then
      menu_init.setup({
        enable_format = true,
        enable_code_actions = true,
        enable_lsp_section = true,
        enable_git_section = true,
        enable_paste = true,
      })
      local ok_km, km = pcall(require, "config.menu.mappings")
      if ok_km and km and km.setup then
        pcall(km.setup)
      end
    else
      notify.warn("config.menu.init not available; custom menu not registered")
    end
  end,
}
