# spotlight.nvim — telemetry

**stopped** · counting + args · 132 wrapped · 28 746 calls · 50 session(s)
Collecting since 2026-08-24 05:59.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `core.match.reconcile_window` | 8 182 | — | — |
| `core.registry.all` | 8 182 | — | — |
| `core.registry.apply_to_window` | 8 182 | — | — |
| `core.match.forget_window` | 2 394 | — | — |
| `core.registry.remove_for_buffer` | 1 434 | — | — |
| `config.get` | 172 | — | — |
| `core.registry.snapshot` | 40 | — | — |
| `persist.flush` | 40 | — | — |
| `persist.save_now` | 40 | — | — |
| `util.lib.debug` | 40 | — | — |
| `util.lib.try_require` | 40 | — | — |

### `core.match.reconcile_window` — argument profile

| Share | Argument |
| ---: | --- |
| 21 % | `(1000, <table:empty>)` |
| 4 % | `(1002, <table:empty>)` |
| 2 % | `(1004, <table:empty>)` |
| 53 % | `<other: 1871 distinct>` |

### `core.registry.all` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `core.registry.apply_to_window` — argument profile

| Share | Argument |
| ---: | --- |
| 21 % | `(1000)` |
| 4 % | `(1002)` |
| 2 % | `(1004)` |
| 53 % | `<other: 1871 distinct>` |

### `core.match.forget_window` — argument profile

| Share | Argument |
| ---: | --- |
| 2 % | `(1003)` |
| 2 % | `(1002)` |
| 2 % | `(1005)` |
| 67 % | `<other: 1647 distinct>` |

### `core.registry.remove_for_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 3 % | `(5)` |
| 2 % | `(6)` |
| 1 % | `(20)` |
| 69 % | `<other: 1006 distinct>` |

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
