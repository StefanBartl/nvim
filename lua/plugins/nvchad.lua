---@module 'plugins.nvchad'
--- Turns nvzone/menu off.
---
--- Until NvChad's removal (ui.nvim roadmap step 7), NvChad's own spec list
--- (`nvchad/plugins/init.lua`, imported from init.lua) is what actually
--- declared `nvzone/volt`, `nvzone/menu` and `nvzone/minty` as installable
--- plugins; this fragment only added `enabled = false` on top, merged by
--- lazy.nvim into that same plugin entry. NvChad's own import is gone now,
--- but a bare `{ "nvzone/menu", enabled = false }` fragment is a complete
--- plugin declaration by itself (the name alone resolves the GitHub repo),
--- so this file needs no change to keep menu off.
---
--- It is safe to keep off: `ui.menu` (ui.nvim) draws through `ui.contextmenu`'s
--- kit renderer, and a grep for `require("menu")` across the whole plugin
--- tree comes back empty.
---
--- `volt` and `minty` left on 2026-09-19: the right-click menu's colour
--- picker is ui.nvim's own `ui.colorpicker` now, so neither is declared
--- anywhere any more.
---
--- To render context menus with nvzone/menu again: drop `enabled = false`
--- here and set `renderer = "nvzone"` in init.lua's `menu` phase.

return {
  "nvzone/menu",
  enabled = false,
}
