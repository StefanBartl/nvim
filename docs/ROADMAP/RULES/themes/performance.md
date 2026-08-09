# Performance

Caching, debouncing, bounded concurrency, async scheduling, and invalidation
patterns pulled from the per-plugin reports.

## Caching

- Weak-keyed caches (`setmetatable({}, {__mode = "k"})`) when a buffer/object
  reference should determine cache lifetime — prevents leaks from forgotten
  namespaces — from [color_my_ascii.nvim](../plugins/color_my_ascii.nvim.md)
  (`cache_manager.lua:17`), [lib.nvim](../plugins/lib.nvim.md)
  (`cache/memory.lua:46,61`), [pickers.nvim](../plugins/pickers.nvim.md)
  (`selected_index/cache.lua`, `__mode = "k"`).
- Cache validity should combine multiple cheap signals, not a single timeout:
  `changedtick` + line count — from
  [color_my_ascii.nvim](../plugins/color_my_ascii.nvim.md)
  (`cache_manager.lua:80-109`); TTL + per-buffer `changedtick` — from
  [lib.nvim](../plugins/lib.nvim.md) (`cache/memory.lua:93-100`).
- mtime-based invalidation is preferable to TTL when the source is a file that
  doesn't change between edits (unlike a live buffer) — from
  [pdfport.nvim](../plugins/pdfport.nvim.md) (`util/cache.lua:1-8,26-56`).
- Cache keys must include every parameter that affects the result (path +
  backend + variant), or the cache silently serves wrong results for a
  different configuration of the same input — from
  [pdfport.nvim](../plugins/pdfport.nvim.md) (`util/cache.lua:17-24`).
- `clear()`/reset on a shared cache should mutate the table in-place, never
  replace the reference — other holders of the same reference would otherwise
  silently freeze on stale data — from [lib.nvim](../plugins/lib.nvim.md)
  (`cache/memory.lua:121-133`).
- Eviction at `max_size` can stay a simple O(n) linear oldest-scan instead of a
  full O(1) LRU, when the realistic cache size is small (e.g. ≤50 buffers) —
  deliberate simplicity trade-off, from
  [color_my_ascii.nvim](../plugins/color_my_ascii.nvim.md)
  (`cache_manager.lua:170-195`). Contrast with
  [lib.nvim](../plugins/lib.nvim.md)'s from-scratch O(1) LRU
  (`memo/lru.lua`) for the case where true LRU is warranted.
- Memoize the *whole* expensive pipeline (walk + parse), not just the cheapest
  sub-step, when parsing itself is the expensive part — from
  [debugging.nvim](../plugins/debugging.nvim.md) (`autocmds/sources.lua:94-98`,
  5s TTL `scan_cache`).
- Re-namespace a shared cache per call site instead of module-wide memoizing,
  so different callers can use different TTLs on the same underlying cache
  without one caller dictating TTL for everyone — from
  [lib.nvim](../plugins/lib.nvim.md) (`fs/scan_cached/init.lua:41-44`).
- Directory-listing caches should invalidate on the event that typically
  creates new files (`BufWritePost`), not be re-stat'd on every keypress —
  from [gopath.nvim](../plugins/gopath.nvim.md) (`docs/BINDINGS.md:110-127`).
- Round-trip a command-invocation's editor-state reads (cursor, selection,
  cfile/cword) through a manual memoization window, since they don't change
  within one invocation — from [open.nvim](../plugins/open.nvim.md)
  (`context.lua:39-53`, `with_cache`).
- Frecency scoring (log-damped count + bucketed recency) is a repeatedly
  reinvented pattern worth centralizing — from
  [pickers.nvim](../plugins/pickers.nvim.md) (`smart/frecency.lua:109-122`),
  [emojis.nvim](../plugins/emojis.nvim.md) (`overlay/frecency.lua:150-162`,
  exponential recency-decay variant).

## Debouncing

- Debounce delay should scale adaptively with input/file size, capped, rather
  than use one fixed value — from
  [color_my_ascii.nvim](../plugins/color_my_ascii.nvim.md)
  (`debounce_manager.lua:82-118`).
- Reuse a per-key debounce handle across calls; only rebuild it when the
  computed delay tier actually changes — avoids timer churn — from
  [color_my_ascii.nvim](../plugins/color_my_ascii.nvim.md)
  (`debounce_manager.lua:120-161`).
- Always explicitly `timer:stop()` + `pcall(timer.close)` before starting a new
  debounce timer, never just overwrite the timer handle — from
  [markdown.nvim](../plugins/markdown.nvim.md) (`core/refs.lua:267-289`).
- Two independent trigger sources feeding the same debounced update (cursor
  move + text change) should funnel through the same debounce instance — from
  [pickers.nvim](../plugins/pickers.nvim.md) (`selected_index/init.lua:180-203`,
  30ms shared debounce for `CursorMoved` + `TextChangedI`).
- `lib.nvim.debounce` centralizes this with an optional "N updates coalesced"
  counter variant for UI feedback — from [lib.nvim](../plugins/lib.nvim.md)
  (`debounce/init.lua:73-103`, lifted from reposcope.nvim).

## Bounded concurrency / scanning

- Async multi-root filesystem scans should use a bounded work-queue
  (fixed `max_concurrency`), re-queueing subdirectories instead of recursing
  immediately, to cap simultaneously-open FS handles regardless of tree size
  (avoids EMFILE / libuv threadpool exhaustion) — from
  [gopath.nvim](../plugins/gopath.nvim.md) (`truncated/cache.lua:136-199`,
  `scan_roots_bounded`).
- Use a read-cursor into the queue instead of `table.remove(queue, 1)` once the
  queue can grow large — avoids O(n) shifts per dequeue — from
  [gopath.nvim](../plugins/gopath.nvim.md) (`truncated/cache.lua`, `qhead`).
- Auto-detected scan roots should stay conservative (cwd, stdpath dirs,
  git-root), never a whole drive/home directory by default — from
  [gopath.nvim](../plugins/gopath.nvim.md) (`truncated/cache.lua:33-67`).
- Guard background rebuild timers against overlapping runs with a `building`
  flag — from [gopath.nvim](../plugins/gopath.nvim.md)
  (`truncated/cache.lua:361-392`).
- Prefer ripgrep/glob prefiltering before opening and parsing every candidate
  file — from [markdown.nvim](../plugins/markdown.nvim.md)
  (`core/file_refs.lua:11-17,46-65,95-122`, `rg --files-with-matches` before
  reading full files).
- Choose the rendering primitive by cost model up front: `matchadd()`
  (O(window)) instead of extmarks (O(file size) per add/edit) for huge files —
  requires a small per-window ledger to fake session-global behavior on top of
  a window-local primitive — from [spotlight.nvim](../plugins/spotlight.nvim.md)
  (`core/match.lua:1-24`).

## Async scheduling / background work

- Every callback that runs in libuv "fast event" context (timers, `vim.uv`,
  process completion) must be wrapped in `vim.schedule` before touching
  `vim.api.*` — centralize this once, don't rely on every caller remembering —
  from [lib.nvim](../plugins/lib.nvim.md) (`debounce/init.lua:7-8`),
  [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md)
  (`runner.lua:131-166`, verified: a bare `nvim_create_buf` inside an
  unscheduled callback throws `E5560`).
- Decouple a background poller's *check* interval from the actual *due*
  interval, and cap the check interval (e.g. max 60 minutes) so a long-running
  session doesn't wait until next restart for an overdue fetch — from
  [github_stats.nvim](../plugins/github_stats.nvim.md) (`background.lua:22-93`).
- Make background-timer `start()` idempotent (`if timer then return end`) with
  an explicit `stop()` counterpart, and defer the very first run past startup
  (`vim.defer_fn`) so it doesn't compete with Neovim's own startup — from
  [github_stats.nvim](../plugins/github_stats.nvim.md) (`background.lua:22-93`).
- For non-cancellable async operations (no killable process handle), implement
  "cancel" as a token-based logical discard: bump a token on each new
  invocation, silently no-op any callback carrying a stale token — from
  [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md)
  (`bindings/usrcmds.lua:94-146,246-260,319-401`).
- When a synchronous, blocking external call is fast enough in practice (e.g.
  `fd`+`rg` inside a per-keystroke picker callback), prefer it over building
  three separate async-streaming integrations per backend — deliberate
  trade-off with a timeout safety net — from
  [pickers.nvim](../plugins/pickers.nvim.md) (`smart/search.lua:1-9`,
  `vim.system():wait()`, 3000ms timeout).
- Diff the computed value against the last-rendered value before firing a
  redraw/update event, to avoid redraw storms on routine lifecycle events —
  from [filetree.nvim](../plugins/filetree.nvim.md)
  (`nav/cwd_mode/init.lua:706-841`).
- History/log caps should default to a count cap (simpler, equally effective
  for small frequent entries) rather than reaching for a time-window by
  default — from
  [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md)
  (`history.lua:29-35`, `MAX_ENTRIES = 200`).
</content>
