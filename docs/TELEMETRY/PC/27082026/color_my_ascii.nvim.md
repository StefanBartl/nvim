# color_my_ascii.nvim — telemetry

**stopped** · counting + args + timing · 95 wrapped · 9 276 186 calls · 22 session(s)
Collecting since 2026-08-19 17:24.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `config.get_char_highlight` | 4 267 912 | 0.00 | — |
| `utils.safe_api.safe_call` | 879 441 | 0.00 | — |
| `config.get` | 868 734 | 0.00 | — |
| `utils.safe_api.buf_set_extmark` | 842 694 | 0.01 | — |
| `utils.safe_api.set_extmark` | 842 694 | 0.01 | — |
| `config.get_keyword_languages` | 700 541 | 0.00 | — |
| `parser.tokenize_line` | 276 868 | 0.00 | — |
| `config.is_function_detection_enabled` | 271 929 | 0.00 | — |
| `utils.safe_api.buf_line_count` | 36 747 | 0.01 | — |
| `config.get_unique_language` | 33 848 | — | — |
| `utils.safe_api.is_valid_buffer` | 23 543 | 0.00 | — |
| `parser.find_inline_codes` | 21 975 | 0.09 | — |
| `parser.scan_blocks_heuristic` | 21 420 | 0.08 | — |
| `cache_manager.cleanup` | 20 030 | 0.01 | — |
| `debounce_manager.debounce` | 15 081 | 0.02 | — |
| `parser.is_ascii_fence` | 14 911 | 0.00 | — |
| `api.fences.list_blocks` | 12 285 | 0.05 | — |
| `fence_hl.clear` | 11 489 | 0.01 | — |
| `highlighter.clear_buffer` | 11 489 | 0.02 | — |
| `cache_manager.get` | 11 457 | 0.01 | — |
| `fence_hl.apply` | 11 457 | 0.04 | — |
| `highlight_buffer` | 11 457 | 1.61 | — |
| `highlighter.highlight_inline_codes` | 11 457 | 1.23 | — |
| `parser.find_all_blocks` | 10 902 | 0.07 | — |
| `cache_manager.set` | 10 518 | 0.02 | — |
| `parser.find_ascii_blocks` | 10 518 | 0.15 | — |
| `parser.find_ascii_blocks_heuristic` | 10 518 | 0.14 | — |
| `highlighter.highlight_block` | 4 662 | — | — |
| `highlighter_ts.highlight_block` | 4 662 | — | — |
| `language_detector.detect_language` | 4 662 | — | — |
| `debounce_manager.cancel` | 75 | — | — |
| `commands.fence.register` | 73 | — | — |
| `setup_buffer` | 73 | — | — |
| `api.fences.block_at` | 32 | 0.02 | — |
| `cache_manager.invalidate` | 32 | — | — |

### `config.get_char_highlight` — argument profile

| Share | Argument |
| ---: | --- |
| 8 % | `("e")` |
| 7 % | `(" ")` |
| 5 % | `("i")` |
| 24 % | `<other: 692001 distinct>` |

### `utils.safe_api.safe_call` — argument profile

| Share | Argument |
| ---: | --- |
| 3 % | `(<function>, 2)` |
| 0 % | `(<function>, 2, 39, 112, …+2)` |
| 0 % | `(<function>, 2, 39, 114, …+2)` |
| 97 % | `<other: 234203 distinct>` |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `utils.safe_api.buf_set_extmark` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `(2, 39, 42, 55, …+1)` |
| 0 % | `(2, 39, 47, 12, …+1)` |
| 0 % | `(2, 39, 47, 16, …+1)` |
| 100 % | `<other: 649950 distinct>` |

### `utils.safe_api.set_extmark` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `(2, 39, 42, 55, …+4)` |
| 0 % | `(2, 39, 47, 12, …+4)` |
| 0 % | `(2, 39, 47, 16, …+4)` |
| 100 % | `<other: 649950 distinct>` |

### `config.get_keyword_languages` — argument profile

| Share | Argument |
| ---: | --- |
| 6 % | `("lua")` |
| 6 % | `("nvim")` |
| 2 % | `("lib")` |
| 76 % | `<other: 327583 distinct>` |

### `parser.tokenize_line` — argument profile

| Share | Argument |
| ---: | --- |
| 2 % | `("nvim/lua/autocmds")` |
| 2 % | `("lua/config/menu")` |
| 2 % | `("lua/wkdnvchad")` |
| 79 % | `<other: 87751 distinct>` |

### `config.is_function_detection_enabled` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `utils.safe_api.buf_line_count` — argument profile

| Share | Argument |
| ---: | --- |
| 61 % | `(2)` |
| 17 % | `(54)` |
| 5 % | `(1)` |
| 8 % | `<other: 63 distinct>` |

### `config.get_unique_language` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `("MB")` |
| 0 % | `("Fonts")` |
| 0 % | `("in")` |
| 98 % | `<other: 14647 distinct>` |

### `utils.safe_api.is_valid_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 60 % | `(2)` |
| 16 % | `(54)` |
| 4 % | `(1)` |
| 8 % | `<other: 73 distinct>` |

### `parser.find_inline_codes` — argument profile

| Share | Argument |
| ---: | --- |
| 61 % | `(2)` |
| 16 % | `(54)` |
| 4 % | `(1)` |
| 8 % | `<other: 63 distinct>` |

### `parser.scan_blocks_heuristic` — argument profile

| Share | Argument |
| ---: | --- |
| 60 % | `(2, <table:map>)` |
| 17 % | `(54, <table:map>)` |
| 4 % | `(1, <table:map>)` |
| 8 % | `<other: 63 distinct>` |

### `cache_manager.cleanup` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `debounce_manager.debounce` — argument profile

| Share | Argument |
| ---: | --- |
| 61 % | `(2, <function>)` |
| 17 % | `(54, <function>)` |
| 5 % | `(20, <function>)` |

### `parser.is_ascii_fence` — argument profile

| Share | Argument |
| ---: | --- |
| 46 % | `("")` |
| 32 % | `("lua")` |
| 6 % | `("text")` |

### `api.fences.list_blocks` — argument profile

| Share | Argument |
| ---: | --- |
| 57 % | `(2, <table:map>)` |
| 3 % | `(2)` |
| 1 % | `(33, <table:map>)` |
| 37 % | `<other: 202 distinct>` |

### `fence_hl.clear` — argument profile

| Share | Argument |
| ---: | --- |
| 60 % | `(2)` |
| 16 % | `(54)` |
| 4 % | `(1)` |
| 8 % | `<other: 67 distinct>` |

### `highlighter.clear_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 60 % | `(2)` |
| 16 % | `(54)` |
| 4 % | `(1)` |
| 8 % | `<other: 67 distinct>` |

### `cache_manager.get` — argument profile

| Share | Argument |
| ---: | --- |
| 61 % | `(2)` |
| 16 % | `(54)` |
| 4 % | `(1)` |
| 8 % | `<other: 63 distinct>` |

### `fence_hl.apply` — argument profile

| Share | Argument |
| ---: | --- |
| 61 % | `(2, <table:map>)` |
| 16 % | `(54, <table:map>)` |
| 4 % | `(1, <table:map>)` |
| 8 % | `<other: 63 distinct>` |

### `highlight_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 61 % | `(2)` |
| 16 % | `(54)` |
| 4 % | `(1)` |
| 8 % | `<other: 63 distinct>` |

### `highlighter.highlight_inline_codes` — argument profile

| Share | Argument |
| ---: | --- |
| 61 % | `(2)` |
| 16 % | `(54)` |
| 4 % | `(1)` |
| 8 % | `<other: 63 distinct>` |

### `parser.find_all_blocks` — argument profile

| Share | Argument |
| ---: | --- |
| 60 % | `(2, <table:map>)` |
| 17 % | `(54, <table:map>)` |
| 4 % | `(1, <table:map>)` |
| 8 % | `<other: 63 distinct>` |

### `cache_manager.set` — argument profile

| Share | Argument |
| ---: | --- |
| 17 % | `(2, <table:empty>, <table:#19>)` |
| 3 % | `(2, <table:empty>, <table:#20>)` |
| 1 % | `(33, <table:#8>, <table:#15>)` |
| 78 % | `<other: 235 distinct>` |

### `parser.find_ascii_blocks` — argument profile

| Share | Argument |
| ---: | --- |
| 60 % | `(2)` |
| 16 % | `(54)` |
| 4 % | `(1)` |
| 8 % | `<other: 63 distinct>` |

### `parser.find_ascii_blocks_heuristic` — argument profile

| Share | Argument |
| ---: | --- |
| 60 % | `(2)` |
| 16 % | `(54)` |
| 4 % | `(1)` |
| 8 % | `<other: 63 distinct>` |

### `highlighter.highlight_block` — argument profile

| Share | Argument |
| ---: | --- |
| 35 % | `(354, <table:map>)` |
| 19 % | `(33, <table:map>)` |
| 19 % | `(54, <table:map>)` |

### `highlighter_ts.highlight_block` — argument profile

| Share | Argument |
| ---: | --- |
| 19 % | `(54, <table:map>, "lua", 30)` |
| 13 % | `(20, <table:map>, "lua", 30)` |
| 7 % | `(33, <table:map>, nil, 39)` |
| 36 % | `<other: 49 distinct>` |

### `language_detector.detect_language` — argument profile

| Share | Argument |
| ---: | --- |
| 19 % | `(54, <table:map>, "    ```lua")` |
| 13 % | `(20, <table:map>, "    ```lua")` |
| 7 % | `(33, <table:map>, "```")` |
| 36 % | `<other: 51 distinct>` |

### `debounce_manager.cancel` — argument profile

| Share | Argument |
| ---: | --- |
| 11 % | `(129)` |
| 5 % | `(29)` |
| 5 % | `(5)` |
| 5 % | `<other: 34 distinct>` |

### `commands.fence.register` — argument profile

| Share | Argument |
| ---: | --- |
| 5 % | `(129)` |
| 5 % | `(3)` |
| 5 % | `(4)` |
| 23 % | `<other: 49 distinct>` |

### `setup_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 5 % | `(129)` |
| 5 % | `(3)` |
| 5 % | `(4)` |
| 23 % | `<other: 49 distinct>` |

### `api.fences.block_at` — argument profile

| Share | Argument |
| ---: | --- |
| 12 % | `(2, 22, <table:map>)` |
| 9 % | `(169, 0, <table:map>)` |
| 9 % | `(2, 1, <table:map>)` |

### `cache_manager.invalidate` — argument profile

| Share | Argument |
| ---: | --- |
| 12 % | `(129)` |
| 6 % | `(5)` |
| 6 % | `(57)` |
