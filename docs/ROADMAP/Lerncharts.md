# Druckbare Lern-Charts (Cheat Sheets)

## Table of content

  - [CHART 1: Suchen in Dateien (Text / Inhalt)](#chart-1-suchen-in-dateien-text-inhalt)
  - [CHART 2: Suchen von Dateien & Ordnern](#chart-2-suchen-von-dateien-ordnern)
  - [CHART 3: Pipes, Content & Textverarbeitung](#chart-3-pipes-content-textverarbeitung)

---

## CHART 1: Suchen in Dateien (Text / Inhalt)

> **Verwendungszweck:** Logfiles analysieren, Systemfehler suchen, Configs prüfen.

```
========================================================================================================
                                CHEAT SHEET 1: GREP vs. SELECT-STRING
========================================================================================================

LINUX (grep)                 POWERSHELL (Select-String / sls)      BESCHREIBUNG / ANWENDUNG
--------------------------------------------------------------------------------------------------------
grep "Error" log.txt         sls -Pattern "Error" -Path log.txt   Einfache Suche nach "Error"
grep -i "error" log.txt      sls -Pattern "error" log.txt -CaseS  Case-Insens. (PS ist standardm. -i!)
                             (sls -CaseSensitive für exakt)

grep -v "DEBUG" log.txt      sls -Pattern "DEBUG" log.txt -NotM   Zeilen OHNE das Muster anzeigen (-v)
grep -c "Error" log.txt      (sls "Error" log.txt).Count          Anzahl der Treffer zählen (-c)
grep -n "Error" log.txt      sls "Error" log.txt                  Zeilennummern anzeigen (PS macht das stdf.)

grep -r "Error" ./logs/      sls "Error" -Path ./logs/* -Recurse  Rekursiv in Ordnern suchen
grep -E "Err|Warn" log.txt   sls -Pattern "Err|Warn" log.txt      Regex (Reguläre Ausdrücke) verwenden
grep -C 3 "Crash" log.txt    sls "Crash" log.txt -Context 3       3 Zeilen VOR und NACH dem Treffer anzeigen

--------------------------------------------------------------------------------------------------------
POWER-TIPP (PS Objekt-Power):
$results = Select-String -Pattern "Error" -Path *.log
$results | Select-Object LineNumber, Filename, Line   # Formatiere die Ausgabe nach Wunsch!
========================================================================================================

```

---

## CHART 2: Suchen von Dateien & Ordnern

> **Verwendungszweck:** Dateien nach Name, Größe oder Änderungsdatum im Dateisystem aufspüren.

```
========================================================================================================
                                CHEAT SHEET 2: FIND vs. GET-CHILDITEM
========================================================================================================

LINUX (find)                 POWERSHELL (Get-ChildItem / gci)     BESCHREIBUNG / ANWENDUNG
--------------------------------------------------------------------------------------------------------
find . -name "*.log"         gci -Filter "*.log" -Recurse         Sucht alle .log Dateien
find . -type d -name "Test"  gci -Directory -Filter "Test" -Rec   Nur Verzeichnisse/Ordner suchen
find . -type f -name "Test"  gci -File -Filter "Test" -Recurse    Nur Dateien suchen

find . -mtime -7             gci -Recurse |                       Dateien der letzten 7 Tage
                             where {$_.LastWriteTime -gt          (PS nutzt echte Datums-Objekte!)
                             (Get-Date).AddDays(-7)}

find . -size +100M           gci -Recurse |                       Dateien größer als 100 MB
                             where {$_.Length -gt 100MB}          (PS versteht 'KB', 'MB', 'GB' direkt!)

find . -maxdepth 2 -name x   gci -Depth 1 -Filter x               Suchtiefe einschränken (0 = nur hier)
find . -name "*.tmp" -delete gci -Filter "*.tmp" -Recurse |       Gefundene Dateien direkt löschen
                             Remove-Item -Force
========================================================================================================

```

---

## CHART 3: Pipes, Content & Textverarbeitung

> **Verwendungszweck:** Ausgaben filtern, Sortieren, Anschauen und Weiterverarbeiten.

```
========================================================================================================
                             CHEAT SHEET 3: PIPES & TEXT PROCESSING
========================================================================================================

LINUX                        POWERSHELL                           BESCHREIBUNG / ANWENDUNG
--------------------------------------------------------------------------------------------------------
cat file.txt                 Get-Content file.txt (Alias: cat)    Dateiinhalt ausgeben
head -n 20 file.txt          gc file.txt -Head 20                 Die ersten 20 Zeilen anzeigen
tail -n 20 file.txt          gc file.txt -Tail 20                 Die letzten 20 Zeilen anzeigen
tail -f app.log              gc app.log -Wait -Tail 10            Logfile LIVE mitlesen (Continuous)

wc -l file.txt               (gc file.txt).Count                  Zeilen in Datei zählen
sort file.txt                gc file.txt | Sort-Object            Textzeilen alphabetisch sortieren
sort -n -k2 file.txt         $data | Sort-Object PropertyName     Nach konkretem Objekt-Attribut sortieren
uniq                         Select-Object -Unique                Duplikate aus der Liste entfernen

cmd1 | awk '{print $1}'      cmd1 | Select-Object -Expand Name    Spezifische Spalte/Eigenschaft extrahieren
cmd1 > output.txt            cmd1 | Out-File output.txt           In Datei schreiben
cmd1 >> output.txt           cmd1 | Out-File output.txt -Append   An Datei anhängen
========================================================================================================

```

---
