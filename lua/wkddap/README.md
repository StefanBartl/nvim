# DAP (Debug Adapter Protocol) Documentation

Comprehensive debugging support for Neovim with multi-language support, rich UI integration, and extensible architecture.

---

## 📚 Table of Contents

- [Quick Start](#quick-start)
- [Supported Languages](#supported-languages)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Architecture](#architecture)
- [Extending](#extending)
- [Troubleshooting](#troubleshooting)
- [API Reference](#api-reference)

---

## 🚀 Quick Start

```lua
-- Minimal setup (auto-detects all available adapters)
require('dap').setup()

-- Custom setup
require('dap').setup({
  languages = { 'lua', 'javascript', 'go', 'python' },
  ui = { enable = true, virtual_text = true },
  keymaps = { enable = true, prefix = '<leader>d' },
  auto_install = false, -- Set to true for Mason auto-install
})
```

**Basic Workflow:**

1. Set breakpoint: `<leader>db`
2. Start debugging: `<leader>dc`
3. Step through: `<leader>ds` (over), `<leader>di` (into), `<leader>do` (out)
4. Toggle UI: `<leader>du`
5. Evaluate: `<leader>de`

---

## 🌐 Supported Languages

| Language       | Adapter             | Status | Notes                    |
| -------------- | ------------------- | ------ | ------------------------ |
| Lua            | OSV                 | ✅     | Neovim-native            |
| JavaScript/TS  | js-debug-adapter    | ✅     | Node.js, Deno, Browser   |
| C/C++          | CodeLLDB / GDB      | ✅     | LLDB or GDB              |
| Go             | Delve               | ✅     | Go 1.16+                 |
| Python         | debugpy             | ✅     | Python 3.7+              |
| Rust           | CodeLLDB            | ✅     | Cargo integration        |
| Zig            | CodeLLDB / LLDB     | ✅     | Zig 0.11+                |
| Assembly       | GDB / LLDB          | ✅     | NASM, GAS, AT&T          |

**Aliases:**
- `typescript` → `javascript`
- `cpp` → `c`
- `asm` → `assembly`

---

## 📦 Installation

### Dependencies

**Required:**
- [nvim-dap](https://github.com/mfussenegger/nvim-dap)

**Recommended:**
- [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) – Visual debugging UI
- [nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text) – Inline variable values
- [mason.nvim](https://github.com/williamboman/mason.nvim) – Adapter management

### Lazy.nvim

```lua
{
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "theHamsta/nvim-dap-virtual-text",
    "jbyuki/one-small-step-for-vimkind", -- Lua debugging
  },
  config = function()
    require('dap').setup({
      languages = {}, -- Empty = all available
      auto_install = true, -- Mason auto-install
    })
  end,
}
```

### Adapter Installation

**Via Mason:**
```vim
:MasonInstall js-debug-adapter codelldb delve debugpy
```

**Manual:**
- **Delve (Go):** `go install github.com/go-delve/delve/cmd/dlv@latest`
- **debugpy (Python):** `pip install debugpy`
- **CodeLLDB:** Download from [GitHub Releases](https://github.com/vadimcn/codelldb/releases)

---

## ⚙️ Configuration

### Full Configuration Example

```lua
require('dap').setup({
  -- Languages to enable (empty = all available)
  languages = {
    'lua',
    'javascript',
    'typescript',
    'go',
    'python',
    'rust',
  },

  -- UI configuration
  ui = {
    enable = true,
    virtual_text = true,
    signs = true,
    highlights = true,
  },

  -- Keymap configuration
  keymaps = {
    enable = true,
    prefix = '<leader>d',
  },

  -- Commands
  commands = {
    enable = true,
    autocmds = true,
  },

  -- Custom adapter overrides
  adapters = {
    javascript = {
      port = 9229, -- Custom port
    },
  },

  -- Custom launch configurations
  configurations = {
    go = {
      {
        type = 'go',
        name = 'Debug Package',
        request = 'launch',
        program = '${fileDirname}',
      },
    },
  },

  -- Mason auto-install
  auto_install = false,

  -- Logging level
  log_level = vim.log.levels.INFO,
})
```

### Per-Language Configuration

See language-specific documentation:
- [Lua](./LANGUAGES.md#lua)
- [JavaScript/TypeScript](./LANGUAGES.md#javascript)
- [Go](./LANGUAGES.md#go)
- [Python](./LANGUAGES.md#python)
- [Rust](./LANGUAGES.md#rust)

---

## 🎯 Usage

### Starting a Debug Session

**Method 1: Continue (auto-launch)**
```vim
:lua require('dap').continue()
```

**Method 2: Select configuration**
```vim
:DapContinue
```

**Method 3: Custom launch**
```vim
:lua require('dap').run({
  type = 'go',
  request = 'launch',
  program = '${file}',
})
```

### Breakpoints

**Toggle:** `<leader>db` or `:DapToggleBreakpoint`

**Conditional:**
```vim
:lua require('dap').set_breakpoint(vim.fn.input('Condition: '))
```

**Log point:**
```vim
:lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Log: '))
```

### Stepping

- **Step Over:** `<leader>ds`
- **Step Into:** `<leader>di`
- **Step Out:** `<leader>do`
- **Continue:** `<leader>dc`

### Evaluation

**Hover:** `K` (in debug mode)

**Evaluate expression:**
```vim
:lua require('dapui').eval('<expression>')
```

**Visual selection:** Select text, then `<leader>de`

### UI Controls

- **Toggle UI:** `<leader>du`
- **Toggle REPL:** `<leader>dR`
- **Scopes/Watches/Stacks:** Auto-displayed in UI

---

## 🏗️ Architecture

```
dap/
├── init.lua              # Main entry point
├── config.lua            # Central configuration
├── registry.lua          # Language registration
├── health.lua            # :checkhealth support
│
├── core/                 # Core functionality
│   ├── setup.lua         # Initialization
│   ├── capabilities.lua  # Feature detection
│   └── state.lua         # Session state
│
├── adapters/             # Language adapters
│   ├── lua.lua
│   ├── javascript.lua
│   └── ...
│
├── configurations/       # Launch configs
│   ├── lua.lua
│   └── ...
│
├── ui/                   # UI integration
│   ├── dapui.lua         # DAP UI setup
│   ├── virtual_text.lua  # Inline values
│   └── signs.lua         # Gutter signs
│
├── commands/             # Commands & Autocommands
├── keymaps/              # Keyboard mappings
└── utils/                # Shared utilities
```

**Design Principles:**

1. **Modularity:** Each language has isolated adapter + configuration
2. **Lazy Loading:** Adapters loaded on-demand
3. **Validation:** All adapters checked for availability
4. **Extensibility:** Simple API for adding languages
5. **Safety:** Comprehensive error handling with pcall

---

## 🔧 Extending

See [EXTENDING.md](./EXTENDING.md) for detailed guide on adding new languages.

**Quick Summary:**

1. Create `adapters/<language>.lua`
2. Create `configurations/<language>.lua`
3. Update `config.lua` with binary info
4. Register in `registry.lua`
5. Add health checks

---

## 🐛 Troubleshooting

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues.

**Quick Checks:**

```vim
:checkhealth dap
:DapShowLog
:lua require('dap.registry').stats()
```

---

## 📖 API Reference

See [API.md](./API.md) for complete API documentation.

**Core Functions:**

```lua
local dap = require('dap')

-- Setup
dap.setup(opts)

-- Session control
dap.continue()
dap.terminate()
dap.restart()

-- Stepping
dap.step_over()
dap.step_into()
dap.step_out()

-- Breakpoints
dap.toggle_breakpoint()
dap.set_breakpoint(condition, hit_condition, log_message)
dap.list_breakpoints()

-- Registry
local registry = require('dap.registry')
registry.register('python')
registry.available_languages()
```

---

## 📝 License

Part of your Neovim configuration. See main repo license.

---

## 🙏 Credits

- [nvim-dap](https://github.com/mfussenegger/nvim-dap) by mfussenegger
- [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) by rcarriga
- Community adapter maintainers
