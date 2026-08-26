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
| `toggle_buffer` | `:ColorMyAscii toggle buffer<cr>` | "color_my_ascii: toggle highlighting for this buffer" |
| `schemes` | `:ColorMyAscii schemes pick<cr>` | "color_my_ascii: switch color scheme" |
| `ensure_blank_lines` | `:ColorMyAscii ensure-blank-lines<cr>` | "color_my_ascii: format code blocks" |
| `show_config` | `:ColorMyAscii show-config<cr>` | "color_my_ascii: show config" |
| `debug` | `:ColorMyAscii debug<cr>` | "color_my_ascii: show debug info" |
| `check_fences` | `:ColorMyAscii check-fences<cr>` | "color_my_ascii: check fences" |
| `fence_jump` | `:ColorMyAscii fence-jump<cr>` | "color_my_ascii: jump between fence markers (%-style)" |
| `fence_yank` | `:Fence yank<cr>` | "color_my_ascii: yank fence content" |
| `fence_export` | `:Fence export<cr>` | "color_my_ascii: export fence content to a file" |
| `fence_open` | `:Fence open<cr>` | "color_my_ascii: open fence content in a split" |
| `fence_run` | `:Fence run<cr>` | "color_my_ascii: run fence content" |
| `fence_format` | `:Fence format<cr>` | "color_my_ascii: format fence content" |
| `fence_select` | `:Fence select<cr>` | "color_my_ascii: select fence content" |
| `fence_wrap` | `:Fence wrap<cr>` | "color_my_ascii: wrap line in a fence" |
| `fence_unwrap` | `:Fence unwrap<cr>` | "color_my_ascii: unwrap fence under cursor" |

All mode `n`. The lhs for each is whatever the user assigns in their own
`setup({ keymaps = { <action> = "<leader>ah" } })` call — there are no
built-in defaults. Since `:Fence` itself is only registered buffer-local on
markdown buffers (see `Autocmds/color_my_ascii.nvim.md`'s `FileType`
registration), the `fence_*` actions (like `check_fences`/`fence_jump`) only
do anything useful there — bound globally via a normal `vim.keymap.set('n',
...)`, same as every other action here.

## Dynamic keymaps (not user-configurable, not in `docs/BINDINGS.md`)

- `lua/color_my_ascii/commands/schemes.lua` — inside `:ColorMyAscii schemes
  pick`'s Telescope picker, a `CursorMoved` autocmd (not a keymap) drives live
  scheme preview as the cursor moves; the picker's own navigation keys are
  Telescope's, not this plugin's.

## Notes

- **`docs/BINDINGS.md` cross-reference**: current and accurate for keymaps/commands.
**Added 2026-08-24:** `toggle_buffer` and `fence_export`.

`toggle` is and always was **global** (one `state.enabled` flag across every
managed buffer); the audit's premise that it was current-buffer-only was
backwards. What had no expression was turning highlighting off in *one*
buffer, which `:ColorMyAscii toggle buffer` now does. The bare command is
unchanged — the new scope argument defaults to `global`.

`fence_export` was the one `Fence` subcommand missing from the ACTIONS table.

- No which-key group — each action carries its own `desc`, and lhs is entirely user-chosen.
