# color_my_ascii.nvim — telemetry

**stopped** · counting + args · 95 wrapped · 5 907 747 calls · 56 session(s)
Collecting since 2026-08-24 05:57.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `config.get_char_highlight` | 2 551 724 | — | — |
| `utils.safe_api.safe_call` | 647 282 | — | — |
| `utils.safe_api.buf_set_extmark` | 634 911 | — | — |
| `utils.safe_api.set_extmark` | 634 911 | — | — |
| `config.get` | 563 793 | — | — |
| `config.get_keyword_languages` | 426 450 | — | — |
| `parser.tokenize_line` | 145 637 | — | — |
| `config.is_function_detection_enabled` | 138 973 | — | — |
| `config.get_unique_language` | 44 099 | — | — |
| `cache_manager.cleanup` | 19 762 | — | — |
| `utils.safe_api.buf_line_count` | 12 371 | — | — |
| `utils.safe_api.is_valid_buffer` | 8 362 | — | — |
| `parser.find_inline_codes` | 7 661 | — | — |
| `parser.scan_blocks_heuristic` | 7 531 | — | — |
| `parser.is_ascii_fence` | 6 380 | — | — |
| `debounce_manager.debounce` | 4 945 | — | — |
| `api.fences.list_blocks` | 4 525 | — | — |
| `fence_hl.clear` | 4 021 | — | — |
| `highlighter.clear_buffer` | 4 021 | — | — |
| `cache_manager.get` | 4 000 | — | — |
| `fence_hl.apply` | 4 000 | — | — |
| `highlight_buffer` | 4 000 | — | — |
| `highlighter.highlight_inline_codes` | 4 000 | — | — |
| `parser.find_all_blocks` | 3 870 | — | — |
| `cache_manager.set` | 3 661 | — | — |
| `parser.find_ascii_blocks` | 3 661 | — | — |
| `parser.find_ascii_blocks_heuristic` | 3 661 | — | — |
| `highlighter.highlight_block` | 3 091 | — | — |
| `highlighter_ts.highlight_block` | 3 091 | — | — |
| `language_detector.detect_language` | 3 091 | — | — |
| `commands.fence.register` | 91 | — | — |
| `setup_buffer` | 91 | — | — |
| `debounce_manager.cancel` | 50 | — | — |
| `cache_manager.invalidate` | 21 | — | — |
| `api.fences.block_at` | 9 | — | — |

### `config.get_char_highlight` — argument profile

| Share | Argument |
| ---: | --- |
| 9 % | `(" ")` |
| 7 % | `("e")` |
| 6 % | `("i")` |
| 25 % | `<other: 354191 distinct>` |

### `utils.safe_api.safe_call` — argument profile

| Share | Argument |
| ---: | --- |
| 1 % | `(<function>, 2)` |
| 0 % | `(<function>, 3)` |
| 0 % | `(<function>, 3, 36, 51, …+2)` |
| 99 % | `<other: 275126 distinct>` |

### `utils.safe_api.buf_set_extmark` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `(3, 74, 2, 6, …+1)` |
| 0 % | `(3, 74, 7, 66, …+1)` |
| 0 % | `(2, 74, 25, 11, …+1)` |
| 100 % | `<other: 585328 distinct>` |

### `utils.safe_api.set_extmark` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `(3, 74, 2, 6, …+4)` |
| 0 % | `(3, 74, 7, 66, …+4)` |
| 0 % | `(2, 74, 25, 11, …+4)` |
| 100 % | `<other: 585328 distinct>` |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `config.get_keyword_languages` — argument profile

| Share | Argument |
| ---: | --- |
| 9 % | `("nvim")` |
| 3 % | `("lib")` |
| 3 % | `("lua")` |
| 77 % | `<other: 253165 distinct>` |

### `parser.tokenize_line` — argument profile

| Share | Argument |
| ---: | --- |
| 2 % | `("nvim/lua/autocmds")` |
| 1 % | `("lua/config/menu")` |
| 1 % | `("lua/wkdnvchad")` |
| 82 % | `<other: 88819 distinct>` |

### `config.is_function_detection_enabled` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `config.get_unique_language` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `("--")` |
| 0 % | `("lua")` |
| 0 % | `("_")` |
| 100 % | `<other: 23259 distinct>` |

### `cache_manager.cleanup` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `utils.safe_api.buf_line_count` — argument profile

| Share | Argument |
| ---: | --- |
| 32 % | `(2)` |
| 13 % | `(163)` |
| 11 % | `(6)` |
| 22 % | `<other: 60 distinct>` |

### `utils.safe_api.is_valid_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 32 % | `(2)` |
| 12 % | `(163)` |
| 11 % | `(6)` |
| 22 % | `<other: 73 distinct>` |

### `parser.find_inline_codes` — argument profile

| Share | Argument |
| ---: | --- |
| 32 % | `(2)` |
| 13 % | `(163)` |
| 11 % | `(6)` |
| 22 % | `<other: 60 distinct>` |

### `parser.scan_blocks_heuristic` — argument profile

| Share | Argument |
| ---: | --- |
| 33 % | `(2, <table:map>)` |
| 12 % | `(163, <table:map>)` |
| 11 % | `(6, <table:map>)` |
| 21 % | `<other: 60 distinct>` |

### `parser.is_ascii_fence` — argument profile

| Share | Argument |
| ---: | --- |
| 57 % | `("lua")` |
| 42 % | `("")` |
| 0 % | `("vim")` |

### `debounce_manager.debounce` — argument profile

| Share | Argument |
| ---: | --- |
| 33 % | `(2, <function>)` |
| 14 % | `(84, <function>)` |
| 12 % | `(163, <function>)` |

### `api.fences.list_blocks` — argument profile

| Share | Argument |
| ---: | --- |
| 28 % | `(2, <table:map>)` |
| 6 % | `(2)` |
| 6 % | `(4, <table:map>)` |
| 50 % | `<other: 156 distinct>` |

### `fence_hl.clear` — argument profile

| Share | Argument |
| ---: | --- |
| 32 % | `(2)` |
| 13 % | `(163)` |
| 11 % | `(6)` |
| 22 % | `<other: 64 distinct>` |

### `highlighter.clear_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 32 % | `(2)` |
| 13 % | `(163)` |
| 11 % | `(6)` |
| 22 % | `<other: 64 distinct>` |

### `cache_manager.get` — argument profile

| Share | Argument |
| ---: | --- |
| 32 % | `(2)` |
| 13 % | `(163)` |
| 11 % | `(6)` |
| 22 % | `<other: 60 distinct>` |

### `fence_hl.apply` — argument profile

| Share | Argument |
| ---: | --- |
| 32 % | `(2, <table:map>)` |
| 13 % | `(163, <table:map>)` |
| 11 % | `(6, <table:map>)` |
| 22 % | `<other: 60 distinct>` |

### `highlight_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 32 % | `(2)` |
| 13 % | `(163)` |
| 11 % | `(6)` |
| 22 % | `<other: 60 distinct>` |

### `highlighter.highlight_inline_codes` — argument profile

| Share | Argument |
| ---: | --- |
| 32 % | `(2)` |
| 13 % | `(163)` |
| 11 % | `(6)` |
| 22 % | `<other: 60 distinct>` |

### `parser.find_all_blocks` — argument profile

| Share | Argument |
| ---: | --- |
| 33 % | `(2, <table:map>)` |
| 12 % | `(163, <table:map>)` |
| 11 % | `(6, <table:map>)` |
| 21 % | `<other: 60 distinct>` |

### `cache_manager.set` — argument profile

| Share | Argument |
| ---: | --- |
| 10 % | `(2, <table:empty>, <table:#21>)` |
| 6 % | `(4, <table:empty>, <table:#21>)` |
| 6 % | `(5, <table:empty>, <table:empty>)` |
| 69 % | `<other: 152 distinct>` |

### `parser.find_ascii_blocks` — argument profile

| Share | Argument |
| ---: | --- |
| 32 % | `(2)` |
| 12 % | `(163)` |
| 11 % | `(6)` |
| 22 % | `<other: 60 distinct>` |

### `parser.find_ascii_blocks_heuristic` — argument profile

| Share | Argument |
| ---: | --- |
| 32 % | `(2)` |
| 12 % | `(163)` |
| 11 % | `(6)` |
| 22 % | `<other: 60 distinct>` |

### `highlighter.highlight_block` — argument profile

| Share | Argument |
| ---: | --- |
| 99 % | `(163, <table:map>)` |
| 0 % | `(29, <table:map>)` |
| 0 % | `(82, <table:map>)` |

> **99 % of calls share one argument — candidate for memoization (lib.lua.memo.memo / .lru)**

### `highlighter_ts.highlight_block` — argument profile

| Share | Argument |
| ---: | --- |
| 66 % | `(163, <table:map>, "lua", 36)` |
| 33 % | `(163, <table:map>, nil, 36)` |
| 0 % | `(29, <table:map>, "vim", 66)` |

### `language_detector.detect_language` — argument profile

| Share | Argument |
| ---: | --- |
| 66 % | `(163, <table:map>, "```lua")` |
| 33 % | `(163, <table:map>, "```")` |
| 0 % | `(29, <table:map>, "```vim")` |

### `commands.fence.register` — argument profile

| Share | Argument |
| ---: | --- |
| 14 % | `(3)` |
| 13 % | `(4)` |
| 8 % | `(5)` |
| 14 % | `<other: 45 distinct>` |

### `setup_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 14 % | `(3)` |
| 13 % | `(4)` |
| 8 % | `(5)` |
| 14 % | `<other: 45 distinct>` |

### `debounce_manager.cancel` — argument profile

| Share | Argument |
| ---: | --- |
| 12 % | `(138)` |
| 12 % | `(5)` |
| 6 % | `(2)` |

### `cache_manager.invalidate` — argument profile

| Share | Argument |
| ---: | --- |
| 14 % | `(138)` |
| 14 % | `(5)` |
| 5 % | `(134)` |

### `api.fences.block_at` — argument profile

| Share | Argument |
| ---: | --- |
| 22 % | `(36, 4, <table:map>)` |
| 11 % | `(1, 15, <table:map>)` |
| 11 % | `(105, 50, <table:map>)` |
