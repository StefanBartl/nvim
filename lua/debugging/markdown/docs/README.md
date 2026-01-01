# debugging.markdown

Tools for debugging Markdown syntax highlighting issues, with focus on inline code and fenced blocks.

## Features

- ✅ **Comprehensive diagnostics** - Environment, buffer, highlights, tree-sitter, LSP
- ✅ **Timestamped logs** - All reports saved with timestamps
- ✅ **Safe API calls** - All operations wrapped in pcall
- ✅ **Automatic execution** - Runs on module load
- ✅ **User command** - `:MarkdownInlineDebugFixed`

---

## Quick Start

```lua
require("debugging.markdown").attach({ inline_debug_fixed = true })
```

```vim
:MarkdownInlineDebugFixed
```

**Output Location:**
- `stdpath("data")/debuglog/markdown_inline/debuglog_TIMESTAMP.log`

---

## Problem Context

### The Issue

Markdown inline code (`` `code` ``) sometimes renders without proper highlighting:

```markdown
This `inline code` should be highlighted.
```

**Expected:** `inline code` has different background/foreground
**Actual:** Renders as plain text

### Causes

1. **Conflicting providers** - Tree-sitter vs Vim syntax
2. **Highlight group conflicts** - `markdownCode` vs `@markup.raw.inline`
3. **Colorscheme issues** - Missing highlight definitions
4. **Tree-sitter not loaded** - Parser not attached
5. **LSP interference** - Semantic tokens override

---

## Commands

### `:MarkdownInlineDebugFixed`

Gathers diagnostic information and writes to timestamped log file.

**Information Collected:**
- Neovim version
- Colorscheme name
- Terminal colors (termguicolors)
- Buffer filetype, syntax, buftype
- Sample buffer content (first 50 lines)
- Highlight groups (markdownCode, @markup.raw.inline, etc.)
- Tree-sitter parser status
- LSP client information
- Autocommands for "MarkdownFencedFix" group
- Loaded Markdown-related modules

**Usage:**
```vim
:MarkdownInlineDebugFixed
```

**Output:**
```
[INFO] markdown.inline_debug: wrote debug log to /path/to/debuglog_20240115-143052.log
buf=5 | filetype=markdown | colorscheme=gruvbox | termguicolors=true | syntax_on=true
```

---

## Log File Format

### Header
```
Markdown Inline Highlight Debug - 20240115-143052
=== ENVIRONMENT ===
{
  background = "dark",
  colorscheme = "gruvbox",
  neovim_version = { major = 0, minor = 10, patch = 0 },
  runtimepath = "...",
  termguicolors = true
}
```

### Buffer Info
```
=== BUFFER ===
{
  bufnr = 5,
  buftype = "",
  filetype = "markdown",
  line_count = 100,
  modified = false,
  name = "/path/to/file.md",
  readonly = false,
  syntax = "markdown"
}
```

### Highlights
```
=== HIGHLIGHTS (selected) ===
markdownCode => {
  bg = "#3c3836",
  fg = "#83a598"
}
@markup.raw.inline.markdown_inline => {
  link = "markdownCode"
}
```

### Tree-sitter
```
=== TREESITTER ===
{
  filetype = "markdown",
  has_parser = true,
  parser_attached = true,
  parsers_available = true
}
```

### LSP
```
=== LSP ===
{
  clients = {
    {
      id = 1,
      name = "marksman",
      attached_buffers = { 5 },
      workspace_folders = "..."
    }
  }
}
```

---

## Use Cases

### 1. Diagnose Highlight Issues

When inline code doesn't highlight:

```vim
:MarkdownInlineDebugFixed

" Check log for:
" - highlight definitions (markdownCode, @markup.raw.inline)
" - tree-sitter status (parser_attached = true?)
" - conflicting autocommands
```

### 2. Compare Colorschemes

Test different colorschemes:

```vim
:colorscheme gruvbox
:MarkdownInlineDebugFixed

:colorscheme catppuccin
:MarkdownInlineDebugFixed

" Compare logs to see highlight differences
```

### 3. Debug Tree-sitter Issues

Check if tree-sitter is working:

```vim
:MarkdownInlineDebugFixed

" Look for in log:
" has_parser = true
" parser_attached = true
```

### 4. LSP Conflict Detection

Find if LSP semantic tokens interfere:

```vim
:MarkdownInlineDebugFixed

" Check LSP section for:
" - client name (marksman, etc.)
" - server_capabilities.semanticTokensProvider
```

---

## API

### Module State

```lua
local M = require("debugging.markdown.inline_debug")

-- Check output path
print(M.out_path)  -- Path to last generated log

-- Check timestamp
print(M.timestamp)  -- "20240115-143052"

-- Check buffer number
print(M.bufnr)  -- Buffer that was analyzed

-- Check results
print(vim.inspect(M.results))  -- Full diagnostic data
```

### `M.gather()`

Collects diagnostic information and writes log.

**Returns:** `boolean ok, string|nil error_or_path`

**Example:**
```lua
local M = require("debugging.markdown.inline_debug")
local ok, path = M.gather()
if ok then
  print("Log written to: " .. path)
else
  print("Error: " .. path)
end
```

### `M.open_log()`

Opens generated log file in new tab.

**Returns:** `boolean ok, string|nil error_or_path`

**Example:**
```lua
local M = require("debugging.markdown.inline_debug")
M.gather()
M.open_log()  -- Opens log in new tab
```

---

## Architecture

### Data Collection Flow

```
User triggers :MarkdownInlineDebugFixed
    ↓
gather() collects:
    • Environment (Neovim version, colorscheme)
    • Buffer info (filetype, syntax)
    • Highlights (via nvim_get_hl)
    • Tree-sitter status
    • LSP clients
    • Autocommands
    • Loaded modules
    ↓
Serialize to log file
    ↓
Notify user of path
```

### Highlight Collection

Uses modern `nvim_get_hl()` API (Neovim 0.9+):

```lua
local function get_highlight(name)
  return vim.api.nvim_get_hl(0, { name = name, link = true })
end
```

**Groups Checked:**
- `markdownCode`
- `markdownCodeDelimiter`
- `MarkdownInlineCode`
- `@markup.raw.inline`
- `@markup.raw.block`
- `@markup.raw.inline.markdown_inline`
- `@text.literal.markdown_inline`
- `@punctuation.delimiter.markdown`
- `Comment`, `String`, `Normal`

---

## Troubleshooting

### Log file not created

**Symptom:** "failed to write log file" error

**Cause:** Permission issues or invalid path

**Solution:**
```lua
-- Check debuglog directory
local dir = vim.fn.stdpath("data") .. "/debuglog/markdown_inline"
print(vim.fn.isdirectory(dir))  -- Should be 1

-- Create if missing
vim.fn.mkdir(dir, "p")
```

### Highlight shows `<error>`

**Symptom:** Highlight value shows `<error: ...>`

**Cause:** Highlight group doesn't exist or API error

**This is informational** - indicates the group isn't defined.

### Tree-sitter not detected

**Symptom:** `parsers_available = false`

**Cause:** nvim-treesitter not installed

**Solution:**
```vim
" Install nvim-treesitter
:Lazy install nvim-treesitter

" Install markdown parser
:TSInstall markdown markdown_inline
```

### LSP section empty

**Symptom:** `clients = {}`

**Cause:** No LSP attached to buffer

**This is normal** if you don't use Markdown LSP.

---

## Common Fixes

### Fix 1: Use Tree-sitter Highlights

```vim
:TSEnable highlight
```

### Fix 2: Disable Conflicting Syntax

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.syntax = "off"  -- Let tree-sitter handle
  end,
})
```

### Fix 3: Define Missing Highlight Groups

```lua
vim.api.nvim_set_hl(0, "markdownCode", {
  bg = "#3c3836",
  fg = "#83a598",
})

vim.api.nvim_set_hl(0, "@markup.raw.inline.markdown_inline", {
  link = "markdownCode",
})
```

### Fix 4: Disable LSP Semantic Tokens

```lua
require("lspconfig").marksman.setup({
  on_attach = function(client, bufnr)
    client.server_capabilities.semanticTokensProvider = nil
  end,
})
```

---

## See Also

- [Main README](../../docs/README.md)
- `:h debugging-markdown`
- `:h 'syntax'`
- `:h nvim-treesitter`
- [Tree-sitter Markdown](https://github.com/MDeiml/tree-sitter-markdown)

---
