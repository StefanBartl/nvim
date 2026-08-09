# themes/ — topic-sorted synthesis (layer 2)

These 9 files are a second, topic-sorted layer over the 33 per-plugin reports
in [`../plugins/`](../plugins/) and the config report at
[`../nvim-config.md`](../nvim-config.md). Every entry here links back to the
plugin report (and where available, the file:line) it was derived from — read
this layer to find "everything about X across all plugins" without opening 33
files; follow a link when you need the grounded source.

This layer is additive: the per-plugin files are untouched.

- [`ui.md`](ui.md) — UI/UX conventions: notifications, highlighting, picker
  UX, progress indicators, window/buffer handling.
- [`performance.md`](performance.md) — caching, debouncing, bounded
  concurrency, async scheduling, invalidation strategies.
- [`security.md`](security.md) — injection avoidance, sandboxing,
  regex-safety, credential/secret handling, defenses against untrusted input.
- [`error-handling.md`](error-handling.md) — defensive checks, edge-case
  handling, fail-open vs. fail-closed, validation patterns.
- [`module-structure.md`](module-structure.md) — architecture/naming
  conventions, `lib.nvim` integration, module boundaries, config validation.
- [`keybindings-count.md`](keybindings-count.md) — cross-plugin synthesis of
  the count-support audit: reference examples, missing-but-plausible cases,
  and a general rule for when count support is worth adding.
- [`autocompletion.md`](autocompletion.md) — cross-plugin synthesis of the
  autocompletion audit: where Ex-command/picker-input completion exists vs.
  is missing, and a general rule for when it should be mandatory.
- [`flags-options-ideas.md`](flags-options-ideas.md) — missing-flag/option
  ideas collected from every report, grouped by plugin.
- [`plugin-ideas.md`](plugin-ideas.md) — "ideas for other plugins" collected
  from every report, grouped by theme (candidate `lib.nvim` modules vs.
  standalone new plugins).
</content>
