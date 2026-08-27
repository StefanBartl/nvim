# fileops.nvim — telemetry

**stopped** · counting + args + timing · 67 wrapped · 200 calls · 35 session(s)
Collecting since 2026-08-19 17:24.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `ops.file.ensure_parent` | 171 | 0.12 | — |
| `config.get` | 14 | — | — |
| `ops.file.delete_current` | 3 | — | — |
| `ops.cycle.get_root_dir` | 2 | — | — |
| `ops.cycle.navigate` | 2 | — | — |
| `ops.cycle.open_path` | 2 | — | — |
| `util.notify.error` | 2 | — | — |
| `util.notify.report` | 2 | — | — |
| `ops.file.notify_change` | 1 | — | — |
| `util.notify.info` | 1 | — | — |

### `ops.file.ensure_parent` — argument profile

| Share | Argument |
| ---: | --- |
| 97 % | `("C:/Users/bartl/AppData/Local/nvim/docs/R"…)` |
| 1 % | `("C:/Users/bartl/AppData/Local/nvim/docs/T"…)` |
| 1 % | `("C:/Users/bartl/AppData/Local/nvim/docs/N"…)` |

> **97 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `ops.file.delete_current` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

### `ops.cycle.get_root_dir` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

### `ops.cycle.navigate` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `("C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\R"…, "next", <table:map>, 1)` |
| 50 % | `("C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\R"…, "prev", <table:map>, 2)` |

### `ops.cycle.open_path` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\R"…, <table:map>)` |

### `util.notify.error` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("buffer has unsaved changes — use :File"…)` |

### `util.notify.report` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(true, nil)` |

### `ops.file.notify_change` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("delete", "C:\\Users\\bartl/AppData/Local/nvim/docs/R"…, <table:map>)` |

### `util.notify.info` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("deleted docmap-desktop.md")` |
