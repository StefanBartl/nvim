# reposcope.nvim — Keymaps Cheatsheet

Sources: `lua/reposcope/bindings/keymaps.lua`, `ui/actions/readme_viewer.lua`, `utils/stats.lua`

**⚠️ `docs/BINDINGS.md` omits two real keymaps** (see below) — everything
else in it matches source closely.

## Global open/close (`M.set_user_keymaps`, only if `config.get_option("keymaps") ~= false`)

| lhs (config key) | mode | action | desc |
| --- | --- | --- | --- |
| `<leader>rs` (`keymaps.open`) | n | `pcall`-wrapped `open_ui()`; prints an error via `print()` (not `notify`) on failure | "Open Reposcope" |
| `<leader>rc` (`keymaps.close`) | n | Same pattern, `close_ui()` | "Close Reposcope" |

Each only registered if its config value is truthy/non-empty.

## Prompt-field keymaps (`M.set_prompt_keymaps`, buffer-local to every prompt buffer)

Built from an actions table, each action individually configurable via
`config.prompt_keymaps` (a value can be a list for multiple lhs, e.g.
`focus_next`); set an action to `false`/`""` to disable it.

| Action | Default lhs | mode | action |
| --- | --- | --- | --- |
| `confirm` | `<CR>` | i | `prompt_input.on_enter()` |
| `nav_up` | `<Up>` | n, i | Navigate list up, fetch README for newly-selected repo |
| `nav_down` | `<Down>` | n, i | Navigate list down, fetch README |
| `focus_next` | `<C-w>`, `<C-l>`, `<Tab>` (list) | n, i | Focus next UI panel |
| `focus_prev` | `<C-h>`, `<S-Tab>` (list) | n, i | Focus previous panel |
| `open_viewer` | `<C-v>` | n, i | Open README viewer |
| `open_editor` | `<C-b>` | n, i | Open README editor |
| `clone` | `<C-c>` | n, i | Prompt and clone selected repo |
| `backspace` | `<BS>` | n, i | Custom: suppressed at column 0, line 2 of the `keywords` prompt buffer (notifies "Backspace disabled..."); otherwise feeds a real `<BS>` |

## Close-UI keymaps (`M.set_close_ui_keymaps`, over background/preview/list/all-prompt buffers, tagged `"reposcope_ui"`)

| lhs | mode | action | desc |
| --- | --- | --- | --- |
| `<Esc>` | n | `close_ui()` | "Close Reposcope" |
| `<Esc>` | i, t, v | `<C-\><C-n>` (switch to normal mode first) | "Switch to normal mode" |
| `<C-w>` | n | `close_ui()` | "Close Reposcope" |
| `<C-w>` | i, t, v | `<Nop>` | "Disabled" |

## Component-local (not in `docs/BINDINGS.md`)

| lhs | mode | Where | action |
| --- | --- | --- | --- |
| `q` | n | `ui/actions/readme_viewer.lua` (`nvim_buf_set_keymap`) | Closes the README viewer, restores prompt autocmds + prompt keymaps |
| `q` / `<Esc>` | n | `utils/stats.lua` | Closes the stats popup buffer/window |

## Notes

- Opening the README viewer explicitly tears down the prompt autocmds and prompt keymaps before installing its own `q` keymap; `close_viewer()` restores them — the two keymap sets are mutually exclusive **by design**, not overlapping accidentally.
- See [Autocmds cheatsheet](../Autocmds/reposcope.nvim.md) for the prompt-buffer autocmds these keymaps interact with.
