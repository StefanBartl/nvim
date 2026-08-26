# insights.nvim — telemetry

**stopped** · counting + args · 31 wrapped · 4 188 calls · 82 session(s)
Collecting since 2026-08-25 16:09.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `util.notify.create` | 3 997 | — | — |
| `devserver.kill_all` | 78 | — | — |
| `config.get` | 44 | — | — |
| `devserver.chan_cmd` | 23 | — | — |
| `devserver.consider` | 23 | — | — |
| `devserver.match` | 23 | — | — |

### `util.notify.create` — argument profile

| Share | Argument |
| ---: | --- |
| 3 % | `("[lsp.nvim]")` |
| 3 % | `("[Lsp]")` |
| 2 % | `("[Commands]")` |
| 59 % | `<other: 2311 distinct>` |

### `devserver.kill_all` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `devserver.chan_cmd` — argument profile

| Share | Argument |
| ---: | --- |
| 17 % | `(1069, 185)` |
| 17 % | `(1084, 204)` |
| 17 % | `(413, 133)` |

### `devserver.consider` — argument profile

| Share | Argument |
| ---: | --- |
| 17 % | `(1069, "C:\\Users\\StefanBartl\\AppData\\Local\\Micro"…)` |
| 17 % | `(1084, "C:\\Users\\StefanBartl\\AppData\\Local\\Micro"…)` |
| 17 % | `(413, "C:\\Users\\StefanBartl\\AppData\\Local\\Micro"…)` |

### `devserver.match` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("C:\\Users\\StefanBartl\\AppData\\Local\\Micro"…, <table:#10>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**
