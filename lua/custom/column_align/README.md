# custom.column_align

Neovim-Modul zum visuellen Ausrichten eines einzelnen Zeichens auf eine gewünschte Zielspalte durch Auffüllen mit einem frei wählbaren Füllzeichen.

Das Modul besteht aus einer UI-/Command-Schicht und einer klar getrennten Core-Implementierung.

---

## Table of content

  - [Zweck](#zweck)
  - [Voraussetzungen](#voraussetzungen)
  - [Installation](#installation)
  - [Tastenkombination](#tastenkombination)
  - [User Commands](#user-commands)
    - [:ColumnAlignInteractive](#columnaligninteractive)
    - [:ColumnAlignToColumn](#columnaligntocolumn)
  - [Verhalten und Validierungen](#verhalten-und-validierungen)
  - [Technische Details](#technische-details)
  - [Typische Anwendungsfälle](#typische-anwendungsflle)
  - [Einschränkungen](#einschrnkungen)
  - [Erweiterungsmöglichkeiten](#erweiterungsmglichkeiten)

---

## Zweck

Das Modul löst ein häufiges Layout-Problem beim Schreiben von Tabellen, Listen oder kommentierten Codezeilen:

* ein einzelnes Zeichen (z. B. `|`, `=`, `:`) soll exakt auf eine bestimmte Spalte verschoben werden
* alle Zwischenräume werden automatisch mit einem Füllzeichen ergänzt
* die restliche Zeile bleibt unverändert

Beispiel:

```
key=value
```

Visuelle Auswahl auf `=` und Zielspalte `10`:

```
key______=value
```

(Standard-Füllzeichen: Leerzeichen)

---

## Voraussetzungen

* Neovim
* visuelle Auswahl (`v` oder `V`)
* exakt **ein** Zeichen ausgewählt
* Auswahl muss sich auf **eine Zeile** beschränken

Mehrzeilige Selektionen oder mehrere Zeichen werden bewusst abgelehnt.

---

## Installation

Das Modul muss sich im Runtimepath befinden, z. B.:

```
lua/
├─ utils/
│  └─ column_align.lua
└─ usrcmds/
   └─ column_align/
      └─ core.lua
```

In der Neovim-Konfiguration einmalig aufrufen:

```lua
require("custom.column_align").setup()
```

---

## Tastenkombination

Im visuellen Modus:

```
<leader>ac
```

Verhalten:

* öffnet eine Eingabeaufforderung
* fragt nach Zielspalte
* fragt optional nach Füllzeichen
* richtet das selektierte Zeichen entsprechend aus

Die Tastenkombination wird buffer-lokal gesetzt, wenn ein Markdown-Buffer erkannt wird, sonst global.

---

## User Commands

### :ColumnAlignInteractive

Interaktive Variante.

Verwendung:

```
:ColumnAlignInteractive
```

Ablauf:

1. Eingabe der Zielspalte
2. Eingabe des Füllzeichens (leer = Leerzeichen)
3. Ausrichtung des selektierten Zeichens

---

### :ColumnAlignToColumn

Nicht-interaktive Variante mit Argumenten.

Syntax:

```
:ColumnAlignToColumn <target_col> [fill_char]
```

Beispiele:

```
:ColumnAlignToColumn 40
:ColumnAlignToColumn 80 .
:ColumnAlignToColumn 60 _
```

Regeln:

* `<target_col>` muss eine positive Ganzzahl sein
* `[fill_char]` ist optional
* `[fill_char]` muss **genau ein Zeichen** sein

---

## Verhalten und Validierungen

Das Modul prüft strikt:

* ob eine visuelle Auswahl existiert
* ob genau ein Zeichen selektiert ist
* ob die Auswahl einzeilig ist
* ob die Zielspalte größer als die aktuelle Spalte ist
* ob das Füllzeichen exakt ein Zeichen lang ist

Bei Regelverletzungen wird keine Änderung vorgenommen und eine Fehlermeldung ausgegeben.

---

## Technische Details

* Spaltenzählung ist 1-basiert
* Markierungen `<` und `>` werden verwendet
* keine Abhängigkeit von Tabstop-Einstellungen
* byte-basierte Zeichenverarbeitung (kein Multibyte-Grapheme-Support)
* Cursor wird nach der Operation auf das ausgerichtete Zeichen gesetzt

---

## Typische Anwendungsfälle

* Markdown-Tabellen
* Key-Value-Paare
* Konfigurationsdateien
* Kommentare mit ausgerichteten Trennzeichen
* visuelle Ausrichtung ohne Autoformatter

---

## Einschränkungen

* keine Unterstützung für Multibyte-Zeichen (z. B. Emojis, kombinierte Unicode-Grapheme)
* keine Mehrzeilen-Ausrichtung
* bewusst kein automatisches Erkennen von Zielspalten

---

## Erweiterungsmöglichkeiten

* Unterstützung für Multibyte-Zeichen
* Ausrichtung mehrerer markierter Zeichen
* Wiederholung der letzten Zielspalte
* Presets pro Dateityp
* Integration in Operator-Mappings
* Multiselect: also mit ctrl-v mehrere start punkt markieren bzw.: echte markierungen und dort werden dann auf einmal alle ausgefphrt

---
