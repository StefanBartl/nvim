# insights.nvim — telemetry

**stopped** · counting + args + timing · 34 wrapped · 2 627 calls · 34 session(s)
Collecting since 2026-08-27 10:45.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `util.notify.create` | 2 306 | 0.00 | — |
| `config.get` | 96 | 0.00 | — |
| `devserver.chan_cmd` | 60 | 0.01 | — |
| `devserver.consider` | 60 | 0.03 | — |
| `devserver.match` | 60 | 0.01 | — |
| `devserver.kill_all` | 30 | 0.00 | — |
| `unimported.handles_filetype` | 15 | 0.02 | — |

### `util.notify.create` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `("[MDTableCol]")` |
| 0 % | `("[MDTableFromCSV]")` |
| 0 % | `("[MDTableUnwrap]")` |
| 96 % | `<other: 2186 distinct>` |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `devserver.chan_cmd` — argument profile

| Share | Argument |
| ---: | --- |
| 5 % | `(1074, 577)` |
| 5 % | `(11, 8)` |
| 5 % | `(1103, 596)` |

### `devserver.consider` — argument profile

| Share | Argument |
| ---: | --- |
| 5 % | `(1074, "C:\\Users\\bartl\\scoop\\shims\\lazygit.EXE")` |
| 5 % | `(11, "C:\\Users\\bartl\\scoop\\shims\\lazygit.EXE")` |
| 5 % | `(1103, "C:\\Users\\bartl\\scoop\\shims\\lazygit.EXE")` |

### `devserver.match` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("C:\\Users\\bartl\\scoop\\shims\\lazygit.EXE", <table:#10>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `devserver.kill_all` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `unimported.handles_filetype` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("markdown")` |
