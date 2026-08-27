# fileops.nvim — User Commands Cheatsheet

`:File` built via `lib.nvim.bindings.usercmd.composer`. Grammar:
`:[count]File[!] {subcommand} [args…]`

Source: `lua/fileops/bindings/usrcmds.lua`
Docs: `doc/fileops.txt`, `docs/commands.md`, `docs/BINDINGS.md`, `README.md`

## Subcommands (21)

| Subcommand | Args | Notes |
| --- | --- | --- |
| `new` | `[path]` | set buffer name, no write; prompts via `vim.ui.input` if `path` omitted |
| `write` | `[path]` | set buffer name + write (`!` overwrites) |
| `saveas` | `[path]` | `:saveas`-equivalent (`!` overwrites) |
| `writeto` | `[path]` | write a copy, name stays (`!` overwrites) |
| `mkdir` | — | create parent dirs for current buffer |
| `touch` | `[path]` | create an empty file if missing (real `touch` semantics) |
| `rename` | `[%] [dest]` | rename + update buffer (reloads); git-aware (see below); resaves active `:mksession` session |
| `move` | `[%] [dest]` | move + update buffer (no reload); git-aware; resaves active `:mksession` session |
| `duplicate` | `[%] [dest]` | copy + open the copy (`!` overwrites); git-aware (warn only) |
| `copy` | `[%] [dest]` | copy without opening (`!` overwrites); git-aware (warn only) |
| `delete` | `[%]` | delete + close buffer (`!` force-closes); git-aware |
| `next` | `[target] [glob]` | navigate directory listing; `[glob]` e.g. `*.lua` narrows before navigating |
| `prev` | `[target] [glob]` | same, backwards |
| `first` | `[target]` | jump to first file in directory listing |
| `last` | `[target]` | jump to last file |
| `open` | `[target]` | reopen the current file in a different window target (no navigation) |
| `path` | `[mode]` | copy path to clipboard — `abs`\|`rel`\|`name`\|`dir` |
| `info` | — | size/mtime/permissions via libuv `fs_stat` |
| `bulk rename` | `{pattern} {replacement}` | batch-rename files in dir via Lua pattern; preview + `vim.ui.select` confirm; `!` overwrites |
| `cd` | `[scope]` | cd to buffer's dir + refresh explorer — `window`\|`tab`\|`global` |
| `help` | — | short usage overview in the command line |

`[path]`/`[dest]` args are all optional: omitted → `vim.ui.input` prompt
instead of an error. Tab-completion for them is relative to the **current
buffer's directory**, not cwd.

`[target]` values (next/prev/first/last/open): `%`/`replace`, `stay`/`current`,
`new`/`split`, `vsplit`, `tab`, `bg`/`background`.

`:N File next/prev` count-prefix still cycles N files at once
(`ctx.range.count`).

## Git-aware ops (opt-in: `git_aware.enable = true`)

`rename`/`move`/`duplicate`/`copy`/`delete` check tracked-ness via
`git ls-files` when enabled. Default `git_aware.warn_only = true` just notes
it in the result message; `warn_only = false` uses `git mv`/`git rm` instead
of the plain libuv op (delete only when `delete.mode == "permanent"`).

## Explorer refresh / events

Every mutating op (new/write/saveas/writeto/mkdir/touch/rename/move/
duplicate/copy/delete) fires a `User FileopsChanged` autocmd
(`{action, path}`) and reloads neo-tree/nvim-tree in place, gated by
`explorer.refresh_on_change` (default `true`; the event itself always fires).

## Session compat (`session_compat.enable`, default true)

`rename`/`move` resave the active `:mksession` session (`v:this_session`)
after repointing the buffer, so the session file doesn't keep pointing at
the old path. No-op when `v:this_session == ""` (no active session). Other
session managers (possession.nvim, `sessions.nvim`) should hook the
`User FileopsChanged` event above instead — this only covers Vim/Neovim's
own built-in `:mksession`.

## Notes

- `next`/`prev`'s first arg can't be a strict enum anymore now that it may
  be a glob pattern instead of a target keyword (`:File next *.lua`) — a
  custom `FILEOPS_CYCLE_ARG` composer type validates anything but still
  offers the known target keywords for `<Tab>`; `resolve_cycle_args()` in
  `usrcmds.lua` decides at dispatch time whether arg1 was a target or the
  pattern.
- `:File open` is new, not a rename of `next`/`prev` — it reopens the
  *current* file in a different window target without navigating anywhere
  (`cycle.open_current()`, which just calls the exported `cycle.open_path()`
  on the current buffer's own name).
- **Motivated a new composer capability — Phase 8, `spec.count`/`route.count`
  (`:N Verb` prefix)**. fileops.nvim's `:File next`/`:File prev` cycling
  needs a `v:count`-style prefix (`:5File next` = skip 5 at once) — composer
  had no way to register this (only `bang`/`range` were wired through to
  `nvim_create_user_command`, even though `ctx.range.count` was already
  plumbed in since Phase 1 and would have silently sat at `-1` forever).
  Added `wants_count(spec)` mirroring `wants_bang`/`wants_range` in
  `lib.nvim` itself before starting this migration — see
  `lib.nvim`'s own `docs/ROADMAP/usrcmd_builder.md` §12 Phase 8. Verified
  headless end-to-end: `:5File next split` → `ctx.range.count == 5`,
  bare `:File next` → falls back to `1` (same as the original's own
  `(a.count and a.count > 0) and a.count or 1`).
- **CI gap found and fixed**: `.github/workflows/ci.yml`'s `test` job ran
  `docs/TESTS/run.lua`, which *hard-fails* (not a soft skip) if lib.nvim
  isn't found — but the workflow never checked out a lib.nvim sibling. This
  predates the composer migration (`ops/file.lua`/`ops/cycle.lua` already
  hard-required lib.nvim) — fixed by checking out `StefanBartl/lib.nvim` as
  a sibling, matching every other CI fix in this migration series.
- **Doc/health "runs fully standalone" claims were already false before
  this migration** — `ops/file.lua`'s `lib.nvim.cross.fs.mutate` and
  `ops/cycle.lua`'s `lib.nvim.buffer.open_background` were already
  unconditional `require`s (no pcall). `doc/fileops.txt` and `health.lua`
  both still described lib.nvim as a fully soft, optional dependency with
  a genuine "standalone mode" — corrected throughout (requirements section,
  installation snippets ×3, architecture note, health check listing) to
  distinguish the actually-required parts (command layer, fs mutate,
  background buffer open) from the genuinely-cosmetic soft part (notify
  styling only).
- `resolve_dest`'s `[%] {dest}` two-shape argument (implicit `%` when one
  arg given, explicit when two) is preserved by forwarding composer's bound
  positionals straight into `resolve_dest(fargs)`/`dispatch()`.

## Changelog

- 2026-07-21: extended from the original 11 subcommands to 19 in one session
  — `open`, `path`, `info`, `bulk rename` are new subcommands; `copy`,
  `touch`, `first`, `last` were added just before that. `bulk rename` is a
  two-segment composer route (`path = { "bulk", "rename" }`), same mechanism
  as any other subcommand, dispatched through a synthetic `"bulk_rename"` key.
- 2026-07-23: the feature branch that did the 2026-07-21 work above
  (`claude/session-ccf9cf`) had branched *before* `d803686`
  ("refactor: drop `_nvim` suffix from lua module root") landed on `main`,
  so it never got that rename and sat unmerged with the whole module tree
  still at `lua/fileops_nvim/`. Discovered it via `git log --oneline --all`
  while starting this same roadmap task fresh — merged it into
  `main`'s successor branch instead of redoing the work, resolving the
  rename conflict by keeping the no-suffix `lua/fileops/` path (3 conflicts
  total: `bindings/usrcmds.lua`'s require block, plus `ops/bulk.lua` and
  `util/git.lua` needing a manual `fileops_nvim` → `fileops` sed pass after
  git placed them at the right new path automatically). This is why the
  Autocmds cheatsheet's augroup names had a stale `fileops_nvim_*` infix
  until the same pass fixed it.
- 2026-07-23 (2): implemented the one item the merged branch had legitimately
  left undone — "Session-Kompatibilität" (`session_compat`, see above) — and
  caught a real bug in the first draft via the new `file_spec.lua` test:
  bare `vim.cmd("mksession!")` does **not** reuse `v:this_session`, it
  writes `./Session.vim` in Neovim's cwd instead (confirmed against
  `:h mksession`'s actual behavior, not just the docstring's assumption).
  Fixed by passing `fn.fnameescape(vim.v.this_session)` explicitly. Left a
  stray `Session.vim` in the repo root during manual debugging before the
  fix landed — cleaned up before committing.
