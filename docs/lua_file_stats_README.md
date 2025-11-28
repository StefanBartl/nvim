# Lua File Stats — README

Eine Kurzreferenz zur Nutzung und zu den Optionen des Skripts `lua_file_stats.lua`. Das Dokument beschreibt alle aktuellen Features, Flags und Beispielaufrufe.

---

## Übersicht

`lua_file_stats.lua` analysiert rekursiv `.lua`-Dateien in einem Verzeichnis und liefert Zeilen- und Wortstatistiken getrennt nach Code, Kommentaren, Annotationen und Whitespace. Ausgabe erfolgt in gut lesbaren ASCII-Tabellen sowie einer kompakten Text-Zusammenfassung. Pfade werden relativ zum aktuellen Arbeitsverzeichnis ausgegeben.

---

## Features (Kurz)

* Rekursive Analyse aller `.lua`-Dateien (Windows-kompatible Standard-`dir`-Abfrage).
* Erkennung von:

  * Inline-Kommentaren: `-- ...`
  * Block-Kommentaren: `--[[ ... ]]`
  * Annotationen: `---@...` (Annotationen werden separat gezählt)
  * Whitespace/leerzeilen
* Zählung von:

  * Zeilen: total, ohne Kommentare, Kommentarzeilen, ohne Annotationen, Annotationzeilen, Whitespace
  * Wörter: total, ohne Kommentare, ohne Annotationen, in Kommentaren, in Annotationen, Whitespace (falls vorhanden)
* ASCII-Tabellen: Single File, per-File, Folder Summary, Total Summary
* Top-N-Listen (Files / Folders nach Lines oder Words) und vollständige, nach Anteil sortierte Folder-Listen
* Konfigurierbare Spaltenbreite, Prozent-/Zahlenanzeige, Filter für ausgegebene Tabellen
* Single-file-Modus (`--file=`) — dann werden keine aggregierten Folder/Total-Tabellen erwartet

---

## Spalten- und Legendenkonvention (aktuell)

Die Tabellen nutzen kurze Spaltenbezeichnungen; Legende immer oberhalb der Tabellen.

Lines:

```
L1 = NoComments
L2 = Comments
L3 = NoAnnotations
L4 = Annotations
L5 = Whitespace
```

Words:

```
W1 = NoComments
W2 = NoAnnotations
W3 = Comments
W4 = Annotations
W5 = Whitespace
```

Hinweis: L1/W1 (Total) wurde auf kurze Form angepasst — im Total Summary werden L1/W1 implizit durch Aggregation ersichtlich. Prozentangaben sind jeweils relativ zur jeweiligen Tabelle (z. B. Datei → Prozent relativ zur Datei-Totalzeilen; Folder → relativ zu Folder-Total; Total → relativ zum Root-Gesamt).

---

## Flags / Optionen (vollständige Liste)

```text
root_dir                Path zur Analyse (optional, Default: .)
--file=<path>           Analysiere nur diese Datei (kein Folder/Total notwendig)
--fields=LIST           Komma-separierte Auswahl, welche Tabellen ausgegeben werden.
                        Mögliche Werte: files, folders, summary
                        Beispiel: --fields=folders,summary

--percent-only          Ausgabe nur in Prozent (ohne Rohzahlen)
--numbers-only          Ausgabe nur als Rohzahlen (ohne Prozent)
(default) beide angezeigt: Zahlen + Prozent

--colwidth=<n>          Spaltenbreite (integer, Default 7). Passt Tabellenbreite an.

--reverse               Reihenfolge umkehren (Total → Folder → Files)

--topn=<N>              Anzahl N für Top-N-Listen (Default 25)
--top-files-lines-only  Ausgabe nur: Top-N Dateien nach Zeilen (wenn kein --topn, Default 25)
--top-files-words-only  Ausgabe nur: Top-N Dateien nach Wörtern
--top-folders-lines-only Ausgabe nur: Top-N Ordner nach Zeilen
--top-folders-words-only Ausgabe nur: Top-N Ordner nach Wörtern
--folders-sorted-only   Shortcut: Ausgabe aller Ordner sortiert nach Zeilenanteil am Root (wenn --topn nicht gesetzt, gibt alle Ordner aus)

--help                  (nicht implementiert im Skript, aber hier dokumentiert)
```

Beispielkombinationen und Verhalten:

* `--top-folders-lines-only` ohne `--topn` → gibt **alle** Ordner sortiert nach Zeilen (Anteil am Root) aus.
* `--top-folders-lines-only --topn=10` → gibt Top 10 Ordner nach Zeilen aus.
* Mehrere `--top-...-only` Flags können kombiniert werden; wenn mindestens ein `--top-...-only` gesetzt ist, werden nur die angeforderten Top-Listen ausgegeben (keine regulären Tabellen).

---

## Beispiele

1. **Vollanalyse (aktuelles Verzeichnis) — Standardausgabe (Zahlen + Prozent):**

```bash
lua lua_file_stats.lua
```

2. **Nur Prozentwerte anzeigen:**

```bash
lua lua_file_stats.lua --percent-only
```

3. **Nur Folder- und Total-Table ausgeben, Spaltenbreite 10:**

```bash
lua lua_file_stats.lua . --fields=folders,summary --colwidth=10
```

4. **Top 10 Dateien nach Zeilen anzeigen (nur Top-Liste):**

```bash
lua lua_file_stats.lua . --top-files-lines-only --topn=10
```

5. **Alle Ordner sortiert nach Anteil an Gesamtlijnen anzeigen:**

```bash
lua lua_file_stats.lua . --folders-sorted-only
```

6. **Single file Mode (nur eine Datei analysieren, keine Folder-/Total-Tabellen):**

```bash
lua lua_file_stats.lua --file=lua/config/init.lua
```

7. **Nur Top-Listen für Dateien nach Wörtern und Ordner nach Zeilen (kombiniert):**

```bash
lua lua_file_stats.lua . --top-files-words-only --top-folders-lines-only --topn=20
```

---

## Ausgabeformat / Interpretation

* Jede ASCII-Tabelle enthält eine Legende mit Bedeutungen von L1..L5 und W1..W5.
* Prozentangaben werden pro Zeile/Spalte berechnet relativ zur jeweiligen Gesamtmenge (Datei / Folder / Gesamt).
* Whitespace (L5/W5) zeigt die Anzahl und Anteile von leerzeilen bzw. Wörtern in diesen Zeilen (normalerweise 0 Wörter).

---

## Anpassung für Unix / Linux / macOS

Das Skript nutzt aktuell Windows-`dir` zum Sammeln von Dateien. Für Unix empfiehlt sich eine kleine Änderung in `get_lua_files`:

Ersetze:

```lua
local p = io.popen('dir "' .. dir .. '" /S /B /A:-D')
```

durch z.B.:

```lua
local p = io.popen('find "' .. dir .. '" -type f -name "*.lua"')
```

oder, falls `ls` bevorzugt:

```lua
local p = io.popen('ls -R "' .. dir .. '" | grep "\.lua$"')
```

(Die `find`-Variante ist robust und empfohlen.)

---

## Anforderungen

* Lua 5.1+ (getestet; läuft mit Lua 5.4)
* Terminal mit monospaced Font (für ASCII-Tabellen)
* Windows: `dir` vorhanden (Standard)
* Unix: empfohlen `find` (siehe Anpassung)

---

## Architekturhinweis / Erweiterbarkeit

* Analyse-Logik ist in einzelne Funktionen kapsuliert (`analyze_file`, `scan_dir`, `compute_percentages`).
* Ausgabefunktionen sind getrennt (`print_file_stats_ascii`, `print_folder_summary_ascii`, `print_total_summary`, Top-N Prints).
* Erweiterung für weitere Sprachen: zentrale Stelle für Kommentar-Syntax pro Sprache einführen (z. B. table `LANG_SYNTAX = { lua = {...}, ts = {...} }`) und `analyze_file` entsprechend parametrisieren.
* Plugin-Proof-of-Concept: die CLI-Logik bleibt erhalten; für Neovim kann man das Modul exportieren und aus `require('code_counter').scan_dir(...)` aufrufen, dadurch kann man in Neovim eine async/Job-Version oder Buffer-basierte Analyse hinzufügen.

---

## Hinweise / Known Caveats

* Annotation-Erkennung: aktuell `---@` am Zeilenanfang in Kommentarteil (z. B. `---@param`). Inline Annotationen sind möglich, werden aber als Kommentar-Annotationen gezählt.
* Inline-Kommentar-Trennung: Inline-Kommentare werden abgeschnitten bei erstem `--` (es wird nicht versucht, Lua-Strings mit `--` zu erkennen).
* Prozentberechnung behandelt Division-by-zero sicher (ergibt 0.0% falls Nenner 0).
* Pfad-Normalisierung: Ausgabe wird relativ zum CWD, sofern möglich. Absolute Pfade bleiben erhalten, wenn kein relativer Pfad ermittelt werden kann.

---

## Lizenz / Weiteres

* Kein Lizenzhinweis im Skript — bei Bedarf License-Header einfügen (z. B. MIT).
* Für Plugin-Integration empfiehlt sich, die CLI-Funktionen in ein `lua`-Modul zu extrahieren (`src/` + `cli.lua`), sodass `require()` aus Neovim funktioniert.

---
