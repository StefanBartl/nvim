# wkdoptions Cheat Sheet

Quick reference for common operations.

## Table of content

- [wkdoptions Cheat Sheet](#wkdoptions-cheat-sheet)
  - [Installation](#installation)
  - [Quick Commands](#quick-commands)
  - [Lua API](#lua-api)
  - [Common Configurations](#common-configurations)
    - [Minimal Setup](#minimal-setup)
    - [Full Featured](#full-featured)
    - [Performance Tuned](#performance-tuned)
  - [Feature Toggles](#feature-toggles)
  - [Color Customization](#color-customization)
  - [Breadcrumbs Configuration](#breadcrumbs-configuration)
  - [Skip Rules](#skip-rules)
  - [Cword Occurrences](#cword-occurrences)
  - [Troubleshooting](#troubleshooting)
  - [Performance Tuning](#performance-tuning)
  - [Keymaps](#keymaps)
  - [Integration Examples](#integration-examples)
    - [With lualine](#with-lualine)
    - [With nvim-cmp](#with-nvim-cmp)
    - [With telescope](#with-telescope)
  - [Quick Fixes](#quick-fixes)
    - [CursorLine not visible](#cursorline-not-visible)
    - [Breadcrumbs empty](#breadcrumbs-empty)
    - [Performance issues](#performance-issues)
  - [Resources](#resources)

---

## Quick Commands

```vim
" Toggle features
:WKDHighlightSet! enable_line
:WKDHighlightSet! enable_breadcrumbs
:WKDOptSet! enable_matchparen

" Set values
:WKDHighlightSet enable_line true
:WKDHighlightSet breadcrumbs_separator " → "
:WKDHighlightSet colors.CursorLine.bg #2a2e36

" Show config
:WKDHighlightShow enable_line
:WKDHighlightList

" Diff profiles
:WKDDiffProfile minimal
:WKDDiffProfile review

" Debug
:WKDHighlightDebugCtx
```

## Lua API

```lua
local W = require("wkdoptions")

-- Get config
local cfg = W.get_cfg()
local hl_cfg = cfg.highlight
local opt_cfg = cfg.options

-- Parse value
local val = W.parse("true")  -- boolean

-- Set with validation
local ok, err = W.set("highlight", "enable_line", true, false)

-- Get value
local enabled = W.get("highlight", "enable_line")

-- List keys
local keys = W.keys("highlight")

-- Register callback
W.on_after_set("highlight", function(key)
  print("Changed:", key)
end)
```

## Common Configurations

### Minimal Setup

```lua
local cfg = require("wkdoptions").get_cfg().highlight

-- Essential only
cfg.enable_line = true
cfg.enable_yank_flash = true
cfg.enable_signcolumn_tint = true

-- Disable heavy features
cfg.enable_indent_scope = false
cfg.enable_breadcrumbs = false
cfg.cword_occurrences.enabled = false
```

### Full Featured

```lua
local cfg = require("wkdoptions").get_cfg().highlight

-- Enable all
cfg.enable_line = true
cfg.enable_column = true
cfg.enable_insert_submode_colors = true
cfg.enable_yank_flash = true
cfg.enable_put_flash = true
cfg.enable_signcolumn_tint = true
cfg.enable_terminal_palette = true
cfg.enable_current_word = true
cfg.enable_indent_scope = true
cfg.enable_breadcrumbs = true
cfg.enable_diff_peek = true
cfg.cword_occurrences.enabled = true
```

### Performance Tuned

```lua
local cfg = require("wkdoptions").get_cfg().highlight

-- Lower thresholds
cfg.large_file_kb = 2000
cfg.min_colored_file_kb = 1024

-- Increase debounce
cfg.cword_occurrences.debounce_ms = 100

-- Viewport only
cfg.cword_occurrences.viewport_only = true
```

## Feature Toggles

| Feature | Config Key | Default |
|---------|-----------|---------|
| CursorLine | `enable_line` | `true` |
| CursorColumn | `enable_column` | `true` |
| Mode Tinting | `enable_insert_submode_colors` | `true` |
| Yank Flash | `enable_yank_flash` | `true` |
| Put Flash | `enable_put_flash` | `true` |
| SignColumn Tint | `enable_signcolumn_tint` | `true` |
| Terminal Palette | `enable_terminal_palette` | `true` |
| Current Word | `enable_current_word` | `true` |
| Indent Scope | `enable_indent_scope` | `false` |
| Breadcrumbs | `enable_breadcrumbs` | `false` |
| Diff Peek | `enable_diff_peek` | `true` |
| Cword Occurrences | `cword_occurrences.enabled` | `true` |

## Color Customization

```lua
local cfg = require("wkdoptions").get_cfg().highlight

-- CursorLine
cfg.colors.CursorLine = { bg = "#2a2e36" }
cfg.colors.CursorLineNr = { fg = "#ffd75f", bold = true }

-- Mode-specific
cfg.colors.CursorLineN = { bg = "#2a2e36" }  -- Normal
cfg.colors.CursorLineI = { bg = "#24313a" }  -- Insert
cfg.colors.CursorLineV = { bg = "#322b3a" }  -- Visual
cfg.colors.CursorLineR = { bg = "#3a2323" }  -- Replace

-- Flash
cfg.colors.YankFlash = { bg = "#3e5f2a" }
cfg.colors.PutFlash = { bg = "#2a4d6b" }

-- SignColumn
cfg.colors.SignColError = { bg = "#3a2323" }
cfg.colors.SignColWarn = { bg = "#3a3623" }
cfg.colors.SignColInfo = { bg = "#22333e" }
cfg.colors.SignColHint = { bg = "#1f2f2a" }

-- Terminal
cfg.colors.TermNormal = { bg = "#151a1f" }
cfg.colors.TermCursorLine = { bg = "#20262d" }

-- Misc
cfg.colors.CursorWord = { underline = true }
cfg.colors.IndentScope = { bg = "#2f3440" }
```

## Breadcrumbs Configuration

```lua
local cfg = require("wkdoptions").get_cfg().highlight

cfg.enable_breadcrumbs = true
cfg.breadcrumbs_max_len = 120
cfg.breadcrumbs_separator = " › "

cfg.breadcrumbs_ctx = {
  -- Providers
  prefer_lsp_function = true,
  use_treesitter_symbol = true,
  use_container_chain = true,
  use_lang_specific = true,

  -- Fallbacks
  fallback_object_when_empty = true,
  fallback_word_when_empty = true,

  -- Container
  container_join = ".",
  container_max_depth = 2,

  -- Order
  providers_order = {
    "lsp_func",
    "ts_symbol",
    "container",
    "lang_extra",
    "word",
  },
}
```

## Skip Rules

```lua
local cfg = require("wkdoptions").get_cfg().highlight

cfg.winbar_skip = {
  only_normal_buffers = true,
  skip_floating = true,
  min_height = 2,
  buftypes = { "nofile", "prompt", "terminal" },
  filetypes = { "neo-tree", "oil", "lazy" },
  name_patterns = { "^oil://", "^term://" },
}

cfg.indent_scope_skip = {
  only_normal_buffers = true,
  skip_floating = true,
  buftypes = { "nofile", "prompt" },
  filetypes = { "neo-tree", "oil" },
}
```

## Cword Occurrences

```lua
local cfg = require("wkdoptions").get_cfg().highlight

cfg.cword_occurrences = {
  enabled = true,

  -- Rendering
  render = "underdashed",  -- or "highlight"/"underline"/etc
  marking = "word",        -- or "leadingchar"/"tailchar"/"firstN"
  firstN = 2,              -- if marking = "firstN"

  -- Performance
  viewport_only = true,
  debounce_ms = 40,
  large_file_kb = nil,     -- nil = use global threshold

  -- Matching
  min_len = 2,
  case_mode = "sensitive", -- or "smart"/"insensitive"
  match_kind = "exact",    -- or "substring"

  -- Behavior
  in_insert = false,

  -- Colors
  hl = "CwordOccur",
  hl_attr = { bg = "#334155" },
}
```

## Troubleshooting

```lua
-- Check feature state
:lua print(require("wkdoptions.hl_config.core.state").is_enabled("breadcrumbs"))

-- Check if buffer is UI-like
:lua print(require("wkdoptions.hl_config.utils.skip").std_skip(0))

-- Check file size
:lua print(require("wkdoptions.hl_config.utils.large_file").is_large(0, require("wkdoptions").get_cfg().highlight))

-- Debug breadcrumbs
:WKDHighlightDebugCtx

-- Check observer count
:lua print(require("wkdoptions.config").observer_count("highlight"))
```

## Performance Tuning

```lua
-- Low-end hardware
local cfg = require("wkdoptions").get_cfg().highlight
cfg.large_file_kb = 1000
cfg.enable_indent_scope = false
cfg.enable_breadcrumbs = false
cfg.cword_occurrences.debounce_ms = 100

-- High-end hardware
cfg.large_file_kb = 10000
cfg.enable_indent_scope = true
cfg.enable_breadcrumbs = true
cfg.cword_occurrences.debounce_ms = 20
```

## Keymaps

```lua
-- Default keymaps (installed when features enabled)
vim.keymap.set("n", "gh", "<cmd>Gitsigns preview_hunk<cr>", { desc = "Preview git hunk" })
vim.keymap.set("n", "p", paste_and_flash("p"), { desc = "Paste (flash)" })
vim.keymap.set("n", "P", paste_and_flash("P"), { desc = "Paste before (flash)" })
```

## Integration Examples

### With lualine

```lua
require("lualine").setup({
  sections = {
    lualine_c = {
      function()
        return require("wkdoptions.hl_config.breadcrumbs.ctx").statusline_module()()
      end,
    },
  },
})
```

### With nvim-cmp

```lua
local cmp = require("cmp")
cmp.setup({
  window = {
    completion = {
      winhighlight = "Normal:CmpPmenu,CursorLine:CmpSel",
    },
  },
})
```

### With telescope

```lua
require("telescope").setup({
  defaults = {
    layout_config = {
      preview_cutoff = 120,
    },
  },
})
```

## Quick Fixes

### CursorLine not visible

```vim
:WKDHighlightSet colors.CursorLine.bg #2a2e36
:WKDHighlightSet! enable_line
```

### Breadcrumbs empty

```vim
:WKDHighlightSet breadcrumbs_ctx.fallback_word_when_empty true
:WKDHighlightDebugCtx
```

### Performance issues

```vim
:WKDHighlightSet large_file_kb 1000
:WKDHighlightSet! enable_indent_scope
```

## Resources

- [README.md](../README.md) - Full documentation
- [PERFORMANCE.md](./PERFORMANCE.md) - Performance guide
- [doc/wkdoptions.txt](../doc/wkdoptions.txt) - Vim help
- [Arch&Coding-Regeln.md](../Arch&Coding-Regeln.md) - Development guide
