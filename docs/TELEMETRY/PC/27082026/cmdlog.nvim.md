# cmdlog.nvim — telemetry

**stopped** · counting + args + timing · 20 wrapped · 3 888 calls · 50 session(s)
Collecting since 2026-08-19 17:24.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `core.errors.is_known_bad` | 3 493 | — | — |
| `core.store.save_json` | 147 | 0.73 | — |
| `core.project_history.get_git_root` | 73 | 36.78 | — |
| `core.project_history.record` | 73 | 37.57 | — |
| `core.stats.record` | 73 | 0.70 | — |
| `core.store.load_json` | 28 | — | — |
| `core.errors.record` | 1 | — | — |

### `core.errors.is_known_bad` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `("'<,'>s/](/](.\\//")` |
| 0 % | `("BindingsPath")` |
| 0 % | `("CopyFilepathAbsolute")` |
| 99 % | `<other: 3493 distinct>` |

### `core.store.save_json` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("C:\\Users\\bartl\\AppData\\Local\\nvim-data/c"…, <table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `core.project_history.get_git_root` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `core.project_history.record` — argument profile

| Share | Argument |
| ---: | --- |
| 16 % | `("m .-2")` |
| 5 % | `("File delete")` |
| 4 % | `("Reposcope status")` |
| 25 % | `<other: 40 distinct>` |

### `core.stats.record` — argument profile

| Share | Argument |
| ---: | --- |
| 16 % | `("m .-2")` |
| 5 % | `("File delete")` |
| 4 % | `("Reposcope status")` |
| 25 % | `<other: 40 distinct>` |

### `core.store.load_json` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("C:\\Users\\bartl\\AppData\\Local\\nvim-data/c"…, <table:empty>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `core.errors.record` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("qaQ", "E492: Not an editor command: qaQ")` |
