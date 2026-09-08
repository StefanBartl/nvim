# config.menu roadmap

## Open

- **Colour picker without minty.** The one general-section entry that depends
  on the NvChad bundle. `minty` is declared by NvChad's own spec list
  (`cmd = { "Huefy", "Shades" }`) and leaves with NvChad, so this is the
  entry to find an answer for during that decoupling.

## Closed

- ~~Retire nvzone/menu.~~ Done 2026-09-08: `lua/plugins/nvchad.lua` disables
  NvChad's spec for it. The claim that `volt`/`minty` were held here was
  wrong — NvChad declares all three, `volt` is what `nvchad/ui`'s theme
  picker draws with, and nothing in the whole plugin tree calls
  `require("menu")` any more.

- ~~Sometimes an empty context-menu window stayed open after a click, without
  an error — make sure the window closes on the click event.~~ That was
  nvzone/menu's window lifecycle. The kit renderer's chooser owns and closes
  its own surface (`WinClosed` autocmd, single active instance), and a click
  on a separator is inert rather than a half-close. Watch for it once in real
  use; if it recurs, it is a different bug than the one recorded here.
