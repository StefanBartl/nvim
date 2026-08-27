# github_stats.nvim — telemetry

**stopped** · counting + args + timing · 143 wrapped · 6 634 calls · 35 session(s)
Collecting since 2026-08-19 17:24.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `config.get_storage_root` | 1 628 | 0.00 | — |
| `storage.delete_metric_file` | 900 | 0.19 | — |
| `api.fetch_metric_async` | 700 | 12.65 | — |
| `config.get_token` | 700 | 0.02 | — |
| `storage.write_metric` | 700 | 1.54 | — |
| `storage.list_metric_files` | 400 | 0.90 | — |
| `config.get` | 364 | 0.01 | — |
| `analytics.query_metric` | 200 | 94.55 | — |
| `retention.compact_metric` | 200 | 97.19 | — |
| `retention.prune_metric` | 200 | 1.25 | — |
| `storage.get_metric_dir` | 200 | 0.01 | — |
| `storage.read_metric_history` | 200 | 94.28 | — |
| `config.get_repos` | 114 | 0.00 | — |
| `fetcher.fetch_all` | 110 | 76.71 | — |
| `config.get_retention` | 7 | 0.00 | — |
| `retention.maybe_run_all` | 7 | 4930.57 | — |
| `retention.run_all` | 4 | 4923.25 | — |

### `config.get_storage_root` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `storage.delete_metric_file` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("C:/Users/bartl/AppData/Local/nvim/lua/pl"…)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `api.fetch_metric_async` — argument profile

| Share | Argument |
| ---: | --- |
| 1 % | `("StefanBartl/buffer-ctx.nvim", "clones", <function>)` |
| 1 % | `("StefanBartl/buffer-ctx.nvim", "paths", <function>)` |
| 1 % | `("StefanBartl/buffer-ctx.nvim", "referrers", <function>)` |
| 68 % | `<other: 508 distinct>` |

### `config.get_token` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `storage.write_metric` — argument profile

| Share | Argument |
| ---: | --- |
| 1 % | `("StefanBartl/debugging.nvim", "paths", <table:#1>)` |
| 1 % | `("StefanBartl/diff.nvim", "clones", <table:map>)` |
| 1 % | `("StefanBartl/diff.nvim", "paths", <table:empty>)` |
| 71 % | `<other: 521 distinct>` |

### `storage.list_metric_files` — argument profile

| Share | Argument |
| ---: | --- |
| 1 % | `("StefanBartl/buffer-ctx.nvim", "clones")` |
| 1 % | `("StefanBartl/buffer-ctx.nvim", "paths")` |
| 1 % | `("StefanBartl/buffer-ctx.nvim", "referrers")` |
| 68 % | `<other: 304 distinct>` |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `analytics.query_metric` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `retention.compact_metric` — argument profile

| Share | Argument |
| ---: | --- |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "clones", <table:map>)` |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "views", <table:map>)` |
| 2 % | `("StefanBartl/cascade.nvim", "clones", <table:map>)` |
| 36 % | `<other: 104 distinct>` |

### `retention.prune_metric` — argument profile

| Share | Argument |
| ---: | --- |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "paths", <table:map>)` |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "referrers", <table:map>)` |
| 2 % | `("StefanBartl/cascade.nvim", "paths", <table:map>)` |
| 36 % | `<other: 104 distinct>` |

### `storage.get_metric_dir` — argument profile

| Share | Argument |
| ---: | --- |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "clones")` |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "views")` |
| 2 % | `("StefanBartl/cascade.nvim", "clones")` |
| 36 % | `<other: 104 distinct>` |

### `storage.read_metric_history` — argument profile

| Share | Argument |
| ---: | --- |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "clones")` |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "views")` |
| 2 % | `("StefanBartl/cascade.nvim", "clones")` |
| 36 % | `<other: 104 distinct>` |

### `config.get_repos` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `fetcher.fetch_all` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(false, nil, <table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `config.get_retention` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `retention.maybe_run_all` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `retention.run_all` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |
