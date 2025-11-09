# Spickzettel

## Table of content

  - [Custom Usrcommands](#custom-usrcommands)
  - [Custom mappings](#custom-mappings)
  - [Custom Markdown: UserCommands und Mappings](#custom-markdown-usercommands-und-mappings)
  - [1. Operator + Textobjekt (präzise und schnell)](#1-operator-textobjekt-przise-und-schnell)
  - [2. Visual + Textobjekt (explizit markieren)](#2-visual-textobjekt-explizit-markieren)
  - [3. Bewegung bis zum Trennzeichen (wenn das nächste Zeichen bekannt ist)](#3-bewegung-bis-zum-trennzeichen-wenn-das-nchste-zeichen-bekannt-ist)
  - [4. Alternative Bewegung statt w in Visual](#4-alternative-bewegung-statt-w-in-visual)
  - [5. Bewegungen innerhalb einer Zeile](#5-bewegungen-innerhalb-einer-zeile)
  - [6. Direkt in den Insert-Modus springen (Bewegung + sofort Einfügen)](#6-direkt-in-den-insert-modus-springen-bewegung-sofort-einfgen)
  - [7. Nützliche Wort- und Satzbewegungen](#7-ntzliche-wort-und-satzbewegungen)
  - [8. Wiederholen & Korrigieren](#8-wiederholen-korrigieren)
  - [9. nach "oben" / "rechts" usw..](#9-nach-oben-rechts-usw)
  - [Markdown](#markdown)
    - [Syntax](#syntax)
      - [Anker](#anker)
      - [Tabellen referenzieren](#tabellen-referenzieren)
      - [Einfache Tabellen-Referenz](#einfache-tabellen-referenz)
      - [Tabelle mit HTML-Wrapper](#tabelle-mit-html-wrapper)
    - [Link unter Cursor in System app öffnen](#link-unter-cursor-in-system-app-ffnen)
    - [Alle Zeilen außer headlines löschen](#alle-zeilen-auer-headlines-lschen)
  - [Terminal](#terminal)
    - [Steuersequenzen](#steuersequenzen)
  - [Powershell](#powershell)
    - [Installationsort / Binary ausgeben](#installationsort-binary-ausgeben)
  - [Schnelle Befehle in Neovim, um Browser manuell zu öffnen](#schnelle-befehle-in-neovim-um-browser-manuell-zu-ffnen)

---

<div id="#...">, <section id="#...">, <a href="#...">, <img src="#...">,

 `<C-6>` oder `edit #` öffnet letzte datei
 `:edit #`: springe zum letzten buffer
 `goto smth` in branches verwenden
 `vert res +10`
 `checkhealth vim.lsp` statt `LspInfo`
 `leader gd` - Diffsplit
 `S-c` - löschen vom Cursor bis ans Ender der Zeile

`:NewFile {path}`           -> set buffer name, create parents, do NOT write by default
`:NewFileWrite {path}`      -> like NewFile, but also :write immediately
`:SaveAsR[!] {path}`        -> save-as, create parents; with ! force overwrite
`:writetor[!] {path} `      -> write copy, create parents; with ! force overwrite
`:MkParent`                 -> ensure parent dir for the current buffer name
`FindFiles{Telescope/Fzf}`  -> Find files in Telescope or Fzf
`Grep{Telescope/Fzf}`       -> Grep in Telescope or Fzf

## Custom mappings

`<A-m>`                     -> Öffnet 'find files or grep' selector
`telf /telg / fzff / fzfg`  -> {find files or grep} in custom dir with {telescope or fzf}
'n', '<leader>tp', tableview.pick, "[Custom.Markdown] Pick table preview", o)
'n', '<leader>tc', tableview.show_table_at_cursor, "[Custom.Markdown] Preview table at cursor", o)

`:ColumnAlignToColumn <target_col> [fill_char]`
'x', `<leader>cal`,  Align character to column

## Custom Markdown: UserCommands und Mappings

| Typ | Command/Mapping | Beschreibung |
|-----|-----------------|--------------|
| UserCommand | ============================ | ============================================================ |
|             | `:OpenWithSystemApplication` | Image/Url/File unter Cursor mit System-App öffnen |
|             | `:TableViewToggle`           | Vorschau der Tabelle unter dem Cursor ein-/ausschalten |
|             | `:TableViewSelect`           | Tabelle aus Liste aller Tabellen im Buffer auswählen und anzeigen |
|             | `:TableViewClose`            | Persistente Tabellenvorschau schließen |
|             | `:TableViewOpenBrowser`      | Tabelle unter Cursor als einfaches HTML im Browser öffnen |
|             | `:TableViewOpenBrowserNice`  | Tabelle unter Cursor als formatiertes HTML im Browser öffnen |
| Mapping     | ============================ | ============================================================ |
|             | `<leader>tvt`                | Toggle: Tabellenvorschau unter Cursor ein-/ausschalten |
|             | `<leader>tvs`                | Select: Tabelle aus Auswahlliste anzeigen |
|             | `<leader>tvb`                | Browser: Tabelle unter Cursor im Browser öffnen |
|             | `<leader>tvc`                | Close: TableView-Vorschau schließen |
|             | `**` (visual)                | Fettformatierung um Auswahl umschalten |
|             | `mk`                         | Zum vorherigen Heading (H2+) springen |
|             | `mj`                         | Zum TOC-Anchor unter Cursor springen |
|             | `<localleader>f` | Fold unter Cursor ein-/ausschalten und zentrieren |
|             | `zf` | Fold unter Cursor ein-/ausschalten (optional override) |
|             | `zu` | Alle Folds öffnen und zentrieren |
|             | `zi` | Vorheriges Heading falten und zentrieren |
|             | `zk` | Alle H2+ Headings falten (H1 bleibt offen) |
|             | `<leader>toc` | Table of Content einfügen oder aktualisieren |
|             | `mo` | Kontextsensitive Aktion: TOC-Navigation/Image/URL/File öffnen |
|             | `<2-LeftMouse>` | Kontextsensitive Aktion: TOC-Navigation/Image/URL/File öffnen |
|             | `<C-LeftMouse>` | Kontextsensitive Aktion: TOC-Navigation/Image/URL/File öffnen |
|             | `mi` | Bild unter Cursor mit System-Viewer öffnen |
|             | `<leader>tp` | Tabelle aus Auswahlliste anzeigen |
|             | `<leader>tc` | Tabellenvorschau unter Cursor anzeigen |
|             | `<leader>mhI` | Heading-Level erhöhen (Zeile/Visual/Motion) |
|             | `<leader>mhD` | Heading-Level verringern (Zeile/Visual/Motion) |
|             | `<leader>mhi` | Heading-Level erhöhen (Operator-Pending-Mode) |
|             | `<leader>mhd` | Heading-Level verringern (Operator-Pending-Mode) |
|             | `<leader>mhIA` | Alle Headings im Buffer um eine Ebene erhöhen |
|             | `<leader>mhDA` | Alle Headings im Buffer um eine Ebene verringern |

## 1. Operator + Textobjekt (präzise und schnell)

   * ciw → „change inner word“: ändert nur das Wort, Satzzeichen bleiben.
   * caw → „change a word“: wie oben, nimmt nachfolgendes Leerzeichen mit.
   * ci" / ci' / ci( / ci[ → „change inside …“: Inhalt zwischen Anführungszeichen/Klammern ändern.
   * ca" / ca' / ca( / ca[ → wie oben, inklusive der Klammern/Anführungszeichen selbst.

## 2. Visual + Textobjekt (explizit markieren)

   * viw gefolgt von c → markiert nur das Wort, kein Komma.
   * vaw gefolgt von c → wie oben, plus nachfolgendes Leerzeichen.
   * vi" / vi' / vi( / vi[ → markiert nur den inneren Inhalt von Anführungszeichen/Klammern.
   * va" / va' / va( / va[ → markiert inkl. Anführungszeichen/Klammern selbst.

## 3. Bewegung bis zum Trennzeichen (wenn das nächste Zeichen bekannt ist)

   * ct, → „change till ,“: ändert bis vor das Komma, Komma bleibt erhalten.
   * dt, / yt, → analog für delete/yank ohne das Komma.
   * f, → springt direkt zum nächsten Komma (inklusive).
   * t, → springt bis vor das nächste Komma.
   * ; / , → wiederholt f/t in Vorwärts- / Rückwärtsrichtung.

## 4. Alternative Bewegung statt w in Visual

   * ve statt vw → „bis Wortende“ statt „zum nächsten Wortanfang“; so wird das Komma nicht mit ausgewählt.
   * vE → bis Wortende (großes E = WORD, inkl. Bindestriche etc. als ein Block).
   * vb / vB → markiert rückwärts bis Wort- / WORD-Anfang.

## 5. Bewegungen innerhalb einer Zeile

   * ^ → zum ersten Nicht-Leerzeichen der Zeile.
   * 0 → zum absoluten Zeilenanfang.
   * $ → zum Zeilenende.
   * g_ → zum letzten Nicht-Leerzeichen der Zeile.

## 6. Direkt in den Insert-Modus springen (Bewegung + sofort Einfügen)

   * ea → springt ans Ende des aktuellen Wortes und startet Insert dahinter.
   * eA → wie ea, aber WORD (inkl. Bindestriche etc.).
   * a → fügt direkt hinter dem aktuellen Zeichen ein.
   * A → fügt am Zeilenende ein.
   * I → fügt am ersten Nicht-Leerzeichen der Zeile ein (wie ^ + i).
   * gI → fügt am absoluten Zeilenanfang ein (wie 0 + i).
   * o → öffnet eine neue Zeile unterhalb und wechselt in Insert.
   * O → öffnet eine neue Zeile oberhalb und wechselt in Insert.

## 7. Nützliche Wort- und Satzbewegungen

   * w / W → vorwärts zum Anfang des nächsten Wortes / WORDs.
   * e / E → vorwärts zum Ende des aktuellen Wortes / WORDs.
   * b / B → rückwärts zum Anfang des aktuellen Wortes / WORDs.
   * ge / gE → rückwärts zum Ende des vorherigen Wortes / WORDs.

## 8. Wiederholen & Korrigieren

   * . → wiederholt die letzte Änderung.
   * u → macht letzte Änderung rückgängig.
   * U → stellt ganze Zeile wieder her.
   * Ctrl-r → stellt rückgängig gemachte Änderungen wieder her (redo).

## 9. nach "oben" / "rechts" usw..
   * d3k → 3 Zeilen nach oben löschen
   * c3k → 3 Zeilen nach oben ändern
   * c3l → 3 chars nach rechts ändern
   * ...

---

## Lua Language Server Annotationen

Beispiel Funktionssignatur:

- `--@return`
    - mehrere return Werte möglich
    - immer return Wert angeben
- `---@param`
    - Parameter extrahieren als eigene Klassen wenn möglich
    - Mit `#` detailierter Beschreibungen trennen

```lua
---@param exe string # Absolute path or candidate name of the browser executable
---@param url string # URL to open
---@return string[] args # Command-line arguments to pass to the executable
---@return string|nil tmp_profile # Path to temporary profile/directory (if created)
return function (exe, url)
```

## Markdown

### Syntax

#### Anker

HTML figure-Element:

```md
<figure id="fig-architecture">
  <img src="images/architecture.png" alt="System Architecture">
  <figcaption>Abbildung 1: Systemarchitektur mit allen Komponenten</figcaption>
</figure>

<!-- Verwendung im Text -->
Wie in [Abbildung 1](#fig-architecture) dargestellt...
```

---

#### Tabellen referenzieren

Tabellen werden ähnlich wie Abbildungen behandelt, sollten aber ein eigenes Präfix verwenden.

#### Einfache Tabellen-Referenz

```md
<a id="tbl-opcodes"></a>

| Opcode | Mnemonic | Beschreibung |
|--------|----------|--------------|
| 0x00   | NOP      | No Operation |
| 0x01   | MOV      | Move Data    |
| 0x02   | ADD      | Addition     |

**Tabelle 3.1:** Übersicht der CPU-Opcodes

<!-- Verwendung -->
Die Opcodes ([Tab. 3.1](#tbl-opcodes)) zeigen die Basisoperationen.
```

#### Tabelle mit HTML-Wrapper

```md
<div id="tbl-memory-layout">

| Segment | Start    | Ende     | Größe |
|---------|----------|----------|-------|
| .text   | 0x400000 | 0x400FFF | 4KB   |
| .data   | 0x600000 | 0x600FFF | 4KB   |
| .bss    | 0x601000 | 0x601FFF | 4KB   |

**Tabelle 4.2:** Memory Layout der einzelnen Segmente

</div>

<!-- Verwendung -->
Das Layout ([siehe Tabelle 4.2](#tbl-memory-layout)) zeigt die Segmentierung.
```

---

### Link unter Cursor in System app öffnen

```lua
" Windows:
:lua vim.fn.jobstart({"cmd.exe", "/c", "start", '""', vim.fn.resolve(vim.fn.expand("%:h") .. "/" .. vim.api.nvim_get_current_line():match("%[.-%]%((.-)%)"))}, {detach=true})

" Oder kürzer mit relativen Pfad direkt:
:!start ./Figures/Figure_4.7_Performance-Effect-of-Mulitple-Cores.png

" Oder am einfachsten mit expandcmd:
:lua vim.fn.jobstart({"cmd.exe", "/c", "start", "", "./Figures/Figure_4.7_Performance-Effect-of-Mulitple-Cores.png"}, {detach=true})
```

### Alle Zeilen außer headlines löschen


```vim
:g/^[^#]/d
:g/^\s*[^#]/d
```

Erklärung:
- `^\s*` → optional beliebige Whitespaces am Zeilenanfang
- `[^#]` → erstes **nicht-# Zeichen**
- `d` → löscht die gesamte Zeile

Wenn man **wirklich alle Zeilen außer Headlines** entfernen will, egal ob leer, nur Leerzeichen oder Text, kann man auch `:v` benutzen:

```vim
:v/^#/d
```

- `:v/^#/d` → löscht **alle Zeilen, die nicht mit `#` beginnen**, inklusive leerer oder whitespace-only Zeilen.

## Terminal

* Einen `Ctrl+C`-Like an das Terminal senden (wenn Terminal ein Buffer ist):

  ```vim
  :lua vim.api.nvim_chan_send(vim.b.terminal_job_id, "\003")
  ```

  Das sendet das Byte \x03 (ETX) — entspricht Ctrl+C — an den Terminal-Job.

* Terminal-Job sauber stoppen (empfohlen):

  ```vim
  :lua vim.fn.jobstop(vim.b.terminal_job_id)
  ```


  ```vim
   Terminierte den aktuellen Prozess (Ctrl+C)
  vim.api.nvim_chan_send(vim.b.terminal_job_id, "\003")
  ```

  ```vim
  -- Sendet Enter
  vim.api.nvim_chan_send(vim.b.terminal_job_id, "\r")
  ```

  ```vim
  -- Sendet Ctrl+D (EOF)
  vim.api.nvim_chan_send(vim.b.terminal_job_id, "\004")
  ```

  ```vim
  -- Sendet Text und Enter
  vim.api.nvim_chan_send(vim.b.terminal_job_id, "echo 'Hello'\r")
  ```

---

### Steuersequenzen

```vim
vim.api.nvim_chan_send(vim.b.terminal_job_id, "ls\n") -- Sendet den Text "ls\n" an das aktive Terminal
vim.api.nvim_chan_send(vim.b.terminal_job_id, "\003")
```

| Escape | Oktal | Hex  | ASCII | Bedeutung                      |
| ------ | ----- | ---- | ----- | ------------------------------ |
| `\000` | 000   | 0x00 | NUL   | Null Byte                      |
| `\003` | 003   | 0x03 | ETX   | End of Text (Ctrl+C)           |
| `\004` | 004   | 0x04 | EOT   | End of Transmission (Ctrl+D)   |
| `\010` | 010   | 0x08 | BS    | Backspace                      |
| `\011` | 011   | 0x09 | TAB   | Tabulator                      |
| `\012` | 012   | 0x0A | LF    | Line Feed (Enter)              |
| `\015` | 015   | 0x0D | CR    | Carriage Return (Enter/Return) |
| `\033` | 033   | 0x1B | ESC   | Escape                         |

| Zeichen | Oktal | Tastenkombination | Bedeutung                 |
| ------- | ----- | ----------------- | ------------------------- |
| `\001`  | 001   | Ctrl+A            | Move cursor to line start |
| `\002`  | 002   | Ctrl+B            | Move cursor left          |
| `\003`  | 003   | Ctrl+C            | Interrupt / SIGINT        |
| `\004`  | 004   | Ctrl+D            | EOF / Exit input          |
| `\005`  | 005   | Ctrl+E            | Move cursor to line end   |
| `\006`  | 006   | Ctrl+F            | Move cursor right         |
| `\007`  | 007   | Ctrl+G            | Bell (Beep)               |
| `\010`  | 010   | Ctrl+H            | Backspace                 |
| `\011`  | 011   | Ctrl+I            | Tab                       |
| `\012`  | 012   | Ctrl+J            | Line Feed (Enter)         |
| `\015`  | 015   | Ctrl+M            | Carriage Return           |
| `\033`  | 033   | ESC               | Escape key                |

---

## Powershell

### Installationsort / Binary ausgeben

```powershell
# Methode 1: where (eingebaut in cmd/PowerShell)
where EXECUTABLE_NAME

# Methode 2: Get-Command (PowerShell)
(Get-Command EXECUTABLE_NAME).Source

# Methode 3: gcm Alias (PowerShell, kürzer)
(gcm EXECUTABLE_NAME).Source
```

## Browser manuell zu öffnen

```lua
-- macOS:
:lua vim.fn.jobstart({"open", "http://localhost:43219"})

-- Linux:
:lua vim.fn.jobstart({"xdg-open", "http://localhost:43219"})

-- Windows (cmd):
:lua vim.fn.jobstart({"cmd", "/c", "start", "", "http://localhost:43219"})
```

---
