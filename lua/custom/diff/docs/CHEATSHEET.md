# Cheatsheet: custom/diff Subsystem

## Table of content

- [Cheatsheet: custom/diff Subsystem](#cheatsheet-customdiff-subsystem)
  - [Befehlsübersicht & Keymaps](#befehlsbersicht-keymaps)
  - [Der `:Diff` Befehl (Parameter-Referenz)](#der-diff-befehl-parameter-referenz)
    - [1. `target=` (Womit vergleichen?)](#1-target-womit-vergleichen)
    - [2. `source=` (Ausgangsbasis; Default: `current`)](#2-source-ausgangsbasis-default-current)
    - [3. `view=` (Wie darstellen?; Default: `vsplit`)](#3-view-wie-darstellen-default-vsplit)
    - [4. `output=` (Wohin mit dem Ergebnis?; Default: `buffer`)](#4-output-wohin-mit-dem-ergebnis-default-buffer)
  - [Praxis-Beispiele (Varianten)](#praxis-beispiele-varianten)
    - [Die Klassiker](#die-klassiker)
    - [Fortgeschrittene Splits & Quellen](#fortgeschrittene-splits-quellen)
    - [Leichtgewichtige Ausgaben (Ohne Fenster-Splits)](#leichtgewichtige-ausgaben-ohne-fenster-splits)
    - [Aufräumen](#aufrumen)

---

## Befehlsübersicht & Keymaps

| Befehl / Keymap | Komponente | Beschreibung |
| --- | --- | --- |
| `:Diff [args]` | `diff` | Startet den flexiblen Diff-Modus (Details siehe unten). |
| `:DiffOrigin` | `diff_origin` | Vergleicht aktuellen Buffer mit der letzten gespeicherten Version auf Festplatte/Git. |
| `:DiffExit` | `diff_exit` | Beendet den Diff-Modus und schließt alle Diff-Fenster sauber. |
| `q` | `diff_exit` | Automatisches Keymap **nur im Diff-Modus**, führt `:DiffExit` aus. |
| `:DiffClear` | `diff` | Schließt alle `:Diff`-Fenster und löscht temporäre Scratch-Buffer. |

---

## Der `:Diff` Befehl (Parameter-Referenz)

**Syntax:** `:Diff [target=...] [source=...] [view=...] [output=...]`

*(Alle Parameter sind optional und nutzen die `key=value` Syntax. Reihenfolge ist egal.)*

### 1. `target=` (Womit vergleichen?)

*Falls weggelassen, öffnet sich ein interaktives Auswahlmenü (Popup).*

* `clipboard` – Inhalt der System-Zwischenablage (`+` Register).
* `<path>` – Pfad zu einer Datei (unterstützt Tab-Completion).
* `<bufnr>` – Nummer eines bereits geöffneten Neovim-Buffers.

### 2. `source=` (Ausgangsbasis; Default: `current`)

* `current` – Der aktuell aktive Buffer bei Befehlsaufruf.
* `<path>` – Pfad zu einer Datei.
* `<bufnr>` – Nummer eines geöffneten Buffers.

### 3. `view=` (Wie darstellen?; Default: `vsplit`)

* `vsplit` – Vertikaler Split (Side-by-Side).
* `split` – Horizontaler Split.
* `inline` – *Für zukünftige In-Place-Darstellung reserviert.*

### 4. `output=` (Wohin mit dem Ergebnis?; Default: `buffer`)

* `buffer` – Interaktiver Scratch-Buffer im Split-Fenster.
* `prompt` – Reiner Text-Diff im Command-Line-Bereich (`:h more-prompt`).
* `file` – Schreibt den Unified-Diff in eine temporäre `.diff` Datei.

---

## Praxis-Beispiele (Varianten)

### Die Klassiker

```vim
" Interaktiver Modus: Frag mich, womit ich den aktuellen Buffer vergleichen will
:Diff

" Aktuellen Buffer gegen die Zwischenablage prüfen
:Diff target=clipboard

" Aktuellen Buffer gegen die letzte gespeicherte Version prüfen (Alternative zu :DiffOrigin)
:DiffOrigin

```

### Fortgeschrittene Splits & Quellen

```vim
" Gegen Buffer Nr. 3 vergleichen, aber im horizontalen Split statt vertikal
:Diff target=3 view=split

" Zwei komplett andere Dateien miteinander vergleichen (ohne im selben Buffer zu sein)
:Diff target=alt.lua source=neu.lua

```

### Leichtgewichtige Ausgaben (Ohne Fenster-Splits)

```vim
" Schneller Inline-Check gegen Clipboard im Command-Line-Prompt (kein neues Fenster)
:Diff target=clipboard output=prompt

" Den Diff als temporäre Datei exportieren (z.B. zum Verschicken)
:Diff target=../old_version.lua output=file

```

### Aufräumen

```vim
" Schließt alle geöffneten Diffs und löscht den RAM-Cache
:DiffClear
" ...oder einfach im Diff-Fenster drücken:
q

```
