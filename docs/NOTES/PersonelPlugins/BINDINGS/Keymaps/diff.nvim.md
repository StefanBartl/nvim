# diff.nvim — Keymaps Cheatsheet

Source: `lua/diff/bindings/keymaps.lua`, `lua/diff/features/exit.lua`, `lua/diff/core/render.lua`
Cross-reference: `docs/BINDINGS.md` — verified accurate and current, including scope caveats.

Module doc: "The only keymap diff.nvim ships is the 'leave diffmode' key."

| lhs | mode | action | desc | condition |
| --- | --- | --- | --- | --- |
| `cfg.key` (default `<Esc><Esc>`; may be a list) | n | Exit diff mode: `:diffoff!` if current window is diffed, else scans all windows for a stray diffed one, else notifies "Not in diff mode" | "[diff] Exit diff mode when active" | Only if `cfg.exit.scope == "global"` (default scope is `"buffer"`, so **off by default**) |
| `cfg.key` (default `<Esc><Esc>`; may be a list) | n | Same exit function, buffer-local | "[diff] Exit diff mode" | Only if `cfg.exit.scope == "buffer"` (**the default**); attached per-buffer right after diff.nvim puts a scratch/base/target buffer into diffmode, and after `:DiffOrig` |

## Dynamic float-close keymaps

| lhs | mode | Where | action |
| --- | --- | --- | --- |
| `q` / `<Esc>` | n | `core/render.lua`'s `open_float()` (used when `view=float`) | Closes the diff float, buffer-local |

## Optional shortcuts (`cfg.keymaps`, since 2026-08-24)

**Nothing bound by default** — every entry is opt-in, so this table lists what
*can* be bound, not what is. The `desc` is exact; the lhs is whatever the user
configured.

| `keymaps.<name>` | mode | runs | desc |
| --- | --- | --- | --- |
| `diff` | n | `:Diff` | "[diff] Diff (pick source and target)" |
| `diff_head` | n | `:Diff target=git:HEAD` | "[diff] Diff against HEAD" |
| `diff_merge` | n | `:Diff base=git:HEAD target=git:MERGE_HEAD` | "[diff] Diff the merge conflict" |
| `diff_buffers` | n | `:DiffBuffers` | "[diff] Diff against another buffer" |
| `diff_orig` | n | `:DiffOrig` | "[diff] Diff against the version on disk" |
| `diff_clear` | n | `:DiffClear` | "[diff] Close all diff windows" |

The rhs is built from `cfg.commands.*`, so a renamed command renames what the
shortcut runs. A shortcut whose `cfg.features.*` gate is off is refused with a
warning instead of bound.

## Notes



- **`cfg.exit.key` accepts a list (since 2026-08-24)**: `{ "<Esc><Esc>", "<C-c>" }` binds both, so a colliding default can be supplemented instead of replaced. `attach_buffer`/`detach_buffer` normalize it in one place — `native_diffthis` previously deleted `cfg.key` directly, which would have silently stopped removing anything once a list was possible.
- **Why buffer scope is the default**: the original global `<Esc><Esc>` mapping noticeably delayed a normal `<Esc>` everywhere, since Neovim had to wait for a possible second key. Scoping the mapping to buffers diff.nvim itself diffs avoids that global cost.
- The float-close key exists separately because split/inline views rely on `:q`/`:DiffClear` instead — a float wants an obvious dedicated close key.
- No which-key group — confirmed against source: no `bindings/which_key.lua` (or equivalent) exists. `desc` is set on every key, so which-key still discovers them individually if installed; there's just no leader-prefixed group to label.
