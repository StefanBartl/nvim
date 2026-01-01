# debugging.nvim_options

Helpers for inspecting and toggling Neovim options, with focus on indentation and syntax providers.

## Table of content

  - [Features](#features)
  - [Quick Start](#quick-start)
  - [API](#api)
    - [`print_indent_options(bufnr)`](#print_indent_optionsbufnr)
    - [`prefer_treesitter_indent(enable)`](#prefer_treesitter_indentenable)
  - [Use Cases](#use-cases)
    - [1. Debug Indentation Issues](#1-debug-indentation-issues)
    - [2. Switch to Tree-sitter Indent](#2-switch-to-tree-sitter-indent)
    - [3. Compare Providers](#3-compare-providers)
    - [4. Per-Filetype Configuration](#4-per-filetype-configuration)
  - [Indentation Providers](#indentation-providers)
    - [Tree-sitter (Recommended)](#tree-sitter-recommended)
    - [cindent](#cindent)
    - [smartindent](#smartindent)
    - [autoindent](#autoindent)
  - [Troubleshooting](#troubleshooting)
    - [Tree-sitter indent not working](#tree-sitter-indent-not-working)
    - [Conflicting indent providers](#conflicting-indent-providers)
    - [indentexpr not set](#indentexpr-not-set)
  - [Configuration Recommendations](#configuration-recommendations)
    - [Global Setup](#global-setup)
    - [Per-Language](#per-language)
  - [See Also](#see-also)

---

## Features

- ✅ **Option inspection** - Print all indentation-related options
- ✅ **Provider toggling** - Switch between indent providers
- ✅ **Buffer-local** - Works on specific buffers
- ✅ **Tree-sitter support** - Prefer tree-sitter indent
- ✅ **Diagnostic output** - Formatted for easy reading

---

## Quick Start

```lua
-- Available immediately after require
local helpers = require("debugging.nvim_options.indent_helpers")

-- Print current indent options
helpers.print_indent_options()

-- Prefer tree-sitter indent
helpers.prefer_treesitter_indent(true)
```

---

## API

### `print_indent_options(bufnr)`

Print current indentation-related buffer options.

**Parameters:**
- `bufnr` (integer|nil): Buffer number (default: current buffer)

**Prints:**
- `autoindent` - Copy indent from current line
- `smartindent` - Smart auto-indenting for C-like code
- `cindent` - C-style indenting
- `indentexpr` - Expression for indent calculation
- `indentkeys` - Keys that trigger indent recalculation
- `shiftwidth` - Number of spaces for each indent step
- `tabstop` - Number of spaces a <Tab> counts for

**Example:**
```vim
:lua require("debugging.nvim_options.indent_helpers").print_indent_options()

" Output:
{
  autoindent = true,
  cindent = false,
  indentexpr = "v:lua.require'nvim-treesitter.indent'.get_indent()",
  indentkeys = "0{,0},0),0],:,0#,!^F,o,O,e",
  shiftwidth = 2,
  smartindent = false,
  tabstop = 2
}
```

**For Specific Buffer:**
```lua
local helpers = require("debugging.nvim_options.indent_helpers")
helpers.print_indent_options(5)  -- Buffer 5
```

---

### `prefer_treesitter_indent(enable)`

Toggle tree-sitter indent by disabling cindent/smartindent.

**Parameters:**
- `enable` (boolean|nil): Enable tree-sitter preference (default: true)

**Behavior:**
- When `enable = true`: Disables `cindent` and `smartindent`
- When `enable = false`: Restores defaults (both off)

**Why This Works:**

Neovim's indent priority:
1. `indentexpr` (highest - tree-sitter uses this)
2. `cindent`
3. `smartindent`
4. `autoindent` (lowest)

Disabling cindent/smartindent lets tree-sitter's `indentexpr` take effect.

**Example:**
```vim
" Enable tree-sitter indent
:lua require("debugging.nvim_options.indent_helpers").prefer_treesitter_indent(true)
" treesitter-prefer mode for lua set to true

" Check result
:lua require("debugging.nvim_options.indent_helpers").print_indent_options()
" {
"   cindent = false,
"   smartindent = false,
"   indentexpr = "v:lua.require'nvim-treesitter.indent'.get_indent()",
"   ...
" }
```

---

## Use Cases

### 1. Debug Indentation Issues

When indentation doesn't work as expected:

```vim
:lua require("debugging.nvim_options.indent_helpers").print_indent_options()

" Check which provider is active:
" - indentexpr set? → Tree-sitter or custom
" - cindent true? → C-style
" - smartindent true? → Smart auto-indent
```

### 2. Switch to Tree-sitter Indent

Force tree-sitter indentation:

```vim
:lua require("debugging.nvim_options.indent_helpers").prefer_treesitter_indent()
```

### 3. Compare Providers

Test different indent providers:

```lua
local helpers = require("debugging.nvim_options.indent_helpers")

-- Test tree-sitter
helpers.prefer_treesitter_indent(true)
-- Try indenting code

-- Test cindent
vim.bo.cindent = true
-- Try indenting code

-- Test smartindent
vim.bo.smartindent = true
-- Try indenting code
```

### 4. Per-Filetype Configuration

In `ftplugin/lua.lua`:

```lua
local helpers = require("debugging.nvim_options.indent_helpers")
helpers.prefer_treesitter_indent(true)
```

---

## Indentation Providers

### Tree-sitter (Recommended)

**Pros:**
- Syntax-aware
- Language-specific
- Most accurate

**Setup:**
```lua
-- In config
require("nvim-treesitter.configs").setup({
  indent = { enable = true },
})

-- Force prefer
require("debugging.nvim_options.indent_helpers").prefer_treesitter_indent()
```

**Check:**
```vim
:lua print(vim.bo.indentexpr)
" v:lua.require'nvim-treesitter.indent'.get_indent()
```

---

### cindent

**Pros:**
- Fast
- Built-in
- Good for C-like languages

**Cons:**
- Not syntax-aware
- Limited language support

**Enable:**
```vim
:set cindent
```

---

### smartindent

**Pros:**
- Simple
- Fast
- Works for many languages

**Cons:**
- Basic heuristics
- No syntax awareness

**Enable:**
```vim
:set smartindent
```

---

### autoindent

**Pros:**
- Universal
- Always available
- No language knowledge needed

**Cons:**
- Just copies previous line indent
- No smart adjustments

**Enable:**
```vim
:set autoindent
```

---

## Troubleshooting

### Tree-sitter indent not working

**Symptom:** Code not indenting correctly despite tree-sitter enabled

**Diagnosis:**
```lua
local helpers = require("debugging.nvim_options.indent_helpers")
helpers.print_indent_options()

-- Check:
-- 1. indentexpr should contain "treesitter"
-- 2. cindent and smartindent should be false
```

**Solution:**
```lua
helpers.prefer_treesitter_indent(true)
```

---

### Conflicting indent providers

**Symptom:** Indentation inconsistent or wrong

**Cause:** Multiple providers active (cindent + smartindent)

**Solution:**
```lua
-- Disable all except tree-sitter
vim.bo.cindent = false
vim.bo.smartindent = false
-- Tree-sitter indentexpr remains
```

---

### indentexpr not set

**Symptom:** `indentexpr` is empty

**Cause:** Tree-sitter indent module not enabled

**Solution:**
```lua
require("nvim-treesitter.configs").setup({
  indent = { enable = true },
})
```

---

## Configuration Recommendations

### Global Setup

In `init.lua`:

```lua
-- Prefer tree-sitter for all buffers
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    if vim.treesitter.language.get_lang(vim.bo.filetype) then
      require("debugging.nvim_options.indent_helpers").prefer_treesitter_indent()
    end
  end,
})
```

### Per-Language

In `ftplugin/python.lua`:

```lua
-- Python-specific: use tree-sitter
require("debugging.nvim_options.indent_helpers").prefer_treesitter_indent()
vim.bo.shiftwidth = 4
vim.bo.tabstop = 4
```

---

## See Also

- [Main README](../README.md)
- `:h debugging-nvim-options`
- `:h 'indentexpr'`
- `:h 'cindent'`
- `:h 'smartindent'`
- [nvim-treesitter indent](https://github.com/nvim-treesitter/nvim-treesitter#indentation)

---
