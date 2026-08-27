# fileops.nvim — telemetry

**stopped** · counting + args + timing · 67 wrapped · 194 calls · 83 session(s)
Collecting since 2026-08-21 11:27.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `ops.file.ensure_parent` | 174 | 0.07 | — |
| `config.get` | 6 | — | — |
| `ops.cycle.get_root_dir` | 3 | — | — |
| `ops.cycle.navigate` | 3 | — | — |
| `ops.cycle.open_path` | 3 | — | — |
| `util.notify.report` | 3 | — | — |
| `ops.file.copy_path` | 1 | — | — |
| `util.notify.info` | 1 | — | — |

### `ops.file.ensure_parent` — argument profile

| Share | Argument |
| ---: | --- |
| 86 % | `("C:/Users/StefanBartl/AppData/Local/nvim/"…)` |
| 8 % | `("C:/repos/WKDBook-Tricentis/ToDo-Collecti"…)` |
| 4 % | `("C:/repos/lsp.nvim/docs/ROADMAP.md")` |

> **86 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `ops.cycle.get_root_dir` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

### `ops.cycle.navigate` — argument profile

| Share | Argument |
| ---: | --- |
| 67 % | `("C:\\Users\\StefanBartl\\AppData\\Local\\nvim\\"…, "next", <table:map>, 1)` |
| 33 % | `("C:/Users/StefanBartl/AppData/Local/nvim/"…, "next", <table:map>, 1)` |

### `ops.cycle.open_path` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("C:\\Users\\StefanBartl\\AppData\\Local\\nvim\\"…, <table:map>)` |

### `util.notify.report` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(true, nil)` |

### `ops.file.copy_path` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("abs")` |

### `util.notify.info` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("copied path (abs): C:\\Users\\StefanBartl\\"…)` |
