# gopath.nvim — telemetry

**stopped** · counting + args + timing · 97 wrapped · 150 calls · 6 session(s)
Collecting since 2026-08-27 10:45.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `config.get` | 28 | 0.00 | — |
| `truncated.cache.needs_refresh` | 27 | 0.00 | — |
| `util.path.invalidate_caches` | 25 | 0.00 | — |
| `truncated.cache._finalize_build` | 14 | 0.01 | — |
| `truncated.cache._save_to_disk` | 14 | 76.06 | — |
| `truncated.cache.build_async` | 14 | 0.54 | — |
| `util.log.debug` | 14 | 0.01 | — |
| `util.safe_notify.safe_notify_defer` | 14 | 0.03 | — |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `truncated.cache.needs_refresh` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(600)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `util.path.invalidate_caches` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `truncated.cache._finalize_build` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<function>)` |

### `truncated.cache._save_to_disk` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `truncated.cache.build_async` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<function>)` |

### `util.log.debug` — argument profile

| Share | Argument |
| ---: | --- |
| 14 % | `("Cache built: 22416 files indexed")` |
| 14 % | `("Cache built: 22420 files indexed")` |
| 7 % | `("Cache built: 22303 files indexed")` |

### `util.safe_notify.safe_notify_defer` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("[gopath] Building cache from 4 roots...", 2, nil, 50)` |
