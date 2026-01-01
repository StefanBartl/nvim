## Beispiel-Konfiguration

```lua
-- In deiner init.lua oder nach dem Laden von debugging/

require("debugging").setup({
  views = {
    keymaps = {
      enable = true,
      prefix = "<leader>d",  -- <leader>dm, <leader>dn, <leader>de, <leader>dc, <leader>dx
    },
    autocmds = {
      enable = true,
      group_name = "DebugViewsAuto",
      auto_refresh = true,
    },
    timings = {
      delay_messages_ms = 30,
      delay_noice_ms = 50,
      retry_delay_ms = 60,
      attempts = 3,
    },
  },

  -- User Commands aktivieren
  usercmds = true,  -- :BufReport, :TabReport, :WinReport

  -- Legacy modules (optional)
  autocmds = nil,
  markdown = nil,
  terminals = nil,
})
```

## Verfügbare Commands

```vim
" Unified Views
:DebugMessagesCapture      " Capture to file + clipboard
:DebugMessagesShow         " Show messages window
:DebugWindowsClear         " Close all debug windows

" User Commands
:BufReport                 " Buffer-Report
:TabReport                 " Tab-Report
:WinReport                 " Current window report
:WinReport 1000            " Report für Window-ID 1000

" Health Check
:checkhealth debugging
```

## Keymaps (Standard: `<leader>d`)

| Key | Action |
|-----|--------|
| `<leader>dm` | Messages view |
| `<leader>dn` | Noice all |
| `<leader>de` | Noice errors |
| `<leader>dc` | Capture to file+clipboard |
| `<leader>dx` | Clear all debug windows |

## Migration von alten Modulen

### Alt (usrcmds.mymessages)
```lua
require("usrcmds.mymessages").enable_usercmds()
```

### Neu (debugging.views)
```lua
require("debugging").setup({ views = {} })
-- Alles automatisch verfügbar
```

### Alt (mappings.dbg_messages)
```lua
require("mappings.dbg_messages").setup({
  keymaps = { enable = true },
  autocmds = { enable = true },
})
```

### Neu (debugging.views)
```lua
require("debugging").setup({
  views = {
    keymaps = { enable = true, prefix = "<lt>" },  -- Dein Prefix
    autocmds = { enable = true, auto_refresh = true },
  }
})
```
