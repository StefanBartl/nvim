# spotlight.nvim — telemetry

**stopped** · counting + args + timing · 133 wrapped · 44 521 calls · 35 session(s)
Collecting since 2026-08-19 17:24.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `core.match.reconcile_window` | 12 889 | 0.00 | — |
| `core.registry.all` | 12 889 | 0.00 | — |
| `core.registry.apply_to_window` | 12 889 | 0.00 | — |
| `core.match.forget_window` | 3 745 | 0.00 | — |
| `core.registry.remove_for_buffer` | 1 831 | 0.00 | — |
| `config.get` | 128 | 0.00 | — |
| `core.registry.snapshot` | 30 | 0.00 | — |
| `persist.flush` | 30 | 0.23 | — |
| `persist.save_now` | 30 | 0.21 | — |
| `util.lib.debug` | 30 | 0.00 | — |
| `util.lib.try_require` | 30 | 0.00 | — |

### `core.match.reconcile_window` — argument profile

| Share | Argument |
| ---: | --- |
| 19 % | `(1000, <table:empty>)` |
| 1 % | `(1004, <table:empty>)` |
| 1 % | `(1025, <table:empty>)` |
| 68 % | `<other: 3388 distinct>` |

### `core.registry.all` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `core.registry.apply_to_window` — argument profile

| Share | Argument |
| ---: | --- |
| 19 % | `(1000)` |
| 1 % | `(1004)` |
| 1 % | `(1025)` |
| 68 % | `<other: 3393 distinct>` |

### `core.match.forget_window` — argument profile

| Share | Argument |
| ---: | --- |
| 1 % | `(1002)` |
| 1 % | `(1005)` |
| 1 % | `(1006)` |
| 84 % | `<other: 3182 distinct>` |

### `core.registry.remove_for_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 1 % | `(7)` |
| 1 % | `(28)` |
| 1 % | `(32)` |
| 75 % | `<other: 1392 distinct>` |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 47 % | `("persist.enable")` |
| 23 % | `("debug")` |
| 23 % | `("persist.default")` |

### `core.registry.snapshot` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `persist.flush` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `persist.save_now` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `util.lib.debug` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("persist: snapshot filtered", <table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `util.lib.try_require` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("lib.nvim.store.project")` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**
