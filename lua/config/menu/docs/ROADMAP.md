# config.menu roadmap

## Open

- **Retire nvzone/menu entirely.** Nothing in this config renders through it
  any more (see [../README.md](../README.md)); the spec in
  `lua/plugins/nvchad.lua` is kept only because `volt` and `minty` (the
  colour-picker entry) ride along with it. Removing it means finding those
  two a home first — part of the NvChad decoupling, not of the menu.
- **Colour picker without minty.** The one general-section entry that depends
  on the NvChad bundle.

## Closed

- ~~Sometimes an empty context-menu window stayed open after a click, without
  an error — make sure the window closes on the click event.~~ That was
  nvzone/menu's window lifecycle. The kit renderer's chooser owns and closes
  its own surface (`WinClosed` autocmd, single active instance), and a click
  on a separator is inert rather than a half-close. Watch for it once in real
  use; if it recurs, it is a different bug than the one recorded here.
