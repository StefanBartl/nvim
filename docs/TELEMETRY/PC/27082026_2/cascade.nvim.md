# cascade.nvim — telemetry

**stopped** · counting + args + timing · 155 wrapped · 14 364 calls · 6 session(s)
Collecting since 2026-08-27 10:45.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `lists.marker.parse` | 6 314 | 0.00 | — |
| `core.patterns.unordered_class` | 5 018 | 0.00 | — |
| `lists.marker.is_blank_line` | 1 015 | 0.00 | — |
| `lists.marker.is_continuation` | 1 015 | 0.00 | — |
| `util.lib.map` | 225 | 0.01 | — |
| `lists.marker.blank_run` | 203 | 0.00 | — |
| `lists.renumber.tree` | 177 | 0.13 | — |
| `config.get` | 158 | 0.00 | — |
| `core.context.writable` | 49 | 0.01 | — |
| `lists.renumber.at` | 31 | 0.00 | — |
| `lists.renumber.all` | 25 | 2.19 | — |
| `core.context.new` | 20 | 0.01 | — |
| `core.treesitter.in_skip_node` | 20 | 0.00 | — |
| `lists.format.apply` | 16 | 0.02 | — |
| `lists.format.list_pat` | 16 | 0.01 | — |
| `lists.continue.cr` | 11 | 0.03 | — |
| `cr` | 6 | 0.15 | — |
| `lists.marker.render` | 6 | 0.00 | — |
| `_move` | 4 | 5.09 | — |
| `dispatch.try` | 4 | 0.85 | — |
| `lists.move.line` | 4 | 5.04 | — |
| `lists.quick_toggle.checkbox` | 4 | 0.81 | — |
| `util.lib.debug_log` | 4 | 0.00 | — |
| `util.lib.dotrepeat_run` | 4 | 5.83 | — |
| `O` | 2 | 0.08 | — |
| `checkbox_toggle` | 2 | 6.36 | — |
| `lists.continue.O` | 2 | 0.01 | — |
| `lists.continue.o` | 2 | — | — |
| `lists.marker.advance` | 2 | — | — |
| `lists.renumber.run` | 2 | — | — |
| `lists.indent.shift_line` | 1 | — | — |
| `lists.transform.block_range` | 1 | 0.02 | — |
| `o` | 1 | — | — |

### `lists.marker.parse` — argument profile

| Share | Argument |
| ---: | --- |
| 21 % | `("", <table:map>)` |
| 3 % | `("---", <table:map>)` |
| 1 % | `("  - [Misc](#misc)", <table:map>)` |
| 62 % | `<other: 3357 distinct>` |

### `core.patterns.unordered_class` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:#3>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `lists.marker.is_blank_line` — argument profile

| Share | Argument |
| ---: | --- |
| 18 % | `("")` |
| 3 % | `("  Es soll immer den letzen echten comman"…)` |
| 2 % | `("      Messung.")` |
| 41 % | `<other: 322 distinct>` |

### `lists.marker.is_continuation` — argument profile

| Share | Argument |
| ---: | --- |
| 18 % | `("", 0, 0)` |
| 3 % | `("  Es soll immer den letzen echten comman"…, 0, 0)` |
| 2 % | `("      Messung.", 0, 0)` |
| 41 % | `<other: 329 distinct>` |

### `util.lib.map` — argument profile

| Share | Argument |
| ---: | --- |
| 4 % | `("i", "<CR>", <function>, <table:map>)` |
| 4 % | `("n", "<A-*>", <function>, <table:map>)` |
| 4 % | `("n", "<A-->", <function>, <table:map>)` |

### `lists.marker.blank_run` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `lists.renumber.tree` — argument profile

| Share | Argument |
| ---: | --- |
| 6 % | `(2, 19, 23, <table:map>, …+1)` |
| 6 % | `(2, 4, 13, <table:map>, …+1)` |
| 3 % | `(2, 28, 30, <table:map>, …+1)` |
| 51 % | `<other: 96 distinct>` |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 80 % | `("lists")` |
| 15 % | `("debug")` |
| 4 % | `("keymaps")` |

> **80 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `core.context.writable` — argument profile

| Share | Argument |
| ---: | --- |
| 65 % | `(2)` |
| 22 % | `(3)` |
| 12 % | `(20)` |

### `lists.renumber.at` — argument profile

| Share | Argument |
| ---: | --- |
| 81 % | `(<table:map>, "save")` |
| 19 % | `(<table:map>, "edit")` |

> **81 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `lists.renumber.all` — argument profile

| Share | Argument |
| ---: | --- |
| 64 % | `(2, <table:map>)` |
| 20 % | `(3, <table:map>)` |
| 16 % | `(20, <table:map>)` |

### `core.context.new` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `core.treesitter.in_skip_node` — argument profile

| Share | Argument |
| ---: | --- |
| 10 % | `(2, 31, 0, "markdown", …+1)` |
| 10 % | `(2, 32, 0, "markdown", …+1)` |
| 10 % | `(2, 46, 0, "markdown", …+1)` |

### `lists.format.apply` — argument profile

| Share | Argument |
| ---: | --- |
| 25 % | `(2, <table:map>)` |
| 25 % | `(20, <table:map>)` |
| 12 % | `(134, <table:map>)` |

### `lists.format.list_pat` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

### `lists.continue.cr` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, <table:map>)` |

### `cr` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `lists.marker.render` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

### `_move` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(-1)` |

### `dispatch.try` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:#1>, <table:map>)` |

### `lists.move.line` — argument profile

| Share | Argument |
| ---: | --- |
| 75 % | `(2, -1, <table:map>)` |
| 25 % | `(20, -1, <table:map>)` |

### `lists.quick_toggle.checkbox` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, <table:map>)` |

### `util.lib.debug_log` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(false, "dispatch.try: handler tried", <table:map>)` |

### `util.lib.dotrepeat_run` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<function>)` |

### `O` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `checkbox_toggle` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `lists.continue.O` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, <table:map>)` |

### `lists.continue.o` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, <table:map>)` |

### `lists.marker.advance` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, <table:map>)` |

### `lists.renumber.run` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `(2, 32, <table:map>)` |
| 50 % | `(3, 44, <table:map>)` |

### `lists.indent.shift_line` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, <table:map>, 1, 1)` |

### `lists.transform.block_range` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(20, 42, <table:map>)` |

### `o` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |
