# cascade.nvim — telemetry

**stopped** · counting + args + timing · 155 wrapped · 76 285 calls · 38 session(s)
Collecting since 2026-08-19 17:24.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `lists.marker.parse` | 32 075 | 0.00 | — |
| `core.patterns.unordered_class` | 25 293 | 0.00 | — |
| `lists.marker.is_blank_line` | 5 098 | 0.00 | — |
| `lists.marker.is_continuation` | 5 098 | 0.00 | — |
| `util.lib.map` | 1 925 | — | — |
| `config.get` | 1 664 | 0.00 | — |
| `lists.marker.blank_run` | 1 386 | 0.00 | — |
| `lists.renumber.tree` | 1 188 | 0.06 | — |
| `core.context.writable` | 563 | 0.01 | — |
| `lists.renumber.at` | 312 | 0.00 | — |
| `core.context.new` | 274 | — | — |
| `core.treesitter.in_skip_node` | 270 | — | — |
| `lists.continue.cr` | 218 | — | — |
| `lists.renumber.all` | 171 | 1.39 | — |
| `cr` | 135 | — | — |
| `_move` | 116 | — | — |
| `lists.move.line` | 116 | — | — |
| `lists.format.apply` | 77 | — | — |
| `lists.format.list_pat` | 77 | — | — |
| `lists.marker.render` | 29 | — | — |
| `lists.continue.o` | 23 | — | — |
| `lists.transform.block_range` | 21 | — | — |
| `lists.marker.is_empty` | 19 | — | — |
| `lists.marker.advance` | 18 | — | — |
| `lists.renumber.run` | 18 | — | — |
| `o` | 15 | — | — |
| `util.lib.dotrepeat_run` | 15 | — | — |
| `dispatch.try` | 11 | — | — |
| `util.lib.debug_log` | 11 | — | — |
| `lists.quick_toggle.checkbox` | 9 | — | — |
| `lists.indent.shift_line` | 8 | — | — |
| `lists.continue.O` | 6 | — | — |
| `O` | 4 | — | — |
| `checkbox_toggle` | 4 | — | — |
| `lists.indent.shift_range` | 4 | — | — |
| `transpose.char.char` | 4 | — | — |
| `bullet_toggle` | 2 | — | — |
| `checkbox_toggle_visual` | 2 | — | — |
| `util.lib.keep_lines` | 2 | — | — |
| `util.lib.lines` | 2 | — | — |
| `util.lib.reselect_lines` | 2 | — | — |

### `lists.marker.parse` — argument profile

| Share | Argument |
| ---: | --- |
| 21 % | `("", <table:map>)` |
| 3 % | `("---", <table:map>)` |
| 0 % | `("# Roadmap", <table:map>)` |
| 74 % | `<other: 18207 distinct>` |

### `core.patterns.unordered_class` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:#3>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `lists.marker.is_blank_line` — argument profile

| Share | Argument |
| ---: | --- |
| 24 % | `("")` |
| 2 % | `("    C:/Users/bartl/AppData/Local/nvim/do"…)` |
| 2 % | `("    ```")` |
| 40 % | `<other: 1250 distinct>` |

### `lists.marker.is_continuation` — argument profile

| Share | Argument |
| ---: | --- |
| 24 % | `("", 0, 0)` |
| 2 % | `("    C:/Users/bartl/AppData/Local/nvim/do"…, 0, 0)` |
| 2 % | `("    ```", 0, 0)` |
| 40 % | `<other: 1250 distinct>` |

### `util.lib.map` — argument profile

| Share | Argument |
| ---: | --- |
| 4 % | `("i", "<CR>", <function>, <table:map>)` |
| 4 % | `("n", "<A-*>", <function>, <table:map>)` |
| 4 % | `("n", "<A-->", <function>, <table:map>)` |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 83 % | `("lists")` |
| 17 % | `("debug")` |
| 0 % | `("transpose")` |

> **83 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `lists.marker.blank_run` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `lists.renumber.tree` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `(2, 53, 53, <table:map>, …+1)` |
| 0 % | `(2, 55, 62, <table:map>, …+1)` |
| 0 % | `(2, 35, 35, <table:map>, …+1)` |
| 95 % | `<other: 891 distinct>` |

### `core.context.writable` — argument profile

| Share | Argument |
| ---: | --- |
| 55 % | `(2)` |
| 22 % | `(54)` |
| 5 % | `(129)` |

### `lists.renumber.at` — argument profile

| Share | Argument |
| ---: | --- |
| 55 % | `(<table:map>, "save")` |
| 45 % | `(<table:map>, "edit")` |

### `core.context.new` — argument profile

| Share | Argument |
| ---: | --- |
| 99 % | `()` |
| 1 % | `(2)` |
| 0 % | `(4)` |

### `core.treesitter.in_skip_node` — argument profile

| Share | Argument |
| ---: | --- |
| 3 % | `(2, 3, 0, "markdown", …+1)` |
| 2 % | `(2, 1, 0, "markdown", …+1)` |
| 2 % | `(2, 17, 0, "markdown", …+1)` |
| 71 % | `<other: 211 distinct>` |

### `lists.continue.cr` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, <table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `lists.renumber.all` — argument profile

| Share | Argument |
| ---: | --- |
| 56 % | `(2, <table:map>)` |
| 12 % | `(54, <table:map>)` |
| 8 % | `(129, <table:map>)` |

### `cr` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `_move` — argument profile

| Share | Argument |
| ---: | --- |
| 58 % | `(-1)` |
| 42 % | `(1)` |

### `lists.move.line` — argument profile

| Share | Argument |
| ---: | --- |
| 34 % | `(54, -1, <table:map>)` |
| 26 % | `(2, 1, <table:map>)` |
| 24 % | `(2, -1, <table:map>)` |

### `lists.format.apply` — argument profile

| Share | Argument |
| ---: | --- |
| 5 % | `(129, <table:map>)` |
| 5 % | `(3, <table:map>)` |
| 5 % | `(4, <table:map>)` |
| 25 % | `<other: 51 distinct>` |

### `lists.format.list_pat` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `lists.marker.render` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `lists.continue.o` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, <table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `lists.transform.block_range` — argument profile

| Share | Argument |
| ---: | --- |
| 10 % | `(54, 57, <table:map>)` |
| 5 % | `(169, 3, <table:map>)` |
| 5 % | `(169, 9, <table:map>)` |

### `lists.marker.is_empty` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

### `lists.marker.advance` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, <table:map>)` |

### `lists.renumber.run` — argument profile

| Share | Argument |
| ---: | --- |
| 22 % | `(2, 22, <table:map>)` |
| 11 % | `(2, 50, <table:map>)` |
| 6 % | `(2, 5, <table:map>)` |

### `o` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `util.lib.dotrepeat_run` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<function>)` |

### `dispatch.try` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:#1>, <table:map>)` |

### `util.lib.debug_log` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(false, "dispatch.try: handler tried", <table:map>)` |

### `lists.quick_toggle.checkbox` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, <table:map>)` |

### `lists.indent.shift_line` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, <table:map>, 1, 1)` |

### `lists.continue.O` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>, <table:map>)` |

### `O` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `checkbox_toggle` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `lists.indent.shift_range` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `(54, 59, 64, 1, …+3)` |
| 25 % | `(169, 3, 5, 1, …+3)` |
| 25 % | `(169, 9, 11, 1, …+3)` |

### `transpose.char.char` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `(<table:map>, -1)` |
| 50 % | `(<table:map>, 1)` |

### `bullet_toggle` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `checkbox_toggle_visual` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `util.lib.keep_lines` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<function>)` |

### `util.lib.lines` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `util.lib.reselect_lines` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(4, 4)` |
