# reposcope.nvim — User Commands Cheatsheet

`:Reposcope` rebuilt via `lib.nvim.usercmd.composer` (migrated 2026-07-19).
**No syntax change**: same `:Reposcope <subcommand> [args]` grammar, now
15 subcommands (was 14 — `session` added 2026-07-25).

Source: `lua/reposcope/bindings/usrcmds.lua`
Docs: `docs/COMMANDS.md`, `README.md`, `doc/reposcope.txt`

`start`, `close`, `sort`, `filter`, `filter-prompt`, `filter-clear`,
`update [dir]`, `status [dir]`, `providers`, `session save|restore|clear`,
`stats`, `skipped-readmes`, `toggle-dev`, `print-dev`, `prompt [fields...]`
— see `docs/COMMANDS.md` for the full per-subcommand reference.

## Notes

- **2026-07-25 — persistent session save/restore landed**: new
  `lua/reposcope/state/session_state.lua` (`save`/`restore`/`clear`) persists
  the active provider, visible prompt fields + their typed text, the last
  built search query, the active filter text, and the sort mode as one JSON
  file at `stdpath("cache")/reposcope/data/session.json` (`config.get_session_path()`).
  `restore()` re-runs the last search via `provider_controller.fetch_repositories_and_display`'s
  `on_success` callback and only then re-applies filter/sort, so it never
  races the async fetch. Required threading a "current value" getter through
  three modules that previously only had UI-driven setters: `filter_repos.get_current_filter()`,
  `sort_prompt.get_current_sort()` (plus a new `apply_sort()` that
  `prompt_sort()`'s `vim.ui.select` callback now just calls), and
  `prompt_input.get_last_query()`. `filter_prompt.lua`'s floating-input
  callback was also collapsed to delegate to `filter_repos.apply_filter`
  instead of duplicating the substring-match loop, so both filter entry
  points share one "current filter" tracking point.
- **2026-07-24 — multi-provider support landed**: `provider` config option
  now accepts `"github"`, `"gitlab"`, or `"codeberg"` (was GitHub-only), each
  with its own `lua/reposcope/providers/<name>/` implementation dispatched
  through `controllers/provider_controller.lua`'s registry. New `providers`
  subcommand lists the registry and marks the active one (`* name` vs
  `  name`). GitLab/Codeberg search only supports plain substring matching
  (no GitHub-style `owner:`/`language:` qualifiers) — a real API constraint,
  not a shortcut taken during implementation.

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
