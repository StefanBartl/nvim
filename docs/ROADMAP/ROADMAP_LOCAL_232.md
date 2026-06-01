# Roadmap for `main-workstation` branch

1. `nvim-container` really needed or should i disable it? `Arch`?
leader fm open in neotree?

## `config`


### Neovim-Usercmd: `Open [wo?]` ähnlich wie  `Format [was?][wie?]` gestalten

wie du in meinen nvim repository sehen kannst, hab ich mir angewöhnt, Usercommands zu schreiben wie

`:Format [was?] [wie?]`
also zb
`:Format table center`
beispiele dafür findest du unter
`custom/format/*`
oder
`custom/insert/*`
Ich möchte nun ein weiters erstellen, nämlich:
`/custom/open/*`
dasd mit der syntax
`:Open [wo öffnen?]`
das was unter dem cursor ist, also ein link, eine dateipfad usw.. das man diesen dann öffnen kann, also zb.: wenn ich auf einen link bin mit dem cursor und
`:Open (standard browser)`
oder
`:Open edge`
oder
`:Open chrome`
usw... Dann wird das in dem browser geöffnet.
oder auf einen dateipfad
`:Open filemanager`
dann wird die datei im filemanager geöffnet
Ich bin mir sicher, es fallen dir auch noch mehrere beisoiele dazu ein
Eine zusätzliche sache noch:
`:Open notepad`
soll den text unter dem curor einfach im default editor öffnen und dort hineinkopieren. Funktioneren soll das ganze im normal modus so, dass das wort auf dem der cursor gerade ist, genommen wird, im visuellen bzw visuellen line modus modus das was markiert ist.
in der befehslzeile sollte autoverollständigung für die commands dabe sein wie bei den insert oder format modulen auch, also:
`:Open`
und dann ein tab soll `notepad`, `filemanager` usw... vorschlagen.


Wie immer:

Beachte dabei die ausgearbeiteten Regeln & Leitlinien zu den Themem
- Architektur
- Clean Code
- Sicherheit
- Performance
- uvm...
-
welche in den Dateien Arch&[Coding-Regeln.md](http://coding-regeln.md/) & [Checklist.md](http://checklist.md/) & [Zentrale-Prinzipien.md](http://zentrale-prinzipien.md/) festgehalten sind und in den in den Projektdateien anhängig sind.
Außerdem erstelle eine `[README.md](http://readme.md/)` sowie eine `/doc/open_custom_usrcmd.txt` für die nvim interne `:h` hilfe.

Die Projekhierarchie könnte ungefähr so aussehen:

```md
lua/custom/open/
├── @types/init.lua
├── handlers/
│   ├── browser.lua
│   ├── filemanager.lua
│   └── notepad.lua
├── context.lua
├── platform.lua^
├── registry.lua
└── init.lua
└── doc/
    ├── open_custom_usrcmd.txt
README.md
```

und die ersten Überlegungen fpr eine

`custom/open/@types/init.lua`:

```lua
---@module 'custom.open.types'
---@brief Type definitions for the custom :Open command module.
---@description
--- This file is a pure annotation target.
--- No executable code is present; its only purpose is to make the LSP
--- aware of the shared types used across all sub-modules.

-- ---------------------------------------------------------------------------
-- Handler keys
-- ---------------------------------------------------------------------------

---@alias Custom.Open.HandlerKey
---| '"browser"'      # System default browser
---| '"chrome"'       # Google Chrome or Chromium
---| '"edge"'         # Microsoft Edge
---| '"firefox"'      # Mozilla Firefox
---| '"safari"'       # Safari (macOS only)
---| '"filemanager"'  # System file manager
---| '"notepad"'      # System default text editor
---| string           # User-registered extension key

-- ---------------------------------------------------------------------------
-- Platform descriptor
-- ---------------------------------------------------------------------------

---Platform flags determined once at startup and cached for the session.
---@class Custom.Open.Platform
---@field is_win   boolean  True on native Windows (win32 or win64 build)
---@field is_mac   boolean  True on macOS
---@field is_wsl   boolean  True when running inside WSL (Linux kernel, Windows host)
---@field is_linux boolean  True on any Linux (including WSL)

-- ---------------------------------------------------------------------------
-- Context
-- ---------------------------------------------------------------------------

---Text and metadata extracted from the cursor position or visual selection.
---Passed to every handler's run() function.
---@class Custom.Open.Context
---@field text    string   Raw text: WORD under cursor in normal mode, or visual selection
---@field is_url  boolean  True when text matches a URL heuristic (http/https/ftp/www)
---@field is_path boolean  True when text matches a path heuristic or exists on disk

-- ---------------------------------------------------------------------------
-- Handler contract
-- ---------------------------------------------------------------------------

---A handler registered with the Open registry.
---@class Custom.Open.Handler
---@field key  string                                   Unique completion key, e.g. "chrome"
---@field desc string                                   Human-readable one-line description
---@field run  fun(ctx: Custom.Open.Context): boolean   Returns true when dispatch was initiated

return {}
```


---

---

## Neotree

---
