# markdown.nvim — telemetry

**stopped** · counting + args + timing · 246 wrapped · 205 784 calls · 6 session(s)
Collecting since 2026-08-27 10:45.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `hl_options.hl_groups.blockquote.highlight_line` | 147 601 | 0.00 | — |
| `core.fold.foldexpr` | 40 261 | 0.00 | — |
| `core.link_scan.from_line` | 3 054 | 0.00 | — |
| `core.link_sanitize.sanitize_line` | 2 884 | 0.00 | — |
| `core.html_links.from_line` | 2 172 | 0.00 | — |
| `config.feature_enabled` | 1 825 | 0.00 | — |
| `scope.enabled` | 1 329 | 0.00 | — |
| `scope.op_enabled` | 1 312 | 0.00 | — |
| `scope.row_fence_kind` | 1 295 | 0.01 | — |
| `core.slug.slugify` | 1 288 | 0.00 | — |
| `config.get` | 712 | 0.00 | — |
| `hover.float.close` | 383 | 0.00 | — |
| `hover.trigger` | 291 | 0.02 | — |
| `hover.link_under_cursor` | 287 | 0.11 | — |
| `hover.show` | 287 | 0.15 | — |
| `core.html_links.figure_at` | 170 | 0.04 | — |
| `core.link_sanitize.sanitize_target` | 110 | 0.00 | — |
| `hover.hide` | 96 | 0.01 | — |
| `core.slug.heading_anchors` | 91 | 0.18 | — |
| `core.refs.baseline` | 41 | 0.23 | — |
| `core.refs.reconcile` | 25 | 3.09 | — |
| `scope.detect` | 17 | 0.07 | — |
| `bindings.keymaps.apply` | 16 | 0.20 | — |
| `bindings.keymaps.apply_tableview` | 16 | 0.07 | — |
| `bindings.usrcmds.apply` | 16 | 0.15 | — |
| `bindings.usrcmds.apply_tableview` | 16 | 0.06 | — |
| `commands.toc.update` | 16 | 1.95 | — |
| `core.refs.attach` | 16 | 0.36 | — |
| `hover.attach` | 16 | 0.03 | — |
| `core.link_sanitize.buffer` | 15 | 0.52 | — |
| `core.link_sanitize.sanitize_lines` | 15 | 0.50 | — |
| `core.link_scan.from_buffer` | 15 | 1.06 | — |
| `core.link_scan.from_lines` | 15 | 1.04 | — |
| `core.heading_gaps.check` | 11 | 0.07 | — |
| `core.heading_gaps.find_gaps` | 11 | 0.06 | — |
| `core.headline_spacing.apply_headl_separators` | 11 | 0.30 | — |
| `core.headline_spacing.find_sections_needing_separator` | 11 | 0.15 | — |
| `core.toc.update_markdown_toc` | 11 | 1.43 | — |
| `core.slug.gfm` | 10 | — | — |
| `util.notify.create` | 6 | — | — |
| `bindings.actions.cursor_action_mouse` | 2 | 1.36 | — |
| `core.fold.heading_fold_row` | 2 | 0.01 | — |
| `handler.handle_cursor_action` | 2 | 1.35 | — |
| `anchor.jump.jump` | 1 | 0.42 | — |
| `core.fold.toggle_under_cursor` | 1 | 2.16 | — |
| `hover.classify.classify` | 1 | — | — |
| `hover.float.open` | 1 | — | — |

### `hl_options.hl_groups.blockquote.highlight_line` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `(20, 28)` |
| 0 % | `(20, 25)` |
| 0 % | `(20, 26)` |
| 97 % | `<other: 62567 distinct>` |

### `core.fold.foldexpr` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `(2)` |
| 0 % | `(3)` |
| 0 % | `(1)` |
| 92 % | `<other: 36855 distinct>` |

### `core.link_scan.from_line` — argument profile

| Share | Argument |
| ---: | --- |
| 1 % | `("", 2)` |
| 0 % | `("", 15)` |
| 0 % | `("# Roadmap", 1)` |
| 93 % | `<other: 2820 distinct>` |

### `core.link_sanitize.sanitize_line` — argument profile

| Share | Argument |
| ---: | --- |
| 29 % | `("")` |
| 5 % | `("---")` |
| 0 % | `("    - [Plugin-Liste](#plugin-liste)")` |
| 57 % | `<other: 1661 distinct>` |

### `core.html_links.from_line` — argument profile

| Share | Argument |
| ---: | --- |
| 1 % | `("# Roadmap", 1)` |
| 0 % | `("## Table of content", 3)` |
| 0 % | `("    - [Plugin-Liste](#plugin-liste)", 13)` |
| 92 % | `<other: 1983 distinct>` |

### `config.feature_enabled` — argument profile

| Share | Argument |
| ---: | --- |
| 73 % | `("fenced_scope")` |
| 22 % | `("keymaps")` |
| 2 % | `("table")` |

### `scope.enabled` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `scope.op_enabled` — argument profile

| Share | Argument |
| ---: | --- |
| 99 % | `("fold")` |
| 1 % | `("toc")` |
| 0 % | `("jump")` |

> **99 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `scope.row_fence_kind` — argument profile

| Share | Argument |
| ---: | --- |
| 4 % | `(2, 0)` |
| 3 % | `(2, 2)` |
| 2 % | `(2, 17)` |
| 77 % | `<other: 526 distinct>` |

### `core.slug.slugify` — argument profile

| Share | Argument |
| ---: | --- |
| 5 % | `("Misc", <table:map>)` |
| 5 % | `("color_my_ascii.nvim", <table:map>)` |
| 5 % | `("filetree.nvim", <table:map>)` |
| 5 % | `<other: 99 distinct>` |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `hover.float.close` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `hover.trigger` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `hover.link_under_cursor` — argument profile

| Share | Argument |
| ---: | --- |
| 40 % | `(2)` |
| 32 % | `(20)` |
| 20 % | `(3)` |

### `hover.show` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `core.html_links.figure_at` — argument profile

| Share | Argument |
| ---: | --- |
| 6 % | `(20, 91)` |
| 5 % | `(2, 2)` |
| 5 % | `(20, 29)` |
| 50 % | `<other: 91 distinct>` |

### `core.link_sanitize.sanitize_target` — argument profile

| Share | Argument |
| ---: | --- |
| 10 % | `("#cdx")` |
| 10 % | `("#color_my_asciinvim")` |
| 10 % | `("#filetreenvim")` |

### `hover.hide` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `core.slug.heading_anchors` — argument profile

| Share | Argument |
| ---: | --- |
| 57 % | `(2)` |
| 18 % | `(20)` |
| 18 % | `(3)` |

### `core.refs.baseline` — argument profile

| Share | Argument |
| ---: | --- |
| 49 % | `(2)` |
| 20 % | `(20)` |
| 15 % | `(3)` |

### `core.refs.reconcile` — argument profile

| Share | Argument |
| ---: | --- |
| 64 % | `(2, <table:map>)` |
| 20 % | `(3, <table:map>)` |
| 16 % | `(20, <table:map>)` |

### `scope.detect` — argument profile

| Share | Argument |
| ---: | --- |
| 94 % | `()` |
| 6 % | `(2)` |

### `bindings.keymaps.apply` — argument profile

| Share | Argument |
| ---: | --- |
| 25 % | `(2)` |
| 25 % | `(20)` |
| 12 % | `(134)` |

### `bindings.keymaps.apply_tableview` — argument profile

| Share | Argument |
| ---: | --- |
| 25 % | `(2)` |
| 25 % | `(20)` |
| 12 % | `(134)` |

### `bindings.usrcmds.apply` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

### `bindings.usrcmds.apply_tableview` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

### `commands.toc.update` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("## Table of content", <table:empty>)` |

### `core.refs.attach` — argument profile

| Share | Argument |
| ---: | --- |
| 25 % | `(2)` |
| 25 % | `(20)` |
| 12 % | `(134)` |

### `hover.attach` — argument profile

| Share | Argument |
| ---: | --- |
| 25 % | `(2)` |
| 25 % | `(20)` |
| 12 % | `(134)` |

### `core.link_sanitize.buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 73 % | `(2)` |
| 27 % | `(20)` |

### `core.link_sanitize.sanitize_lines` — argument profile

| Share | Argument |
| ---: | --- |
| 20 % | `(<table:#212>)` |
| 13 % | `(<table:#108>)` |
| 13 % | `(<table:#209>)` |

### `core.link_scan.from_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 73 % | `(2)` |
| 27 % | `(20)` |

### `core.link_scan.from_lines` — argument profile

| Share | Argument |
| ---: | --- |
| 20 % | `(<table:#212>)` |
| 13 % | `(<table:#108>)` |
| 13 % | `(<table:#209>)` |

### `core.heading_gaps.check` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(2, <table:map>)` |

### `core.heading_gaps.find_gaps` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(2)` |

### `core.headline_spacing.apply_headl_separators` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(2, <table:map>)` |

### `core.headline_spacing.find_sections_needing_separator` — argument profile

| Share | Argument |
| ---: | --- |
| 27 % | `(<table:#212>)` |
| 18 % | `(<table:#211>)` |
| 18 % | `(<table:#228>)` |

### `core.toc.update_markdown_toc` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("## Table of content", <table:map>)` |

### `core.slug.gfm` — argument profile

| Share | Argument |
| ---: | --- |
| 10 % | `("Misc")` |
| 10 % | `("Roadmap")` |
| 10 % | `("Table of content")` |

### `util.notify.create` — argument profile

| Share | Argument |
| ---: | --- |
| 33 % | `("[markdown.core.heading_gaps]")` |
| 33 % | `("[markdown.core.headline_spacing]")` |
| 33 % | `("[markdown.core.toc]")` |

### `bindings.actions.cursor_action_mouse` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `core.fold.heading_fold_row` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `(2, 3)` |
| 50 % | `(2, 31)` |

### `handler.handle_cursor_action` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

### `anchor.jump.jump` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `core.fold.toggle_under_cursor` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `hover.classify.classify` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("#true-check", "C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\R"…)` |

### `hover.float.open` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:#21>, <table:map>)` |
