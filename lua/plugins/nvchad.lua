---@module 'plugins.nvchad'
--- nvzone/menu, kept as an installed-but-unused fallback renderer.
---
--- The context menu itself no longer loads from here: `config.menu` is set
--- up from a startup phase in init.lua and draws through
--- `lib.nvim.contextmenu`'s kit renderer, so it does not wait on this plugin
--- and does not break if it goes away. What still argues for keeping the
--- spec is the dependency chain — nvzone/menu pulls in `volt`, and `minty`
--- (the menu's colour picker) sits in the same bundle. Dropping all three is
--- the `nvchad-ui` decoupling step, not this one.
---
--- `require("config.menu").setup({ renderer = "nvzone" })` in init.lua puts
--- rendering back on this plugin, unchanged.

return {
  "nvzone/menu",
  event = "VeryLazy",
}
