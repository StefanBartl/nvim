---@module 'plugins.nvchad'
--- Turns nvzone/menu off.
---
--- NvChad's own spec list (`nvchad/plugins/init.lua`, imported in init.lua)
--- declares `nvzone/volt`, `nvzone/menu` and `nvzone/minty`. This fragment
--- disables the menu one; lazy.nvim merges both fragments and `enabled =
--- false` wins, so the plugin is not installed.
---
--- It is safe to drop because nothing calls it any more: `config.menu` draws
--- through `lib.nvim.contextmenu`'s kit renderer, and a grep for
--- `require("menu")` across the whole plugin tree — NvChad and nvchad/ui
--- included — comes back empty.
---
--- The other two stay, and they were never held here in the first place:
--- `volt` is what `nvchad/ui`'s theme picker draws with, and `minty` (the
--- menu's colour picker, `cmd = { "Huefy", "Shades" }`) hangs off NvChad's
--- list, not off this one. Both leave with NvChad, not with the menu.
---
--- To render context menus with nvzone/menu again: drop `enabled = false`
--- here and set `renderer = "nvzone"` in init.lua's `menu` phase.

return {
  "nvzone/menu",
  enabled = false,
}
