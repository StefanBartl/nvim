# Neo-tree — Autocmds

Betrifft `nvim-neo-tree/neo-tree.nvim`. Für
`mrbjarksen/neo-tree-diagnostics.nvim`, `TimCreasman/neo-tree-tests-source.nvim`
und den Window-Picker (`s1n7ax/nvim-window-picker` bis 2026-09-19, seither
ui.nvim's `ui.windowpicker`) gibt es in dieser Config keine eigenen
Autocmds/Event-Handler — siehe stattdessen
[Keymaps/NeoTree.md](../Keymaps/NeoTree.md).

Neo-tree hat kein klassisches `vim.api.nvim_create_autocmd`-Erweiterungsfeld
in seiner Config; stattdessen gibt es einen eigenen Event-Bus
(`neo-tree.events`), an den `opts.event_handlers` angehängt wird. Diese Config
nutzt genau dieses Feld — funktional entspricht das einem Autocmd, deshalb
steht es hier und nicht bei den Keymaps.

Registriert in
[lua/config/neotree/event_handlers/init.lua](../../../../../lua/config/neotree/event_handlers/init.lua),
eingebunden über `event_handlers = require("config.neotree.event_handlers")`
in [lua/plugins/neotree.lua](../../../../../lua/plugins/neotree.lua).

| Neo-tree-Event | Quelle | Zweck | Status |
|---|---|---|---|
| `neo_tree_window_after_open` | [config/neotree/event_handlers/init.lua](../../../../../lua/config/neotree/event_handlers/init.lua) | Setzt im frisch geöffneten Neo-tree-Fenster (jede Position, jede Quelle) `foldmethod=manual` und `foldenable=false`, fensterlokal (`vim.wo[winid][0]`, also `:setlocal`; sonst würden später dort geöffnete Dateien und vom Baumfenster abgespaltene Fenster das Folding verlieren). Das Baumfenster wird vom Editor-Fenster abgesplittet und erbt dessen `foldmethod`/`foldexpr`; bei `expr` wertet jede Buffer-Änderung den Ausdruck pro Zeile aus, was bei großen Verzeichnissen (z. B. `%TEMP%`, ca. 5400 Einträge, ca. 35 s) Neovim einfrieren lässt. `foldenable=false` allein stoppt das Update nicht, `manual` schon. | [custom] |
| `neo_tree_preview_buffer_enter` | [config/neotree/event_handlers/init.lua](../../../../../lua/config/neotree/event_handlers/init.lua) | Setzt den Cursor im neu geöffneten Preview-Buffer auf Zeile 1, Spalte 0 (Scroll-Position bei jedem neuen Preview zurücksetzen). | [custom] |

## Entfernte Handler (zur Einordnung, nicht mehr Teil dieser Config)

Laut Kommentaren in derselben Datei wurden zwei frühere Handler entfernt, weil
**filetree.nvim** (ein anderes lokales Plugin) dieselbe Aufgabe jetzt
Adapter-agnostisch übernimmt:

- **Cursor-Hide**: früher ein eigener Handler, jetzt filetree.nvim's
  `ui/cursor_hide`-Feature (per `winhighlight`).
- **Layout-Guard**: früher ein eigener Handler, der verhinderte, dass Neo-tree
  als letztes Fenster im Tab übrig bleibt; jetzt filetree.nvim's
  `nav/layout_guard`.

## Neo-tree-eigene Autocmds (Plugin-Default, nicht von dieser Config gesetzt)

Zur Vollständigkeit — diese laufen unabhängig von dieser Config, weil sie im
Plugin selbst (`plugin/neo-tree.lua`) registriert werden, Augroup `NeoTree`:

| Event | Zweck |
|---|---|
| `BufEnter` | Lazy-Load von Neo-tree triggern bzw. Netrw-Hijack versuchen, solange Neo-tree noch nicht aktiv „lauscht". |
| `WinEnter` | Reihenfolge zuletzt fokussierter Fenster je Tab mitschreiben (für „intuitives" Öffnen von Dateien im richtigen Fenster). |
| `SessionLoadPost` | Nach dem Wiederherstellen einer Session verwaiste Neo-tree-Buffer aufräumen (`auto_clean_after_session_restore`). |
| `WinClosed` | `close_if_last_window`: Neovim beenden, wenn nach dem Schließen nur noch ein Neo-tree-Fenster übrig bleibt. |

Diese sind `[default]` und werden hier nur der Vollständigkeit halber
erwähnt — sie werden von dieser Config nicht verändert.
