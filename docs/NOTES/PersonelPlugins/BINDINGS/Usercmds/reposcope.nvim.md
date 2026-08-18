# reposcope.nvim — User Commands Cheatsheet

`:Reposcope` rebuilt via `lib.nvim.usercmd.composer` (migrated 2026-07-19).
**No syntax change**: same `:Reposcope <subcommand> [args]` grammar, now
17 subcommands (was 14 — `session` added 2026-07-25; `favorites`/`queries`
added 2026-08-09).

Source: `lua/reposcope/bindings/usrcmds.lua`
Docs: `docs/COMMANDS.md`, `README.md`, `doc/reposcope.txt`

`start`, `close`, `sort`, `filter`, `filter-prompt`, `filter-clear`,
`update [dir]`, `status [dir] [--out] [--to]`, `providers`,
`session save|restore|clear`, `favorites list|clear`, `queries list|clear`,
`stats`, `skipped-readmes`, `toggle-dev`, `print-dev`, `prompt [fields...]`
— see `docs/COMMANDS.md` for the full per-subcommand reference.

## Notes

- **2026-08-18 — `:Reposcope status` dashboard reworked** (no new subcommand,
  so the count above is unchanged): the "no feedback after pressing p/P/f"
  complaint turned out to be a *bug*, not a missing feature —
  `status_view._run_row_action` reported via `notify(..., 2)`, but
  `utils/debug.lua`'s notify drops anything below WARN unless dev mode is on,
  so every "push …"/"done" message had always been invisible in normal use and
  only failures got through. Raised to level 3, plus a spinner on the row and a
  `utils.progress` handle — reposcope already had `progress_style = "statusline"`
  in `lua/plugins/personal/init.lua`, so this surfaces in the `plugin_progress`
  statusline component with no new wiring.
  Also: AHEAD/BEH (which printed `+0/-0` on nearly every row) replaced by a
  SYNC column that renders only real divergence and vanishes when nothing
  differs; new LAST COMMIT column (second, concurrent `git log -1` per repo);
  extmark highlighting via `ReposcopeStatus*` groups linked to diagnostic
  colors — deliberately *not* a syntax file, which would also colour a repo
  literally named "clean"; name/branch columns capped, since one long topic
  branch stretched the column for all 54 repos; the dashboard now survives
  opening a README (cached records + `M.reopen()` + buffer-local `q`, bound
  explicitly rather than via a `BufWinLeave` autocmd, which fires on *any*
  navigation away); new `S`/`s`/`r`/`R`/`y`/`?` keys. The winbar legend and the
  `?` cheatsheet are both generated from one `ROW_KEYMAPS` table, so they can't
  advertise a key that isn't bound (same single-source-of-truth idea as
  `help_view.lua`). Two LuaJIT gotchas hit here: `//` integer division is Lua
  5.3+ only (Neovim is LuaJIT/5.1), and `git status --short --branch` always
  emits a `## branch` line, so raw-output emptiness is not a valid "is it
  clean" test.

- **2026-08-09 (2) — `favorites`/`queries` added (roadmap item "Favoriten
  für Repositories")**: two new generic-wrapper subcommands (both go
  through the same `build_routes()` machinery as `session`/`providers`, no
  custom composer route needed since neither takes flags). `favorites
  list|clear` fronts the new `state/favorites_state.lua` (persisted
  metadata + README snapshot per favorite, toggled via the `toggle_favorite`
  prompt keymap — see the Keymaps cheatsheet — not a separate add command).
  `queries list|clear` fronts `state/query_stats.lua`, which
  `prompt_input.on_enter()` now calls on every real search
  (`record_query(query)`, right after `_last_query = query`) — recording is
  unconditional, no config flag, since it's local-only and mirrors how
  `session_state` already works with no opt-in. Both new state modules
  copy `session_state.lua`'s persistence idiom exactly (raw `io.open` +
  `vim.json`, `safe_mkdir`, `utils.debug.notify` on error) rather than
  `cmdlog.nvim`'s `lib.nvim.fs`-based `core/favorites.lua` this task was
  pattern-sourced from — consistency with this repo's own established
  convention won over cross-repo pattern matching.
- **2026-08-09 — `status` gained multi-backend output + `$REPOS_DIR`
  completion**: `vim.notify` truncated and couldn't be scrolled, unusable
  past a handful of repos. `status` is now its own hand-built composer
  route (not going through the generic per-subcommand wrapper the rest of
  the table uses) specifically so it can declare `--out`/`--to` flags —
  `--out=popup` (default, scrollable float via `lib.nvim.ui.kit.surface`),
  `buffer`, `split`, `vsplit`, `clipboard`, `path` (`--to=<file>`); see
  `lua/reposcope/ui/actions/status_view.lua`. Separately, `[dir]`'s
  completion type (`REPOSCOPE_STATUS_DIR`) now offers `$REPOS_DIR` and `~`
  ahead of real directory listings — `$REPOS_DIR` is a `lib.nvim.system.env`
  convention, previously invisible on `<Tab>` since plain directory
  completion has no notion of env vars.
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
