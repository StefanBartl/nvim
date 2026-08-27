# markdown.nvim — telemetry

**stopped** · counting + args + timing · 232 wrapped · 1 343 771 calls · 22 session(s)
Collecting since 2026-08-19 17:24.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `hl_options.hl_groups.blockquote.highlight_line` | 1 192 419 | 0.00 | — |
| `core.fold.foldexpr` | 110 749 | 0.01 | — |
| `config.feature_enabled` | 7 382 | 0.00 | — |
| `core.slug.slugify` | 5 981 | 0.00 | — |
| `scope.enabled` | 5 060 | 0.00 | — |
| `scope.op_enabled` | 5 032 | 0.00 | — |
| `scope.row_fence_kind` | 5 004 | 0.03 | — |
| `config.get` | 3 721 | 0.00 | — |
| `hover.float.close` | 1 945 | 0.00 | — |
| `hover.trigger` | 1 391 | 0.02 | — |
| `hover.link_under_cursor` | 1 353 | 0.03 | — |
| `hover.show` | 1 353 | 0.07 | — |
| `core.slug.heading_anchors` | 586 | 0.11 | — |
| `hover.hide` | 568 | 0.00 | — |
| `core.refs.baseline` | 244 | 0.11 | — |
| `core.refs.reconcile` | 171 | 0.83 | — |
| `core.link_scan.from_line` | 82 | 0.00 | — |
| `bindings.keymaps.apply` | 73 | — | — |
| `bindings.keymaps.apply_tableview` | 73 | — | — |
| `bindings.usrcmds.apply` | 73 | — | — |
| `bindings.usrcmds.apply_tableview` | 73 | — | — |
| `core.refs.attach` | 73 | — | — |
| `hover.attach` | 73 | — | — |
| `util.notify.create` | 35 | 0.01 | — |
| `hover.float.is_open` | 31 | — | — |
| `hover.float.open` | 31 | — | — |
| `hover.float.win` | 31 | — | — |
| `hover.classify.classify` | 29 | — | — |
| `scope.detect` | 28 | 0.07 | — |
| `hover.float.set_on_close` | 22 | — | — |
| `commands.toc.update` | 15 | 23.99 | — |
| `core.fold.heading_fold_row` | 10 | — | — |
| `bindings.actions.cursor_action_mouse` | 9 | — | — |
| `core.fold.toggle_under_cursor` | 6 | — | — |
| `handler.image.is_image_line` | 4 | — | — |
| `bindings.actions.heading_dec` | 3 | — | — |
| `bindings.actions.heading_dec_all` | 3 | — | — |
| `bindings.actions.heading_inc` | 3 | — | — |
| `commands.complete` | 3 | — | — |
| `scope.is_excluded` | 3 | — | — |
| `util.path.resolve` | 3 | — | — |
| `bindings.actions.heading_inc_all` | 2 | — | — |
| `bindings.actions.toc` | 2 | — | — |
| `commands.execute` | 2 | — | — |
| `commands.links.complete` | 2 | — | — |
| `core.headings.shift_range` | 2 | 2.47 | — |
| `core.refs.detach` | 2 | — | — |
| `handler.image.open` | 2 | — | — |
| `handler.image.open_image` | 2 | — | — |
| `util.picker.select` | 2 | — | — |
| `bindings.actions.next_heading` | 1 | — | — |
| `bindings.actions.prev_heading` | 1 | — | — |
| `commands.image.complete` | 1 | — | — |
| `core.link_scan.from_buffer` | 1 | 0.36 | — |
| `core.link_scan.from_lines` | 1 | 0.33 | — |

### `hl_options.hl_groups.blockquote.highlight_line` — argument profile

| Share | Argument |
| ---: | --- |
| 2 % | `(2, 9)` |
| 2 % | `(2, 8)` |
| 2 % | `(2, 12)` |
| 60 % | `<other: 254645 distinct>` |

### `core.fold.foldexpr` — argument profile

| Share | Argument |
| ---: | --- |
| 1 % | `(8)` |
| 1 % | `(10)` |
| 1 % | `(11)` |
| 85 % | `<other: 91146 distinct>` |

### `config.feature_enabled` — argument profile

| Share | Argument |
| ---: | --- |
| 69 % | `("fenced_scope")` |
| 25 % | `("keymaps")` |
| 2 % | `("table")` |

### `core.slug.slugify` — argument profile

| Share | Argument |
| ---: | --- |
| 5 % | `("Roadmap", <table:map>)` |
| 4 % | `("Misc", <table:map>)` |
| 3 % | `("(AN CLAUDE: NOCH NIHCT IMPLEMENTIEREN: E"…, <table:map>)` |
| 72 % | `<other: 1379 distinct>` |

### `scope.enabled` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `scope.op_enabled` — argument profile

| Share | Argument |
| ---: | --- |
| 99 % | `("fold")` |
| 0 % | `("toc")` |
| 0 % | `("shift")` |

> **99 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `scope.row_fence_kind` — argument profile

| Share | Argument |
| ---: | --- |
| 3 % | `(2, 0)` |
| 1 % | `(2, 2)` |
| 1 % | `(2, 19)` |
| 89 % | `<other: 2368 distinct>` |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `hover.float.close` — argument profile

| Share | Argument |
| ---: | --- |
| 99 % | `()` |
| 1 % | `(nil)` |

### `hover.trigger` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `hover.link_under_cursor` — argument profile

| Share | Argument |
| ---: | --- |
| 35 % | `(2)` |
| 19 % | `(54)` |
| 12 % | `(20)` |
| 2 % | `<other: 39 distinct>` |

### `hover.show` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |
| 0 % | `(<table:map>)` |

### `core.slug.heading_anchors` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `(2)` |
| 11 % | `(54)` |
| 8 % | `(129)` |
| 9 % | `<other: 56 distinct>` |

### `hover.hide` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `core.refs.baseline` — argument profile

| Share | Argument |
| ---: | --- |
| 41 % | `(2)` |
| 9 % | `(54)` |
| 7 % | `(129)` |
| 12 % | `<other: 56 distinct>` |

### `core.refs.reconcile` — argument profile

| Share | Argument |
| ---: | --- |
| 56 % | `(2, <table:map>)` |
| 12 % | `(54, <table:map>)` |
| 8 % | `(129, <table:map>)` |

### `core.link_scan.from_line` — argument profile

| Share | Argument |
| ---: | --- |
| 2 % | `("## markdown.nvim, images.nvim", 3)` |
| 1 % | `("", 15)` |
| 1 % | `("", 2)` |
| 60 % | `<other: 81 distinct>` |

### `bindings.keymaps.apply` — argument profile

| Share | Argument |
| ---: | --- |
| 5 % | `(129)` |
| 5 % | `(3)` |
| 5 % | `(4)` |
| 23 % | `<other: 49 distinct>` |

### `bindings.keymaps.apply_tableview` — argument profile

| Share | Argument |
| ---: | --- |
| 5 % | `(129)` |
| 5 % | `(3)` |
| 5 % | `(4)` |
| 23 % | `<other: 49 distinct>` |

### `bindings.usrcmds.apply` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `bindings.usrcmds.apply_tableview` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `core.refs.attach` — argument profile

| Share | Argument |
| ---: | --- |
| 5 % | `(129)` |
| 5 % | `(3)` |
| 5 % | `(4)` |
| 23 % | `<other: 49 distinct>` |

### `hover.attach` — argument profile

| Share | Argument |
| ---: | --- |
| 5 % | `(129)` |
| 5 % | `(3)` |
| 5 % | `(4)` |
| 23 % | `<other: 49 distinct>` |

### `util.notify.create` — argument profile

| Share | Argument |
| ---: | --- |
| 17 % | `("[markdown.anchor.jump]")` |
| 17 % | `("[markdown.handler.file]")` |
| 17 % | `("[markdown.handler.url]")` |

### `hover.float.is_open` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `hover.float.open` — argument profile

| Share | Argument |
| ---: | --- |
| 58 % | `(<table:empty>, <table:map>)` |
| 39 % | `(<table:#2>, <table:map>)` |
| 3 % | `(<table:#1>, <table:map>)` |

### `hover.float.win` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `hover.classify.classify` — argument profile

| Share | Argument |
| ---: | --- |
| 38 % | `("assets/ROADMAP-1787215848.png", "C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\R"…)` |
| 14 % | `("personal/gopatcache.pdf", "C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\R"…)` |
| 10 % | `("./pdf_test.pdf", "C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\T"…)` |

### `scope.detect` — argument profile

| Share | Argument |
| ---: | --- |
| 96 % | `()` |
| 4 % | `(33)` |

### `hover.float.set_on_close` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<function>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `commands.toc.update` — argument profile

| Share | Argument |
| ---: | --- |
| 73 % | `("## Table of content", <table:empty>)` |
| 27 % | `(nil, nil)` |

### `core.fold.heading_fold_row` — argument profile

| Share | Argument |
| ---: | --- |
| 20 % | `(54, 53)` |
| 20 % | `(54, 57)` |
| 10 % | `(2, 51)` |

### `bindings.actions.cursor_action_mouse` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `core.fold.toggle_under_cursor` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `handler.image.is_image_line` — argument profile

| Share | Argument |
| ---: | --- |
| 25 % | `("   ")` |
| 25 % | `("")` |
| 25 % | `("- [ ] Featureliste: welche bereits imple"…)` |

### `bindings.actions.heading_dec` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `bindings.actions.heading_dec_all` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `bindings.actions.heading_inc` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `commands.complete` — argument profile

| Share | Argument |
| ---: | --- |
| 67 % | `("", "Markdown links ", 0)` |
| 33 % | `("", "Markdown image ", 0)` |

### `scope.is_excluded` — argument profile

| Share | Argument |
| ---: | --- |
| 33 % | `(<table:map>, 181)` |
| 33 % | `(<table:map>, 47)` |
| 33 % | `(<table:map>, 77)` |

### `util.path.resolve` — argument profile

| Share | Argument |
| ---: | --- |
| 67 % | `("assets/ROADMAP-1787215848.png")` |
| 33 % | `("C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\R"…)` |

### `bindings.actions.heading_inc_all` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `bindings.actions.toc` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `commands.execute` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:#2>, <table:map>)` |

### `commands.links.complete` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("")` |

### `core.headings.shift_range` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `(1, 93, -1)` |
| 50 % | `(1, 93, 1)` |

### `core.refs.detach` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `(3)` |
| 50 % | `(60)` |

### `handler.image.open` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `handler.image.open_image` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\R"…)` |

### `util.picker.select` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:#2>, <table:map>, <function>)` |

### `bindings.actions.next_heading` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `bindings.actions.prev_heading` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `commands.image.complete` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("")` |

### `core.link_scan.from_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(2)` |

### `core.link_scan.from_lines` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:#106>)` |
