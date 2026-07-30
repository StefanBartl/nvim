# unicode.vim — User-Commands

Alle Commands kommen direkt aus dem Plugin
([doc/unicode.txt](../../../../../../nvim-data/lazy/unicode.vim/doc/unicode.txt),
Abschnitt 2 "Commands") — kein Wrapper, kein eigener `usrcmds.lua` in diesem
Repo. Lazy-geladen über
[lua/plugins/workflow.lua](../../../../../lua/plugins/workflow.lua)
(`cmd = { "UnicodeName", "UnicodeSearch", "UnicodeTable", "Digraphs" }`).

Alle Einträge **[default]**.

| Command | Wirkung |
|---|---|
| `:UnicodeName [reg [type]]` | Unicode-Name, Codepoint (hex/dec) und Such-Pattern für das Zeichen unter dem Cursor ausgeben; optional in Register `reg` sichern (`type`: `digraph`/`html`/`name`/`regex`/`value`). |
| `:UnicodeSearch [name\|nr]` | Unicode-Zeichen nach Name (Regex) oder Wert (`U+`/`0x`-Präfix) suchen und auflisten. Mit `!`: fragt nach Nummern und fügt die passenden Zeichen an der Cursor-Position ein. |
| `:UnicodeTable[!]` | Neues Fenster mit Tabelle aller Unicode-Zeichen; wird lokal gecacht (`UnicodeTable.txt`), `!` erzwingt Neugenerierung. Wird zusätzlich von `lua/config/menu/custom_menu/init.lua` (`open_unicode_table()`) im Custom-Menu als Floating-Window-Wrapper genutzt. |
| `:Digraphs[!] [pattern]` | Digraph-Liste anzeigen bzw. nach `pattern` filtern (Einzelzeichen = literal, mehrere Zeichen = Regex, matcht auch den Unicode-Namen). `!` = ein Digraph pro Zeile inkl. Name. |

## Nicht in `cmd = {...}` gelistet, aber vom Plugin bereitgestellt

Diese Commands existieren im Plugin, sind aber **nicht** in der
lazy.nvim-`cmd`-Liste — sie funktionieren trotzdem, sobald das Plugin auf
anderem Weg (z. B. über einen der obigen Commands oder den `uni`-Keymap-Trigger,
siehe [Keymaps/Unicode.md](../Keymaps/Unicode.md)) geladen wurde, lösen aber
selbst **kein** Lazy-Load aus, wenn sie als allererster Aufruf getippt werden:

| Command | Wirkung |
|---|---|
| `:UnicodeDownload[!]` | `UnicodeData.txt` (neu) herunterladen. `!` unterdrückt die Rückfrage. |
| `:DigraphNew {char1}{char2} {pattern}` | Neuen Digraph für ein per `{pattern}` gefundenes Zeichen anlegen. |
| `:UnicodeCache` | Cache-Datei (`UnicodeData.vim`) manuell neu aus `UnicodeData.txt` erzeugen. |

**[default]**, aber praktisch nur relevant, falls das Plugin bereits über
einen der `cmd`-Trigger geladen wurde.
