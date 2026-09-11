---@module 'config.menu'
--- Entry point for the general (non-tree) right-click menu: picks the
--- renderer, hands the general section its options, and binds the triggers.
---
--- The menu no longer registers itself under nvzone/menu's `menus.*`
--- namespace and no longer opens through `require("menu")`. Both went
--- through `lib.nvim.contextmenu`, which since gained a renderer switch —
--- so the menu is drawn by `lib.nvim.ui.kit.menu` and keeps working with
--- nvzone/menu uninstalled. `renderer = "nvzone"` here restores the old
--- rendering unchanged.
---
--- Also opts out of Neovim's own built-in right-click PopUp menu by default
--- (`native_popup = false` sets `'mousemodel' = "extend"`): that menu pops up
--- natively wherever a click lands on no active `<RightMouse>` mapping at
--- all — a blank filetree line past the last node, say — which otherwise
--- looks indistinguishable from this menu occasionally showing something
--- else. Pass `native_popup = true` here to restore vanilla Neovim behaviour.

local contextmenu = require("lib.nvim.contextmenu")

local M = {}

--- Set up the context menu.
---@param opts table|nil  # `config.menu.custom_menu` options, plus `renderer`/`native_popup`
function M.setup(opts)
  opts = opts or {}

  contextmenu.setup({
    renderer = opts.renderer or "kit",
    native_popup = opts.native_popup == true,
  })

  local mappings = require("config.menu.mappings")
  mappings.set_custom_opts(opts)
  mappings.setup()
end

return M
