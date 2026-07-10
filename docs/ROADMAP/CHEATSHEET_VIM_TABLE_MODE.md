# Vim Table Mode Cheatsheet

## Table of content

  - [Globale Befehle (User Commands)](#globale-befehle-user-commands)
  - [Standard-Tastenkombinationen (Keymaps)](#standard-tastenkombinationen-keymaps)
    - [Modus & Formatierung](#modus-formatierung)
    - [Tabellen-Manipulation (Editieren)](#tabellen-manipulation-editieren)
    - [Navigation (Bewegung zwischen Zellen)](#navigation-bewegung-zwischen-zellen)
    - [Text-Objekte (Text Objects)](#text-objekte-text-objects)
  - [On-the-Fly Shortcuts (Insert-Modus Abkürzungen)](#on-the-fly-shortcuts-insert-modus-abkrzungen)
  - [Tabellenkalkulation & Formeln (Spreadsheet)](#tabellenkalkulation-formeln-spreadsheet)
    - [Formel-Tastenkombinationen](#formel-tastenkombinationen)
    - [Syntax-Referenz für Targets & Variablen](#syntax-referenz-fr-targets-variablen)
    - [Integrierte Sonderfunktionen](#integrierte-sonderfunktionen)
  - [Wichtige Konfigurationsvariablen (`vim.g`)](#wichtige-konfigurationsvariablen-vimg)

---

## Globale Befehle (User Commands)

| Befehl | Beschreibung |
| --- | --- |
| `:TableModeToggle` | Schaltet den automatischen Tabellenmodus an/aus. |
| `:TableModeEnable` | Aktiviert den Tabellenmodus explizit. |
| `:TableModeDisable` | Deaktiviert den Tabellenmodus explizit. |
| `:TableModeRealign` | Richtet eine bestehende (z.B. reinkopierte) Tabelle neu aus. |
| `:Tableize` | Konvertiert visuell markierten CSV-Text in eine Tabelle (Komma-getrennt). |
| `:Tableize/{pattern}` | Konvertiert Text anhand eines eigenen Trennzeichens (z.B. `:Tableize/;`). |
| `:TableAddFormula` | Fügt der aktuellen Zelle eine Tabellenkalkulations-Formel hinzu. |
| `:TableEvalFormulaLine` | Berechnet alle mathematischen Formeln in der Formel-Zeile neu. |

---

## Standard-Tastenkombinationen (Keymaps)

*Hinweis: `<Leader>` ist standardmäßig die Backslash-Taste `\`, sofern du sie nicht umbelegt hast.*

### Modus & Formatierung

| Keymap | Modus | Beschreibung |
| --- | --- | --- |
| `<Leader>tm` | Normal | Schaltet den Tabellenmodus um (`Toggle`). |
| `<Leader>tr` | Normal | Richtet die Tabelle unter dem Cursor neu aus (`Realign`). |
| `<Leader>tt` | Visuell | Konvertiert markierte CSV-Zeilen in eine Tabelle (`Tableize`). |
| `<Leader>T` | Normal | Nimmt via Command-Line ein Trennzeichen entgegen, um die nächsten `[count]` Zeilen zu konvertieren. |

### Tabellen-Manipulation (Editieren)

| Keymap | Modus | Beschreibung |
| --- | --- | --- |
| `<Leader>tdd` | Normal | Löscht die aktuelle Tabellenzeile (akzeptiert `[count]`). |
| `<Leader>tdc` | Normal | Löscht die aktuelle Spalte komplett (akzeptiert `[count]`). |
| `<Leader>tic` | Normal | Fügt eine neue Spalte **nach** der aktuellen Cursorposition ein. |
| `<Leader>tiC` | Normal | Fügt eine neue Spalte **vor** der aktuellen Cursorposition ein. |

### Navigation (Bewegung zwischen Zellen)

| Keymap | Modus | Beschreibung |
| --- | --- | --- |
| `]` `|` | Normal | Springt eine Zelle nach **rechts** (springt am Zeilenende in die nächste Zeile). |
| `[` `|` | Normal | Springt eine Zelle nach **links** (springt am Zeilenanfang in die vorherige Zeile). |
| `}` `|` | Normal | Springt eine Zelle nach **unten**. |
| `{` `|` | Normal | Springt eine Zelle nach **oben**. |

### Text-Objekte (Text Objects)

| Keymap | Modus | Beschreibung |
| --- | --- | --- |
| `i|` | Operator-Pending / Visuell | Wählt den **Inhalt** der aktuellen Tabellenzelle aus (inner cell). |
| `a|` | Operator-Pending / Visuell | Wählt die aktuelle Zelle **inklusive** des rechten Trennzeichens `|` aus (around cell). |

---

## On-the-Fly Shortcuts (Insert-Modus Abkürzungen)

Wenn du das im README gezeigte Snippet in deiner Konfiguration aktivierst, gelten im **Insert-Modus** folgende Automatismen am Zeilenanfang:

* `||` Schaltet den Tabellenmodus sofort ein und bereitet die erste Zeile vor.
* `__` Schaltet den Tabellenmodus im Insert-Modus stumm wieder aus.
* Tippst du im Tabellenmodus in der zweiten Zeile `||`, wird automatisch die Trennlinie (`|---|---|`) generiert.

---

## Tabellenkalkulation & Formeln (Spreadsheet)

Formeln werden direkt unter der Tabelle in einer Kommentarzeile deklariert, die mit `tmf:` beginnt (z.B. `# tmf: $3=$2*$1`).

### Formel-Tastenkombinationen

| Keymap | Modus | Beschreibung |
| --- | --- | --- |
| `<Leader>tfa` | Normal | Formel über die Befehlszeile (`f=`) zur aktuellen Zelle hinzufügen. |
| `<Leader>tfe` | Normal | Formellauf erzwingen / Werte neu berechnen (`Evaluate`). |
| `<Leader>t?` | Normal | Zeigt die Formel an, die für die aktuelle Zelle gilt. |

### Syntax-Referenz für Targets & Variablen

* `$n` Steht für die Spalte `n` (z. B. `$3` ist die 3. Spalte). Negative Indizes zählen von rechts (`$-1` ist die letzte Spalte).
* `$n,m` Steht für eine exakte Zelle (`$Zeile,Spalte`). Negative Werte zählen vom Ende.
* **Bereiche (Ranges):**
* `r1:r2` Alle Zellen in der aktuellen Spalte von Zeile `r1` bis `r2` (z.B. `1:-1` für alle vorherigen Datenzeilen).
* `r1,c1:r2,c2` Matrix-Bereich von Zelle `r1,c1` bis `r2,c2`.



### Integrierte Sonderfunktionen

* `Sum(Bereich)` Bildet die Summe des angegebenen Bereichs (z.B. `$5,1 = Sum(1:-1)`).
* `Average(Bereich)` Berechnet den Durchschnitt des Bereichs.
* *Hinweis: Alle nativen Vim-Mathematikfunktionen (wie `pow()`, `float2nr()`) können verwendet werden.*

---

## Wichtige Konfigurationsvariablen (`vim.g`)

In Lua (für Neovim / Lazy) setzt du diese Werte mit `vim.g.VARIABLEN_NAME = WERT`.

* **Markdown-Kompatibilität erzwingen:**
```lua
vim.g.table_mode_corner = '|'

```


* **ReST-Kompatibilität erzwingen:**
```lua
vim.g.table_mode_corner_corner = '+'
vim.g.table_mode_header_fillchar = '='

```


* **Dynamische Zelleneinfärbung aktivieren:**
```lua
vim.g.table_mode_color_cells = 1
-- Färbt Zellen, die mit "yes" starten grün (yesCell), mit "no" rot (noCell) und mit "?" gelb (maybeCell).

```
