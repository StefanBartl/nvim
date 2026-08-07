# fileops.nvim — Autocmds Cheatsheet

Sources: `lua/fileops/bindings/autocmds.lua`, `features/on_hold.lua`, `features/conflict_marks.lua`
Cross-reference: `docs/BINDINGS.md` (complete, incl. augroup names), `docs/autocommands.md` (narrower, conceptual overview) — both current.

| Event(s) | Augroup (clear) | Condition | Action |
| --- | --- | --- | --- |
| `BufWritePre` | `fileops_auto_mkdir` | `cfg.auto_mkdir.enable ~= false` (default on) | Creates parent dirs before write; skips remote paths (`ssh://`, `http://`, …) unless `skip_remote=false` |
| `CursorHold`/`CursorHoldI` | `fileops_on_hold_preview` | `cfg.on_hold.enable == true` (default **off**) | Per-window-throttled: shows gitsigns inline hunk preview, or a fallback previous-line-content virtual-text via `git blame`/`git show` (argv-only, no shell). Sets `vim.o.updatetime = 100` as a side effect |
| `CursorMoved`, `BufHidden`, `InsertEnter` (`once`, buffer-local) | `fileops_on_hold_cleanup` | registered dynamically each time a preview fires | Clears the line-diff virtual text on next move |
| `ModeChanged` | `fileops_on_hold_modeclear` | same feature | Clears preview + bumps generation counter when leaving an allowed mode (guards against a stale scheduled preview firing after a mode switch) |
| `BufWinEnter` | `fileops_conflict_marks_on` | `cfg.conflict_marks.enable ~= false` (default on) | `matchadd()`s conflict-marker patterns (`<<<<<<<`/`=======`/`>>>>>>>`) per-window |
| `BufWinLeave` | `fileops_conflict_marks_off` | same | `matchdelete()`s the stored match IDs |

Plus a `User FileopsChanged` event (`{action, path}`) fired via
`nvim_exec_autocmds` from `ops/file.lua`'s `notify_change()` — not a
listener registered here, but the extension point third-party plugins
(session managers, tree explorers) can hook. Fired unconditionally on every
tree-changing op; fileops.nvim's own neo-tree/nvim-tree reload additionally
gated by `config.explorer.refresh_on_change`.

## Notes

- `on_hold` is opt-in — most invasive feature here (changes `updatetime` globally while enabled).
- `conflict_marks` uses window-local match IDs (`vim.w._fileops_conflict_match_ids`), cleaned up symmetrically on enter/leave.

## Changelog

- 2026-07-23: fixed the `_nvim` infix throughout this file (`fileops_nvim_*` →
  `fileops_*`) — stale from before the `lua/fileops_nvim` → `lua/fileops`
  module rename (`d803686`, see git log). The session-ccf9cf branch that
  added most of the autocmd/usrcmd feature work below had branched before
  that rename landed on main and was merged back in afterwards; see the
  Usercmds note for the full merge story.
