# fileops.nvim — User Commands Cheatsheet

`:File` rebuilt via `lib.nvim.usercmd.composer` (migrated 2026-07-19).
**No syntax change**: same `:[count]File[!] {subcommand} [args…]` grammar,
same 11 subcommands, same `:N File next/prev` count-prefix cycling.

Source: `lua/fileops_nvim/bindings/usrcmds.lua`
Docs: `doc/fileops.txt`, `docs/installation.md`, `README.md`

`new`, `write`, `saveas`, `writeto`, `mkdir`, `rename [%] {dest}`,
`duplicate [%] {dest}`, `delete`, `next [target]`, `prev [target]`,
`cd [window|tab|global]` — see `doc/fileops.txt` §5 for the full reference.

## Notes

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
- **Vestigial completion dropped**: the original's `delete` subcommand
  offered `"%"` as a first-arg completion candidate, but `dispatch()`'s
  `delete` branch takes zero arguments (`file.delete_current({force=bang})`
  never reads `fargs`) — a harmless leftover, not reproduced (`delete` has
  no declared args in the composer route).
- `resolve_dest`'s `[%] {dest}` two-shape argument (implicit `%` when one
  arg given, explicit when two) is preserved by forwarding composer's bound
  positionals straight into the unchanged `resolve_dest(fargs)`/
  `dispatch()` functions — no reimplementation.
