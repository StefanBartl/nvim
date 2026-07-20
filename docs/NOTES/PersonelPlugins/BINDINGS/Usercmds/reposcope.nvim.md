# reposcope.nvim — User Commands Cheatsheet

`:Reposcope` rebuilt via `lib.nvim.usercmd.composer` (migrated 2026-07-19).
**No syntax change**: same `:Reposcope <subcommand> [args]` grammar, same
13 subcommands.

Source: `lua/reposcope/bindings/usrcmds.lua`
Docs: `docs/COMMANDS.md`, `README.md`, `doc/reposcope.txt`

`start`, `close`, `sort`, `filter`, `filter-prompt`, `filter-clear`,
`update [dir]`, `status [dir]`, `stats`, `skipped-readmes`, `toggle-dev`,
`print-dev`, `prompt [fields...]` — see `docs/COMMANDS.md` for the full
per-subcommand reference.

## Notes

- **Hand-rolled `print_usage()` replaced outright by composer's own
  auto-generated usage** (matches the roadmap note this repo was
  earmarked for) — same content shape (subcommand + `.desc` per line), no
  functionality lost, one less thing to keep in sync by hand. Bare
  `:Reposcope` and an unknown-subcommand error both now go through
  composer's own usage listing instead of the removed `print_usage()`.
- **Dynamic per-subcommand completion types, not static snapshots**: a
  real bug caught and fixed during implementation — my first pass called
  each subcommand's `entry.complete("")` *once* at `setup()` time to bake
  a static `values` list, which is actively wrong for `update`/`status`
  (directory listings change constantly) and stale for `prompt` (available
  fields could change with config). Fixed by registering one small custom
  composer type per completable subcommand (`REPOSCOPE_UPDATE`,
  `REPOSCOPE_STATUS`, `REPOSCOPE_PROMPT`), each delegating straight to the
  original `entry.complete(arg_lead)` fresh on every `<Tab>` request —
  verified headless that `update <Tab>` returns live directory listings
  and `prompt <Tab>` returns the live field list, not a setup-time
  snapshot.
- **`prompt`'s multi-field completion**: the original completer is
  position-agnostic (always returns the full field list regardless of how
  many field names already precede the cursor) — same tradeoff already
  documented elsewhere in this migration series (buffer-ctx.nvim's
  `:Format`, github_stats.nvim): composer only completes the declared
  first slot (`a1`), so `:Reposcope prompt prefix <Tab>` no longer
  re-offers the field list for the second field onward. Dispatch is
  unaffected — `reload_prompt` still receives every typed field via
  `{ctx.args.a1, ...ctx.rest}`, verified with a 3-field dispatch test.
- lib.nvim was already a deep, pervasive hard dependency throughout this
  repo (network layer, `utils.checks`, `utils.os`, `utils.protection`,
  ...) — README/INSTALLATION.md already listed it as a plain, unqualified
  `dependencies` entry with no "optional" framing to fix. No health.lua
  check added (the file has no existing lib.nvim section to extend
  consistently with, unlike other migrated repos).
- No CI for this repo — pre-existing, not part of this migration's scope.
