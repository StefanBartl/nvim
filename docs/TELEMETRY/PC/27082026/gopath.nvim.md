# gopath.nvim — telemetry

**stopped** · counting + args + timing · 97 wrapped · 2 450 calls · 35 session(s)
Collecting since 2026-08-19 17:24.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `config.get` | 515 | 0.00 | — |
| `truncated.cache.needs_refresh` | 497 | 0.00 | — |
| `util.log.debug` | 248 | 0.01 | — |
| `truncated.cache.build_async` | 247 | 0.55 | — |
| `truncated.cache._finalize_build` | 246 | 0.00 | — |
| `truncated.cache._save_to_disk` | 246 | 74.75 | — |
| `util.safe_notify.safe_notify_defer` | 246 | 0.02 | — |
| `util.path.invalidate_caches` | 171 | 0.00 | — |
| `commands.resolve_and_open` | 3 | — | — |
| `providers.builtin.expand_cfile` | 3 | — | — |
| `resolve.resolve_at_cursor` | 3 | — | — |
| `resolvers.common.filetoken.resolve` | 3 | — | — |
| `resolvers.common.help.resolve` | 3 | — | — |
| `util.cross.to_forward` | 3 | — | — |
| `util.path.exists` | 3 | — | — |
| `open.open` | 2 | — | — |
| `truncated.cache.search` | 2 | — | — |
| `util.location.parse_location` | 2 | — | — |
| `util.log.info` | 2 | — | — |
| `util.log.warn` | 2 | — | — |
| `util.location.create_range` | 1 | — | — |
| `util.log.error` | 1 | — | — |
| `util.path.search_with_vim_path` | 1 | — | — |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `truncated.cache.needs_refresh` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(600)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `util.log.debug` — argument profile

| Share | Argument |
| ---: | --- |
| 17 % | `("Cache built: 20513 files indexed")` |
| 14 % | `("Cache built: 20473 files indexed")` |
| 9 % | `("Cache built: 20524 files indexed")` |
| 24 % | `<other: 91 distinct>` |

### `truncated.cache.build_async` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<function>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `truncated.cache._finalize_build` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<function>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `truncated.cache._save_to_disk` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `util.safe_notify.safe_notify_defer` — argument profile

| Share | Argument |
| ---: | --- |
| 70 % | `("[gopath] Building cache from 3 roots...", 2, nil, 50)` |
| 30 % | `("[gopath] Building cache from 4 roots...", 2, nil, 50)` |

### `util.path.invalidate_caches` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `commands.resolve_and_open` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("edit")` |

### `providers.builtin.expand_cfile` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `resolve.resolve_at_cursor` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:empty>)` |

### `resolvers.common.filetoken.resolve` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `resolvers.common.help.resolve` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `util.cross.to_forward` — argument profile

| Share | Argument |
| ---: | --- |
| 33 % | `("C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\R"…)` |
| 33 % | `("gopath")` |
| 33 % | `("personal/gopatcache.pdf")` |

### `util.path.exists` — argument profile

| Share | Argument |
| ---: | --- |
| 33 % | `("C:/Users/bartl/AppData/Local/nvim/docs/R"…)` |
| 33 % | `("docs\\ROADMAP\\personal/gopatcache.pdf")` |
| 33 % | `("personal/gopatcache.pdf")` |

### `open.open` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, "edit")` |

### `truncated.cache.search` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `("cache")` |
| 50 % | `("gopatcache.pdf)")` |

### `util.location.parse_location` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `("gopath")` |
| 50 % | `("personal/gopatcache.pdf")` |

### `util.log.info` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `("Dateisuche läuft…")` |
| 50 % | `("Opening externally: gopatcache.pdf")` |

### `util.log.warn` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `("File not created: cache")` |
| 50 % | `("no match: no-match")` |

### `util.location.create_range` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(nil, nil)` |

### `util.log.error` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("Filesystem cache build failed")` |

### `util.path.search_with_vim_path` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("personal/gopatcache.pdf")` |
