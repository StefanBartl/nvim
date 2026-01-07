---@module 'debugging'

local M = {}

---@param opts Dbg.Setup|nil
---@return nil
function M.setup(opts)
  opts = opts or {}

  if opts.autocmds or opts.all == true then
    require("debugging.autocmds").setup(opts.autocmds or { all = true })
  end

  if opts.markdown or opts.all == true then
    require("debugging.markdown").setup(opts.markdown or { all = true })
  end

  if opts.terminals or opts.all == true then
    require("debugging.terminals").setup(opts.terminals or { all = true })
  end

  -- User commands (BufReport, TabReport, WinReport)
  if opts.usercmds ~= false or opts.all == true then
    require("debugging.usercmds").setup(opts.usercmds or { all = true })
  end

  if opts.views ~= false or opts.all == true then
    require("debugging.views").setup(opts.views or { all = true })
  end

end

return M

--[[
Debugging.nvim – Konfigurationsreferenz

Diese Referenz zeigt alle Module, Optionen, Default-Werte und Beispiele für
require("debugging").setup(opts).

------------------------------------------------------------
1. Hauptsetup
------------------------------------------------------------

require("debugging").setup({
    all = false,        -- optional: aktiviert alle Module
    autocmds = nil,     -- Dbg.Autocmds.Modules|nil
    markdown = nil,     -- Dbg.Markdown.Modules|nil
    terminals = nil,    -- Dbg.Terminals.Modules|nil
    views = nil,        -- Dbg.Views.Setup|nil
    usercmds = true,    -- boolean|nil
    tools = nil,        -- Dbg.Tools.Modules|nil
})

------------------------------------------------------------
2. Module und Optionen
------------------------------------------------------------

2.1 Autocmds

Options:
    all           : boolean?  -- aktiviert alle Autocmd-bezogenen Module (default: false)
    list_autocmds : boolean?  -- listet alle Autocmds über :autocmd auf (default: false)

Beispiel:
require("debugging").setup({
    autocmds = { list_autocmds = true }
})

------------------------------------------------------------
2.2 Markdown

Options:
    all                : boolean? -- aktiviert alle Markdown-Module (default: false)
    inline_debug_fixed : boolean? -- Inline-Debug für Markdown (default: false)

Beispiel:
require("debugging").setup({
    markdown = { inline_debug_fixed = true }
})

------------------------------------------------------------
2.3 Terminals

Options:
    all       : boolean? -- aktiviert alle Terminal-Tools (default: false)
    keylogger : boolean? -- aktiviert Keylogger-Funktion (default: false)

Beispiel:
require("debugging").setup({
    terminals = { keylogger = true }
})

------------------------------------------------------------
2.4 Views

Options:
    keymaps : Dbg.Views.Keymaps|nil
        enable : boolean      -- aktiviert Keymaps (default: true)
        map    : fun()         -- mapping-Funktion, default: vim.keymap.set
        prefix : string        -- Prefix für Keymaps, default: "<lt>"

    autocmds : Dbg.Views.Autocmds|nil
        enable       : boolean -- aktiviert Autocmds (default: true)
        group_name   : string  -- Autocmd-Gruppe, default: "DebugViewsAuto"
        auto_refresh : boolean -- Refresh bei Änderungen (default: true)

    timings : Dbg.Views.Timings|nil
        delay_messages_ms : integer -- Delay für Messages (default: 30)
        delay_noice_ms    : integer -- Delay für Noice (default: 50)
        retry_delay_ms    : integer -- Retry-Delay (default: 60)
        attempts          : integer -- Anzahl Retry-Versuche (default: 3)

    capture : Dbg.Views.CaptureOpts|nil
        debug      : boolean?  -- debug output (default: false)
        clipboard  : boolean?  -- copy to clipboard (default: true)
        save_file  : boolean?  -- save to file (default: true)
        output_dir : string?   -- directory for output file

Beispiel:
require("debugging").setup({
    views = {
        keymaps = { enable = true, prefix = "<leader>d" },
        autocmds = { enable = true, auto_refresh = true },
        timings = { delay_messages_ms = 20, attempts = 5 },
        capture = { clipboard = true, save_file = true },
    }
})

------------------------------------------------------------
2.5 Tools

Options:
    all               : boolean?  -- aktiviert alle Tools (default: false)
    buffer_inspector  : boolean?  -- aktiviert Buffer-Inspektor (default: false)
    cursor_state      : boolean?  -- zeigt Cursor-Zustand an (default: false)
    vardump           : boolean?  -- aktiviert Vardump (default: false)

Beispiel:
require("debugging").setup({
    tools = { vardump = true, cursor_state = true }
})

------------------------------------------------------------
2.6 Nvim Options

Options:
    all              : boolean?  -- aktiviert alle NvimOption-Tools (default: false)
    indent_helpers   : boolean?  -- aktiviert Indent-Helper (default: false)

------------------------------------------------------------
2.7 User Commands

Option:
    usercmds : boolean?  -- aktiviert :BufReport, :TabReport, :WinReport (default: true)

Beispiel:
require("debugging").setup({
    usercmds = true
})

------------------------------------------------------------
3. Beispiele für Setup

-- Alle Views + Vardump aktivieren
require("debugging").setup({
    views = { all = true },
    tools = { vardump = true },
})

-- Nur Views mit Keymaps aktivieren
require("debugging").setup({
    views = {
        keymaps = { enable = true, prefix = "<leader>d" }
    }
})

-- Nur Tools aktivieren
require("debugging").setup({
    tools = { cursor_state = true, vardump = true }
})

-- Alles aktivieren
require("debugging").setup({
    all = true
})

------------------------------------------------------------
4. Keymaps (Standard "<leader>d")

| Key           | Action                     |
|---------------|----------------------------|
| <leader>dm    | Messages view               |
| <leader>dn    | Noice all                   |
| <leader>de    | Noice errors                |
| <leader>dc    | Capture to file+clipboard   |
| <leader>dx    | Clear all debug windows     |

------------------------------------------------------------
5. User Commands

:BufReport       -- Buffer-Report
:TabReport       -- Tab-Report
:WinReport       -- Aktuelles Fenster
:WinReport 1000  -- Bestimmtes Fenster
:DebugMessagesCapture
:DebugMessagesShow
:DebugWindowsClear

------------------------------------------------------------
6. Notes

- Module werden nur aktiviert, wenn Flag true oder all=true gesetzt ist.
- all=true überschreibt selektive Optionen innerhalb des Moduls.
- Default-Prefix für Views-Keymaps ist "<lt>".
- Vardump nimmt Variable unter Cursor, wenn kein Argument angegeben wird.
]]

