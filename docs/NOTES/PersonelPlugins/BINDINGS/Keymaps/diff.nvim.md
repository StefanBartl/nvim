# diff.nvim — Keymaps Cheatsheet

Source: `lua/diff_nvim/bindings/keymaps.lua`, `lua/diff_nvim/features/exit.lua`, `lua/diff_nvim/core/render.lua`
Cross-reference: `docs/BINDINGS.md` — verified accurate and current, including scope caveats.

Module doc: "The only keymap diff.nvim ships is the 'leave diffmode' key."

| lhs | mode | action | desc | condition |
| --- | --- | --- | --- | --- |
| `cfg.key` (default `<Esc><Esc>`) | n | Exit diff mode: `:diffoff!` if current window is diffed, else scans all windows for a stray diffed one, else notifies "Not in diff mode" | "[diff] Exit diff mode when active" | Only if `cfg.exit.scope == "global"` (default scope is `"buffer"`, so **off by default**) |
| `cfg.key` (default `<Esc><Esc>`) | n | Same exit function, buffer-local | "[diff] Exit diff mode" | Only if `cfg.exit.scope == "buffer"` (**the default**); attached per-buffer right after diff.nvim puts a scratch/base/target buffer into diffmode, and after `:DiffOrig` |

## Dynamic float-close keymaps

| lhs | mode | Where | action |
| --- | --- | --- | --- |
| `q` / `<Esc>` | n | `core/render.lua`'s `open_float()` (used when `view=float`) | Closes the diff float, buffer-local |

## Notes

- **Why buffer scope is the default**: the original global `<Esc><Esc>` mapping noticeably delayed a normal `<Esc>` everywhere, since Neovim had to wait for a possible second key. Scoping the mapping to buffers diff.nvim itself diffs avoids that global cost.
- The float-close key exists separately because split/inline views rely on `:q`/`:DiffClear` instead — a float wants an obvious dedicated close key.
