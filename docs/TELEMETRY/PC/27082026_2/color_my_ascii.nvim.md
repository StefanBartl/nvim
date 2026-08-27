# color_my_ascii.nvim — telemetry

**stopped** · counting + args + timing · 95 wrapped · 1 048 510 calls · 6 session(s)
Collecting since 2026-08-27 10:45.

| Function | Calls | Ø ms | Errors |
| --- | ---: | ---: | ---: |
| `config.get_char_highlight` | 547 608 | 0.00 | — |
| `config.get_keyword_languages` | 91 502 | 0.00 | — |
| `config.get` | 81 228 | 0.00 | — |
| `utils.safe_api.safe_call` | 75 409 | 0.00 | — |
| `utils.safe_api.buf_set_extmark` | 71 114 | 0.00 | — |
| `utils.safe_api.set_extmark` | 71 114 | 0.01 | — |
| `config.is_function_detection_enabled` | 40 365 | 0.00 | — |
| `parser.tokenize_line` | 40 365 | 0.00 | — |
| `utils.safe_api.buf_line_count` | 4 295 | 0.01 | — |
| `utils.safe_api.is_valid_buffer` | 2 799 | 0.00 | — |
| `parser.find_inline_codes` | 2 596 | 0.08 | — |
| `parser.scan_blocks_heuristic` | 2 531 | 0.06 | — |
| `debounce_manager.debounce` | 1 752 | 0.02 | — |
| `api.fences.list_blocks` | 1 490 | 0.06 | — |
| `fence_hl.clear` | 1 354 | 0.00 | — |
| `highlighter.clear_buffer` | 1 354 | 0.03 | — |
| `cache_manager.get` | 1 353 | 0.02 | — |
| `fence_hl.apply` | 1 353 | 0.07 | — |
| `highlight_buffer` | 1 353 | 1.91 | — |
| `highlighter.highlight_inline_codes` | 1 353 | 1.54 | — |
| `parser.find_all_blocks` | 1 288 | 0.06 | — |
| `cache_manager.set` | 1 243 | 0.01 | — |
| `parser.find_ascii_blocks` | 1 243 | 0.09 | — |
| `parser.find_ascii_blocks_heuristic` | 1 243 | 0.08 | — |
| `cache_manager.cleanup` | 1 108 | 0.01 | — |
| `api.fences.block_at` | 19 | 0.04 | — |
| `parser.is_ascii_fence` | 18 | 0.00 | — |
| `commands.fence.register` | 16 | 0.05 | — |
| `setup_buffer` | 16 | 11.93 | — |
| `highlighter.highlight_block` | 8 | 1.90 | — |
| `highlighter_ts.highlight_block` | 8 | 1.16 | — |
| `language_detector.detect_language` | 8 | 0.00 | — |
| `debounce_manager.cancel` | 3 | 0.00 | — |
| `cache_manager.invalidate` | 1 | 0.00 | — |

### `config.get_char_highlight` — argument profile

| Share | Argument |
| ---: | --- |
| 9 % | `("e")` |
| 5 % | `("i")` |
| 5 % | `("r")` |
| 23 % | `<other: 79112 distinct>` |

### `config.get_keyword_languages` — argument profile

| Share | Argument |
| ---: | --- |
| 6 % | `("M")` |
| 6 % | `("nvim")` |
| 4 % | `("md")` |
| 48 % | `<other: 36690 distinct>` |

### `config.get` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `utils.safe_api.safe_call` — argument profile

| Share | Argument |
| ---: | --- |
| 6 % | `(<function>, 20, 30, 27, …+2)` |
| 4 % | `(<function>, 20, 30, 96, …+2)` |
| 4 % | `(<function>, 2)` |
| 73 % | `<other: 14817 distinct>` |

### `utils.safe_api.buf_set_extmark` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `(2, 30, 21, 193, …+1)` |
| 0 % | `(2, 30, 21, 393, …+1)` |
| 0 % | `(2, 30, 21, 498, …+1)` |
| 94 % | `<other: 45250 distinct>` |

### `utils.safe_api.set_extmark` — argument profile

| Share | Argument |
| ---: | --- |
| 0 % | `(2, 30, 21, 193, …+4)` |
| 0 % | `(2, 30, 21, 393, …+4)` |
| 0 % | `(2, 30, 21, 498, …+4)` |
| 94 % | `<other: 45255 distinct>` |

### `config.is_function_detection_enabled` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `parser.tokenize_line` — argument profile

| Share | Argument |
| ---: | --- |
| 9 % | `("3 M-Right")` |
| 5 % | `("Merged_Finished.md")` |
| 3 % | `("cascade.nvim")` |
| 52 % | `<other: 14689 distinct>` |

### `utils.safe_api.buf_line_count` — argument profile

| Share | Argument |
| ---: | --- |
| 71 % | `(2)` |
| 18 % | `(20)` |
| 11 % | `(3)` |

### `utils.safe_api.is_valid_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 70 % | `(2)` |
| 18 % | `(20)` |
| 11 % | `(3)` |

### `parser.find_inline_codes` — argument profile

| Share | Argument |
| ---: | --- |
| 70 % | `(2)` |
| 18 % | `(20)` |
| 11 % | `(3)` |

### `parser.scan_blocks_heuristic` — argument profile

| Share | Argument |
| ---: | --- |
| 70 % | `(2, <table:map>)` |
| 18 % | `(20, <table:map>)` |
| 11 % | `(3, <table:map>)` |

### `debounce_manager.debounce` — argument profile

| Share | Argument |
| ---: | --- |
| 71 % | `(2, <function>)` |
| 17 % | `(20, <function>)` |
| 11 % | `(3, <function>)` |

### `api.fences.list_blocks` — argument profile

| Share | Argument |
| ---: | --- |
| 65 % | `(2, <table:map>)` |
| 16 % | `(20, <table:map>)` |
| 10 % | `(3, <table:map>)` |

### `fence_hl.clear` — argument profile

| Share | Argument |
| ---: | --- |
| 70 % | `(2)` |
| 18 % | `(20)` |
| 11 % | `(3)` |

### `highlighter.clear_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 70 % | `(2)` |
| 18 % | `(20)` |
| 11 % | `(3)` |

### `cache_manager.get` — argument profile

| Share | Argument |
| ---: | --- |
| 70 % | `(2)` |
| 18 % | `(20)` |
| 11 % | `(3)` |

### `fence_hl.apply` — argument profile

| Share | Argument |
| ---: | --- |
| 70 % | `(2, <table:map>)` |
| 18 % | `(20, <table:map>)` |
| 11 % | `(3, <table:map>)` |

### `highlight_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 70 % | `(2)` |
| 18 % | `(20)` |
| 11 % | `(3)` |

### `highlighter.highlight_inline_codes` — argument profile

| Share | Argument |
| ---: | --- |
| 70 % | `(2)` |
| 18 % | `(20)` |
| 11 % | `(3)` |

### `parser.find_all_blocks` — argument profile

| Share | Argument |
| ---: | --- |
| 71 % | `(2, <table:map>)` |
| 17 % | `(20, <table:map>)` |
| 11 % | `(3, <table:map>)` |

### `cache_manager.set` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `(2, <table:empty>, <table:#12>)` |
| 11 % | `(20, <table:empty>, <table:#51>)` |
| 10 % | `(2, <table:empty>, <table:#14>)` |

### `parser.find_ascii_blocks` — argument profile

| Share | Argument |
| ---: | --- |
| 70 % | `(2)` |
| 18 % | `(20)` |
| 12 % | `(3)` |

### `parser.find_ascii_blocks_heuristic` — argument profile

| Share | Argument |
| ---: | --- |
| 70 % | `(2)` |
| 18 % | `(20)` |
| 12 % | `(3)` |

### `cache_manager.cleanup` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `()` |

### `api.fences.block_at` — argument profile

| Share | Argument |
| ---: | --- |
| 11 % | `(2, 205, <table:map>)` |
| 11 % | `(2, 32, <table:map>)` |
| 11 % | `(2, 33, <table:map>)` |

### `parser.is_ascii_fence` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `("lua")` |

### `commands.fence.register` — argument profile

| Share | Argument |
| ---: | --- |
| 25 % | `(2)` |
| 25 % | `(20)` |
| 12 % | `(134)` |

### `setup_buffer` — argument profile

| Share | Argument |
| ---: | --- |
| 25 % | `(2)` |
| 25 % | `(20)` |
| 12 % | `(134)` |

### `highlighter.highlight_block` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `(134, <table:map>)` |
| 38 % | `(543, <table:map>)` |
| 12 % | `(4, <table:map>)` |

### `highlighter_ts.highlight_block` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `(134, <table:map>, "lua", 30)` |
| 38 % | `(543, <table:map>, "lua", 30)` |
| 12 % | `(4, <table:map>, "lua", 31)` |

### `language_detector.detect_language` — argument profile

| Share | Argument |
| ---: | --- |
| 50 % | `(134, <table:map>, "      ```lua")` |
| 38 % | `(543, <table:map>, "```lua")` |
| 12 % | `(4, <table:map>, "      ```lua")` |

### `debounce_manager.cancel` — argument profile

| Share | Argument |
| ---: | --- |
| 67 % | `(543)` |
| 33 % | `(55)` |

### `cache_manager.invalidate` — argument profile

| Share | Argument |
| ---: | --- |
| 100 % | `(543)` |
