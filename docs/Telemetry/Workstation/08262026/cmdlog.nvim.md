# cmdlog.nvim — telemetry

**stopped** · counting + args · 20 wrapped · 111 calls · 71 session(s)
Collecting since 2026-08-25 16:17.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `core.store.save_json` | 43 | — | — |
| `core.project_history.get_git_root` | 20 | — | — |
| `core.project_history.record` | 20 | — | — |
| `core.stats.record` | 20 | — | — |
| `core.store.load_json` | 5 | — | — |
| `core.errors.record` | 3 | — | — |

### `core.store.save_json` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("C:\\Users\\StefanBartl\\AppData\\Local\\nvim-"…, <table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `core.project_history.get_git_root` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `core.project_history.record` — argument profile

| Share | Argument |
| ---: | --- |
| 20 % | `("CopyFilepathAbsolute")` |
| 10 % | `(":lua vim.api.nvim_win_set_width(vim.fn.w"…)` |
| 10 % | `("Reposcope status")` |

### `core.stats.record` — argument profile

| Share | Argument |
| ---: | --- |
| 20 % | `("CopyFilepathAbsolute")` |
| 10 % | `(":lua vim.api.nvim_win_set_width(vim.fn.w"…)` |
| 10 % | `("Reposcope status")` |

### `core.store.load_json` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("C:\\Users\\StefanBartl\\AppData\\Local\\nvim-"…, <table:empty>)` |

### `core.errors.record` — argument profile

| Share | Argument |
| ---: | --- |
| 33 % | `("lua print(vim.stdpath('cache'))", "E5108: Lua: [string \":lua\"]:1: attempt t"…)` |
| 33 % | `("print stdpath('cache')", "E488: Trailing characters: stdpath('cach"…)` |
| 33 % | `("print(stdpath('cache'))", "E488: Trailing characters: (stdpath('cac"…)` |
