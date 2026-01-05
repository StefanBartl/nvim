# function_index

A high-performance, multi-language function indexer for Neovim that builds a searchable index of function definitions across your entire working directory without requiring Tree-sitter, LSP, or loading files as buffers.

## Features

- **Multi-language support**: Lua, Python, JavaScript/TypeScript, Go, Rust, C/C++, and more
- **Zero dependencies on LSP/Tree-sitter**: Uses `ripgrep` for blazing-fast pattern matching
- **Persistent caching**: Index is built once and cached to disk
- **Incremental updates**: Smart cache invalidation based on file modification times
- **Telescope & fzf-lua integration**: Choose your preferred fuzzy finder
- **Pre-filled prompts**: Initialize search with explicit function names or clipboard content
- **Logical grouping**: Functions grouped by visibility (local, module, global) and language
- **Type-aware**: Distinguishes between function types (local, method, exported, etc.)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/function_index",
  dependencies = {
    "nvim-telescope/telescope.nvim",  -- or
    "ibhagwan/fzf-lua",
  },
  config = function()
    require("custom.function_index").setup({
      -- optional configuration
    })
  end,
}
```

### Requirements

- Neovim >= 0.9.0
- [ripgrep](https://github.com/BurntSushi/ripgrep) >= 13.0 (with PCRE2 support)
- One of: Telescope or fzf-lua

## Usage

### Commands

```vim
:FunctionIndexTelescope    " Open function index with Telescope
:FunctionIndexFzfLua       " Open function index with fzf-lua
:FunctionIndexRebuild      " Force rebuild the cache
:FunctionIndexClearCache   " Clear cached index
:FunctionIndexStats
```

### Keymaps (Example)

```lua
vim.keymap.set("n", "<leader>pf", "<cmd>FunctionIndexTelescope<cr>", {
  desc = "Find functions (Telescope)"
})

vim.keymap.set("n", "<leader>ff", "<cmd>FunctionIndexFzfLua<cr>", {
  desc = "Find functions (fzf-lua)"
})
```

### Pre-filled Search

The picker can be initialized with a search term:

```lua
-- Search for function under cursor
vim.keymap.set("n", "<leader>pg", function()
  local word = vim.fn.expand("<cword>")
  require("custom.function_index.ui.telescope_picker").pick_with_query(word)
end, { desc = "Find current function definition" })

-- Search from clipboard
vim.keymap.set("n", "<leader>pc", function()
  local clip = vim.fn.getreg("+")
  require("custom.function_index.ui.telescope_picker").pick_with_query(clip)
end, { desc = "Find function from clipboard" })
```

## Configuration

```lua
require("custom.function_index").setup({
  -- Cache settings
  cache = {
    enabled = true,                    -- Enable persistent cache
    dir = vim.fn.stdpath("cache") .. "/function_index",
    ttl_seconds = 3600,                -- Cache validity duration
  },

  -- Indexing behavior
  indexing = {
    auto_rebuild_on_save = false,      -- Rebuild when files change
    exclude_patterns = {               -- Patterns to ignore
      "node_modules/",
      ".git/",
      "build/",
      "dist/",
    },
    max_file_size_kb = 1024,           -- Skip files larger than this
  },

  -- Language support
  languages = {
    lua = true,
    python = true,
    javascript = true,
    typescript = true,
    go = true,
    rust = true,
    c = true,
    cpp = true,
  },

  -- UI preferences
  ui = {
    show_language_icons = true,
    show_function_types = true,         -- local, method, exported, etc.
    group_by_file = false,              -- Group entries by file
    default_picker = "telescope",       -- "telescope" or "fzf"
  },
})
```

### How It Works

1. **Indexing Phase**:
   - Uses `ripgrep` with language-specific patterns to find function definitions
   - Parses output into structured entries (file, line, column, signature, type)
   - Groups functions by language and visibility (local, module-level, exported)

2. **Caching Phase**:
   - Serializes index to JSON in `stdpath("cache")`
   - Stores file modification times for incremental updates
   - Cache is invalidated when files change or TTL expires

3. **Search Phase**:
   - Loads cached index (or rebuilds if stale)
   - Presents entries to Telescope/fzf-lua
   - Supports pre-filled queries and fuzzy matching

4. **Navigation**:
   - On selection, opens file and jumps to exact line/column
   - No buffer pre-loading, fast and memory-efficient

## Supported Languages

### Lua
- `local function foo()`
- `function M.bar()`
- `foo = function()`
- `M.foo = function()`

### Python
- `def foo():`
- `async def bar():`
- `class Baz:\n    def method():`

### JavaScript/TypeScript
- `function foo()`
- `const bar = () => {}`
- `export function baz()`
- `class.method()`

### Go
- `func foo()`
- `func (r *Receiver) Method()`

### Rust
- `fn foo()`
- `pub fn bar()`
- `impl Struct { fn method() }`

### C/C++
- `void foo()`
- `int bar(int x)`
- `Class::method()`

## Performance

- **Indexing**: ~500-1000 functions/second (depends on disk I/O)
- **Cache loading**: <50ms for 10k functions
- **Search latency**: Instant (fuzzy matching in Telescope/fzf-lua)
- **Memory**: ~1KB per 100 function entries

## Limitations

- **No semantic analysis**: Cannot detect all edge cases (e.g., functions in strings, comments)
- **Static patterns**: May miss unconventional function definitions
- **Ripgrep dependency**: Requires `rg` with PCRE2 support
- **No realtime updates**: Index is snapshot-based (use `:FunctionIndexRebuild` to refresh)

## Troubleshooting

### "ripgrep not found"
Install ripgrep: `brew install ripgrep` (macOS) or `apt install ripgrep` (Linux)

### "No functions found"
- Check that your language is enabled in config
- Ensure files are not excluded by `exclude_patterns`
- Verify ripgrep version: `rg --version` (needs PCRE2 support)

### "Cache is stale"
Clear cache: `:FunctionIndexClearCache` and rebuild: `:FunctionIndexRebuild`

## Contributing

Contributions are welcome! To add support for a new language:

1. Add regex patterns to `core/patterns.lua`
2. Update `core/parser.lua` to handle the language
3. Add tests in `tests/`
4. Update this README

## License

MIT

## Credits

- Inspired by Telescope's `builtin.lsp_document_symbols`
- Uses [ripgrep](https://github.com/BurntSushi/ripgrep) for fast searching
- Built with Neovim's `vim.loop` for async operations
