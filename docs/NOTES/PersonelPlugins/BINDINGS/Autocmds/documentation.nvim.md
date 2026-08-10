# documentation.nvim — Autocmds Cheatsheet

Source of truth: `lua/documentation/bindings/autocmds.lua` — a **manifest**, not
a creation site. `:checkhealth documentation` reads it, and the repo's generated
`docs/BINDINGS.md` renders from it.

Six autocommands, **all created lazily**. Requiring `documentation` installs
none of them; `require("documentation")` on its own never touches the editor.

| Event | Owner | Scope | Lifetime |
| --- | --- | --- | --- |
| `BufWritePost` | `documentation.editor.registry` | global | created by `install()` **only when `opts.watch`**; removed by `uninstall()` |
| `BufReadPost`, `BufNewFile` | `documentation.editor.registry` | global | created by `install()` **only when `opts.callhierarchy`** (`ensure_callhierarchy`); removed by `uninstall()`. Shipped 2026-08-10. |
| `BufReadPost`, `BufNewFile` | `documentation.editor.registry` | global | created by `install()` **only when `opts.diagnostics`** (`ensure_diagnostics`); removed by `uninstall()`. Shipped 2026-08-10. |
| `CursorMoved` | `documentation.editor.browse` | buffer | created by `bind()` on the browser's list buffer; dies with the buffer |
| `VimLeavePre` | `documentation.editor.browse.trail_store` | global | created by `attach()` on the first browser open; idempotent, lives for the session |
| `VimLeavePre` | `documentation.editor.serve` | global | created by `start()`; removed by `stop()` with its augroup |

## Why they are not centralised

Deliberate, and the opposite of the `insights.nvim` arrangement. Each of these
belongs to a lifecycle its own module owns:

- the watch autocmd is torn down by `registry.uninstall`, and its augroup
  identity is **per handle** — a shared augroup would cost `uninstall()` its
  precision;
- the two `VimLeavePre` hooks flush state their own modules are the only
  writers of;
- the browser's `CursorMoved` is scoped to a buffer that only exists while a
  browser is mounted.

A single `autocmds.lua` that *created* all four would have to reach into three
modules' teardown paths. What was missing was not a home — it was an **account**
of what the plugin installs, which is what the manifest is.

## Details

- **`BufWritePost` (watch)** — rescans the tree after a write under `source/`,
  debounced by `opts.watch_ms` (default 500). Filtered with
  `lib.nvim.fs.is_subpath`, **not** with an autocmd glob pattern: a pattern
  would have to match the user's path spelling exactly, and a mismatch fails
  silently. Off unless `opts.watch` is set.
- **`BufReadPost`/`BufNewFile` (callhierarchy)** — attaches a second, narrow
  in-process LSP client (`editor/callhierarchy.lua`) to a Lua buffer opened
  under `source/`, answering `textDocument/prepareCallHierarchy` and
  `callHierarchy/{incoming,outgoing}Calls`, and injects a caller/callee count
  into hover, alongside whatever real language server (LuaLS) is already
  attached. Same `is_subpath` scoping as watch. Off unless `opts.callhierarchy`
  is set. Shipped 2026-08-10.
- **`BufReadPost`/`BufNewFile` (diagnostics)** — publishes
  `Documentation.Finding[]` as native `vim.diagnostic` entries
  (`bindings/diagnostics.lua`) on a Lua buffer opened under `source/`, plus one
  `handle.on_change` subscription for live refresh on a watch-triggered or
  manual rescan. Same `is_subpath` scoping as watch. Off unless
  `opts.diagnostics` is set. Shipped 2026-08-10.
- **`CursorMoved` (browser)** — drives the detail pane from the cursor. This is
  what lets `j`/`k` stay native keys, so counts and `scrolloff` keep working.
- **`VimLeavePre` (trail_store)** — flushes pinned trails to `stdpath("state")`.
  Never into the repository: a trail has no more claim on the project than a
  jumplist has, and committing it would give `--check` an opinion about where
  one person happened to look.
- **`VimLeavePre` (serve)** — shuts the local map server down with the editor,
  so no listening socket outlives the session that opened it.
