---@module 'config/menu/init.lua'
-- Orchestrates submodules and exposes a setup() that controls which top-level menu entries are enabled.

local custom_menu = require("config.menu.custom_menu")

local M = {}

-- Setup: registers the built menu under 'menus.custom' so menu.open("custom") works.
function M.setup(opts)
  opts = opts or {}
  local menu_table = custom_menu(opts)

  -- AUDIT: Warum sollte man das genau machen ?

  -- Register so require("menus.custom_menu") returns the table; menu.open normally does require("menus.<name>")
  package.loaded["menus.custom"] = menu_table
  -- Also set to preload for compatibility
  package.preload["menus.custom"] = function()
    return menu_table
  end

  -- Provide a convenient global flag so other modules can detect we installed a custom menu (menu/mapppings)
  vim.g._menu_custom_registered = true
end

return M
