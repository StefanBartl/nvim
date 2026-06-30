```lua
## Installation setup

**When to use which:**

| Variant | Startup impact | Commands available | When to use |
|---|---|---|---|
| **Default (lazy)** | Minimal | On first `:SessionLoad` / `:SessionSave` | Large config, many plugins |
| **`lazy = false`** | Loads immediately | Right from the start | Small plugin, want instant availability |
| **`event = "VimEnter"`** | After UI init | After editor UI ready | **Recommended** — autoload/autosave timing, minimal impact |

### lazy.nvim

*Load at startup (eager):*
```lua
{
  "stefanbartl/sessions.nvim",
  dependencies = { "stefanbartl/lib.nvim" },
  lazy = false,
  opts = {},
}
```

*Load after UI init (recommended for session auto-load/auto-save):*
```lua
{
  "stefanbartl/sessions.nvim",
  dependencies = { "stefanbartl/lib.nvim" },
  event = "VimEnter",
  opts = {},
}
```

### packer

*Default setup:*
```lua
use {
  "stefanbartl/sessions.nvim",
  requires = { "stefanbartl/lib.nvim" }, -- optional
  config = function()
    require("sessions").setup()
  end,
}
```

*With immediate load (packer equivalent of `lazy = false`):*
```lua
use {
  "stefanbartl/sessions.nvim",
  requires = { "stefanbartl/lib.nvim" },
  module_pattern = "sessions", -- eager
  config = function()
    require("sessions").setup()
  end,
}
```

---

```
