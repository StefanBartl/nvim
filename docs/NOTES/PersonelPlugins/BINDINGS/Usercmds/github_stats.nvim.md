# github_stats.nvim — User Commands Cheatsheet

One command tree, built via `lib.nvim.usercmd.composer` (migrated 2026-07-19).
Replaces 10 independent flat `:GithubStatsX` commands — breaking change, no
compat aliases.

Source: `lua/github_stats/bindings/usrcmds/init.lua`
Docs: `docs/usercommands.md`, `docs/BINDINGS.md`, `doc/github_stats.txt`
(renamed from `doc/github_stats.nvim.txt` in the 2026-08-06 checklist pass,
to match the sibling-plugin `doc/<name>.txt` convention)

| Command | Args | Effect |
| --- | --- | --- |
| `:GithubStats fetch` | `[force]` | Fetch all metrics (respects/bypasses interval) |
| `:GithubStats show` | `{repo} {metric} [start] [end]` | Detailed stats for repo/metric |
| `:GithubStats summary` | `{clones\|views}` | Aggregate across all configured repos |
| `:GithubStats referrers` | `{repo} [limit]` | Top referrers |
| `:GithubStats paths` | `{repo} [limit]` | Top paths |
| `:GithubStats chart` | `{repo} {clones\|views\|both} [start\|range] [end]` | Sparkline/comparison chart |
| `:GithubStats export` | `{repo\|all} {metric} {filepath}` | Export to CSV/Markdown |
| `:GithubStats diff` | `{repo} {metric} {period1} {period2}` | Compare two periods |
| `:GithubStats debug` | — | Diagnostic dump |
| `:GithubStats[!] dashboard` | — | Open dashboard (`!` forces refresh) |

## Notes

- **Dead code removed**: `lua/github_stats/commands.lua` (383 lines) was a
  fully orphaned duplicate of the real `bindings/usrcmds/` registration —
  never `require`d anywhere (confirmed via grep), left behind by an earlier
  modularization pass. This resolves the "possible duplicate registration"
  flagged in the original migration survey: it was dead code, not a live
  double-registration (`init.lua` only ever required `bindings.usrcmds`, so
  `nvim_create_user_command` was never actually called twice at runtime).
  Deleted as part of this migration.
- **Bang moved to the verb**: `:GithubStatsDashboard!` → `:GithubStats!
  dashboard` (composer has one bang slot per command, shared across
  subcommands — same breaking-syntax shape as cascade.nvim's `:Cascade!
  rotate`).
- **Composer migration design**: every `execute()`/`complete()` pair under
  `bindings/usrcmds/*.lua` (fetch/show/summary/referrers/paths/chart/export/
  diff/debug/dashboard) is byte-for-byte unchanged. Each composer route
  declares a typed positional-arg schema (custom types `GH_REPO`,
  `GH_REPO_OR_ALL`, `GH_DATE_OR_PRESET`, `GH_PERIOD` for dynamic,
  config-driven completion), then reconstructs a single space-joined string
  (`table.concat(ctx.pos + ctx.rest, " ")`) and forwards it as `{ args =
  "..." }` — the exact shape `nvim_create_user_command`'s callback used to
  pass — so every handler's own `vim.split(args.args, "%s+")` parsing keeps
  working unmodified.
- **Full multi-position completion recovered** (unlike buffer-ctx.nvim's
  `:Format`): `show`/`chart`/`export`/`diff` all declare their real
  multi-slot arg schema (repo, metric, dates/periods, filepath) rather than
  a single-first-arg + `ctx.rest` escape hatch, since these are genuine
  fixed-position grammars, not open-ended ones. One accepted, minor
  completion-parity loss: the original `show`/`chart` completers suppressed
  `end_date` suggestions once `start_date` was itself a preset (a preset
  already implies its own end date) — that cross-slot refinement doesn't
  fit composer's per-slot completion model, so `end_date` now always offers
  presets regardless. Dispatch/validation is unaffected either way.
- **Metric validation now via composer's `enum`** (`clones`/`views`, or
  `clones`/`views`/`both` for `chart`) instead of each handler's own
  `if metric ~= "clones" and metric ~= "views"` check — the original checks
  are still there and still run (defense in depth, now redundant but
  harmless), since the reconstructed string is passed straight into the
  unmodified handler.
- **No CI exists for this repo** (no `.github/workflows/`) and no locally
  runnable test suite (`lua/github_stats/tests/**` are `busted` specs with
  no local runner — a pre-existing, documented gap in
  `docs/ROADMAP/Checklist.md`, not something this migration touches).
  Verified entirely via manual headless `nvim --headless` dispatch/
  completion checks instead.
- **Background task spun off, already fixed**: `health.lua` had two
  separate `vim.health.start("GitHub Stats Dashboard")` blocks (found
  incidentally while updating the `:GithubStatsFetch`/`:GithubStatsDebug`
  hint strings inside health.lua's error messages) — merged in a follow-up
  commit (`6f1660c fix(health): merge duplicate GitHub Stats Dashboard
  health sections`), already pushed.
