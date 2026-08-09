# Neovim Notes

[NVIM-API Notes](../Notes/NVIM-Notes/NVIM-Api-Notes.md)
[NVIM-Lua Notes](../Notes/NVIM-Notes/NVIM-Lua-Notes.md)
[Vimscript Dokumentation](https://vimdoc.sourceforge.net/htmldoc/usr_41.html#function-list)
[Vimdoc](https://vimdoc.sourceforge.net/htmldoc/usr_41.html#function-list)

**Eigene Befehle**:
| Befehl                        | Beschreibung                                                  | Info                                         |
| ----------------------------- | ------------------------------------------------------------- | -------------------------------------------- |
| `:UserCommands`               | Zeigt alle User-Commands                                      |                                              |
| `:BufferClear`                | Lösche alle Zeilen des aktuellen Buffer                       |                                              |
| `:CopyFilepathToClipboard`    | Kopiert aktuellen Dateipfad ins Clipboard (`+`)               | Ausgabe: `Copied path to clipboard`          |
| `:CompressDir`                | Komprimiert aktuelles Verzeichnis in `~/temp`                 | Alt: `leader cc`                             |
| `:ProjectTreeGet`             | Speichert die Projektstruktur als Textdatei                   |                                              |
| `:ProjectTreeCopyClipboard`   | Kopiert die gespeicherte Struktur in das Clipboard            |                                              |
| `:ProjectFilesCount`          | Zählt alle Dateien im Projektverzeichnis                      |                                              |
| `:MDUnfatHeadings`            | Entfernt Markdown `**Bold**` Formatierungen                   | `**text** → text`                            |
| `:MyMessages`                 | Gibt `:messages` aus, speichert sie und kopiert in Clipboard  |                                              |
| `:NvimTreeSetRoot`            | Setzt den Root für `nvim-tree` (Pfad oder Git root)           |                                              |
| ----------------------------  | ------------------------------------------------------------- |                                              |
| **Suchen**                    |                                                               |                                              |
| `:FindOnSystem`               | Datei im System finden                                        | Alt: `leader fs`, `:Telescope fd_multi_root` |
| `:FindMappings`               | Öffnet Mappings-Suche                                         |                                              |
| `:TelescopeFdMultiRoot`       | FD-Suche über mehrere Root-Verzeichnisse                      | Nutzt `custom.fd_multi_root`                 |
| `:MultigrepFile`              | Grep in Projektordner nach Syntax `<NAME> <*.ext>`            | Optionales Argument für `cwd`                |
| `:FindFiles [depth] [engine]` | Dateisuche mit variabler Tiefe                                |                                               |
| ----------------------------  | ------------------------------------------------------------- |                                              |
| **LastFileSave**              |                                                               |                                              |
| `:LastFileSave`               | Speichert letzte Datei + Cursorposition                       | `[last_session]`                             |
| `:LastFileRestore`            | Stellt letzte Datei + Cursorposition wieder her               | `[last_session]`                             |
| `:LastFileClear`              | Löscht gespeicherten letzten Zustand                          | `[last_session]`                             |

**Wichtige NVIM-Befehlszeile Commands**:
`luafile %`: source der Datei
`:bnext | bd`: spring zum nächsten Buffer und beendet den vorigen
`:lua confirm_delete()`: Delete current selected file w. confirmation
`:call DeleteFile()`: Delete current selected file wo. confirmation and close buffer
`:redir > plugins.txt | silent echo execute('packloadall!') | redir END`: Beispiel für das umleiten eines Resultates eines Befehls
`:lua FzfLua.files({ cwd = '~/.config' })` oder `:FzfLua files cwd=~/.config`
`:print(vim.api.nvim_buf_line_count(0))` oder `:echo line('$')`: Buffer line count
`:botright vsplit | edit <cfile>`: [Details](E:\MyGithub\Notes\NVIM-Notes\MyNotes\JumpPositiong.md)

**redir**
`:redir! > file` → erzwingt das Überschreiben der Datei
`:redir > file`  → bricht ab, wenn Datei existiert
`:redir! >> file` → hängt an bestehende Datei an
`:redir! > %`     → überschreibt aktuelle Datei (Vorsicht!)

**suchen-springen:**
Vorwärts:  `/pattern`, `#`, `f`
Rückwärts: `?pattern`, `*`, `F`
`t{c}` | `T{c}` -> Springt in der Zeile „bis vor“/„bis hinter“ Zeichen `{c}`
`Visual *` | `Visual #` -> Sucht den aktuell markierten Text vorwärts/rückwärts

**Wichtige Mappings**:
`]d`: zur nächsten LSP-Meldung
`leader fk`: Finde Keymappings mit Telescope
`<leader>fzb` -> `:FzfLua buffers<CR>`: FzfLua: Search in Buffer
`grn` / `leader rn` / `leader nam`: Rename
`A-k`, `A-j`, `A-x`: Noice LSP-Hover steuern
`C-e`: cmp ablehnen

**Wichtige Vimmotions:**
```bash
f, # vor inklusive char
F, # zurück inklusive char
t, # vor exklusive char
T, # zurück exklusive Komma char
%  # springt zum zugehörigen Klammerpaar
I  # Erster char der Zeile mit insert
^  # Erster char der Zeile ohne insert
```

---

[FzfLua Filtertechniken](./08_plugins/fuzzy_finder/fzflua/Filtertechniken.md)

| Such-Modus | Syntax-Muster | Funktionsweise | Anwendungsfall |
| --- | --- | --- | --- |
| **Dateiname (`files`)** | `[Endung]$ [Begriff]` | **Suffix-Match:** Filtert die Dateiliste via Regex-Anker vor. | Findet z.B. nur `.lua`-Dateien, die das Wort "config" enthalten. |
| **Inhalt (`live_grep`)** | `[Begriff] -- -g "*.[endung]"` | **CLI-Globbing:** Übergibt das Glob-Flag direkt an `ripgrep`. | Sucht Textinhalte exklusiv in `.md`- oder `.json`-Dateien. |

---

| Aktion                        | Tasten            | Kommentar                                  |
| ----------------------------- | ----------------- | ------------------------------------------ |
| LSP Definition in vsplit      | `gvd`             | LSP Definitnion in vsplit                  |
| LSP Definition in split       | `gsd`             | LSP Definitnion in vsplit                  |
| LSP Definition in tab         | `gtd`             | LSP Definitnion in vsplit                  |
| Datei unter Cursor öffnen     | `gf`              | Öffnet im aktuellen Fenster (neuer Buffer) |
| Datei+Zeile „file:123“ öffnen | `gF`              | Wie gf, springt zusätzlich zu Zeile        |
| In neuem Split öffnen         | `<C-w> f`         | Horizontaler Split + Datei                 |
| In neuem Tab öffnen           | `<C-w> gf`        | Neuer Tab + Datei                          |
| Bel. Befehl mit Dateiname     | `:e <cfile>`      | <cfile> = „Dateiname unter dem Cursor“     |
| Vertikaler Split              | `:vsplit <cfile>` | Analog für vsplit/split/tabedit            | d |
| URL extern öffnen             | `gx`              | Netrw: öffnet http(s)://… im System        |
| Zurück zum vorherigen Buffer  | `<C-^>`           | Alternativedatei                           |
| Zurück im Jumplist            | `<C-o>`           | Zum Sprungpunkt vor gf zurück              |

**mappings**:
```lua
"C-x oder C-c" "<C-\\><C-N>" "terminal escape terminal mode"
"n <leader>tz terminal new horizontal term"
"n <leader>tv terminal new vertical term"
"<A-v> terminal toggleable vertical term"
"<A-h> terminal toggleable horizontal term"
"<A-i> terminal toggle floating term"
```

**Shell-Befehle direkt aus der Neovim-Befehlszeile (`:`) nutzen:**
| Aktion                                     | Ziel / Beschreibung                        | Befehl (zb `ls`, `grep`, etc.)                   |
| ------------------------------------------ | ------------------------------------------ | ------------------------------------------------ |
| **In aktuellen Buffer einfügen**           | Fügt Ergebnis unter Cursor ein             | `:read !<cmd>`<br>`:read !ls`                    |
| **Oben in Buffer einfügen**                | Fügt Ergebnis an Zeile 0 ein               | `:0read !<cmd>`<br>`:0read !git log`             |
| **Neuen Buffer + Shell-Ausgabe**           | Ergebnis in neuen Buffer                   | \`:new                                           |
| **Neuen Tab + Shell-Ausgabe**              | Führt Befehl in Tab aus                    | \`:tabnew                                        |
| **In Quickfix-Liste laden**                | Ergebnis im Qfx-Fenster                    | `:cexpr systemlist('<cmd>')`                     |
| **In Location List laden (local ctx)**     | Analog zu Qfx, aber lokal je Buffer        | `:lexpr systemlist('<cmd>')`                     |
| **Als Notification anzeigen**              | Gibt Ergebnis in `:messages` aus           | `:lua vim.notify(vim.fn.system('<cmd>'))`        |
| **Im Terminal-Fenster anzeigen**           | Öffnet Terminal-Split und führt Befehl aus | `:term <cmd>`<br>`:term git log --oneline`       |
| **Vertikales Terminal starten**            | Terminal in vertikalem Split               | `:vert term <cmd>`                               |
| **Mit `ToggleTerm` interaktiv**            | Öffnet Terminal mit Zugriff auf Shell      | `:ToggleTerm direction=float` → dann `cmd`       |
| **async Hintergrundprozess starten**       | Befehl o. UI-Blockierung (nur Lua)         | `:lua vim.fn.jobstart({ "ping", "google.com" })` |
| **In Register speichern (kurzzeitig)**     | Speichert Ausgabe in Register              | `:let @a = system('<cmd>')`                      |
| **Mit `filter` Buf nach ext Tool filtern** | Filtert akt. Bufferzeilen m Sh-Commands    | `:'<,'>!sort` oder `:'<,'>!uniq`                 |

```vim
:new | read !<cmd>
:new | read !ls -la
```
* `:new` öffnet einen neuen leeren Buffer in einem horizontalen Split
* `|` verbindet den nächsten Befehl (`:read !ls -la`)
* `read !...` führt den Shell-Befehl aus und fügt das Ergebnis in den Buffer ein

```vim
:tabnew | read !<cmd>
:tabnew | read !git log --oneline
```
* `:tabnew` öffnet einen neuen Tab mit einem leeren Buffer
* `:read !...` fügt die Ausgabe des Shell-Kommandos in diesen Buffer ein

**Windows-Kompatibilität (zb.: falls `grep` nicht installiert)**
```vim
:new | r !powershell -Command "Get-ChildItem -Recurse -File -Path $env:LOCALAPPDATA\nvim-data | Select-String -Pattern Foldexpr_markdown"
```

**`grep` Aufrufe direkt aus der Neovim-Befehlszeile (`:`)**
| Methode                             | Ziel                            | Neovim-Befehl                                                            |
| ----------------------------------- | ------------------------------- | ------------------------------------------------------------------------ |
| **Terminal-Split**                  | Ergebnis im Horizontal-Terminal | `:term grep -rnw "$LOCALAPP..PATH" -e Searchterm`                        |
| **Terminal-Vertikal**               | Ergebnis im vertikalen Split    | `:vert term grep -rnw "$LOCALAPP..PATH" -e Searchterm`                   |
| **Ergebnis im Quickfix**            | Ausgabe in Quickfix-Fenster     | `:cexpr systemlist('grep -rnw "$LOCALAPP..PATH" -e Searchterm')`         |
| **Ergebnis in Messages**            | Nur anzeigen, nicht bearbeiten  | `:lua print(vim.fn.system('grep -rnw "$LOCALAPP..PATH" -e Searchterm'))` |
| **Terminal per `termopen` starten** | direkt Shell-Befehl             | `:call termopen('grep -rnw "$LOCALAPP..PATH" -e Searchterm')`            |

**Windows/Buffer/Tabs:**
| Ziel                                         | Normaler Vim-Befehl                  | Erklärung                                                   |
| -------------------------------------------- | ------------------------------------ | ----------------------------------------------------------- |
| Neues Fenster vertikal teilen                | `:vsplit [Datei]  oder  :vs [Datei]` | Teilt aktuelles Fenster senkrecht, optional mit Dateiinhalt |
| Neues Fenster horizontal teilen              | `:split [Datei]  oder  :sp [Datei]`  | Teilt aktuelles Fenster waagerecht                          |
| Zwischen Fenstern wechseln                   | `<C-w>h / <C-w>l / <C-w>j / <C-w>k`  | Wechsel nach links/rechts/unten/oben                        |
| Größe von Fenstern ändern                    | `:resize N  /  :vertical resize N `  | Höhe/Breite anpassen                                        |
| Gleiche Datei in mehreren Fenstern öffnen    | `:vsplit`                            | Öffnet dieselbe Buffer-Instanz in zweitem Fenster           |
| Anderen Buffer im aktuellen Fenster laden    | `:buffer {Nr}  oder  :b {Teilname}`  | Lädt vorhandenen Buffer in aktuelles Fenster                |
| Gleiche Datei in mehreren Tabs anzeigen      | `:tabnew %`                          | Neues Tab, selbe Datei (%)                                  |
| Neuen Tab mit anderer Datei öffnen           | `:tabedit {Datei}`                   | Neuer Tab mit Dateiinhalt                                   |
| Zwischen Tabs wechseln                       | `:tabn` / `:tabp`  oder  `gt` / `gT` | Nächster / vorheriger Tab                                   |
| Buffer-Liste anzeigen                        | `:ls`   oder   `:buffers`            | Zeigt alle geöffneten Buffer an                             |
| Zu bestimmtem Buffer springen                | `:buffer {Nr}`                       | Wechselt Buffer (egal in welchem Fenster/Tab)               |
| Fenster in anderem Tab öffnen                | `:tab split {Datei}`                 | Öffnet Datei in neuem Tab als einzelnes Fenster             |
| Fenster schließen                            | `:close`                             | Schließt aktuelles Fenster                                  |
| Tab schließen                                | `:tabclose`                          | Schließt gesamten Tab (alle Fenster darin)                  |
| Buffer schließen (aber Fenster offen lassen) | `:bdelete`  oder  `:bd`              | Entfernt Buffer aus Liste, Fenster bleibt leer              |
| Alle außer aktuellem Buffer schließen        | `:%bd \| e#`                         | Schließt alle anderen Buffer, lädt wieder den aktuellen     |

---

## Interessante Befehle

- Man hat zwei Fenster/Tabpages mit unterschiedlichen Buffern offen. Der Puffer aus Fenster/Tab 2 soll in Fenster 1 als Split geöffnet werden. danach soll das ursprüngliche Fenster/Tab 2 geschlossen werden.MMMan hat zwei Fenster/Tabpages mit unterschiedlichen Buffern offen. Der Puffer aus Fenster/Tab 2 soll in Fenster 1 als Split geöffnet werden, danach soll das ursprüngliche Fenster/Tab 2 geschlossen werden.
an hat zwei Fenster/Tabpages mit unterschiedlichen Buffern offen. Der Puffer aus Fenster/Tab 2 soll in Fenster 1 als Split geöffnet werden, danach soll das ursprüngliche Fenster/Tab 2 geschlossen werden.
an hat zwei Fenster/Tabpages mit unterschiedlichen Buffern offen. Der Puffer aus Fenster/Tab 2 soll in Fenster 1 als Split geöffnet werden, danach soll das ursprüngliche Fenster/Tab 2 geschlossen werden.

`:ls` oder `:echo bufnr('%')`, Horizontaler Split: `:sbuffer N` Vertikaler Split: `:vert sbuffer N`

- plattformneutrales Zusammenfügen von Pfadsegmenten
```lua
-- Joins path components with the correct separator on any OS.
local p = vim.fs.joinpath("home", "user", "project")  -- e.g. "home/user/project"
```


## Groß/Kleinschreibung

| Befehl              | Wirkung                                      |
| ------------------- | -------------------------------------------- |
| \~                  | Zeichen unter dem Cursor umschalten (toggle) |
| gu l                | Zeichen unter dem Cursor in klein            |
| gU l                | Zeichen unter dem Cursor in groß             |
| guw / gUw           | Wort in klein / groß                         |
| guu / gUU           | Zeile in klein / groß                        |
| v{Markierung} u / U | Markierte Auswahl in klein / groß            |

## Pfad des aktuellen Buffer ausgeben

Kommandozeile (Ex) — direkte Einzeiler
* `:echo expand('%:p')`
  Erläutert: Gibt den absoluten Pfad des aktuellen Buffers aus; leer bei unbenannten Buffern.
* `:echo fnamemodify(expand('%'), ':p')`
  Erläutert: Gleichwertig, explizit über `fnamemodify`.
* `:echo fnamemodify(@%, ':p')`
  Erläutert: Verwendet das Dateinamen-Register `%`.
* `:echo resolve(expand('%:p'))`
  Erläutert: Wie oben, aber inklusive Auflösung von Symlinks auf den Realpfad.
* `:echo expand('%:p:h')`
  Erläutert: Nur das Verzeichnis (Head) des absoluten Pfads.
* `:echo expand('%:p:t')`
  Erläutert: Nur der Dateiname (Tail) ohne Verzeichnis.
* Hinweis: In Terminal-/Hilfe-/Quickfix-/Plugin-Buffern kann der Name „term://…“, „\[No Name]“ oder ein Schema sein; es existiert dann ggf. kein echter Dateipfad.

Vimscript — robuste Varianten (als Einzeiler und Helfer)
* Einzeiler (wie oben, in Skripten/mappings einsetzbar):
  `echo expand('%:p')`
  `echo fnamemodify(bufname('%'), ':p')`
  `echo resolve(fnamemodify(expand('%'), ':p'))`

* Alternativen über `getbufinfo()` (liefert immer einen String, ggf. leer):
  `echo fnamemodify(getbufinfo(bufnr('%'))[0].name, ':p')`

Lua — Einzeiler, realpath, und User-Command
* Einzeiler:
```lua
-- Absolute path via Vim's expand (handles modifiers like :p)
print(vim.fn.expand("%:p"))

-- Absolute path from buffer name (0 = current buffer)
print(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p"))

-- Resolve symlinks to a real path (Neovim 0.10+: vim.uv; older: vim.loop)
do
  local name = vim.api.nvim_buf_get_name(0)                 -- may be empty
  local abs  = vim.fn.fnamemodify(name, ":p")               -- absolute path
  local real = (vim.uv or vim.loop).fs_realpath(abs) or abs -- resolve symlinks if possible
  print((real ~= "" and real) or "[No Name]")
end
```

Wichtige Hinweise
* Unbenannte Buffer haben keinen Pfad; die oben gezeigten robusten Varianten geben dann bewusst „\[No Name]“ aus.
* In Terminal-, Hilfe-, Quickfix- oder plugin-spezifischen Buffern ist der „Name“ oft kein Dateipfad (z. B. `term://…`, `man://…`). In solchen Fällen ist keine Dateisystem-Auflösung möglich; es wird der Buffer-Name ausgegeben.
* `resolve()` (Vimscript) und `vim.uv.fs_realpath()` (Lua) sind die geeigneten Wege, um Symlinks aufzulösen.

## tabs

Tab öffnen: Datei unter dem Cursor

| Tasten/Befehl | Modus  | Count | Beschreibung                                                              | Beispiel                                                 |
| ------------- | ------ | ----- | ------------------------------------------------------------------------- | -------------------------------------------------------- |
| CTRL-W gf     | Normal | –     | Öffnet einen neuen Tab und editiert die Datei unter dem Cursor.           | In einem Include-Pfad auf `foo/bar.c` stehen → CTRL-W gf |
| CTRL-W gF     | Normal | –     | Wie oben, zusätzlich Sprung zur nachgestellten Zeilennummer (`file:123`). | Cursor auf `main.c:42` → CTRL-W gF                       |


Tabnavigation und Übersicht

| Tasten/Befehl | Modus  | Count | Wirkung                                                                                    | Beispiel                    |
| ------------- | ------ | ----- | ------------------------------------------------------------------------------------------ | --------------------------- |
| gt            | Normal | {N}   | Nächster Tab; mit Count direkt zu Tab {N} (1-basiert).                                     | `3gt` springt zu Tab 3      |
| gT            | Normal | {N}   | Voriger Tab; mit Count N Tabs zurück (wrap-around).                                        | `2gT` geht zwei Tabs zurück |
| :tabn \[N]    | Ex     | \[N]  | Nächster Tab oder zu Tab {N}.                                                              | `:tabnext 5`                |
| :tabN \[N]    | Ex     | \[N]  | Voriger Tab oder N Tabs zurück.                                                            | `:tabN 2`                   |
| :tabfir       | Ex     | –     | Zum ersten Tab.                                                                            | `:tabfirst`                 |
| :tabl         | Ex     | –     | Zum letzten Tab.                                                                           | `:tablast`                  |
| :tabo\[!]     | Ex     | –     | Alle anderen Tabs schließen (mit `!` trotz geänderter Buffer).                             | `:tabonly!`                 |
| :tabs         | Ex     | –     | Liste aller Tabs und enthaltenen Fenster (`>` aktuelles Fenster, `+` modifizierte Buffer). | `:tabs`                     |

Tabreihenfolge ändern

| Befehl     | Bedeutung                                                                      | Beispiel                 |
| ---------- | ------------------------------------------------------------------------------ | ------------------------ |
| :tabm \[N] | Aktuellen Tab hinter Tab N schieben; `0` = ganz nach vorne; ohne N = ans Ende. | `:tabmove 0`, `:tabmove` |
| :tabm +N   | Aktuellen Tab N Positionen nach rechts.                                        | `:tabmove +2`            |
| :tabm -N   | Aktuellen Tab N Positionen nach links.                                         | `:tabmove -1`            |
| :0tabmove  | Kurzform: an den Anfang.                                                       | `:0tabmove`              |
| :\$tabmove | Kurzform: ans Ende.                                                            | `:$tabmove`              |

Neuen Tab mit Datei öffnen

| Befehl  | Syntax                                      | Wirkung                                               | Hinweise/Optionen                                                                                               | Beispiel                           |
| ------- | ------------------------------------------- | ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| :tabe   | :\[count]tabe\[dit] \[++opt] \[+cmd] {file} | Öffnet neuen Tab und editiert {file}.                 | `++opt` z. B. `++enc=utf-8`, `++ff=unix`; `+cmd` führt Ex-Befehl nach dem Öffnen aus (z. B. `+99` zu Zeile 99). | `:tabe +99 ++enc=utf-8 src/main.c` |
| :tabnew | :\[count]tabnew \[++opt] \[+cmd] {file}     | Wie `:tabe`; ohne {file} leerer Buffer.               | Count setzt die Einfügeposition des neuen Tabs (siehe unten `:tab`).                                            | `:tabnew README.md`                |
| :tabf   | :\[count]tabf\[ind] \[++opt] \[+cmd] {file} | Findet {file} in `'path'` und öffnet es im neuen Tab. | Nutzt `'path'`/Globbing; Abkürzung `:tabf`.                                                                     | `:tabf utils.lua`                  |

`:tab`-Modifier für beliebige Befehle

| Form               | Bedeutung                                                                                                                                                                                                                                                       | Beispiel                                                                                                                    |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| :\[count]tab {cmd} | Führt `{cmd}` aus; wenn dabei ein neues Fenster entstünde, wird stattdessen ein neuer Tab geöffnet. Ohne Count erscheint der neue Tab rechts neben dem aktuellen; mit Count kommt er hinter Tab {count}. `:0tab {cmd}` öffnet den neuen Tab an erster Position. | `:tab split` (aktuellen Buffer in neuem Tab), `:0tab help gt` (Help im ersten Tab), `:tab terminal` (Terminal in neuem Tab) |

Typische `++opt`/`+cmd` Beispiele

| Option                | Beschreibung                                   | Beispiel                      |
| --------------------- | ---------------------------------------------- | ----------------------------- |
| ++enc={encoding}      | Erzwingt Dateikodierung beim Öffnen.           | `:tabe ++enc=utf-8 file.txt`  |
| ++ff={unix\|dos\|mac} | Erzwingt Fileformat (Zeilenenden).             | `:tabnew ++ff=unix script.sh` |
| +{line}               | Cursor nach dem Laden zu Zeile {line}.         | `:tabe +120 main.c`           |
| +{Ex-Befehl}          | Führt beliebigen Ex-Befehl nach dem Laden aus. | `:tabe +'/TODO' src/app.lua`  |

---

## `cmp`, ``nvim-cmp` & `blink`

### eingebautes neovim (popup-menu / ins-completion)

| Taste         | Aktion                                                        |
| ------------- | ------------------------------------------------------------- |
| <C-n> / <C-p> | Nächstes / vorheriges Match im Popup-Menü                     |
| <C-y>         | Auswahl annehmen und Completion beenden                       |
| <C-e>         | Completion abbrechen und ursprünglichen Text wiederherstellen |
| <C-x><C-o>    | Omni-Completion (meist LSP)                                   |
| <C-x><C-n>    | Keywords aus aktuellem Buffer                                 |
| <C-x><C-k>    | Wörter aus 'dictionary'                                       |
| <C-x><C-t>    | Wörter aus 'thesaurus'                                        |
| <C-x><C-f>    | Dateinamen                                                    |
| <C-x>\<C-]>   | Tags                                                          |
| <C-x><C-i>    | Keywords aus Include-Dateien                                  |
| <C-x><C-d>    | Definitionen/Makros                                           |
| <C-x><C-l>    | Ganze Zeilen                                                  |
| <C-x><C-v>    | Vim-Befehle/Argumente                                         |
| <C-x><C-r>    | Inhalte aus Registern (Wörter)                                |
| <C-x><C-s>    | Rechtschreibvorschläge                                        |
| <C-x><C-z>    | Completion stoppen (ohne Textänderung)                        |

Hinweise: <C-y>/<C-e> sind die Standardtasten zum Annehmen/Abbrechen; Details siehe Hilfe zu complete\_CTRL-Y/complete\_CTRL-E. Die obigen <C-x>-Kombinationen sind die eingebaute Trigger-Matrix. ([Neovim][1])

### nvim-cmp (plugin) – typische preset.insert-Belegung laut README

| Taste     | Befehl (Lua)                           | Wirkung                                                                     |
| --------- | -------------------------------------- | --------------------------------------------------------------------------- |
| <C-b>     | cmp.mapping.scroll\_docs(-4)           | Doku nach oben scrollen                                                     |
| <C-f>     | cmp.mapping.scroll\_docs(4)            | Doku nach unten scrollen                                                    |
| <C-Space> | cmp.mapping.complete()                 | Menü anzeigen/triggern                                                      |
| <C-e>     | cmp.mapping.abort()                    | Abbrechen/Schließen                                                         |
| <CR>      | cmp.mapping.confirm({ select = true }) | Ausgewähltes Item bestätigen (mit select=true wird ggf. das erste genommen) |

Anmerkung: Die `cmp.mapping.preset.*`-Presets sind vorgefertigte Beispiele und können sich ohne Ankündigung ändern; offiziell wird empfohlen, Keymaps selbst zu definieren. Quelle: README. ([GitHub][2])

### blink.cmp (plugin) – Standard-Preset 'default'

| Taste         | blink-Command(s)                                     | Wirkung                                                   |
| ------------- | ---------------------------------------------------- | --------------------------------------------------------- |
| <C-space>     | show → show\_documentation → hide\_documentation     | Menü zeigen, Doku ein/aus                                 |
| <C-e>         | hide                                                 | Menü verbergen                                            |
| <C-y>         | select\_and\_accept                                  | Auswahl (oder erstes Item) einfügen                       |
| <Up>/<Down>   | select\_prev / select\_next → fallback               | Auswahl wechseln (Pfeile), sonst nächste/normale Belegung |
| <C-p>/<C-n>   | select\_prev / select\_next → fallback\_to\_mappings | Wie oben, aber bevorzugt eigene Mappings wenn kein Menü   |
| <C-b>/<C-f>   | scroll\_documentation\_up / \_down                   | Doku scrollen                                             |
| <Tab>/<S-Tab> | snippet\_forward / snippet\_backward → fallback      | Snippet-Sprünge; sonst nächstes Mapping                   |
| <C-k>         | show\_signature → hide\_signature → fallback         | Signaturhilfe ein/aus                                     |

Alternativ-Presets: 'enter' (bestätigt mit <CR>), 'super-tab' (Tab bestätigt/steuert). Vollständige Liste der Commands siehe nächste Tabelle. ([cmp.saghen.dev][3])

blink.cmp – wichtige commands (API)

| Command                                   | Bedeutung                                                             |
| ----------------------------------------- | --------------------------------------------------------------------- |
| show                                      | Menü anzeigen (optional Anbieter filtern)                             |
| show\_and\_insert                         | Menü zeigen und erstes Item einsetzen (bei auto\_insert)              |
| hide / cancel                             | Verbergen / Auto-Insert zurücksetzen + verbergen                      |
| accept / accept\_and\_enter               | Aktuelles Item annehmen / annehmen + <CR> einspeisen                  |
| select\_and\_accept                       | Aktuelles oder erstes Item annehmen                                   |
| select\_accept\_and\_enter                | Wie oben + <CR> einspeisen                                            |
| select\_prev / select\_next               | Auswahl wechseln (optional on\_ghost\_text / auto\_insert steuern)    |
| insert\_prev / insert\_next               | Vor/Nachstes Item direkt einfügen (triggert Completion falls nötig)   |
| show\_documentation / hide\_documentation | Doku ein/aus                                                          |
| scroll\_documentation\_up / \_down        | Doku scrollen (Default ±4 Zeilen)                                     |
| show\_signature / hide\_signature         | Signaturhilfe ein/aus                                                 |
| snippet\_forward / snippet\_backward      | Snippet-Placeholder vor/zurück                                        |
| fallback / fallback\_to\_mappings         | Nächstes Nicht-blink-Mapping / explizit nur zu Mappings fallen lassen |

---

## loclist & quickfixlist

| Eigenschaft              | **Location List**                                   | **Quickfix-List**                                  |
| ------------------------ | --------------------------------------------------- | -------------------------------------------------- |
| **Geltungsbereich**      | Nur für das aktuelle Fenster/Buffer                 | Global für alle Fenster/Buffer                     |
| **Mehrere Listen**       | Ja, jede Fenster-Instanz kann eigene haben          | Nein, nur eine globale Liste                       |
| **Typische Nutzung**     | Diagnosen, Linter-Fehler, Tests im aktuellen Buffer | Compiler-Fehler, Suchergebnisse, globale Diagnosen |
| **Öffnen**               | `:lopen` / `:lwindow`                               | `:copen` / `:cwindow`                              |
| **Schließen**            | `:lclose`                                           | `:cclose`                                          |
| **Navigation**           | `:lnext`, `:lprev`, `:lfirst`, `:llast`, `:lN`      | `:cnext`, `:cprev`, `:cfirst`, `:clast`, `:cN`     |
| **Befüllen (Beispiele)** | `:lua vim.diagnostic.setloclist()`                  | `:lua vim.diagnostic.setqflist()`                  |
| **Manuell befüllen**     | `:laddfile`, `:laddexpr`                            | `:caddfile`, `:caddexpr`                           |
| **Plugins**              | Z. B. LSP, Test-Runner                              | Z. B. `:make`, `:grep`, Telescope, fzf             |

| Keymap           | Modes | Befehl/Aktion                            | Beschreibung                        |
| ---------------- | ----- | ---------------------------------------- | ----------------------------------- |
| **loclist**      |       |                                          |                                     |
| `<leader>ls`     | n     | `vim.diagnostic.setloclist()`            | [Loclist] Diagnostic loclist        |
| `<leader>lo`     | n     | `vim.diagnostic.setloclist()` → `:lopen` | [Loclist] Diagnostic loclist (open) |
| `[l`             | n     | `vim.diagnostic.goto_prev()`             | [Loclist] Prev Diagnostic           |
| `]l`             | n     | `vim.diagnostic.goto_next()`             | [Loclist] Next Diagnostic           |
| `<leader>lf`     | n     | `vim.diagnostic.open_float()`            | [Loclist] Diagnostic popup          |
| `<leader>xl`     | n     | `:Trouble loclist`                       | [Trouble] Location List             |
| ------------     | ----- | -------------------------------------    | --------------------------------    |
| **quickfixlist** |       |                                          |                                     |
| `<leader>qs`     | n     | `:vim.diagnostic.setqflist`              | [Quickfix] Set Quickfix List        |
| `[q`             | n     | `:cprev()`                               | [Quickfix] Prev Diagnostic          |
| `]q`             | n     | `:cnext()`                               | [Quickfix] Next Diagnostic          |
| `<leader>fzn`    | n     | `:FzfLua quickfix_stack`                 | [Quickfix] Quickfix Stack           |
| `<leader>fqf`    | n     | `:FzfLua quickfix`                       | [Quickfix] Quickfix                 |
| `<leader>xq`     | n     | `:Trouble qflist`                        | [Quickfix] Quickfix List            |

---

## Expand flags

| Ausdruck | Beschreibung                                                | Beispiel (für `~/projects/foo/bar.txt`) |
| -------- | ----------------------------------------------------------- | --------------------------------------- |
| `%`      | Dateiname relativ zum aktuellen Arbeitsverzeichnis (`:pwd`) | `projects/foo/bar.txt`                  |
| `%:p`    | Absoluter Pfad zur Datei                                    | `/home/user/projects/foo/bar.txt`       |
| `%:t`    | Nur Dateiname (tail)                                        | `bar.txt`                               |
| `%:p:h`  | Absoluter Pfad zum Verzeichnis der Datei (head)             | `/home/us0:er/projects/foo`             |
| `%:h`    | Relativer Verzeichnisname der Datei                         | `projects/foo`                          |
| `%:r`    | Dateiname ohne Endung (root)                                | `projects/foo/bar`                      |
| `%:e`    | Dateiendung (extension)                                     | `txt`                                   |
| `%:p:t`  | Nur Dateiname, absolut (tail des Pfads)                     | `bar.txt`                               |

`:echo expand('%:p')` - nvim
`print(vim.fn.expand("%:p"))` - lua
`:let @+ = expand('%:p')` - In Zwischenablage kopieren

---

## Zeilenbereiche (`[range]`) für Ex-Befehle

| Symbol      | Bedeutung                                                           |
| ----------- | ------------------------------------------------------------------- |
| `.`         | Aktuelle Zeile                                                      |
| `$`         | Letzte Zeile der Datei                                              |
| `%`         | Ganze Datei (Alias für `1,$`)                                       |
| `'<`        | Start der zuletzt **visuell markierten** Auswahl                    |
| `'>`        | Ende der zuletzt **visuell markierten** Auswahl                     |
| `/pattern/` | Nächste Zeile, die **pattern** enthält                              |
| `?pattern?` | Vorherige Zeile, die **pattern** enthält                            |
| `+N`        | **N Zeilen weiter unten** ab dem vorhergehenden Range (z. B. `.+3`) |
| `-N`        | **N Zeilen vorher** ab dem vorhergehenden Range (z. B. `.-2`)       |
| `;`         | Trennt zwei Ranges mit **kontextbezogener Auswertung**              |
| `,`         | Trennt zwei Ranges mit **absoluter Auswertung**                     |

* `'<` → Die Position, an der man den **visuellen Modus** gestartet hat
* `'>` → Die Position, an der man die visuelle Auswahl **beendet** hat
* `:'<,'>` → Wendet einen Befehl auf **den markierten Bereich** an (z. B. per `V`, `v`, `Ctrl-v`)

Diese Bereiche können in fast allen Ex-Befehlen (z. B. `:s`, `:d`, `:y`, `:m`, `:t`, usw.) verwendet werden.

| Ausdruck          | Bedeutung                                     |
| ----------------- | --------------------------------------------- |
| `:%`              | Ganze Datei (`:1,$`)                          |
| `1,10`            | Zeilen 1 bis 10                               |
| `'a,'b`           | Bereich zwischen Markierung `a` und `b`       |
| `'<,'>`           | visuelle Auswahl (z. B. per `V`, dann `:`)    |
| `.,$`             | von aktueller Zeile bis zum Ende              |
| ----------------- | --------------------------------------------- |
| `:10s/.../.../`   | Nur **Zeile 10** bearbeiten                   |
| `:5,10s/.../.../` | Von **Zeile 5 bis 10**                        |
| `:1,$s/.../.../`  | Von **erster bis letzter** Zeile (`$`)        |
| `:.`              | **Aktuelle Zeile**                            |
| `:-2`             | **Zwei Zeilen vor** aktueller Zeile           |
| `:+3`             | **Drei Zeilen nach** aktueller Zeile          |
| `:.,+2d`          | **Lösche** aktuelle + **zwei weitere Zeilen** |
| `:.-1s/.../.../`  | **Ersetze in Zeile vor** der aktuellen        |

| Beispiel           | Bedeutung                                         |
| ------------------ | ------------------------------------------------- |
| `:'<,'>center`     | Zentriert den Text im gewählten Bereich           |
| `:'<,'>left`       | Linksbündig ausrichten                            |
| `:'<,'>right`      | Rechtsbündig ausrichten                           |
| `:'<,'>sort`       | Zeilen alphabetisch sortieren                     |
| `:'<,'>!column -t` | Externes Kommando (z. B. für Tabellenausrichtung) |
| `:'<,'>g/^$/d`     | Leere Zeilen im markierten Bereich löschen        |

| Befehl               | Zweck                                             |
| -------------------- | ------------------------------------------------- |
| `:'<,'>retab`        | Tabs in Spaces umwandeln (oder umgekehrt)         |
| `:'<,'>normal ggVG=` | Reindenten des markierten Bereichs                |
| `:'<,'>TOhtml`       | In HTML exportieren (mit Syntax)                  |
| `:'<,'>!sort`        | Sortieren via Shell                               |
| `:'<,'>!awk ...`     | Live-Verarbeitung mit `awk`, `sed`, `column` usw. |

---

## Suchmuster in `:substitute` und `:global`

| Pattern   | Bedeutung                                        |
| --------- | ------------------------------------------------ |
| `foo`     | Alle Vorkommen von `"foo"`                       |
| `\<foo\>` | **Exaktes Wort** „foo“                           |
| `\<`      | **Wortanfang**                                   |
| `\>`      | **Wortende**                                     |
| `\v...`   | Aktiviert „very magic“-Modus (regex wie in Perl) |

```vim
:1,$s/\<cache\>/Cache/g
```
→ ersetzt nur das **Wort „cache“**, aber nicht z. B. „cached“ oder „supercache“.

---

## `wincmd`

- wincmd entspricht in Normal-Mode der Sequenz <C-w> gefolgt von einem Buchstaben (oder `:wincmd X` auf der Befehlszeile)
- Viele Befehle akzeptieren eine Count-Angabe (z. B. 5<C-w>+).

**Navigation zwischen Fenstern:**

| Befehl    | Wirkung                          | Hinweise/Beispiele                  |
| --------- | -------------------------------- | ----------------------------------- |
| `<C-w> h` | Fokus nach links                 | Analog: j/k/l für unten/oben/rechts |
| `<C-w> j` | Fokus nach unten                 |                                     |
| `<C-w> k` | Fokus nach oben                  |                                     |
| `<C-w> l` | Fokus nach rechts                |                                     |
| `<C-w> w` | Nächstes Fenster (zyklisch)      | Alias: <C-w><C-w>                   |
| `<C-w> W` | Vorheriges Fenster (rückwärts)   | Zyklisch rückwärts                  |
| `<C-w> p` | Vorher genutztes Fenster         | „previous window“                   |
| `<C-w> t` | Fenster links-oben fokussieren   | „top-left“                          |
| `<C-w> b` | Fenster rechts-unten fokussieren | „bottom-right“                      |
| `<C-w> P` | Zum Preview-Fenster springen     | Wechselt nur, erstellt keins        |

**Fenster erzeugen/öffnen:**

| Befehl    | Wirkung                                      | Hinweise/Beispiele                  |
| --------- | -------------------------------------------- | ----------------------------------- |
| `<C-w> s` | Horizontal split mit gleichem Buffer         | Entspricht \:split                  |
| `<C-w> v` | Vertikaler Split mit gleichem Buffer         | Entspricht \:vsplit                 |
| `<C-w> n` | Neuer leerer Buffer im Split                 | Entspricht \:new                    |
| `<C-w> ^` | Alternativen Buffer im Split öffnen          | Entspricht \:split #                |
| `<C-w> f` | Datei unter Cursor im Split öffnen           | Pfad muss unter Cursor stehen       |
| `<C-w> F` | Wie <C-w> f, versucht Zeilennummer zu nutzen | z. B. „file:123“                    |
| `<C-w> ]` | Split und zum Tag unter Cursor springen      | Tag-Navigation                      |
| `<C-w> }` | Tag unter Cursor im Preview-Fenster zeigen   | Erstellt Preview-Fenster bei Bedarf |

**Fenster verschieben/umordnen:**

| Befehl    | Wirkung                                    | Hinweise/Beispiele                |
| --------- | ------------------------------------------ | --------------------------------- |
| `<C-w> K` | Aktuelles Fenster ganz nach oben           | Orientiert zu horizontal oben     |
| `<C-w> J` | Aktuelles Fenster ganz nach unten          |                                   |
| `<C-w> H` | Aktuelles Fenster ganz nach links          | Orientiert zu vertikal links      |
| `<C-w> L` | Aktuelles Fenster ganz nach rechts         |                                   |
| `<C-w> r` | Fensteranordnung rotieren (vorwärts)       | Zyklisches Rotieren               |
| `<C-w> R` | Fensteranordnung rotieren (rückwärts)      | Gegenrichtung                     |
| `<C-w> x` | Mit Nachbarfenster Position tauschen       | Tauscht Layout-Positionen         |
| `<C-w> T` | Aktuelles Fenster in neuen Tab verschieben | Kein Duplikat; Fenster „zieht um“ |

**Größe ändern:**

| Befehl     | Wirkung                               | Hinweise/Beispiele                      |
| ---------- | ------------------------------------- | --------------------------------------- |
| `<C-w> =`  | Alle Fenster gleich groß machen       | „equalize“                              |
| `<C-w> _`  | Maximale Höhe für aktuelles Fenster   | Count setzt absolute Höhe: 20<C-w>\_    |
| `<C-w> \|` | Maximale Breite für aktuelles Fenster | Count setzt absolute Breite: 100<C-w>\| |
| `<C-w> +`  | Höhe erhöhen                          | Mit Count: 5<C-w>+                      |
| `<C-w> -`  | Höhe verringern                       | Mit Count                               |
| `<C-w> >`  | Breite erhöhen                        | Mit Count                               |
| `<C-w> <`  | Breite verringern                     | Mit Count                               |

**Schließen/Reduzieren:**

| Befehl    | Wirkung                          | Hinweise/Beispiele                                    |
| --------- | -------------------------------- | ----------------------------------------------------- |
| `<C-w> q` | Aktuelles Fenster schließen/quit | Entspricht \:quit; schließt ggf. Tab/Neovim           |
| `<C-w> c` | Aktuelles Fenster schließen      | Entspricht \:close; schlägt beim letzten Fenster fehl |
| `<C-w> o` | Nur aktuelles Fenster behalten   | Entspricht \:only                                     |
| `<C-w> z` | Preview-Fenster schließen        | Entspricht \:pclose                                   |

**Befehlszeile-Varianten von wincmd:**

| Befehl                    | Wirkung                          | Hinweise/Beispiele           |
| ------------------------- | -------------------------------- | ---------------------------- |
| `:wincmd h/j/k/l`         | Entspricht <C-w> h/j/k/l         | Für Skripte/Commands         |
| `:wincmd H/J/K/L`         | Fenster an Kante verschieben     | Wie die Normal-Mode-Pendants |
| `:wincmd =/\_/\|/+/-/>/<` | Größenänderungen                 | Entspricht <C-w> …           |
| `:wincmd T`               | Fenster in neuen Tab verschieben | Wie <C-w> T                  |

---

## `Registers`

| Befehl | Funktion                               |
| ------ | -------------------------------------- |
| `"ayy` | yanke die aktuelle Zeile in Register a |
| `"ap`  | paste aus Register a                   |
| `"by`  | Kopiert in Register b                  |
| `"bp`  | paste aus Register b                   |
| `"+y`  | In System-Clipboard kopieren           |
| `"+p`  | Aus System-Clipboard einfügen          |


---

## `ps` cli-tool

* Zeigt **laufende Prozesse** mit PID, CPU-, RAM-Verbrauch, Benutzer, Kommando usw.
* Ermöglicht Filterung und Sortierung nach verschiedenen Kriterien.
* Dient zur Kontrolle von Hintergrundprozessen, Systemdiensten oder Containern.

```sh
ps -eo pid,comm,%mem,%cpu --sort=-%mem | head  # → Zeigt die Top-RAM-Prozesse im System (Speicherintensiv).
```

**Häufig verwendete Optionen (GNU/Linux-Stil):**
| Option       | Bedeutung                                                                  |
| ------------ | -------------------------------------------------------------------------- |
| `a`          | Zeigt Prozesse **aller Benutzer** (nicht nur eigene)                       |
| `u`          | **Benutzerfreundliche Ausgabe** mit USER, CPU, MEM usw.                    |
| `x`          | Zeigt auch Prozesse **ohne zugeordnetes Terminal** (z. B. Daemons)         |
| `-e`, `-A`   | Zeigt **alle Prozesse** (äquivalent zu `aux` ohne Formatierung)            |
| `-o FORMAT`  | Gibt **nur bestimmte Spalten** aus (z. B. `-o pid,comm,%mem`)              |
| `-p PID`     | Zeigt **nur den Prozess mit gegebener PID**                                |
| `--sort=KEY` | Sortiert nach beliebigen Spalten (z. B. `--sort=-%mem` für RAM absteigend) |
| `-C NAME`    | Filtert Prozesse mit **exaktem Kommandonamen**                             |

**Typische Beispiele:**
```sh
ps aux                                 # Alle Prozesse mit USER, CPU, MEM, COMMAND
ps -ef                                 # System-V-Style mit vollständigen Argumenten
ps aux | grep nginx                    # Filtert alle nginx-Prozesse
ps -u $USER                            # Zeigt Prozesse des aktuellen Benutzers
ps -p 1234                             # Zeigt Prozess mit PID 1234
ps -o pid,comm,%cpu,%mem --sort=-%mem # Sortiert Prozesse nach RAM-Nutzung
```

| Spalte    | Bedeutung                                |
| --------- | ---------------------------------------- |
| `USER`    | Prozessbesitzer                          |
| `PID`     | Prozess-ID                               |
| `%CPU`    | CPU-Nutzung seit Start                   |
| `%MEM`    | RAM-Anteil am Gesamtsystem               |
| `VSZ`     | Virtueller Speicher in KB                |
| `RSS`     | Physischer Speicherverbrauch (RAM) in KB |
| `TTY`     | Terminal zugeordnet (falls vorhanden)    |
| `STAT`    | Status (z. B. S = Sleeping, R = Running) |
| `COMMAND` | Ausgeführtes Kommando mit Argumenten     |

**Spalten gezielt anzeigen mit `-o`:**
```sh
ps -o pid,comm,%mem,%cpu --sort=-%cpu   # Zeigt nur PID, Name, RAM und CPU, sortiert nach CPU-Auslastung.
```

**Kombination mit anderen Tools:**
```sh
ps aux | grep postgres                      # Filter für postgres-Prozesse
ps -eo pid,%cpu,comm | sort -k2 -r          # Nach CPU-Auslastung sortieren
watch -n 2 'ps -eo pid,comm,%mem'           # RAM-Verbrauch alle 2 Sekunden anzeigen
```

**Prozessstatus (STAT-Spalte)**
| Kürzel | Bedeutung                                          |
| ------ | -------------------------------------------------- |
| `R`    | Running – Prozess läuft aktiv                      |
| `S`    | Sleeping – wartet auf Ereignis                     |
| `D`    | Uninterruptible Sleep – blockiert, z. B. I/O       |
| `Z`    | Zombie – beendet, aber noch nicht aus Prozessliste |
| `T`    | Stopped – z. B. durch `SIGSTOP` angehalten         |
| `+`    | Prozess gehört zu einer Job-Kontrolle (Foreground) |

**Unterschiede: `ps aux` vs. `ps -ef`:**
| Merkmal             | `ps aux`                       | `ps -ef`                               |
| ------------------- | ------------------------------ | -------------------------------------- |
| Ursprung            | BSD                            | UNIX System V                          |
| Spaltenstruktur     | USER-freundlich                | POSIX-konform                          |
| Argumentdarstellung | Kürzer, manchmal abgeschnitten | Volle Argumentliste                    |
| Gängigkeit          | Häufiger in Linux-Umgebungen   | Häufiger in Unix- / Solaris-Umgebungen |

---

## `sort` cli-tool

| Option         | Bedeutung                                                          | Beispiel                              |
| -------------- | ------------------------------------------------------------------ | ------------------------------------- |
| *(leer)*       | Alphabetische Sortierung (z. B. `2 < 10`)                          | `sort namen.txt`                      |
| `-n`           | Numerische Sortierung (z. B. `2 < 10`)                             | `sort -n zahlen.txt`                  |
| `-r`           | Umgekehrte Reihenfolge (absteigend)                                | `sort -r namen.txt`                   |
| `-k N`         | Nach Feld `N` sortieren (z. B. `-k2` für zweite Spalte)            | `sort -k2 namen.csv`                  |
| `-t CHAR`      | Spaltentrenner setzen (z. B. `-t,` für CSV)                        | `sort -t, -k2 daten.csv`              |
| `-u`           | Duplikate entfernen (unique lines)                                 | `sort -u namen.txt`                   |
| `-V`           | "Version sort": 1.9 < 1.10 < 2.0                                   | `sort -V versionen.txt`               |
| `-M`           | Monatlich sortieren (Jan, Feb, ...)                                | `sort -M monate.txt`                  |
| `-b`           | Leerzeichen am Zeilenanfang ignorieren                             | `sort -b daten.txt`                   |
| `-f`           | Groß-/Kleinschreibung ignorieren (case-insensitive)                | `sort -f namen.txt`                   |
| `-o DATEI`     | Sortiertes Ergebnis in Datei schreiben                             | `sort -o sortiert.txt unsortiert.txt` |
| `--parallel=N` | N Kerne für parallele Sortierung verwenden (für große Dateien)     | `sort --parallel=4 große_datei.txt`   |
| `--stable`     | Stabile Sortierung (Reihenfolge gleicher Einträge bleibt erhalten) | `sort --stable -k2 daten.txt`         |

---

## `tr` cli-tool

| Option / Klasse     | Funktion / Ziel                                                 | Beispiel                     | Beschreibung                              |
| ------------------- | --------------------------------------------------------------- | ---------------------------- | ----------------------------------------- |
| *(keine Option)*    | Zeichen aus `SET1` durch `SET2` ersetzen                        | `tr 'abc' 'ABC'`             | Ersetzt `a→A`, `b→B`, `c→C`               |
| `-d`                | Zeichen aus `SET1` löschen                                      | `tr -d '\n'`                 | Entfernt Zeilenumbrüche                   |
| `-s`                | Mehrfache Zeichen aus `SET1` zu einem zusammenfassen            | `tr -s ' '`                  | Macht aus `"  a   b"` → `" a b"`          |
| `-c`                | Komplement: alle Zeichen **außer** `SET1` verwenden             | `tr -cd '[:print:]'`         | Nur druckbare Zeichen beibehalten         |
| `[:upper:]`         | Großbuchstaben (A–Z)                                            | `tr '[:upper:]' '[:lower:]'` | Wandelt Groß- in Kleinbuchstaben um       |
| `[:lower:]`         | Kleinbuchstaben (a–z)                                           | –                            | Wird mit `[:upper:]` kombiniert           |
| `[:digit:]`         | Ziffern (0–9)                                                   | `tr -d '[:digit:]'`          | Entfernt alle Zahlen                      |
| `[:space:]`         | Whitespace (Leerzeichen, Tab, ...)                              | –                            | Kann mit `-s` verwendet werden            |
| `[:alnum:]`         | Alphanumerisch (a–z, A–Z, 0–9)                                  | –                            | Nützlich mit `-d`, `-c`                   |
| `[:punct:]`         | Satzzeichen (.,;!?…)                                            | –                            | Kann mit `-d` oder `-c` kombiniert werden |
| Umlaute ersetzen    | Ersetzt Umlaute durch ASCII-nahe Zeichen                        | `tr 'äöü' 'aou'`             | Nützlich zur Vereinfachung von Text       |
| Groß- zu Kleinschr. | Wandelt Großbuchstaben in Kleinbuchstaben um                    | `tr 'A-Z' 'a-z'`             | ASCII-basiert (nicht UTF-8 aware!)        |
| Zeilenumbrüche weg  | Entfernt neue Zeilen                                            | `tr -d '\n'`                 | Kombiniert alle Zeilen in eine einzige    |
| Leerzeichen normal. | Führt mehrere aufeinanderfolgende Leerzeichen zu einem zusammen | `tr -s ' '`                  | Ideal nach unformatierten `cut`, `awk`    |
| Zahlen entfernen    | Entfernt alle Ziffern                                           | `tr -d '[:digit:]'`          | Kann z. B. Log-Zeilen anonymisieren       |

---

## `join` cli-tool

Verknüpft **zwei textbasierte Dateien** auf Basis eines **gemeinsamen Feldes** (Join-Key). Es ist vergleichbar mit einem SQL-„INNER JOIN“ für Zeilen aus zwei Dateien. `join` funktioniert **zeilenbasiert** und benötigt **sortierte** Eingabedateien nach dem Join-Feld.

| Option            | Bedeutung                                                               | Beispiel                         |
| ----------------- | ----------------------------------------------------------------------- | -------------------------------- |
| `-1 N`            | Spalte N in Datei 1 als Join-Schlüssel verwenden                        | `join -1 2 file1 file2`          |
| `-2 N`            | Spalte N in Datei 2 als Join-Schlüssel verwenden                        | `join -2 3 file1 file2`          |
| `-t CHAR`         | Trennzeichen setzen (Standard: Whitespace)                              | `join -t, file1 file2`           |
| `-o FORMAT`       | Bestimmt die Ausgabespalten                                             | `join -o 1.1,2.3 file1 file2`    |
| `-e STRING`       | Ersetzt fehlende Felder mit STRING                                      | `join -e "-" ...`                |
| `-a N`            | Gibt **alle Zeilen** aus Datei N aus, auch wenn kein Join-Match besteht | `join -a 1 file1 file2`          |
| `-v N`            | Gibt **nur nicht gematchte Zeilen** aus Datei N aus (Anti-Join)         | `join -v 2 file1 file2`          |
| `--check-order`   | Prüft, ob Eingabedateien sortiert sind                                  | `join --check-order file1 file2` |
| `--nocheck-order` | Deaktiviert Sortierprüfung (bei unsortierten Eingaben verwenden)        | `join --nocheck-order f1 f2`     |

```bash
Beispiel: Zwei CSV-Dateien zusammenführen: `:join -t',' -1 1 -2 1 users.csv scores.csv`
              1,Alice                 1,85              1,Alice,85
users.csv ->  2,Bob    scores.csv ->  2,91  Ausgabe ->  2,Bob,91
              3,Clara                 3,78              3,Clara,78
```
---

## `column` cli-tool

| Option / Ziel                      | Beschreibung                                           | Beispiel                      | Beispielausgabe / Bemerkung                  |
| ---------------------------------- | ------------------------------------------------------ | ----------------------------- | -------------------------------------------- |
| *(keine Option)*                   | Einfaches horizontales Layout                          | `ls                           | column`                                      | Zeigt Dateinamen in mehreren Spalten       |
| `-t`                               | Tabelle mit Spaltenausrichtung (nach Trennzeichen)     | `column -t -s',' daten.csv`   | CSV optisch aufbereiten                      |
| `-s <ZEICHEN>`                     | Spaltentrenner setzen (z. B. für `:` oder `,`)         | `column -t -s':' /etc/passwd` | Username + UID in Spalten                    |
| `-n`                               | Keine Kopfzeile erkennen (Header-Erkennung abschalten) | `column -t -n daten.csv`      | Verhindert Sonderbehandlung der ersten Zeile |
| `-c <ZAHL>`                        | Maximale Spaltenbreite                                 | `column -c 80`                | Zeilenumbruch nach max. 80 Zeichen           |
| `-x`                               | Horizontal auffüllen statt Spaltenweise                | `seq 1 10                     | column -x`                                   | Zeigt `1 2 3` ... statt Spalten            |
| `-o <ZEICHEN>`                     | Ausgabefeldtrenner setzen                              | `column -t -s',' -o '         | '`                                           | Nutzt Pipe als sichtbare Spaltenbegrenzung |
| CSV-Datei ausrichten               | CSV als Spalten anzeigen                               | `column -t -s',' csv.csv`     | Inhalt von `csv.csv` lesbar formatiert       |
| `/etc/passwd` lesbar formatieren   | Nur Name + UID anzeigen und schön formatieren          | `cut -d: -f1,3 /etc/passwd    | column -t -s ':'`                            | Username  UID                              |
| Zahlen in Spalten nebeneinander    | Zahlenfolge umwandeln in Zeilenweise                   | `seq 1 12                     | column`                                      | 1  2  3 ...                                |
| Pipes in Spalten umwandeln         | Pipe-getrennten String lesbar darstellen               | `echo "a                      | b                                            | c"                                         | column -t -s '                              | ' -o ' | '` | a | b | c |
| Unterschied `-t` vs `-x`           | `-t`: Tabellarisch / `-x`: zeilenorientiert            | `seq 1 6                      | column` vs. `seq 1 6                         | column -x`                                 | Unterschiedliche Darstellung je nach Option |
| Zeilen mit fester Breite umbrechen | Zeilen auf definierte Länge umbrechen                  | `command                      | column -c 50`                                | Spaltenumbrüche ab 50 Zeichen              |

---

## `paste` cli-tool

Das CLI-Tool `paste` kombiniert **Zeileninhalte mehrerer Dateien spaltenweise** (Standardmodus) oder **zeilenweise hintereinander** (Serial-Modus).

```sh
paste [OPTION]... [DATEI1 [DATEI2]...]
```

* `-` steht für `stdin`
* Standard-Trennzeichen: **Tab**
* Dateien **sollten gleich viele Zeilen** haben

**Optionen & Beispiele:**
| Option     | Wirkung                                    | Beispiel            |                        |
| ---------- | ------------------------------------------ | ------------------- | ---------------------- |
| `-d','`    | Komma als Trennzeichen                     | `paste -d',' f1 f2` |                        |
| `-s`       | Serial: dateiweise hintereinander          | `paste -s file.txt` |                        |
| `-`        | `stdin` explizit                           | \`cat names         | paste - - scores.txt\` |
| kombiniert | aus `stdin` und Datei spaltenweise mischen | `paste - file.txt`  |                        |

**Verhaltensmodi:**
| Modus         | Beschreibung                                        | Beispiel            |
| ------------- | --------------------------------------------------- | ------------------- |
| Standard      | Zeilenweise spaltenweise (default)                  | `paste a.txt b.txt` |
| Serial (`-s`) | Zeilen einer Datei hintereinander (jede in 1 Zeile) | `paste -s list.txt` |

**Visualisiertes Beispiel:**

```bash
paste file1.txt file2.txt
# result:
file1 -> Alice   file2 -> 90    ⇒  Alice    90
        Bob               85        Bob      85
```

**Nützliche Kombinationen:**
| Ziel                                   | Befehl                             |                        |
| -------------------------------------- | ---------------------------------- | ---------------------- |
| CSV-Ausgabe                            | `paste -d',' names.csv scores.csv` |                        |
| Datei & stdin kombinieren              | \`cat id.txt                       | paste - - scores.txt\` |
| Spalten aus Datei extrahieren          | \`cut -f1 f.txt                    | paste - f2.txt\`       |
| Vorher sortieren                       | \`sort f1.txt                      | paste - f2.txt\`       |
| Serienweise alle Zeilen zusammenführen | `paste -s f.txt`                   |                        |

---

## `wsl process analyse` - cli-tools

**Empfohlene Kombination für Statusanalyse (PowerShell + WSL):**
```powershell
# PowerShell (Host):
Get-Process -Name podman
Get-Process -Name vmmemWSL

# WSL (Gast):
wsl --distribution podman-machine-default -- free -h
wsl --distribution podman-machine-default -- ps aux | grep conmon
wsl --distribution podman-machine-default -- top -b -n 1 | head -n 20
```

**PowerShell-Befehle (Host-seitig):**
| Befehl                       | Beschreibung                                                          | Beispielausgabe / Zweck                                           |                                                |
| ---------------------------- | --------------------------------------------------------------------- | ----------------------------------------------------------------- | ---------------------------------------------- |
| `wsl -l -v`                  | Zeigt alle installierten WSL-Distributionen inkl. Zustand und Version | Welche WSL-VM Podman nutzt                                        |                                                |
| `Get-Process -Name podman`   | Zeigt Speicher/CPU des Windows-Prozesses `podman.exe`                 | CLI-Prozess von Podman                                            |                                                |
| `Get-Process -Name vmmemWSL` | Zeigt Speicher/CPU der WSL2-VM (Podman/Docker/Nutzerdistros)          | RAM-/CPU-Zeiten der gesamten VM                                   |                                                |
| \`Get-Process                | Where-Object { $\_.Name -like "wsl\*" }\`                             | Listet alle Prozesse, die vom Windows-Subsystem for Linux stammen | Zeigt Host-bezogene WSL-Verwaltungskomponenten |
| \`Get-Process                | Where-Object { $\_.Name -like "*docker*" }\`                          | Zeigt Prozesse wie `dockerd.exe`, falls Docker Desktop läuft      | Vergleich mit Podman                           |

**WSL-Befehle (Gast-seitig, also innerhalb Podman-WSL):** Alle diese Befehle laufen mit:
```bash
wsl --distribution podman-machine-default -- <befehl>
```

**Container- und Systemnutzung:**
| Befehl        | Beschreibung                                                | Beispiel                                       |                                      |
| ------------- | ----------------------------------------------------------- | ---------------------------------------------- | ------------------------------------ |
| `free -h`     | Zeigt RAM-Nutzung im Container/VM (ähnlich `top`)           | `2.0Gi total, 150Mi used`                      |                                      |
| \`top -b -n 1 | head -n 20\`                                                | Zeigt laufende Prozesse, sortiert nach CPU/RAM | Schnappschuss der Auslastung         |
| `ps aux`      | Zeigt alle aktiven Prozesse inkl. Speicher- und CPU-Nutzung | Details zu Containerdiensten                   |                                      |
| \`ps aux      | grep podman\`                                               | Filtert Prozesse auf den Podman-API-Dienst     | z. B. `/usr/bin/podman ...`          |
| \`ps aux      | grep conmon\`                                               | Zeigt Prozesse, die Container verwalten        | z. B. `conmon` als Container-Wrapper |
| \`ps aux      | grep bash\`                                                 | Container-Hauptprozesse (z. B. Shell) anzeigen | z. B. `/bin/bash`                    |

**Nützliche Kombinationsbefehle für Automatisierung:**
| Zweck                          | Befehl (Gast)                       |              |         |
| ------------------------------ | ----------------------------------- | ------------ | ------- |
| Alle Container-Prozesse zählen | \`ps aux                            | grep conmon  | wc -l\` |
| RAM nach Prozess sortiert      | \`ps -eo pid,comm,%mem --sort=-%mem | head -n 10\` |         |
| RAM im Container selbst        | `free -h` oder `cat /proc/meminfo`  |              |         |
| Container-Init-Prozess finden  | `ps -p 1 -o comm=`                  |              |         |

---

## `neotree`

Tabelle: globale Keymaps aus `keys` (plugin-weit)

| Taste            | Gilt in | Aktion                                                                   | Details                                                                                                   |
| ---------------- | ------- | ------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `<localleader>e` | überall | Remap auf `<leader>fe`                                                   | Öffnet den Explorer „Root Dir“ gemäß bestehendem `<leader>fe`-Mapping.                                    |
| `<localleader>E` | überall | Remap auf `<leader>fE`                                                   | Öffnet den Explorer im aktuellen Arbeitsverzeichnis (cwd) gemäß bestehendem `<leader>fE`-Mapping.         |
| `<localleader>a` | überall | `neo-tree.command.execute({ reveal = true, dir = Project_root.get(0) })` | Reveal der aktuellen Datei bei Projekt-Root (Heuristik: LSP-Root → Git-Top → Buffer-Verzeichnis → `cwd`). |
| `<localleader>A` | überall | `neo-tree.command.execute({ reveal = true, dir = vim.uv.cwd() })`        | Reveal der aktuellen Datei im aktuellen `cwd` (ohne Projekt-Heuristik).                                   |

Tabelle: Neo-tree Fenster-Mappings (`opts.window.mappings`)

| Taste           | Gilt in  | Aktion                    | Details                                                                                                        |      |
| --------------- | -------- | ------------------------- | -------------------------------------------------------------------------------------------------------------- | ---- |
| `q`             | Neo-tree | `close_window`            | Schließt das Neo-tree-Fenster.                                                                                 |      |
| `?`             | Neo-tree | `noop`                    | Deaktiviert Hilfe-Popup auf `?` im Neo-tree-Fenster.                                                           |      |
| `g?`            | Neo-tree | `show_help`               | Zeigt Neo-tree-Hilfe.                                                                                          |      |
| `<leader>`      | Neo-tree | `noop`                    | Verhindert Leader-Ketten im Neo-tree-Fenster.                                                                  |      |
| `<Esc>`         | Neo-tree | Funktion                  | Löscht Filter, bricht externe Filter ab, schließt Preview, entfernt Such-Highlight.                            |      |
| `<2-LeftMouse>` | Neo-tree | `open`                    | Öffnet Node (Doppelklick).                                                                                     |      |
| `<CR>`          | Neo-tree | Funktion „safe open“      | Directories: toggeln; ansonsten Preview schließen und Datei öffnen; bevorzugt `window-picker` falls vorhanden. |      |
| `SV`            | Neo-tree | Funktion „safe split“     | Preview schließen; öffnet im horizontalen Split; mit `window-picker` falls vorhanden, sonst normal.            |      |
| `SG`            | Neo-tree | Funktion „safe vsplit“    | Preview schließen; öffnet im vertikalen Split; mit `window-picker` falls vorhanden, sonst normal.              |      |
| `l`             | Neo-tree | Funktion                  | Bei Verzeichnis: toggeln/expandieren; sonst öffnen (entspricht „go right/open“).                               |      |
| `h`             | Neo-tree | `close_node`              | Knoten schließen (entspricht „go left/close“).                                                                 |      |
| `C`             | Neo-tree | `close_node`              | Wie `h`, Knoten schließen.                                                                                     |      |
| `z`             | Neo-tree | `close_all_nodes`         | Alle Knoten zuklappen.                                                                                         |      |
| `<C-r>`         | Neo-tree | `refresh`                 | Baum neu laden.                                                                                                |      |
| `s`             | Neo-tree | `noop`                    | Reserviert: deaktiviert Standard-`s`.                                                                          |      |
| `sv`            | Neo-tree | `open_split`              | Horizontaler Split öffnen (direkt, ohne Picker).                                                               |      |
| `sg`            | Neo-tree | `open_vsplit`             | Vertikaler Split öffnen (direkt, ohne Picker).                                                                 |      |
| `st`            | Neo-tree | `open_tabnew`             | In neuem Tab öffnen.                                                                                           |      |
| `<S-Tab>`       | Neo-tree | `prev_source`             | Zum vorherigen Source wechseln (z. B. Files/Buffers/Git).                                                      |      |
| `c`             | Neo-tree | `copy_to_clipboard`       | In die Neo-tree-Zwischenablage kopieren.                                                                       |      |
| `x`             | Neo-tree | `cut_to_clipboard`        | In die Neo-tree-Zwischenablage ausschneiden.                                                                   |      |
| `p`             | Neo-tree | `paste_from_clipboard`    | Aus Neo-tree-Zwischenablage einfügen.                                                                          |      |
| `r`             | Neo-tree | `rename`                  | Umbenennen.                                                                                                    |      |
| `dd`            | Neo-tree | `delete`                  | Löschen.                                                                                                       |      |
| `a`             | Neo-tree | `add` (nowait, relativ)   | Datei anlegen; Pfadangabe relativ anzeigen.                                                                    |      |
| `N`             | Neo-tree | `add_directory` (relativ) | Verzeichnis anlegen; Pfadangabe relativ anzeigen.                                                              |      |
| `<Tab>`         | Neo-tree | `toggle_preview` (float)  | Vorschau-Fenster (floating) umschalten.                                                                        |      |
| `K`             | Neo-tree | `preview` (float)         | Einmalige Vorschau (floating).                                                                                 |      |
| `[a`            | Neo-tree | Funktion                  | Absoluten Pfad des Node in System-Clipboard `+` kopieren; Info-Toast.                                          |      |
| `{ab`           | Neo-tree | Funktion                  | Basis-/Verzeichnis-Pfad in `+` kopieren; für Dateien wird `:h` verwendet.                                      |      |
| `w`             | Neo-tree | Funktion                  | Fensterbreite zyklisch umschalten: klein ↔ normal ↔ groß (per \`wincmd                                         | \`). |
| `Y`             | Neo-tree | Funktion                  | Absoluten Pfad in `+` kopieren.                                                                                |      |
| `O`             | Neo-tree | Funktion                  | Pfad mit System-Anwendung öffnen (`lazy.util.open`, `system = true`).                                          |      |
| `M`             | Neo-tree | Funktion                  | Windows-Explorer öffnen (ruft `configs.neotree.open_fm.win`). Plattform-spezifisch.                            |      |
| `+`             | Neo-tree | Funktion                  | `cwd` auf Node-Verzeichnis setzen, Neo-tree auf dieses Verzeichnis fokussieren (Reveal), Toast anzeigen.       |      |
| `-`             | Neo-tree | Funktion                  | Eine Ebene nach oben: `cwd` auf Elternverzeichnis setzen, Neo-tree dort öffnen (Reveal), Toast anzeigen.       |      |

Tabelle: Filesystem-Quelle (`opts.filesystem.window.mappings`)

| Taste   | Gilt in             | Aktion             | Details                                                    |
| ------- | ------------------- | ------------------ | ---------------------------------------------------------- |
| `d`     | Neo-tree Filesystem | `noop`             | Deaktiviert Standard-`d`.                                  |
| `/`     | Neo-tree Filesystem | `noop`             | Deaktiviert Suche auf `/` (hier zugunsten eigener Filter). |
| `f`     | Neo-tree Filesystem | `filter_on_submit` | Filter anwenden, wenn bestätigt.                           |
| `F`     | Neo-tree Filesystem | `fuzzy_finder`     | Fuzzy-Suche innerhalb der Quelle.                          |
| `<C-c>` | Neo-tree Filesystem | `clear_filter`     | Aktiven Filter löschen.                                    |

Tabelle: Buffers-Quelle (`opts.buffers.window.mappings`)

| Taste | Gilt in          | Aktion          | Details                   |
| ----- | ---------------- | --------------- | ------------------------- |
| `dd`  | Neo-tree Buffers | `buffer_delete` | Buffer löschen/schließen. |

Tabelle: Git-Status-Quelle (`opts.git_status.window.mappings`)

| Taste | Gilt in      | Aktion   | Details                                |
| ----- | ------------ | -------- | -------------------------------------- |
| `d`   | Neo-tree Git | `noop`   | Deaktiviert Standard-`d`.              |
| `dd`  | Neo-tree Git | `delete` | Datei löschen (im Git-Status-Kontext). |

Tabelle: Document-Symbols-Quelle (`opts.document_symbols.window.mappings`)

| Taste | Gilt in          | Aktion   | Details                    |
| ----- | ---------------- | -------- | -------------------------- |
| `/`   | Neo-tree Symbols | `noop`   | Deaktiviert Suche auf `/`. |
| `F`   | Neo-tree Symbols | `filter` | Symbol-Filter aktivieren.  |

Hinweise

• Groß-/Kleinschreibung ist relevant: `SV`/`SG` (Großbuchstaben) sind eigene „safe“ Varianten, `sv`/`sg` (Kleinbuchstaben) rufen die direkten Neo-tree-Befehle auf.
• `Reveal` markiert die aktuelle Datei im Baum, funktioniert aber nur, wenn die Datei unterhalb des gesetzten `dir` liegt.
• `O` ist plattformübergreifend (ruft das System zum Öffnen auf), `M` ist explizit für Windows vorgesehen.
• Im Neo-tree-Fenster werden einige Standardtasten bewusst neutralisiert (`noop`), um Konflikte mit globalen Leader-Ketten oder Such-Shortcuts zu vermeiden.

---

## `nvim-tree`

| Keymap       | Modus  | Aktion                      | Beschreibung                                                        |
| ------------ | ------ | --------------------------- | ------------------------------------------------------------------- |
| `<C-]>`      | normal | `change_root_to_node()`     | Wechselt das Root-Verzeichnis zum selektierten Node                 |
| `]o`         | normal | `jobstart(open_cmd, path)`  | Öffnet die Datei im Systemstandardprogramm (`xdg-open` oder `open`) |
| `<leader>on` | normal | `open_in_nautilus()`        | Öffnet den aktuellen Ordner im Dateimanager Nautilus                |
| `.`          | normal | `api.node.run.cmd`          | Gibt den pfad in die Befehlszeile                                   |
| `gy`         | normal | `api.fs.copy.absolute_path` | Kopiert den absoluten Pfad des aktuellen Nodes                      |
| `ge`         | normal | `api.fs.copy.basename`      | Kopiert nur den Dateinamen (Basename) des aktuellen Nodes           |
| `<C-k>`      | normal | `api.node.show_info_popup`  | Zeigt ein Popup mit Informationen zum aktuellen Node                |
| `D`          | normal |                             | Papierkorb                                                          |

---

## `:Myterm`

**UserCommands**

| Befehl          | Argument(e)                                    | Beschreibung                                                                     |
| --------------- | ---------------------------------------------- | -------------------------------------------------------------------------------- |
| `:Myterm`       | *(optional)* `float`, `horizontal`, `vertical` | Toggle aktives Terminal oder neues öffnen im gewählten Layout                    |
| `:MytermToggle` | *(optional)* `float`, `horizontal`, `vertical` | Toggle aktives Terminal oder neues öffnen im gewählten Layout                    |
| `:MytermNew`    | `float` / `horizontal` / `vertical`            | Öffnet ein neues Terminal im angegebenen Layout (Standard: `horizontal`)         |
| `:MytermRun`    | *(optional)* `1`, `2`, `3`, ...                | Führt gespeicherten Befehl im aktiven oder gewählten Terminal aus                |
| `:MytermSend`   | `id command...`                                | Sendet Befehl im Hintergrund an Terminal-ID (ohne zu öffnen oder zu fokussieren) |
| `:MytermSet`    | –                                              | Fragt nach einem Befehl und speichert ihn                                        |
| `:MytermClear`  | –                                              | Löscht den gespeicherten Befehl                                                  |
| `:MytermFocus`  | `1`, `2`, `3`, ...                             | Wechselt den Fokus auf ein bestimmtes Terminal                                   |
| `:MytermInfo`   | –                                              | Gibt ID und Modus des aktuell aktiven Terminals aus                              |
| `:MytermClose`  | `1`, `2`, `3`, ...                             | Schließt das angegebene Terminal und entfernt es aus dem Status                  |

**Keymaps**

| Tastenkombination | Funktion                   | Beschreibung auf Deutsch                                |
| ----------------- | -------------------------- | ------------------------------------------------------- |
| `<leader>tf`      | `myterm.new("float")`      | Neues Floating-Terminal öffnen                          |
| `<leader>th`      | `myterm.new("horizontal")` | Neues horizontales Terminal öffnen                      |
| `<leader>tv`      | `myterm.new("vertical")`   | Neues vertikales Terminal öffnen                        |
| `<leader>to`      | `myterm.toggle()`          | Toggle zuletzt aktives Terminal (anzeigen/verstecken)   |
| `<leader>tt`      | `myterm.set_command()`     | Shell-Befehl eingeben und speichern                     |
| `<leader>tr`      | `myterm.run()`             | Gespeicherten Befehl im fokussierten Terminal ausführen |
| `<leader>tc`      | `myterm.clear_command()`   | Gespeicherten Befehl löschen                            |
| `<leader>ti`      | `myterm.show_active()`     | Zeigt aktives Terminal (z. B. `2* (float)`)             |
| `<leader>tx`      | `myterm.close(last_id)`    | Schließt das zuletzt fokussierte Terminal               |
| `<leader>ts`      | `send_background(id, cmd)` | Fragt nach ID und Befehl, sendet im Hintergrund         |
| `<leader>tfoc`    | `myterm.focus(id)`         | Fragt nach einer Terminal-ID und fokussiert diese       |

---

## `Toggleterm`

| Befehl                                                       | Zweck                                                     |
| ------------------------------------------------------------ | --------------------------------------------------------- |
| `:ToggleTerm direction=float`                                | Öffnet ein schwebendes Terminal                           |
| `:TermExec cmd="cargo test" dir=git_dir`                     | Führt `cargo test` im Wurzelverzeichnis des Git-Repos aus |
| `:2TermExec cmd="npm start"`                                 | Startet `npm start` im Terminal 2                         |
| `:TermNew name=watcher`                                      | Erstellt neues Terminal mit Namen „watcher“               |
| `:ToggleTermSetName`                                         | Öffnet Terminalauswahl, dann Namensdialog                 |
| `:ToggleTermSetName myterm`                                  | Legt neuen Namen „myterm“ fest                            |
| `:ToggleTermToggleAll`                                       | Öffnet oder schließt alle Terminals                       |
| `:ToggleTermSendCurrentLine 1`                               | Sendet aktuelle Zeile an Terminal 1                       |
| `:ToggleTermSendVisualLines`                                 | Sendet komplette visuelle Zeilen an Standard-Terminal     |
| `:ToggleTermSendVisualSelection 2`                           | Sendet Auswahl (auch blockweise) an Terminal 2            |
| `require("toggleterm").setup{ persist_size = false }`        | Größe wird beim Umschalten nicht gemerkt                  |
| `require("toggleterm").setup{ shade_terminals = false }`     | Terminalfenster werden nicht abgedunkelt                  |
| `require("toggleterm").setup{ shade_filetypes = { "fzf" } }` | Nur bestimmte Filetypes (z. B. fzf) werden gedimmt        |

---

## `gp.nvim`

| Befehl                 | Beschreibung                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------------- |
| **Chat-Befehle**       |                                                                                                   |
| `:GpChatNew`           | Öffnet einen neuen Chat im aktuellen Fenster. Optional: visueller Bereich oder Range als Kontext  |
| `:GpChatNew vsplit`    | Neuer Chat im vertikalen Split-Fenster                                                            |
| `:GpChatNew split`     | Neuer Chat im horizontalen Split-Fenster                                                          |
| `:GpChatNew tabnew`    | Neuer Chat in einem neuen Tab                                                                     |
| `:GpChatNew popup`     | Neuer Chat im Pop-up-Fenster                                                                      |
| `:GpChatPaste`         | Fügt Auswahl oder Range in den zuletzt aktiven Chat ein                                           |
| `:GpChatToggle`        | Öffnet (oder schließt) Chat in einem Popup – zeigt letzten oder neuen Chat                        |
| `:GpChatFinder`        | Sucht durch bestehende Chats (z. B. nach Schlüsselwörtern)                                        |
| `:GpChatRespond`       | Fordert eine neue Antwort im aktuellen Chat an (optional mit `N` letzten Nachrichten als Kontext) |
| `:GpChatDelete`        | Löscht den aktuellen Chat (Bestätigung nötig, außer deaktiviert in Config)                        |
| **Text-/Code-Befehle** |                                                                                                   |
| `:GpRewrite`           | Ersetzt ausgewählten Textbereich durch Antwort basierend auf benutzerdefiniertem Prompt           |
| `:GpAppend`            | Fügt Antwort **nach** aktuellem Textbereich ein                                                   |
| `:GpPrepend`           | Fügt Antwort **vor** aktuellem Textbereich ein                                                    |
| `:GpEnew`              | Antwort erscheint in einem **neuen leeren Buffer** im aktuellen Fenster                           |
| `:GpNew`               | Antwort erscheint in einem **neuen horizontalen Split**                                           |
| `:GpVnew`              | Antwort erscheint in einem **neuen vertikalen Split**                                             |
| `:GpTabnew`            | Antwort erscheint in einem **neuen Tab**                                                          |
| `:GpPopup`             | Antwort erscheint in einem **Popup-Fenster**                                                      |
| `:GpImplement`         | Beispiel-Hook: Entwickelt Code aus Kommentaren im ausgewählten Bereich                            |
| **Kontext-Befehle**    |                                                                                                   |
| `:GpContext`           | Öffnet oder erweitert `.gp.md`-Datei für kontextbasierte Prompts im Projekt-Root                  |
| `:GpContext vsplit`    | `.gp.md` in vertikalem Split anzeigen                                                             |
| `:GpContext split`     | `.gp.md` in horizontalem Split anzeigen                                                           |
| `:GpContext tabnew`    | `.gp.md` in neuem Tab anzeigen                                                                    |
| `:GpContext popup`     | `.gp.md` in Popup anzeigen                                                                        |

### AI-Modelle

#### OpenAI

| Modell                     | Kontextfenster   | Besonderheit                                                     | Ideal für                                   |
| -------------------------- | ---------------- | ---------------------------------------------------------------- | ------------------------------------------- |
| GPT-4.1                    | 1 Million Tokens | Leistungsstark, teuer                                            | Komplexe Codierung, Planung                 |
| GPT-4.1 mini               | 1 Million Tokens | Fast, günstig, nahe Vollmodellleistung                           | Interaktives Coding, Tools                  |
| GPT-4.1 nano               | 1 Million Tokens | Schnell, sehr günstig, abgespeckt                                | Autocompletion, Klassifikation              |
| GPT-4o                     | 128 k Tokens     | Multimodal (Text, Bild, Audio), schnell, günstiger als 4.1       | Realtime-Chat, multimodale Anwendungen      |
| GPT-4o-search-preview      | 128 k Tokens     | Speziell für Websuche optimiert                                  | Retrieval-Augmented-Generation, Suchsysteme |
| GPT-4o-mini                | 128 k Tokens     | Leichtgewichtige 4o-Variante, sehr günstig, gute Geschwindigkeit | Alltags-Chat, schnelle Code-Snippets        |
| GPT-4o-mini-search-preview | 128 k Tokens     | Kombination aus Mini-Variante und Suchoptimierung                | Schnelle, kostengünstige Suchanfragen       |

* **GPT-4.1 (voll)**
  Vollwertiges, leistungsstarkes Modell mit bis zu **1 Million Tokens Kontextfenster**, optimiert für robuste Coding- und Instruktionsaufgaben ([OpenAI][1], [Wikipedia][2]).

* **GPT-4.1 mini**
  Schnellere und günstigere Variante, ≈ 80–90 % der Leistung von GPT-4.1 bei deutlich reduzierter Latenz und deutlich geringeren Kosten ([OpenAI][1]). Oft Standard im ChatGPT für Free- und Plus-Nutzer ([Wikipedia][2], [Omni][3]).

* **GPT-4.1 nano**
  Kleinstes und günstigstes Modell der Reihe, ideal für einfache Aufgaben wie Autocomplete oder Klassifikation. Unterstützt trotz Größe das volle **1 Million Tokens** Kontextfenster; sehr niedrige Kosten, aber eingeschränkte Reasoning-Performance ([Zapier][4]).

* **GPT-4o**
  Multimodales Modell (Text, Bild, Audio) mit **128 k Tokens** Kontextfenster. Optimiert für Realtime-Interaktion, schnelles Response-Streaming und günstigere Nutzung als GPT-4.1. Ideal für interaktive, multimodale Anwendungen.

* **GPT-4o-search-preview**
  Spezialversion von GPT-4o für Such- und Retrieval-Aufgaben, abgestimmt auf die Verarbeitung und Optimierung von Suchanfragen. Nutzt ebenfalls 128 k Tokens.

* **GPT-4o-mini**
  Leichte, kostengünstige Variante von GPT-4o mit 128 k Tokens Kontextfenster. Hohe Geschwindigkeit, gute Qualität für Alltags-Chat und schnelle Coding-Aufgaben.

* **GPT-4o-mini-search-preview**
  Kombination aus GPT-4o-mini und Search-Preview-Optimierungen. Ideal für schnelle, kostengünstige Suchanfragen und RAG-Anwendungen mit geringeren Kosten.

---

### Chat-Befehle

| Befehl              | Beschreibung                                                                                      |
| ------------------- | ------------------------------------------------------------------------------------------------- |
| `:GpChatNew`        | Öffnet einen neuen Chat im aktuellen Fenster. Optional: visueller Bereich oder Range als Kontext  |
| `:GpChatNew vsplit` | Neuer Chat im vertikalen Split-Fenster                                                            |
| `:GpChatNew split`  | Neuer Chat im horizontalen Split-Fenster                                                          |
| `:GpChatNew tabnew` | Neuer Chat in einem neuen Tab                                                                     |
| `:GpChatNew popup`  | Neuer Chat im Pop-up-Fenster                                                                      |
| `:GpChatPaste`      | Fügt Auswahl oder Range in den zuletzt aktiven Chat ein                                           |
| `:GpChatToggle`     | Öffnet (oder schließt) Chat in einem Popup – zeigt letzten oder neuen Chat                        |
| `:GpChatFinder`     | Sucht durch bestehende Chats (z. B. nach Schlüsselwörtern)                                        |
| `:GpChatRespond`    | Fordert eine neue Antwort im aktuellen Chat an (optional mit `N` letzten Nachrichten als Kontext) |
| `:GpChatDelete`     | Löscht den aktuellen Chat (Bestätigung nötig, außer deaktiviert in Config)                        |

---

### Text-/Code-Befehle

| Befehl         | Beschreibung                                                                            |
| -------------- | --------------------------------------------------------------------------------------- |
| `:GpRewrite`   | Ersetzt ausgewählten Textbereich durch Antwort basierend auf benutzerdefiniertem Prompt |
| `:GpAppend`    | Fügt Antwort **nach** aktuellem Textbereich ein                                         |
| `:GpPrepend`   | Fügt Antwort **vor** aktuellem Textbereich ein                                          |
| `:GpEnew`      | Antwort erscheint in einem **neuen leeren Buffer** im aktuellen Fenster                 |
| `:GpNew`       | Antwort erscheint in einem **neuen horizontalen Split**                                 |
| `:GpVnew`      | Antwort erscheint in einem **neuen vertikalen Split**                                   |
| `:GpTabnew`    | Antwort erscheint in einem **neuen Tab**                                                |
| `:GpPopup`     | Antwort erscheint in einem **Popup-Fenster**                                            |
| `:GpImplement` | Beispiel-Hook: Entwickelt Code aus Kommentaren im ausgewählten Bereich                  |

---

### Kontext-Management

| Befehl              | Beschreibung                                                                     |
| ------------------- | -------------------------------------------------------------------------------- |
| `:GpContext`        | Öffnet oder erweitert `.gp.md`-Datei für kontextbasierte Prompts im Projekt-Root |
| `:GpContext vsplit` | `.gp.md` in vertikalem Split anzeigen                                            |
| `:GpContext split`  | `.gp.md` in horizontalem Split anzeigen                                          |
| `:GpContext tabnew` | `.gp.md` in neuem Tab anzeigen                                                   |
| `:GpContext popup`  | `.gp.md` in Popup anzeigen                                                       |

---

### Custom Instructions

* Man kann ein `.gp.md` im Projektverzeichnis anlegen via `:GpContext`
* Diese Datei enthält Regeln, die für alle weiteren Befehle (`:GpRewrite`, `:GpAppend`, …) gelten
* Beispielinhalt:

```md
Verwende C++17
Verwende die Testify-Library für Go-Tests
Vermeide tiefe Verschachtelung, nutze Guard-Clauses
```

---

## `vim-visual-multi`

[Link](https://github.com/mg979/vim-visual-multi)

| Aktion                          | Tastenkombination        | Beschreibung                                    |
| ------------------------------- | ------------------------ | ----------------------------------------------- |
| **Grundlegende Steuerung**      |                          |                                                 |
| Wort unter Cursor markieren     | `<C-n>`                  | Fügt Wort Mehrfachauswahl hinzu                 |
| Nächstes/Vorheriges Vorkommen   | `n` / `N`                | Nächste oder vorherige Übereinstimmung          |
| Aktuellen Treffer überspringen  | `q`                      | Überspringt aktuellen Treffer                   |
| Aktuellen Cursor entfernen      | `Q`                      | Entfernt den Cursor/Selektion                   |
| Zwischen den Cursorn navigieren | `[` / `]`                | Bewegung durch aktiven Cursorn                  |
| Modus wechseln                  | `<Tab>`                  | Wechsel zw. Cursor- und Extend-Mode             |
| ------------------------------  | ------------------------ | ----------------------------------------------- |
| **Multi-Cursor-Erstellung**     |                          |                                                 |
| Vertikalen Cursor oben/unten    | `<C-Up>` / `<C-Down>`    | Fügt ober- oder unterhalb Cursor hinzu          |
| Bereich zeichenweise erweitern  | `<S-Left>` / `<S-Right>` | Auswahl erweitern (nur im Extend-Modus)         |
| Muster mit Regex markieren      | `\\`                     | Wechselt zur Regex-Suche im Visual-Mode         |
| -----------------------------   | ------------------       | ----------------------------------------------- |
| **Bearbeiten an allen Cursorn** |                          |                                                 |
| In Insert-Mode gehen            | `i`, `a`, `I`, `A`       | Gleichzeitig an allen Stellen                   |
| Groß-/Kleinschreibung ändern    | `~`                      | Toggle case (Normalmodus)                       |
| Einzelnes Zeichen ersetzen      | `r<char>`                | Zeichen ersetzen                                |
| Bereich löschen oder kopieren   | `d`, `y`, `c`            | Delete/Copy/Change für Regionen                 |
| Block aus Register einfügen     | `p`                      | An j. Position den kopierten Block ein          |

| Aktion                             | Beschreibung                                      |
| ---------------------------------- | ------------------------------------------------- |
| **Komplexe Operationen**           |                                                   |
| Mehrere Zeilen gleichzeitig ändern | Vert. Cursor setzen mit `<C-Down>`                |
| Regex-Match & selektieren          | markieren → `\\` → Eingabe Regex-Muster           |
| Alle `foo` durch `bar` ersetzen    | `<C-n>` → `c` → `bar<Esc>`                        |
| ---------------------------------- | ------------------------------------------------- |
| **Zusätzliche Befehle**            |                                                   |
| `:VMSearch /pattern/`              | Wendet Suche auf alle Cursorregionen an           |
| `:VMSave` / `:VMLoad`              | Speichert/Lädt aktuelle Regionenselektion         |
| `:help visual-multi`               | Einstieg in Dokumentation                         |
| `:help vm-mappings`                | Übersicht aller Tastenzuweisungen                 |

---

## Todo Comments

`INFO`, `DEBUG`, `TODO`, `WARN`, `PERF`, `NOTE`, `TEST`, `EXP`,
`HACK` (weird code),
`FIX` alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
`REF` alt = { "REFACTOR", "REWRITE", "CLEANUP", "IMPROVE", "RESTRUCTURE" }
`WATCH`alt = { "MONITOR", "OBSERVE", "TRACK", "INSPECT", "SURVEILLANCE" },

:TodoTelescope → durchsucht alle TODOs im Projekt
:TodoQuickFix → lädt alle TODOs ins QuickFix
:TodoLocList This uses the location list to show all todos in your project.
:TodoTrouble oder :Trouble todo  → falls du trouble.nvim nutzt
:TodoFzfLua
:TodoTelescope cwd=~/projects/foobar
:TodoTelescope keywords=EXP
:TodoTelescope keywords=TODO,DEBUG
`"n", "]t",  "Next todo comment"`
`"n", "[t", "Previous todo comment"`

## DiffView

```bash
| Taste(n)      | Aktion                                                         |
| ------------- | -------------------------------------------------------------- |
| <leader>e     | Fokus auf das Datei-Panel setzen                               |
| j / <down>    | Nächsten Dateieintrag auswählen                                |
| k / <up>      | Vorherigen Dateieintrag auswählen                              |
| <leader>cA    | Alle Versionen eines Konflikts für die ganze Datei auswählen   |
| <leader>cB    | "BASE"-Version eines Konflikts für die ganze Datei auswählen   |
| <leader>cO    | "OURS"-Version eines Konflikts für die ganze Datei auswählen   |
| <leader>cT    | "THEIRS"-Version eines Konflikts für die ganze Datei auswählen |
| zM            | Alle Folds schließen                                           |
| zc / h        | Aktuellen Fold schließen                                       |
| zR            | Alle Folds öffnen                                              |
| zo            | Aktuellen Fold öffnen                                          |
| f             | Leere Unterverzeichnisse im Tree-View zusammenfalten           |
| ]x / [x       | Zum nächsten / vorherigen Konflikt springen                    |
| L             | Commit-Log-Panel öffnen                                        |
| [F / ]F       | Diff der ersten / letzten Datei anzeigen                       |
| <tab>         | Diff der nächsten Datei anzeigen                               |
| <s-tab>       | Diff der vorherigen Datei anzeigen                             |
| <2-LeftMouse> | Diff für den ausgewählten Eintrag öffnen                       |
| l / o / <CR>  | Diff für den ausgewählten Eintrag öffnen                       |
| <C-w><C-f>    | Datei im horizontalen Split öffnen                             |
| <C-w>gf       | Datei in neuem Tab öffnen                                      |
| gf            | Datei im vorherigen Tab öffnen                                 |
| g?            | Hilfe-Panel anzeigen                                           |
| X             | Eintrag zum Zustand auf der linken Seite zurücksetzen          |
| <C-f> / <C-b> | Ansicht nach unten / oben scrollen                             |
| s / -         | Eintrag (de)stagen                                             |
| S             | Alle Einträge stagen                                           |
| i             | Zwischen Listen- und Baumansicht umschalten                    |
| za            | Fold umschalten                                                |
| <leader>b     | Datei-Panel ein-/ausblenden                                    |
| U             | Alle Einträge unstage                                          |
| R             | Liste und Statistiken aktualisieren                            |
```
---

## Vimmotions

 Befehl    | Aktion                                                                      |
| --------- | --------------------------------------------------------------------------- |
| `*`       | Nächstes Vorkommen des **Worts**                                            |
| `#`       | Vorheriges Vorkommen des **Worts**                                          |
| `g*`      | Nächstes Vorkommen des **Teilworts**                                        |
| `g#`      | Vorheriges Vorkommen des **Teilworts**                                      |
| `n`       | Wiederhole Suche in gleicher Richtung                                       |
| `N`       | Wiederhole Suche in Gegenrichtung                                           |
| `f<char>` | Springe **nach vorne** zur **nächsten Vorkommen** von `<char>` in der Zeile |
| `F<char>` | Springe **rückwärts** zum **vorherigen Vorkommen** von `<char>`             |
| `t<char>` | Springe **nach vorne**, aber **bleibe direkt vor** `<char>`                 |
| `T<char>` | Springe **rückwärts**, aber **bleibe direkt hinter** `<char>`               |
| `dfa`     | Lösche **bis einschließlich** nächstem `a`                                  |
| `dta`     | Lösche **bis vor** nächstem `a`                                             |
| `vfa`     | Visueller Modus bis einschließlich `a`                                      |
| `cF.`     | Ändere Text **bis zum vorherigen Punkt**                                    |

| Bewegung                   | Beschreibung                                                            |
| -------------------------- | ----------------------------------------------------------------------- |
| **Zeichenweise**           |                                                                         |
| `l`                        | Ein Zeichen nach rechts                                                 |
| `h`                        | Ein Zeichen nach links                                                  |
| `f<char>`                  | Springe vorwärts zum nächsten `<char>` in der Zeile                     |
| `F<char>`                  | Springe rückwärts zum vorherigen `<char>`                               |
| `t<char>`                  | Wie `f`, aber **bleibt vor** dem Zeichen                                |
| `T<char>`                  | Wie `F`, aber **bleibt hinter** dem Zeichen                             |
| `;`                        | Wiederhole letzten `f`, `F`, `t`, `T`                                   |
| `,`                        | Wiederhole letzten `f`, `F`, `t`, `T` in **entgegengesetzter Richtung** |
| -------------------------- | ----------------------------------------------------------------------- |
| **Wortweise**              | Cursor springt zu Wortgrenzen                                           |
| `w`                        | Springe zum Anfang des nächsten Wortes                                  |
| `W`                        | Wie `w`, aber ignoriert Interpunktion                                   |
| `e`                        | Springe zum Ende des aktuellen/nächsten Wortes                          |
| `E`                        | Wie `e`, aber ignoriert Interpunktion                                   |
| `b`                        | Springe zum Anfang des vorherigen Wortes                                |
| `B`                        | Wie `b`, aber ignoriert Interpunktion                                   |
| `ge`                       | Springe zum Ende des vorherigen Wortes                                  |
| `gE`                       | Wie `ge`, aber ignoriert Interpunktion                                  |
| -------------------------- | ----------------------------------------------------------------------- |
| **Zeilenintern**           |                                                                         |
| `^`                        | Zum ersten Nicht-Leerzeichen der Zeile                                  |
| `0`                        | Zum Anfang der Zeile                                                    |
| `$`                        | Zum Ende der Zeile                                                      |
| `g_`                       | Zum letzten sichtbaren Zeichen der Zeile                                |
| -------------------------- | ----------------------------------------------------------------------- |
| **Zeilenweise**            |                                                                         |
| `j`                        | Eine Zeile nach unten                                                   |
| `k`                        | Eine Zeile nach oben                                                    |
| `gj`                       | Eine Bildschirmzeile nach unten                                         |
| `gk`                       | Eine Bildschirmzeile nach oben                                          |
| `+`                        | Zum ersten Nicht-Leerzeichen der nächsten Zeile                         |
| `-`                        | Zum ersten Nicht-Leerzeichen der vorherigen Zeile                       |
| -------------------------- | ----------------------------------------------------------------------- |
| **Dokumentenweit**         | Abschnitte, Sprünge                                                     |
| `G`                        | Gehe zur letzten Zeile                                                  |
| `gg`                       | Gehe zur ersten Zeile                                                   |
| `{` / `}`                  | Vorheriger/nächster Absatz                                              |
| `[[` / `]]`                | Zu vorherigem/nächstem Funktionsanfang (bei C/Java etc.)                |
| `%`                        | Springe zur passenden Klammer ( `()[]{}<>` )                            |
| -------------------------- | ----------------------------------------------------------------------- |
| **Suche**                  |                                                                         |
| `/text`                    | Suche vorwärts nach `text`                                              |
| `?text`                    | Suche rückwärts nach `text`                                             |
| `n`                        | Wiederhole letzte Suche in gleiche Richtung                             |
| `N`                        | Wiederhole letzte Suche in entgegengesetzter Richtung                   |
| `*`                        | Suche nächstes Vorkommen des aktuellen Wortes                           |
| `#`                        | Suche vorheriges Vorkommen des aktuellen Wortes                         |
| `g*`                       | Suche nächstes Teilwort                                                 |
| `g#`                       | Suche vorheriges Teilwort                                               |
| -------------------------- | ----------------------------------------------------------------------- |
| **Fenster-/Bufferwechsel** |                                                                         |
| `<C-w>h`                   | Wechsel nach links                                                      |
| `<C-w>l`                   | Wechsel nach rechts                                                     |
| `<C-w>j`                   | Wechsel nach unten                                                      |
| `<C-w>k`                   | Wechsel nach oben                                                       |
| `:bnext`                   | Nächster Buffer                                                         |
| `:bprev`                   | Vorheriger Buffer                                                       |
| -------------------------- | ----------------------------------------------------------------------- |
| **Treesitter**             |                                                                         |
| `]m`, `[m`                 | Nächste / vorherige Methode                                             |
| `]c`, `[c`                 | Nächstes / vorheriges Statement / Block                                 |
| `]a`, `[a`                 | Nächste / vorherige Argumentgruppe                                      |
| `]f`, `[f`                 | Nächste / vorherige Funktion                                            |

---

## Treesitter

TODO:

```lua
["af"] = "@function.outer",
["if"] = "@function.inner",
["ac"] = "@class.outer",
["ic"] = "@class.inner",
["ab"] = "@block.outer",
["ib"] = "@block.inner",
["ap"] = "@parameter.outer",
["ip"] = "@parameter.inner",
["]m"] = "@function.outer",
["]c"] = "@class.outer",
["]b"] = "@block.outer",
["]p"] = "@parameter.inner",
```

| Taste | Bedeutung                                   | Ziel (`@capture`)  |
| ----- | ------------------------------------------- | ------------------ |
| af    | Funktion (außen, inkl. Signatur und Body)   | `@function.outer`  |
| if    | Funktion (innen, nur Body)                  | `@function.inner`  |
| ac    | Klasse (außen)                              | `@class.outer`     |
| ic    | Klasse (innen)                              | `@class.inner`     |
| ab    | Block (außen, inkl. `{}`)                   | `@block.outer`     |
| ib    | Block (innen, ohne `{}`)                    | `@block.inner`     |
| ap    | Parameter (außen, inkl. Komma/Trennzeichen) | `@parameter.outer` |
| ip    | Parameter (innen, nur Wert/Inhalt)          | `@parameter.inner` |
| ]f    | Zum Start der nächsten Funktion             | `@function.outer`  |
| ]c    | Zum Start der nächsten Klasse               | `@class.outer`     |
| ]b    | Zum Start des nächsten Blocks               | `@block.outer`     |
| ]p    | Zum Start des nächsten Parameters           | `@parameter.inner` |
| ]F    | Zum Ende der nächsten Funktion              | `@function.outer`  |
| ]C    | Zum Ende der nächsten Klasse                | `@class.outer`     |
| [f    | Zum Start der vorherigen Funktion           | `@function.outer`  |
| [c    | Zum Start der vorherigen Klasse             | `@class.outer`     |
| [b    | Zum Start des vorherigen Blocks             | `@block.outer`     |
| [p    | Zum Start des vorherigen Parameters         | `@parameter.inner` |
| [F    | Zum Ende der vorherigen Funktion            | `@function.outer`  |
| [C    | Zum Ende der vorherigen Klasse              | `@class.outer`     |
| >,    | Tauscht aktuellen Parameter mit nächstem    | `@parameter.inner` |
| <,    | Tauscht aktuellen Parameter mit vorherigem  | `@parameter.inner` |

| Befehl | Aktion          |
| ------ | --------------- |
| `viw`  | mark inner word |
| `vaw`  | mark outer word |

---

## redir

**Allgemeine Syntax von `:redir`:**

```vim
:redir {ausgabeziel} {Befehl}
```

- `{ausgabeziel}` kann ein Register (wie `@+` für die Zwischenablage) oder eine Datei (wie `file.txt`) sein.
- `{Befehl}` ist der Befehl, dessen Ausgabe umgeleitet werden soll.

**Beispiel:**
```vim
:redir => g:msgs      " Umleitung starten in Variable g:msgs
:messages             " alles, was angezeigt wird, wird umgeleitet
:redir END            " Umleitung beenden
:new                  " neues Fenster
:put =g:msgs          " Inhalt der Variable ins Fenster schreiben
```

| Zieltyp                  | Syntax                                           | Beschreibung                                                        | Besonderheiten / Hinweise                                   | Beispiel                          |
| ------------------------ | ------------------------------------------------ | ------------------------------------------------------------------- | ----------------------------------------------------------- | --------------------------------- |
| **Datei (neu)**          | `:redir > datei.txt`                             | Leitet Ausgaben in eine neue Datei um                               | Überschreibt existierende Datei                             | `:redir > debug.txt`              |
| **Datei (anhängen)**     | `:redir >> datei.txt`                            | Fügt Ausgaben an bestehende Datei an                                | Praktisch für Log-Append                                    | `:redir >> log.txt`               |
| **Register**             | `:redir @a`                                      | Leitet Ausgaben in Register `a` um                                  | Mit `"ap` einfügen                                          | `:redir @a` + `:highlight`        |
| **Register (append)**    | `:redir @a>>`                                    | Fügt neue Ausgabe an vorhandenes Register an                        | Enthält vorherigen Inhalt plus neuen                        |                                   |
| **System-Clipboard**     | `:redir @+` / `:redir @*`                        | Gibt Ausgabe ins Clipboard / Selection-Clipboard                    | `@+` = System, `@*` = Selection                             | `:redir @+` + `:set`              |
| **Variable**             | `:redir => varname`                              | Speichert Ausgabe in einer Vim-Variable                             | Mit `:echo varname` sichtbar                                | `:redir => g:result`              |
| **Beenden**              | `:redir END`                                     | Beendet aktive Umleitung                                            | Muss **immer** gesetzt werden                               | `:redir END`                      |
| **Debugging**            | `:redir > debug.txt`                             | Ausgabe von `:echo`, `:set`, `:map`, `:ls`, `:highlight` sammeln    | Ideal zur Fehleranalyse                                     |                                   |
| **Scripting**            | Innerhalb `function` oder Lua                    | Ermöglicht Protokollierung innerhalb benutzerdefinierter Funktionen | Lua: `vim.cmd('redir > ...')` oder `vim.fn.execute(...)`    | Siehe `CreateDebugReport()`       |
| **Clipboard-Support**    | `:redir @+`                                      | Direktes Logging in System-Zwischenablage                           | Einfügen außerhalb von Vim möglich                          |                                   |
| **Lua-Ausgabe erfassen** | Lua-Funktion mit `vim.cmd` oder `vim.fn.execute` | Alternativen für moderne Konfigurationen                            | Lua: `vim.fn.execute('ls')` oder mit `redir =>` kombinieren | Siehe `capture_vim_output()`      |
| **RedirCommands Plugin** | `:RR cmd => var` etc.                            | Vereinfachte Redir-Syntax mit `:R`, `:RR`                           | Ermöglicht `:RR <cmd> > file.txt` etc.                      | `:RR highlight > hi.txt`          |
| **Try-Catch**            | `try ... redir ... finally`                      | Fehlerresistente Umleitung bei riskanten Befehlen                   | Verhindert hängenbleibende `redir`-Sitzungen                | Siehe `:try ... redir ... endtry` |

**Gebräuchliche `:redir`-Flags und Optionen:**

1. **`:redir` Flags:**
   - `@{register}`: Umleitung in ein Register. Zum Beispiel `@+` für die Zwischenablage.
   - `>`: Umleitung in eine Datei. Zum Beispiel `> file.txt`.

2. **`:redir` Optionen:**
   - `END`: Beendet die Umleitung.
   - `SILENT`: Unterdrückt normale Meldungen.
   - `APPEND`: Fügt Ausgabe an, anstatt die Datei zu überschreiben (nur bei Verwendung von `>`).
   - `EX` oder `EX-CMD`: Interpretiert die Ausgabe als Ex-Befehl (nur bei Verwendung von `>`).

3. Mit `:messages` kan man die Ausgabe des Befehls einsehen


**Um den Inhalt der `:messages` direkt in das Clipboard-Register (`+`) zu speichern:**

```vim
:redir @+ | silent messages | redir END
```

* `:redir @+`:

  * Leitet die Ausgabe aller nachfolgenden Befehle direkt in das Clipboard-Register (`+`).
* `silent messages`:

  * Führt den Befehl `:messages` (Anzeige der letzten Nachrichten) aus.
  * `silent` sorgt dafür, dass keine zusätzliche Ausgabe erfolgt.
* `redir END`:

  * Beendet die Umleitung.

---

**Mit `:redir` einen Befehl in Neovim ausführen und in Zwischenablage kopieren:**

Die `:redir`-Funktion in Vim und Neovim wird verwendet, um die Ausgabe von Befehlen in eine Datei oder einen Register umzuleiten. Hier ist eine ausführliche Erklärung der Technik, und ich werde auch einige gebräuchliche `:redir`-Flags und Optionen vorstellen.

```vim
:redir @+ | silent echon &packpath | redir END
```

- `redir @+`: Leitet die Ausgabe in das Register `+` (Zwischenablage) um.
- `|`: Erlaubt das Verketten von Befehlen.
- `silent echon &packpath`: Druckt den Wert von `&packpath` ohne Meldungen. `echon` schreibt Wert in Register, `echo` in die Konsole
- `redir END`: Beendet die Umleitung.

Angenommen, du möchtest die Liste der installierten Plugins in eine Datei namens `plugins.txt` umleiten:

```vim
:redir > plugins.txt | silent echo execute('packloadall!') | redir END
```

Dieser Befehl leitet die Ausgabe von `execute('packloadall!')` in die Datei `plugins.txt` um und unterdrückt dabei alle Meldungen. Beachte, dass `packloadall!` alle Plugins lädt und die Informationen über die geladenen Plugins als Ausgabe generiert.

---

## Vimscript Funktionen

- Aufufen mit `:call` in `nvim`

```vim
:call delete("file.txt")                         " Datei löschen
:call mkdir("build/log", "p")                    " Verzeichnis rekursiv erstellen
:call setline(1, ["Hello", "World"])             " Zeilen in Buffer schreiben
:echo join(getline(1, '$'), "\n")                " Zeilen zusammenfügen und ausgeben
:call setreg('+', 'Text')                        " In Zwischenablage schreiben
:echo system("ls -la")                           " Shell-Befehl ausführen
```

- Die meisten dieser Funktionen sind auch aus Lua zugreifbar:

```lua
vim.fn.delete("file.txt")
vim.fn.getline(1, '$')
```

| Funktion                                       | Beschreibung                                       |
| ---------------------------------------------- | -------------------------------------------------- |
| **Allgemein nützliche Funktionen (Basics)**    |                                                    |
| `delete({filename})`                           | Löscht eine Datei oder ein Verzeichnis             |
| `mkdir({dirname}, {flags?}, {prot?})`          | Erstellt ein Verzeichnis (z. B. `p` für `parents`) |
| `rename({from}, {to})`                         | Bennent eine Datei oder Verzeichnis um             |
| `copy({from}, {to})`                           | Kopiert Datei oder Verzeichnis                     |
| `writefile({list}, {fname}, {flags?})`         | Schreibt eine Liste (`String[]`) in Datei          |
| `readfile({fname}, {binary?}, {max?})`         | Liest Datei in eine Liste von Zeilen               |
| `glob({expr}, {nosuf?}, {list?}, {alllinks?})` | Datei-Matching via Wildcards                       |
| `fnamemodify({fname}, {mods})`                 | Pfad manipulieren (`:p`, `:t`, `:e`, …)            |
| `expand({expr})`                               | Pfad- oder Platzhalter-Auflösung (z. B. `%`, `~`)  |
| `resolve({filename})`                          | Symlink auflösen                                   |
| **Zeilen und Textmanipulation**                |                                                    |
| `getline('.')`                                 | Gibt aktuelle Zeile zurück                         |
| **Clipboard, Register & Marks**                |                                                    |
| `getreg({reg})`                                | Gibt Inhalt eines Registers zurück                 |
| `setreg({reg}, {value}, {type})`               | Setzt Inhalt eines Registers                       |
| **System & Shell**                             |                                                    |
| `system({cmd})`                                | Führt Shell-Befehl aus und gibt Output             |
| `executable({cmd})`                            | Prüft, ob ausführbar im `$PATH`                    |
| `has({feature})`                               | Prüft, ob Vim-Feature vorhanden ist                |
| **Auswerten und Funktionskontrolle**           |                                                    |
| `has({feature})`                               | Prüft auf Vim-Feature (z. B. `nvim`, `python3`)    |
| `exists({expr})`                               | Prüft, ob Variable/Funktion existiert              |
| `function({name})`                             | Ruft Funktion als Funktionswert ab                 |
| `mapcheck({lhs}, {mode?})`                     | Prüft, ob eine Mapping existiert                   |
| `isdirectory({name})`                          | Prüft auf Verzeichnis                              |
| **Evaluierung & dynamische Strings**           |                                                    |
| `eval({string})`                               | Führt Ausdruck als Vimscript aus                   |
| `execute({command})`                           | Führt String als Ex-Command aus                    |
| `printf({fmt}, {...})`                         | Formatierte Strings (wie C)                        |
| `string({expr})`                               | Gibt String-Darstellung eines Werts                |

### `writefile({list}, {fname}, {flags?})`

| Parameter  | Typ        | Beschreibung                                                                  |
| ---------- | ---------- | ----------------------------------------------------------------------------- |
| `{list}`   | `string[]` | Eine Liste von Strings. Jeder Eintrag entspricht einer Zeile in der Zieldatei |
| `{fname}`  | `string`   | Der Pfad zur Zieldatei                                                        |
| `{flags?}` | `string`   | Optionales Flag(s) zur Steuerung des Schreibverhaltens                        |

**Beispiel 1: Datei neu schreiben,** Erstellt/überschreibt `/tmp/test.txt` mit zwei Zeilen.

```vim
:call writefile(['Zeile 1', 'Zeile 2'], '/tmp/test.txt')
```

**Beispiel 2: An Datei anhängen,** Fügt die Zeile `Nachtrag` am Ende von `/tmp/test.txt` hinzu.

```vim
:call writefile(['Nachtrag'], '/tmp/test.txt', 'a')
```
**Beispiel 3: Binärdatei schreiben,** Erstellt eine Binärdatei mit PNG-Header.

```vim
:call writefile([nr2char(0x89) . "PNG"], '/tmp/out.bin', 'b')
```

**In Lua:**

```lua
vim.fn.writefile({ "line 1", "line 2" }, "/tmp/out.txt")
```

---

## LiveGrep mit ripgrep

1. **Wortgrenze mit Regex:**

Verwende in `Telescope live_grep`:

```vim
:Telescope live_grep grep_open_files=true
```

Dann gib im Prompt Folgendes ein:

```regex
my_func\b
```

**Erklärung:**

* `\b` = Wortgrenze (word boundary)
* findet `my_func` aber **nicht** `my_func_is` oder `my_functional`

**Hinweis:** In `telescope.nvim` musst du dann `--regex` in den Defaults aktivieren, sonst wird der Ausdruck als plain text gewertet (siehe unten).

---

2. **Exakter Match mit Anchors:**

```regex
^my_func$
```

Dies funktioniert nur, wenn du **nur nach `my_func` in einer ganzen Zeile** suchst – also exakte Zeilentreffer. In `live_grep` eher unpraktisch, aber erwähnenswert.

---

## `expand()` - filename modifiers

Neben `%` (für die aktuelle Datei) gibt es in `expand()` viele weitere **Sonderzeichen (Placeholders)**, die **andere Dateien oder Pfade im aktuellen Kontext** referenzieren.

Typische Anwendungskombinationen:

| Ausdruck                | Bedeutung                                 |
| ----------------------- | ----------------------------------------- |
| `expand('%:p')`         | Absoluter Pfad der aktuellen Datei        |
| `expand('%:p:h')`       | Verzeichnis der Datei (absolut)           |
| `expand('<sfile>:p:h')` | Pfad zum aktuell `sourced` Lua/Vim-Skript |
| `expand('%:t:r')`       | Dateiname ohne Endung                     |
| `expand('<cfile>')`     | Pfad unter dem Cursor                     |
| `expand('%:gs?/?\\?')`  | Pfad mit `\` statt `/` (für Windows)      |

Für vollständige Liste:

```vim
:help expand()
:help filename-modifiers
```

### Verwendungsarten

| Kontext                  | Typische Ausdrücke              | Verwendung                            |
| ------------------------ | ------------------------------- | ------------------------------------- |
| **Mappings**             | `<cword>`, `<cfile>`            | Datei öffnen, grep auf Wort, etc.     |
| **Autocmd**              | `<afile>`, `<amatch>`, `<abuf>` | Dynamisches Verhalten bei Events      |
| **Funktionen**           | `<f-args>`                      | Zugriff auf Funktionsargumente        |
| **Befehle (`:command`)** | `<args>`                        | Zugriff auf alle Kommandoargumente    |
| **Scripting**            | `<sfile>`, `<slnum>`, `<SID>`   | Referenz zur aktuellen Datei/Funktion |

### 1. Dateibezogene Platzhalter (`expand()`)

| Platzhalter | Beschreibung                                                           | Beispiel (bei `foo/bar.txt`) |
| ----------- | ---------------------------------------------------------------------- | ---------------------------- |
| `%`         | Der Name der aktuell geöffneten Datei                                  | `foo/bar.txt`                |
| `#`         | Der Name der **alternativen Datei** (per `:e #`, zuletzt bearbeitete)  | `README.md`                  |
| `#n`        | Datei aus der Jumplist (z. B. `#3` für Eintrag 3)                      | `~/.config/nvim/init.lua`    |
| `<afile>`   | Wird bei Autocommands durch den betroffenen Dateinamen ersetzt         | `/tmp/swapfile.swp`          |
| `<abuf>`    | Buffernummer für Autocommands                                          | `4`                          |
| `<amatch>`  | Muster, das den Autocommand ausgelöst hat                              | `*.lua`                      |
| `<sfile>`   | Pfad der aktuell ausgeführten Sourced-Datei (`:source`, Pluginkontext) | `~/.config/nvim/lua/foo.lua` |
| `<SID>`     | Skriptlokaler Prefix für Funktionsdefinitionen (`s:`-Namespace)        | `123_`                       |

### 2. Modifikatoren (anhängbar mit `:`)

Diese kannst du an Platzhalter anhängen, z. B. `expand('%:p:h')`

| Modifikator | Bedeutung                                  | Beispiel (`foo/bar.txt`)      |
| ----------- | ------------------------------------------ | ----------------------------- |
| `:p`        | Absoluter Pfad                             | `/home/user/foo/bar.txt`      |
| `:h`        | Head = Pfad zum Verzeichnis                | `/home/user/foo`              |
| `:t`        | Tail = Dateiname                           | `bar.txt`                     |
| `:r`        | Root = Ohne Dateiendung                    | `foo/bar`                     |
| `:e`        | Extension = nur Dateiendung                | `txt`                         |
| `:s?A?B?`   | Ersetze `A` durch `B`                      | `bar.txt` → `bar.md`          |
| `:gs?A?B?`  | Ersetze alle Vorkommen von `A` durch `B`   | `foo/bar/baz` → `foo_bar_baz` |
| `:8`        | Nur die ersten 8 Zeichen                   | (veraltet, MS-DOS-kompatibel) |
| `:~`        | Zeige `~` für \$HOME                       | `~/foo/bar.txt`               |
| `:.`        | Relativ zu `:cd` (aktuelles Verzeichnis)   | `./bar.txt`                   |
| `:t:r`      | Tail und dann Root → Dateiname ohne Endung | `bar`                         |

### 3. Sonderfall `<cword>` und Co. (nur in `expand()`-Kontexten)

Diese beziehen sich auf den **aktuellen Cursor-Kontext**:

| Ausdruck   | Beschreibung                                              | Beispiel                 |
| ---------- | --------------------------------------------------------- | ------------------------ |
| `<cword>`  | Das Wort unter dem Cursor                                 | `my_variable`            |
| `<cWORD>`  | Großes WORD (inkl. `_`, `-`, etc.)                        | `some-var123`            |
| `<cfile>`  | Pfad unter dem Cursor                                     | `src/utils/file.lua`     |
| `<cexpr>`  | Ausdruck unter dem Cursor                                 | `1 + 2 * var`            |
| `<sfile>`  | Aktuelle Sourced-Datei (z. B. Pluginkontext)              | `~/.config/nvim/lua/...` |
| `<slnum>`  | Aktuelle Zeilennummer im Skript (`<sfile>`)               | `42`                     |
| `<args>`   | Argumente in benutzerdefiniertem `:command` als String    | `foo bar`                |
| `<f-args>` | Argumente in einer Funktionsdefinition als Listenelemente | `{"foo", "bar"}`         |

### Beispielanwendung

```vim
:edit <cfile>                                 " Öffnet Datei unter Cursor
:grep <cword> .                               " Sucht nach Wort unter Cursor im aktuellen Verzeichnis
:autocmd BufReadPost * echo "Opened: <afile>" " Zeigt beim Öffnen einer Datei den Pfad im Echo an
:function! MyFunc(...) echo <f-args>          " Gibt alle übergebenen Funktionsargumente aus
:echo expand("<cword>")                       " Gibt das aktuelle Wort unter dem Cursor aus
```

---

## DEBUG buffer und win

**Aktueller Buffer und Fenster-Infos:**
```lua
:lua print("Buf:", vim.api.nvim_get_current_buf())
:lua print("Win:", vim.api.nvim_get_current_win())
:lua print("Name:", vim.api.nvim_buf_get_name(0))  -- Buffer-Name & Pfad
-- Buffer-Optionen analysieren
:set buftype?
:set filetype?
:set bufhidden?
:set buflisted?
:lua vim.print(vim.api.nvim_win_get_config(0)) -- Fenster-Position & -Typ
:verbose set filetype? -- Zeigt, **welches Skript den `filetype` gesetzt** hat → oft ein Hinweis auf das Plugin.
:verbose nmap <buffer> -- Zeigt buffer-lokale Mappings und deren Herkunftsskript.
:verbose autocmd BufEnter,BufRead <buffer> -- Zeigt z. B. welche Plugins bei Betreten des Buffers etwas tun.
-- Durch Einzelschritte (`n`, `c`, `s`) die Stack-Trace anschauen, bis `vim.api.nvim_open_win(...)` oder `buf_set_lines(...)` auftaucht:
:lua debug.debug()
-- Alternativ mit `:verbose`:
:verbose command MyCommand -- zeigt die Datei, die das Kommando registriert hat.
```

---

## Sync/Async/Parallel

**Begriffe kurz und präzise:**

| Begriff                       | Kurzbeschreibung                                             | Wichtig im Kontext von Neovim/Lua                                                 |
| ----------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| Prozess                       | Eigenständiger Adressraum + Ressourcen, vom OS geplant       | „Parallel“ per mehrere Prozesse (z. B. `rg`, `git`) ist immer möglich             |
| Thread                        | Ausführungseinheit innerhalb eines Prozesses, teilt Speicher | In Neovim nur vorsichtig: Neovim-APIs sind nicht thread-safe                      |
| Parallelismus                 | Gleichzeitige Ausführung auf mehreren CPU-Kernen             | Lua in Neovim ist i. d. R. single-threaded; Parallelismus via Threadpool/Prozesse |
| Nebenläufigkeit (Concurrency) | Überlappende Arbeiten (muss nicht gleichzeitig)              | Event-Loop + Callbacks/Coroutinen in Neovim                                       |
| Synchron                      | Aufruf blockiert bis Ergebnis vorliegt                       | Blockiert UI; vermeiden in Plugins                                                |
| Asynchron                     | Aufruf kehrt sofort zurück, Ergebnis via Callback/Event      | libuv/`vim.loop`/`vim.uv`, `vim.system`, Jobs, Timers                             |
| Blocking                      | Thread wartet (z. B. I/O), keine andere Arbeit               | Vermeiden; ggf. Job/Threadpool nutzen                                             |
| Non-blocking                  | Thread gibt Kontrolle ab, Event-Loop meldet später           | Standardmodell von libuv/Neovim                                                   |
| Event-Loop                    | Zentrale Schleife, die Events/Callbacks abarbeitet           | libuv (wie in Node.js) ist die Basis von Neovim                                   |
| Coroutine                     | Kooperatives „Fiber“-Konstrukt in Lua (kein OS-Thread)       | Ermöglicht „async/await“-Stil in Lua, bleibt single-threaded                      |
| Race Condition                | Nichtdeterminismus durch gemeinsame Daten                    | Relevanz bei Threads/Prozessen; Neovim-API nur im Main-Thread                     |
| Deadlock                      | Gegenseitiges Warten zweier Ausführungsstränge               | Vermeiden durch klare Ownership/kein Blocking im Main-Thread                      |
| Mutex/Semaphor                | Synchronisations-Primitive für Threads                       | In Neovim-Lua selten nötig; lieber Message-Passing/Callbacks                      |

### Was geht in Neovim/Lua wirklich?

• Lua in Neovim läuft im Main-Thread (LuaJIT/5.1). Es gibt keine echten „Lua-Threads“, aber Coroutinen (kooperativ).
• Neovim basiert auf libuv (Event-Loop). Asynchronität kommt über:
– Subprozesse/Jobs: `vim.system` (neu), `vim.fn.jobstart` (alt), RPC-Plugins
– libuv-APIs: `vim.loop`/`vim.uv` (Timer, FS-I/O, TCP/UDP, Spawn, Pipes, Work-Pool)
– Threadpool: libuvs `queue_work` (in Lua via `uv.new_work`) für CPU-lastige Tasks
• Neovim-API ist nicht thread-safe. Aus Worker-Threads niemals direkt `vim.api.*` aufrufen; immer zurück in den Main-Thread „hoppen“ (z. B. via `vim.schedule`).

### Praktische Muster

#### 1) Asynchron via Callbacks (libuv, „roh“)

```lua
-- Uses vim.uv (alias vim.loop). Works on Linux/macOS.
-- Non-blocking fs_stat; prints result on completion.

---@param path string
local function stat_async(path)
  local uv = vim.uv or vim.loop
  uv.fs_stat(path, function(err, stat)
    if err then
      -- Switch to main thread for Neovim APIs/UI
      vim.schedule(function() vim.notify("stat error: " .. err, vim.log.levels.ERROR) end)
      return
    end
    vim.schedule(function()
      vim.notify(("size=%d mtime=%d"):format(stat.size, stat.mtime.sec))
    end)
  end)
end

stat_async(vim.fn.expand("~/.config/nvim/init.lua"))
```

Wichtig: Callback läuft im libuv-Loop-Kontext; für UI/Neovim-APIs immer `vim.schedule`.

#### 2) „async/await“-Stil mit Coroutinen

```lua
-- Minimal await helper: turn a callback-style function into a coroutine-friendly one.

---@generic T
---@param starter fun(cb:fun(err?:string, result?:T))   -- function that starts async op and calls cb
---@return T|nil, string|nil
local function await(starter)
  local co = coroutine.running()
  assert(co, "await must be called from within a coroutine")
  local returned, err, result = false, nil, nil
  starter(function(e, r)
    if not returned then
      returned = true
      return assert(coroutine.resume(co, e, r))
    end
  end)
  returned = true
  return coroutine.yield()
end

-- Example: await fs_stat using libuv
local function fs_stat_await(path)
  local uv = vim.uv or vim.loop
  return await(function(cb)
    uv.fs_stat(path, function(err, stat) cb(err, stat) end)
  end)
end

-- Run a coroutine "task"
local function run_task(fn)
  local co = coroutine.create(fn)
  local ok, err = coroutine.resume(co)
  if not ok and err then vim.notify("task error: " .. tostring(err), vim.log.levels.ERROR) end
end

run_task(function()
  local err, st = fs_stat_await(vim.fn.expand("~/.config/nvim/init.lua"))
  if err then
    vim.schedule(function() vim.notify("fs_stat failed: " .. err, vim.log.levels.ERROR) end)
    return
  end
  vim.schedule(function() vim.notify(("mtime=%d"):format(st.mtime.sec)) end)
end)
```

Hinweis: Das bleibt single-threaded, fühlt sich aber an wie „await“. Alternativ kann man Libraries wie `plenary.async` nutzen.

#### 3) Subprozesse: modern mit `vim.system`

```lua
-- Run an external command asynchronously and handle output safely.
-- Neovim 0.10+: vim.system is the preferred API.

---@param cmd string[]
---@param on_done fun(code: integer, out: string, err: string)
local function run_system(cmd, on_done)
  vim.system(cmd, { text = true }, function(obj)
    -- Back to main thread for UI
    vim.schedule(function() on_done(obj.code, obj.stdout or "", obj.stderr or "") end)
  end)
end

run_system({ "rg", "--version" }, function(code, out, err)
  if code == 0 then
    vim.notify("ripgrep: " .. out:match("[^\n]+"))
  else
    vim.notify("rg failed: " .. err, vim.log.levels.ERROR)
  end
end)
```

Alt/Kompat: `vim.fn.jobstart`/`jobwait`/`chan*` in Vimscript; in Lua nutzt man gewöhnlich `vim.system` oder `plenary.job`.

#### 4) CPU-Arbeit in Threads (libuv Threadpool)

```lua
-- Offload CPU-bound work to libuv's threadpool; never touch Neovim API in worker!

local uv = vim.uv or vim.loop

-- Create a work item: first function runs in a worker thread, second runs on loop thread.
---@type uv_work_t
local work = uv.new_work(
  function(n) -- worker thread: pure Lua, no Neovim API here!
    -- Example: a naive CPU-heavy loop
    local s = 0
    for i = 1, n do s = s + math.sqrt(i) end
    return s
  end,
  function(result) -- completion callback on event loop thread
    vim.schedule(function()
      vim.notify(("work done: %.2f"):format(result))
    end)
  end
)

-- Queue the work item
work:queue(2e6)  -- tune n to your needs
```

Notizen:
• libuv-Threadpoolgröße standardmäßig 4; bei Bedarf per Umgebungsvariable `UV_THREADPOOL_SIZE` erhöhen (vor Start von Neovim).
• Niemals `vim.api.*` im Worker benutzen; Ergebnisse per Rückgabewert in den After-Callback, dann `vim.schedule`.

#### 5) Timer/„sleep“ ohne Blockieren

```lua
-- Non-blocking sleep implemented with a timer + coroutine await

---@param ms integer
local function sleep(ms)
  return await(function(cb)
    local timer = (vim.uv or vim.loop).new_timer()
    timer:start(ms, 0, function()
      timer:stop(); timer:close()
      cb(nil, true)
    end)
  end)
end

run_task(function()
  vim.schedule(function() vim.notify("wait 300ms...") end)
  sleep(300)
  vim.schedule(function() vim.notify("done") end)
end)
```

#### 6) Multiprozess-Architektur / RPC

• Neovim kann externe Prozesse (z. B. eigene Lua/Go/Node-Programme) per msgpack-RPC anbinden.
• Diese Prozesse laufen „parallel“, können CPU-lastige Aufgaben übernehmen und schicken Ergebnisse zurück.
• Für Lua bietet sich ein eigenständiger Prozess (LuaJIT/luvi) an; in Plugins meist einfacher: `vim.system`/`jobstart` mit Zeilen-basiertem Protokoll.

### Was ist mit „echtem“ Multithreading in Lua?

• Innerhalb *einer* Lua-VM gibt es keine Preemption/echte Lua-Threads. Coroutinen sind kooperativ.
• libuv bietet Worker-Threads, aber diese teilen keine Neovim-State/VM. Kommunikation erfolgt über Rückgabewerte in den Completion-Callback oder über Pipes/Queues (`uv.new_async`, Pipes).
• Es gibt in luv auch echte Threads (`uv.new_thread`), aber: eigene Lua-States, kein sicherer Zugriff auf Neovim-APIs; in Plugins i. d. R. nicht nötig—`uv.new_work` ist der sichere Pfad.

### Vimscript-Gegenstücke (kurz)

| Feld     | Vimscript                                                         |
| -------- | ----------------------------------------------------------------- |
| Jobs     | `job_start()` + `on_stdout`/`on_stderr`/`on_exit`, `job_stop()`   |
| Warten   | `job_wait()` (blockiert), Timer via `timer_start(ms, {callback})` |
| Channels | `ch_sendraw()`/`ch_read()`                                        |
| RPC      | `rpcstart()`, `rpcrequest()`/`rpcnotify()`                        |

Für neue Projekte empfiehlt sich in Neovim Lua die Nutzung von `vim.system`/`vim.uv`.

### Best Practices

• Keine blockierenden Aufrufe im Main-Thread (kein `vim.fn.systemlist()` für große Jobs).
• IO-lastig: `vim.system` oder `vim.uv` benutzen; CPU-lastig: `uv.new_work` oder externer Prozess.
• Alle UI/Neovim-API-Zugriffe via `vim.schedule` zurück in den Main-Thread.
• Pfade/Quoting robust halten (POSIX vs. macOS Besonderheiten); auf Linux/macOS sind `bash`-Semantiken erwartbar.
• Für „await“-artige APIs lieber Coroutinen kapseln oder `plenary.async` verwenden, statt busy-wait (`vim.wait`) zu nutzen.

### Kurzfazit

• „Multithreaded arbeiten“ in Neovim bedeutet: CPU-Arbeit in libuvs Threadpool auslagern oder externe Prozesse verwenden; die Lua-Seite selbst bleibt kooperativ (Coroutinen).
• „async/await“ erreicht man mit Coroutinen (eigener Wrapper oder `plenary.async`).
• libuv liefert Asynchronität über Event-Loop, Non-Blocking-IO, Timer, Subprozesse und einen Threadpool; in Lua erreichbar via `vim.uv`/`vim.loop` und `vim.system`.

---

