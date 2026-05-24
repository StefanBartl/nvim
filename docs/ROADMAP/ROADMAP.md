# Roadmap for `main-workstation` branch

  GOUT.prod("TEST eins")
  GOUT.prod("TEST zqa")
  GOUT.prod("TEST eiasddd")
  GOUT.prod("TEST plpl")

- Fighting Game
- WebAssembly
- nvim-nexus
- Portfolio (mit den nvim plugins, htmx, Zertifikate, fighting game einbinden)

## Table of content

- [WKD Neovim Roadmap](#wkd-neovim-roadmap)
  - [Table of content](#table-of-content)
  - [Watch](#watch)
  - [Important](#important)
  - [MIXED](#mixed)
  - [UI](#ui)
  - [Neotest](#neotest)
  - [`custom.format.text_width`](#customformattext_width)
  - [ideas](#ideas)
  - [Long run](#long-run)

---

## Watch

---

## Important

1. toc ??
2. Fehler meldungen mit  ⚠️ versehen; generell notifys aufhübschen
3. chrome debnug adapter -> js debug adapter
4. `custom.insert` nach `usrcmds.isnert` ?
5. trroublke bzw workspacve diagonisc sollen die zeile hervorheben in der man ist
6. `mappings.` nach `.config` refactoren


## MIXED

1. Usercommands so strukturieren:
    - `:DeleteCurrentFile` zu `:File delete`; `:Fileinfo` zu `File info`; Weiters `File rename;convert;`
    - ein usercommand, das alle emojis entfernt im buffer: `:Buffer remove emojis` `:Buffer remove empty_lines` `:Buffer translate de` `:Buffer translate_replace en ` `:Buffer insert ...`
2. lsp.tools behandeln
3. `:CwdHere` fixen
4. "a" in neotree scheint nicht mehr ganz typsiereungen ezuer rstellen
5. `:LuaFileStats` eine option machen, die keine file erzeugt sondern nur eine ausgabe im stdout/noify
6. `leader fg` soll nicht zuerst eine prompt haben, sondern gleich den picker aufmachen.
    - jeder buchstabe ist in der trefferliste eingetragen
    - Was siond die stats neben der prompt? weeenn ich `nvim_set_current_win` eingebe steht 2871/6343649
7. `sessions` überarbeiten
8. `Recommender`
    - so machen, dass ein telescope oder ein selection aufgemacht wird, und dort kann man dann aussuchen ,welche auf einmal angewandt werden

--

## UI

Implementieren in `:UI` sowie auch als config
- `autocmds.auto-center-fexplorer` (hat aber eigentlcih nichts mitr nvchad ui zu tun, also eigene oder wkdoptions/ui/config)

- `:UI` -> `:NvChadUI` / `:WKDUI`--> `:UI NvChad bzw :UI WKD`


## Neotest

1. neotest [lernen]()
2. `config.neotest.commands`
    - ein zentrales :Neotest-Command mit Subcommands bauen
    - Telescope-Integration (:Telescope neotest)
    - Neo-tree Actions direkt auf diese Commands mappen
3. ein einziges :Neotest Dispatcher-Command bauen oder Neo-tree Kontextmenü-Actions direkt an diese UserCommands binden
4. `config.neotest.neotree` einbinden in neotree

## `custom.format.text_width`

1. Limitationen: Hyphenation (geteilt mit -) und komplexe Worttrennungsregeln sind nicht implementiert. Listen- und Bullet-Erkennung ist eine einfache Heuristik: einfache Bullet-Marker wie - , * , + oder 1. werden auf der ersten Zeile beibehalten; Fortsetzungen werden passend eingerückt.
2. Erweiterungen, die man später leicht hinzufügen kann:
    - Bessere List- und Codeblock-Erkennung (z. B. Markdown-Codeblöcke ausschließen).
    - Hyphenation mittels externem Dienst oder Wörterbuch.
    - ? Buffer-locales Autowrap beim Tippen (z. B. über autocmd BufEnter,BufWinEnter + formatoptions oder textwidth während Insert).
    - SUPER: Verbinden mit marksman format + der Idee, dass man in codeblöcken lsp callt

--

## ideas

---

## Long run

- `editor_interface` verwenden, um funktionen, die sowohl mappings als auch usercommands begründen.
- autocmds fokussieren, so dass sie sich die durchgänge teilen
- workspace lsp warnings debuggen
    . Todo Coments anschauen und durchgehen
- probieren nvchad rauszunehmen und nochmal mit lazyvim
- experimental options:
- [nvim install doc](./NVIM-Install Doc/install_notes.md) fertig aufteilen
-- WKDBook lua und Neovim mit Notes zusammenführen

1. `nvim-container` really needed or should i disable it? `Arch`?
<<<<<<< HEAD
2. `markdown_render`-implementieren in `:Markdown [] []`
3. `leader fc` findet `git.lua` nicht???


`open` solte natürlich nach usrcmd sowie andere aus `custom` wahrscheinlich auch!

`usrcmds.collection` machen wenn diese nirgends anders zueprdnet werden können, dami die uscmds aus der init.lua rauskommen!

## tresitter

`9:09:55 PM msg_show Treesitter konnte noch nicht geladen werden. Starte Neovim ggf. neu.`
=======
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
>>>>>>> 1a9a40e (TEMP)

## Neotree

<<<<<<< HEAD
### `leader fm` - open in file manager

   Warn  9:58:23 AM notify.warn [config.neotree.open.filemanager.win] Open in Explorer: no path under cursor
   Warn  9:58:23 AM notify.warn [cfg.neotree.keymaps.fs.info] Failed to open in file manager

=======
>>>>>>> e3965d5 (neotree open in filemanager debugged)
---
