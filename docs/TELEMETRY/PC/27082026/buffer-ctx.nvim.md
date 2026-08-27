# buffer-ctx.nvim — telemetry

**stopped** · counting + args · 86 wrapped · 162 calls · 20 session(s)
Collecting since 2026-08-05 22:22.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `commands._dispatch` | 26 | — | — |
| `ops.filepath._format_segments` | 26 | — | — |
| `ops.filepath.get_path` | 26 | — | — |
| `ops.filepath.parse_args` | 26 | — | — |
| `util.clip.copy` | 26 | — | — |
| `util.notify.info` | 26 | — | — |
| `mark.toggle` | 2 | — | — |
| `mark.yank` | 2 | — | — |
| `util.notify.warn` | 2 | — | — |

### `commands._dispatch` — argument profile

| Share | Argument |
| ---: | --- |
| 77 % | `("filepath", <table:#1>, "clip")` |
| 23 % | `("filepath", <table:#1>, "clip", nil)` |

> **77 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `ops.filepath._format_segments` — argument profile

| Share | Argument |
| ---: | --- |
| 58 % | `(<table:#10>, "unix")` |
| 15 % | `(<table:#11>, "unix")` |
| 15 % | `(<table:#5>, "unix")` |

### `ops.filepath.get_path` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:map>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `ops.filepath.parse_args` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(<table:#1>)` |

> **100 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `util.clip.copy` — argument profile

| Share | Argument |
| ---: | --- |
| 62 % | `("C:/Users/bartl/AppData/Local/nvim/docs/R"…)` |
| 12 % | `("C:/Users/bartl/AppData/Local/nvim/lua/pl"…)` |
| 8 % | `("E:/repos/documentation.nvim/docs/FEATURE"…)` |

### `util.notify.info` — argument profile

| Share | Argument |
| ---: | --- |
| 77 % | `("copied: C:/Users/bartl/AppData/Local/nvi"…)` |
| 8 % | `("copied: E:/repos/documentation.nvim/docs"…)` |
| 4 % | `("copied: E:/repos/Notes/MyNotes/Checklist"…)` |

> **77 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `mark.toggle` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(32)` |

### `mark.yank` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `util.notify.warn` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("No marked lines in this buffer")` |
