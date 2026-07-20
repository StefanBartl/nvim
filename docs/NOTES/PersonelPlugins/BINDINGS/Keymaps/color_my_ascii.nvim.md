# color_my_ascii.nvim — Keymaps Cheatsheet

Source: `lua/color_my_ascii/bindings/keymaps.lua`
Bridge: local `set()` helper — prefers `lib.nvim.map`, falls back to
`vim.keymap.set` (`noremap=true, silent=true`).

**Off by default** (`config.keymaps = false` — deliberately, per a comment in
`config/DEFAULTS.lua`: keymaps claim a slot in the user's global namespace and
can silently collide with existing mappings). Only registered if the user
passes a `keymaps = { action = lhs, ... }` table to `setup()`.

## Actions (`M.attach(km)`)

| action key | rhs (`<cmd>...<cr>`) | desc |
| --- | --- | --- |
| `highlight` | `:ColorMyAscii<cr>` | "color_my_ascii: highlight buffer" |
| `toggle` | `:ColorMyAscii toggle<cr>` | "color_my_ascii: toggle highlighting" |
| `schemes` | `:ColorMyAscii schemes pick<cr>` | "color_my_ascii: switch color scheme" |
| `ensure_blank_lines` | `:ColorMyAscii ensure-blank-lines<cr>` | "color_my_ascii: format code blocks" |
| `show_config` | `:ColorMyAscii show-config<cr>` | "color_my_ascii: show config" |
| `debug` | `:ColorMyAscii debug<cr>` | "color_my_ascii: show debug info" |
| `check_fences` | `:ColorMyAscii check-fences<cr>` | "color_my_ascii: check fences" |

All mode `n`. The lhs for each is whatever the user assigns in their own
`setup({ keymaps = { <action> = "<leader>ah" } })` call — there are no
built-in defaults.

## Dynamic keymaps (not user-configurable, not in `docs/BINDINGS.md`)

- `lua/color_my_ascii/commands/schemes.lua` — inside `:ColorMyAscii schemes
  pick`'s Telescope picker, a `CursorMoved` autocmd (not a keymap) drives live
  scheme preview as the cursor moves; the picker's own navigation keys are
  Telescope's, not this plugin's.

## Notes

- **`docs/BINDINGS.md` cross-reference**: current and accurate for keymaps/commands.
- No which-key group — each action carries its own `desc`, and lhs is entirely user-chosen.
