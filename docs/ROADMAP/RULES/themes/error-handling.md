# Error handling

Defensive checks, edge-case handling, fail-open vs fail-closed decisions, and
validation patterns pulled from the per-plugin reports.

## Return-value contracts

- Core/logic functions return `(ok, msg)` or `(result, err)` and never call
  `notify` themselves; only the outermost UI layer decides how to present a
  failure — from [fileops.nvim](../plugins/fileops.nvim.md) (`ops/*.lua:5-9`),
  [emojis.nvim](../plugins/emojis.nvim.md) (`core/scope.lua:17`),
  [diff.nvim](../plugins/diff.nvim.md) (`core/resolve.lua`, `core/git.lua`,
  `core/url.lua`), [debugging.nvim](../plugins/debugging.nvim.md)
  (`capture/init.lua:321-328` — explicitly because it has two call sites that
  each want to present the result differently).
- A function whose result can mean "nothing to report" *or* "something went
  wrong" should return distinguishable values, even when the shape looks the
  same — from [github_stats.nvim](../plugins/github_stats.nvim.md)
  (`storage.lua:104-129`, `read_last_fetch`: "file missing" → empty table, no
  error; "file corrupt" → empty table, WITH error message).
- Distinguish "no argument given" from "invalid argument given" explicitly
  (`nil, false` vs `nil, true`) rather than collapsing both to the same `nil`
  — a real bug this fixed: a typo silently behaved like "no argument", acting
  on *everything* instead of erroring — from
  [debugging.nvim](../plugins/debugging.nvim.md) (`commands.lua:24-43`,
  `parse_id`).

## Fail-open vs fail-closed

- Spellcheck/lint-style filters that restrict scope via an optional signal
  (tree-sitter `@spell` captures) must fail **open** (check everything) when
  the signal is unavailable (missing parser/query), never fail closed (check
  nothing) — from [language.nvim](../plugins/language.nvim.md)
  (`spell/core/regions.lua:1-107`).
- Unknown/unrecognized environments (e.g. a terminal not in a known-good list)
  should get a one-time warning and still attempt the primary behavior,
  rather than a hard block — false-negative tolerance is preferred over
  false-positive blocking of a working setup — from
  [images.nvim](../plugins/images.nvim.md) (`terminal.lua:56-80`).
- Config validation should degrade an individual bad value to its default
  rather than aborting the whole plugin's initialization, surfaced via
  `:checkhealth` — from [spotlight.nvim](../plugins/spotlight.nvim.md)
  (guideline 11).

## Stale-state and TOCTOU

- Every match/edit computed during a scan must be re-verified against the
  *current* text immediately before writing; a mismatch means "stale,"
  skip it rather than overwrite blindly — from
  [replacer.nvim](../plugins/replacer.nvim.md) (`apply.lua:117-129,266-274`).
- `touch`/file-create should use `O_CREAT|O_EXCL` and treat the resulting
  `EEXIST` as success ("the file existing is the outcome we wanted either
  way"), rather than a naive check-then-create sequence — from
  [fileops.nvim](../plugins/fileops.nvim.md) (`ops/file.lua:310-338`).
- A generation counter guards against a `vim.defer_fn`/`vim.schedule` callback
  rendering into a state that has since changed (e.g. mode switched between
  timer start and fire) — from [fileops.nvim](../plugins/fileops.nvim.md)
  (`features/on_hold.lua:251-258,301-316`), and independently by
  [pickers.nvim](../plugins/pickers.nvim.md)'s selected-index debounce guard.
- Any callback deferred via `vim.defer_fn`/`vim.schedule` must re-validate its
  window/buffer handles (`nvim_win_is_valid`/`nvim_buf_is_valid`) at execution
  time, not just at capture time — from
  [debugging.nvim](../plugins/debugging.nvim.md) (`views/utils.lua:10-12`).
- Symlinked directories must never be entered during a recursive walk, to
  avoid an infinite loop on a symlink cycle — from
  [fileops.nvim](../plugins/fileops.nvim.md) (`ops/cycle.lua:89-117`).

## Retry and best-effort

- Windows file-sharing violations should be retried with active handle
  release (not blind waiting): release the concrete watcher handle via a
  shared registry, then `vim.wait()` briefly so libuv's async handle-close can
  actually complete before the next attempt — from
  [fileops.nvim](../plugins/fileops.nvim.md) (`ops/file.lua:76-108`),
  [filetree.nvim](../plugins/filetree.nvim.md) (`infra/handle_guard/init.lua`).
- Retry budgets should be platform-specific with a documented reason (Windows:
  several retries with backoff; POSIX: essentially none) rather than a
  pan-platform default — from [fileops.nvim](../plugins/fileops.nvim.md)
  (`config/DEFAULTS.lua:39-45`), [lib.nvim](../plugins/lib.nvim.md)
  (`cross/fs/mutate/init.lua:54`).
- Batch operations over N independent items should be best-effort, not
  fail-fast: one item's error shouldn't block the rest; report the first
  error but keep processing — from [fileops.nvim](../plugins/fileops.nvim.md)
  (`ops/bulk.lua:79-108`), [github_stats.nvim](../plugins/github_stats.nvim.md)
  (`api.lua:143-229`, paginated fetch: page-1 failure propagates, a later
  page's failure returns already-collected results).
- If ≥50% of expected matches had to be skipped as stale, warn proactively
  instead of only reporting a bare count — a high skip-rate usually signals a
  systematic problem, not scattered noise — from
  [replacer.nvim](../plugins/replacer.nvim.md) (`apply.lua:288-298`).
- Non-cancellable async operations should implement "cancel" as a token-based
  logical discard, never pretend to kill a process handle that can't actually
  be killed — from
  [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md)
  (`bindings/usrcmds.lua:94-146`); same principle in
  [pdfport.nvim](../plugins/pdfport.nvim.md) (`dispatcher.lua`, no fake
  `on_cancel` — only a real `timeout_ms`).

## Config / merge safety

- Config validation (unknown-key detection, "did you mean") must run
  **before** merge, not after — a typo in a nested option otherwise vanishes
  silently into the defaults post-merge and is never caught — from
  [mdview.nvim](../plugins/mdview.nvim.md) (`config/init.lua:72-114`).
- Config merges must deep-copy defaults and use
  `vim.tbl_deep_extend("force", ...)`, never mutate the shared defaults table
  — from [debugging.nvim](../plugins/debugging.nvim.md) (`config/init.lua:23`),
  [diff.nvim](../plugins/diff.nvim.md) (`config/init.lua:25`),
  [documentation.nvim](../plugins/documentation.nvim.md) (`config/init.lua:75`).
- `vim.tbl_deep_extend` merges lists index-wise, which is wrong for a
  "curated, closed set" list (five specific glyphs must mean exactly five) —
  such fields need an explicit `vim.deepcopy(user_value)` override after the
  generic merge, not a blind merge — from
  [emojis.nvim](../plugins/emojis.nvim.md) (`config/init.lua:44-63`).
- In-place deep-merge (not table replacement) is required when submodules hold
  a direct reference into a sub-table of the central defaults — replacing the
  table would silently decouple those already-taken references — from
  [mdview.nvim](../plugins/mdview.nvim.md) (`config/init.lua:5-9,24-32`).

## Common Lua footguns

- `a and b or c` silently picks `c` whenever `b` itself is falsy (e.g. `nil`),
  regardless of `a` — use an explicit `if`. Caught by a failing test, not code
  review — from [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md)
  (`history.lua:86-93`).
- Don't trust documented API behavior blindly — `vim.json.encode`'s `indent`
  option was verified to *not* indent (it inserts the literal text of the
  number) — verify against real behavior before depending on a formatting
  feature — from [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md)
  (`runner.lua:43-69`).
- `pairs()` never yields a key whose value is `nil`, so `{field = nil}` is
  indistinguishable from "field not set" — a dedicated sentinel value is
  needed when a patch/merge structure must express "delete this field
  explicitly" — from [documentation.nvim](../plugins/documentation.nvim.md)
  (`editor/browse/init.lua:319-323`, `CLEAR` sentinel).

## Health checks

- `:checkhealth` should audit truth, not just presence — check every soft
  dependency actually referenced via `pcall(require, ...)` in the code, and
  flag when documentation claims something is optional but the code requires
  it unconditionally — from [fileops.nvim](../plugins/fileops.nvim.md)
  (`health.lua:71-75`, catches its own README's false "no mandatory
  dependency" claim), [debugging.nvim](../plugins/debugging.nvim.md)
  (`health.lua`, one check per soft dependency, matching the code's actual
  `pcall(require, ...)` surface).
</content>
