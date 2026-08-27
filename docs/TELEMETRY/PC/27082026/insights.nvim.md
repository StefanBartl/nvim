# insights.nvim — telemetry

**stopped** · counting + args + timing · 31 wrapped · 8 021 calls · 52 session(s)
Collecting since 2026-08-19 17:24.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `util.notify.create` | 7 382 | 0.00 | — |
| `config.get` | 289 | 0.00 | — |
| `devserver.chan_cmd` | 101 | — | — |
| `devserver.consider` | 101 | — | — |
| `devserver.match` | 101 | — | — |
| `devserver.kill_all` | 47 | 0.00 | — |

### `util.notify.create` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `("[Commands]")` |
| 0 % | `("[DiffPeek]")` |
| 0 % | `("[LspMdHints]")` |
| 89 % | `<other: 6182 distinct>` |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `devserver.chan_cmd` — argument profile

| Share | Argument |
| ---: | --- |
| 5 % | `(38, 81)` |
| 3 % | `(122, 67)` |
| 3 % | `(131, 101)` |
| 3 % | `<other: 33 distinct>` |

### `devserver.consider` — argument profile

| Share | Argument |
| ---: | --- |
| 6 % | `(19, "C:\\Users\\bartl\\scoop\\shims\\lazygit.EXE")` |
| 5 % | `(38, "C:\\Users\\bartl\\scoop\\shims\\lazygit.EXE")` |
| 3 % | `(122, "C:\\Users\\bartl\\scoop\\shims\\lazygit.EXE")` |

### `devserver.match` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("C:\\Users\\bartl\\scoop\\shims\\lazygit.EXE", <table:#10>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `devserver.kill_all` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |
