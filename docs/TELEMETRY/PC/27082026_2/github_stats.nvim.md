# github_stats.nvim — telemetry

**stopped** · counting + args + timing · 143 wrapped · 30 140 calls · 22 session(s)
Collecting since 2026-08-27 10:45.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `config.get_storage_root` | 6 565 | 0.00 | — |
| `analytics.query_metric` | 6 136 | — | — |
| `storage.read_metric_history` | 6 136 | — | — |
| `config.get` | 4 611 | 0.00 | — |
| `analytics.trend_over` | 2 028 | — | — |
| `visualization.generate_sparkline` | 2 028 | — | — |
| `storage.invalidate` | 254 | — | — |
| `dashboard.state.update_scroll_limits` | 206 | — | — |
| `dashboard.state.get_repo_line` | 143 | — | — |
| `dashboard.state.clamp_scroll_offset` | 128 | — | — |
| `dashboard.schedule_render` | 119 | — | — |
| `dashboard.state.should_render` | 118 | — | — |
| `api.fetch_metric_async` | 104 | — | — |
| `config.get_token` | 104 | — | — |
| `storage.list_metric_files` | 104 | — | — |
| `storage.write_metric` | 104 | — | — |
| `storage.delete_metric_file` | 100 | — | — |
| `dashboard.render.set_cursor_to_current` | 79 | — | — |
| `dashboard.state.get_state` | 79 | — | — |
| `state.ui_state.buf_is_valid` | 79 | — | — |
| `state.ui_state.win_is_valid` | 79 | — | — |
| `analytics.count_days` | 78 | — | — |
| `dashboard.render.render_dashboard` | 78 | — | — |
| `dashboard.state.mark_rendered` | 78 | — | — |
| `dashboard.state.set_current_index` | 78 | — | — |
| `dashboard.state.update_window_height` | 78 | — | — |
| `state.ui_state.get_buf_win` | 78 | — | — |
| `dashboard.movement.move_cursor_up` | 68 | — | — |
| `retention.compact_metric` | 52 | — | — |
| `retention.prune_metric` | 52 | — | — |
| `storage.get_metric_dir` | 52 | — | — |
| `dashboard.state.scroll_by` | 50 | — | — |
| `dashboard.movement.move_cursor_down` | 49 | — | — |
| `config.get_repos` | 14 | 0.00 | — |
| `fetcher.fetch_all` | 12 | 0.36 | — |
| `bindings.keymaps.setup_keymaps` | 1 | — | — |
| `bindings.usrcmds.dashboard.execute` | 1 | — | — |
| `config.get_notification_level` | 1 | — | — |
| `config.get_retention` | 1 | — | — |
| `config.notify` | 1 | — | — |
| `dashboard.open` | 1 | — | — |
| `dashboard.state.clear_state` | 1 | — | — |
| `dashboard.state.init_state` | 1 | — | — |
| `dashboard.state.mark_closed` | 1 | — | — |
| `dashboard.state.mark_open` | 1 | — | — |
| `retention.maybe_run_all` | 1 | — | — |
| `retention.run_all` | 1 | — | — |
| `state.ui_state.cleanup_all` | 1 | — | — |
| `state.ui_state.clear` | 1 | — | — |
| `state.ui_state.close_window` | 1 | — | — |
| `state.ui_state.delete_buffer` | 1 | — | — |
| `state.ui_state.get_win` | 1 | — | — |
| `state.ui_state.set_buf` | 1 | — | — |
| `state.ui_state.set_win` | 1 | — | — |

### `config.get_storage_root` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `analytics.query_metric` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `storage.read_metric_history` — argument profile

| Share | Argument |
| ---: | --- |
| 3 % | `("StefanBartl/buffer-ctx.nvim", "clones")` |
| 3 % | `("StefanBartl/cascade.nvim", "clones")` |
| 3 % | `("StefanBartl/color_my_ascii.nvim", "clones")` |
| 57 % | `<other: 2402 distinct>` |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `analytics.trend_over` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, 7)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `visualization.generate_sparkline` — argument profile

| Share | Argument |
| ---: | --- |
| 96 % | `(<table:#30>, 24)` |
| 4 % | `(<table:#14>, 24)` |

> **96 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `storage.invalidate` — argument profile

| Share | Argument |
| ---: | --- |
| 1 % | `("StefanBartl/cascade.nvim", "views")` |
| 1 % | `("StefanBartl/cmdlog.nvim", "views")` |
| 1 % | `("StefanBartl/diff.nvim", "clones")` |
| 83 % | `<other: 244 distinct>` |

### `dashboard.state.update_scroll_limits` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `dashboard.state.get_repo_line` — argument profile

| Share | Argument |
| ---: | --- |
| 15 % | `(1)` |
| 9 % | `(26)` |
| 6 % | `(7)` |

### `dashboard.state.clamp_scroll_offset` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `dashboard.schedule_render` — argument profile

| Share | Argument |
| ---: | --- |
| 99 % | `(false)` |
| 1 % | `(true)` |

> **99 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `dashboard.state.should_render` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(50)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `api.fetch_metric_async` — argument profile

| Share | Argument |
| ---: | --- |
| 1 % | `("StefanBartl/buffer-ctx.nvim", "clones", <function>)` |
| 1 % | `("StefanBartl/buffer-ctx.nvim", "paths", <function>)` |
| 1 % | `("StefanBartl/buffer-ctx.nvim", "referrers", <function>)` |
| 69 % | `<other: 104 distinct>` |

### `config.get_token` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `storage.list_metric_files` — argument profile

| Share | Argument |
| ---: | --- |
| 1 % | `("StefanBartl/buffer-ctx.nvim", "clones")` |
| 1 % | `("StefanBartl/buffer-ctx.nvim", "paths")` |
| 1 % | `("StefanBartl/buffer-ctx.nvim", "referrers")` |
| 69 % | `<other: 104 distinct>` |

### `storage.write_metric` — argument profile

| Share | Argument |
| ---: | --- |
| 1 % | `("StefanBartl/cascade.nvim", "paths", <table:#1>)` |
| 1 % | `("StefanBartl/cascade.nvim", "views", <table:map>)` |
| 1 % | `("StefanBartl/cmdlog.nvim", "referrers", <table:empty>)` |
| 69 % | `<other: 104 distinct>` |

### `storage.delete_metric_file` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("C:/Users/bartl/AppData/Local/nvim/lua/pl"…)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `dashboard.render.set_cursor_to_current` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `dashboard.state.get_state` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `state.ui_state.buf_is_valid` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `state.ui_state.win_is_valid` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `analytics.count_days` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("2026-07-28", "2026-08-26")` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `dashboard.render.render_dashboard` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `dashboard.state.mark_rendered` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `dashboard.state.set_current_index` — argument profile

| Share | Argument |
| ---: | --- |
| 24 % | `(1)` |
| 15 % | `(26)` |
| 5 % | `(7)` |

### `dashboard.state.update_window_height` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(27)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `state.ui_state.get_buf_win` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `dashboard.movement.move_cursor_up` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, 1)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `retention.compact_metric` — argument profile

| Share | Argument |
| ---: | --- |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "clones", <table:map>)` |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "views", <table:map>)` |
| 2 % | `("StefanBartl/cascade.nvim", "clones", <table:map>)` |
| 38 % | `<other: 52 distinct>` |

### `retention.prune_metric` — argument profile

| Share | Argument |
| ---: | --- |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "paths", <table:map>)` |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "referrers", <table:map>)` |
| 2 % | `("StefanBartl/cascade.nvim", "paths", <table:map>)` |
| 38 % | `<other: 52 distinct>` |

### `storage.get_metric_dir` — argument profile

| Share | Argument |
| ---: | --- |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "clones")` |
| 2 % | `("StefanBartl/buffer-ctx.nvim", "views")` |
| 2 % | `("StefanBartl/cascade.nvim", "clones")` |
| 38 % | `<other: 52 distinct>` |

### `dashboard.state.scroll_by` — argument profile

| Share | Argument |
| ---: | --- |
| 56 % | `(-5)` |
| 44 % | `(5)` |

### `dashboard.movement.move_cursor_down` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, 1)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `config.get_repos` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `fetcher.fetch_all` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(false, nil, <table:map>)` |

### `bindings.keymaps.setup_keymaps` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(32)` |

### `bindings.usrcmds.dashboard.execute` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

### `config.get_notification_level` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `config.get_retention` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `config.notify` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("GitHub Stats Dashboard Keybindings:\
  j/"…, "info")` |

### `dashboard.open` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(false)` |

### `dashboard.state.clear_state` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `dashboard.state.init_state` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:#26>)` |

### `dashboard.state.mark_closed` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `dashboard.state.mark_open` — argument profile

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

### `state.ui_state.cleanup_all` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `state.ui_state.clear` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `state.ui_state.close_window` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `state.ui_state.delete_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `state.ui_state.get_win` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `state.ui_state.set_buf` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(32)` |

### `state.ui_state.set_win` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(1019)` |
