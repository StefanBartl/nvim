# Ideas for other plugins (cross-report synthesis)

Collected "Ideen für andere Plugins" from every per-plugin report, grouped by
theme and lightly deduplicated. Each idea links back to the report(s) it came
from.

## Standalone plugin ideas

Ideas framed as an entirely new *.nvim project, not just a lib.nvim module.

- **Explorer-Singleton plugin** generalizing the "two competing file-browser
  UIs displace/restore each other" logic out of a config-local autocmd file —
  from [nvim-config](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/nvim-config.md).

- ~~**Word/Number-Cycler plugin** (`cycler.nvim`) extracting `ctrl_cycle.lua`'s
  case-aware cycling of configurable word pairs~~ — **done, as
  [cascade.nvim](https://github.com/StefanBartl/cascade.nvim)'s cycle domain.**
  It went well past the original idea: operator flips, ISO dates, single-letter
  and in-word character stepping, counts, dot-repeat, a picker and language
  packs. The config-local source file was deleted on 2026-08-30 after checking
  that all 49 words of its 24 groups are covered by cascade's defaults.

- **EmmyLua-aware comment-toggler** handling `---@` annotations distinctly
  from normal comments — from [nvim-config](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/nvim-config.md).
- **sticky-marks.nvim**: multi-colored, named, persistent line marks with
  yank/jump/clear surviving reloads/sessions, generalizing
  [buffer-ctx.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/buffer-ctx.nvim.md)'s extmark-based mark
  pattern.

- **dependency-graph-diff tool** comparing two `insights.imports` scans
  (e.g. pre/post refactor), rendering only changed edges, building on
  `build_dot`'s pure edge list — from [insights.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/insights.nvim.md).

- **datewalker.nvim**: standalone generalization of `cascade.nvim`'s
  calendar-aware ISO-date cycling (cursor position determines year/month/day
  segment, with rollover), useful outside list contexts (log files, commit
  messages) — from [cascade.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/cascade.nvim.md).

- **Vendored-Code-Drift-Checker**: periodic/on-demand check of configured
  local-file-to-URL pairs for drift, building on `diff.nvim`'s URL-diff
  capability — from [diff.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/diff.nvim.md).

- **dedupe.nvim**: standalone structural-duplicate finder using only
  `documentation.nvim`'s `fn.shape` tree-sitter-subtree hashing, as a
  general-purpose CPD tool for any Lua tree — from
  [documentation.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/documentation.nvim.md).

- **systemctl.nvim** / **k8s.nvim**: same hexagonal ports-&-adapters +
  list-view UI as [sandbox.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/sandbox.nvim.md), retargeted at
  systemd units or Kubernetes resources.

- **`.projectrc` family**: generalizing `sandbox.nvim`'s `.sandboxrc` pattern
  (key=value project-root config file, whitelisted values, session > project
  > default precedence) for other per-project overrides (formatter, linter,
  interpreter choice) — from [sandbox.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/sandbox.nvim.md).

- **safeguard.nvim**: generalizing `cmdlog.nvim`'s risky-vs-known-failed
  command classification into a proactive interceptor that confirms before
  executing a risky `:`/shell command, not just retroactive picker
  highlighting — from [cmdlog.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/cmdlog.nvim.md).

- **table-view.nvim**: standalone extraction of `markdown.nvim`'s TableView
  rendering engine (Markdown/box-style, browser export) for CSV/TSV or
  Ex-command output, decoupled from Markdown — from
  [markdown.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/markdown.nvim.md).

- **rename-tracker** (extmark + positional-fallback) as a lib.nvim building
  block other plugins could reuse for variable names/tags/IDs, generalized
  from `markdown.nvim`'s heading-rename detection — from
  [markdown.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/markdown.nvim.md).

- **merge-assist.nvim**: builds on `fileops.nvim`'s conflict-marker
  highlighting to add navigation between conflict blocks (`]x`/`[x`),
  "take ours/theirs" actions, and auto `git add` after resolution — from
  [fileops.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/fileops.nvim.md).

- **line-history-preview.nvim**: standalone extraction of `fileops.nvim`'s
  `on_hold.lua` ambient git-blame line-diff preview, independent of a
  file-ops context — from [fileops.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/fileops.nvim.md).

- **Bulk-File-Op plugin**: generalizing `fileops.nvim`'s
  plan/preview/confirm/execute pattern to bulk delete/move with pattern
  matching, not just rename — from [fileops.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/fileops.nvim.md).

- **`:LockWho <path>` standalone command/plugin**: Windows file-lock diagnosis
  usable anywhere in the editor, not tied to fileops.nvim — from
  [fileops.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/fileops.nvim.md); overlaps with
  [lib.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/lib.nvim.md)'s own `:LibWhoLocks` idea above.

- **Proc-Watch plugin (Windows)**: standalone extraction of
  `debugging.nvim`'s UI-freeze diagnosis (blocking-call tracing + external
  process-tree watcher), usable without the rest of debugging.nvim — from
  [debugging.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/debugging.nvim.md).

- **Keylogger-as-input-recorder**: generalizing `debugging.nvim`'s terminal
  keylogger loop into a generic timestamped input recorder (e.g. for macro
  recording beyond terminal buffers) — from [debugging.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/debugging.nvim.md).

