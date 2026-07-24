# reposcope.nvim — Autocmds Cheatsheet

Sources: `lua/reposcope/bindings/autocmds.lua`, `ui/prompt/prompt_autocmds.lua`
Cross-reference: `docs/BINDINGS.md` — thorough, matches source for everything it covers.

## Global

| Event | Augroup | Pattern (matched in callback) | Action |
| --- | --- | --- | --- |
| `QuitPre` | **none** — registered directly via `nvim_create_autocmd`, id tracked manually in a module-local var and deleted with `nvim_del_autocmd` on close/re-registration | checks `nvim_buf_get_name(buf):find("^reposcope://")` | Closes the whole Reposcope UI when one of its windows is closed directly via `:q`/`:q!`/`:wq` |

**Note**: unlike every other autocmd in this codebase (and every other
audited repo), this one deliberately skips `nvim_create_augroup`, relying on
manual id-tracking instead — worth flagging since it breaks the pattern used
everywhere else.

## Prompt (`prompt_autocmds.lua`, group `reposcope_prompt_autocmds`)

Explicitly `nvim_del_augroup_by_name` + recreated with `clear=true` on every
`setup_autocmds()` call — called from `ui/prompt/init.lua` on every UI open,
and from `readme_viewer.lua`'s `close_viewer()` on viewer close.

| Event(s) | Pattern | Action |
| --- | --- | --- |
| `TextChangedI` | `*` | Reads line 2 of the active prompt buffer (trimmed), stores it via `prompt_state.set_field_text(field, input)` |
| `CursorMoved`, `CursorMovedI`, `InsertEnter`, `InsertLeave` | `*` | If the buffer has ≥2 lines and cursor isn't on line 2, force-resets it there (pcall-guarded, notifies on failure) |

## Details

- **Why the cursor gets forced to line 2**: prompt buffers use line 1 as a label/header and line 2 as the actual editable input — this autocmd is what prevents users from typing on the wrong line.
- **The one real doc gap found**: `docs/BINDINGS.md` doesn't mention the buffer-local `q`/`<Esc>` close keymaps on the stats popup or the README viewer's `q` keymap — see [Keymaps cheatsheet](../Keymaps/reposcope.nvim.md).
