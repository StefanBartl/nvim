# unicode.vim — Keymaps

Plugin-Spec in
[lua/plugins/workflow.lua](../../../../../lua/plugins/workflow.lua).
Kein eigener Config-Layer (kein `lua/config/unicode/`) — keine der
Plugin-Variablen (`g:Unicode_no_default_mappings`, `g:Unicode_ShowPreviewWindow`,
`g:Unicode_CompleteName`, `g:Unicode_data_directory`, `g:Unicode_use_cache`) wird
gesetzt, das Plugin läuft also **komplett mit seinen Defaults**.

`chrisbra/unicode.vim` ist ein klassisches Vimscript-Plugin: die Mappings
kommen aus dem Plugin selbst
([doc/unicode.txt](../../../../../../nvim-data/lazy/unicode.vim/doc/unicode.txt),
Abschnitt `unicode-mappings`), nicht aus diesem Config-Repo.

---

## Lazy-Load-Trigger (custom)

| Mapping | Modus | Quelle |
|---|---|---|
| `uni` | Normal | `keys = { { "uni", desc = "Show Unicode character info" } }` in [lua/plugins/workflow.lua](../../../../../lua/plugins/workflow.lua) |

**[custom]** — Das ist **keine** Funktion des Plugins, sondern ein
lazy.nvim-Lazy-Load-Trigger: es wird nur ein `vim.keymap.set`-Eintrag für die
exakte Tastenfolge `u`,`n`,`i` angelegt, ohne eigene rhs. lazy.nvim löscht
diesen Platzhalter-Keymap beim ersten Treffer wieder, lädt das Plugin und
feedet die Tasten erneut — die zweite Auswertung von `u`,`n`,`i` läuft dann
als **drei separate Standard-Normal-Commands** (`u` Undo, `n` nächster
Such-Treffer, `i` Insert-Mode), **nicht** als ein Aufruf von `:UnicodeName`
o. ä. Der `desc`-Text "Show Unicode character info" beschreibt also die
Absicht, nicht das tatsächliche Verhalten nach dem Laden — siehe offene Frage
unten.

---

## Default-Mappings des Plugins (aktiv, da keine Overrides gesetzt sind)

Aus `doc/unicode.txt`, Abschnitt 4 "Mappings":

| Mapping | Modus | Aktion |
|---|---|---|
| `<C-x><C-z>` | Insert | Unicode-Name/-Glyph vor dem Cursor vervollständigen (`i_CTRL-X_CTRL-Z`, `<Plug>(UnicodeComplete)`) |
| `<C-x><C-g>` | Insert | Digraph vor dem Cursor vervollständigen (`i_CTRL-X_CTRL-G`, `<Plug>(DigraphComplete)`) |
| `<C-x><C-b>` | Insert | HTML-Entity vor dem Cursor vervollständigen (`i_CTRL-X_CTRL-B`) |
| `<C-g><C-f>` | Insert | Fuzzy-Suche über alle Unicode-Namen via fzf, Treffer einfügen (`<Plug>(UnicodeFuzzy)`, benötigt `fzf`) |
| `<F4>` | Normal/Visual | Zeichenpaar in sein Digraph umwandeln, `operatorfunc`-Mapping (`<Plug>(MakeDigraph)`) |
| `<Leader>un` | Normal | Umschalten zwischen Vervollständigung von Unicode-Namen und Unicode-Glyphen (`<Plug>(UnicodeSwapCompleteName)`) |

Alle als **[default]** markiert — keines dieser Mappings wird in diesem
Repo überschrieben oder zusätzlich gebunden.

### Nicht standardmäßig gebunden, aber vom Plugin bereitgestellt

`ga` ist **nicht** auf `<Plug>(UnicodeGA)` umgemappt (das müsste explizit per
`nmap ga <Plug>(UnicodeGA)` passieren) — in diesem Repo bleibt `ga` also das
eingebaute Vim-`ga` (Zeichen-Info unter Cursor), nicht die erweiterte
Unicode-Variante.

---

## Offene Frage

Der `uni`-Trigger in `workflow.lua` wirkt wie ein Copy-Paste-Rest oder eine
missverstandene lazy.nvim-`keys`-Nutzung: ohne explizite rhs (z. B.
`"<cmd>UnicodeName<cr>"` oder `"<cmd>UnicodeTable<cr>"`) tut er nach dem Laden
nichts Unicode-Bezogenes. Zu klären, ob hier eigentlich ein Aufruf von
`:UnicodeTable` (siehe `lua/config/menu/custom_menu/init.lua`,
`open_unicode_table()`) oder `:UnicodeSearch!` gemeint war.
