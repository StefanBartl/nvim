# lua_file_stats

## Table of content

  - [Überblick](#berblick)
  - [Voraussetzungen](#voraussetzungen)
  - [Ausführung](#ausfhrung)
  - [Was wird analysiert](#was-wird-analysiert)
    - [Zeilenbasierte Kennzahlen](#zeilenbasierte-kennzahlen)
    - [Ausgabeformate](#ausgabeformate)
    - [Einzeldatei analysieren](#einzeldatei-analysieren)
    - [Top-N Auswertungen](#top-n-auswertungen)
    - [Reihenfolge der Ausgabe](#reihenfolge-der-ausgabe)
  - [Interpretation der Ergebnisse](#interpretation-der-ergebnisse)
  - [Plattformhinweise](#plattformhinweise)
  - [Typische Anwendungsfälle](#typische-anwendungsflle)

---

## Überblick

`lua_file_stats.lua` ist ein CLI-Werkzeug zur statischen Analyse von Lua-Codebasen.
Es analysiert Zeilen, Wörter, Kommentare und EmmyLua-Annotationen und stellt die Ergebnisse als ASCII-Tabellen dar.

Der Fokus liegt auf:

* Wartbarkeit
* Dokumentationsqualität
* Typisierungsgrad (LuaLS / EmmyLua)
* Vergleichbarkeit zwischen Modulen (Ordnern)

Das Tool ist editorunabhängig und benötigt **kein Neovim**.

Zusätzlich werden relative Anteile (Prozent) berechnet.

## Voraussetzungen

* Lua 5.1+ (getestet mit LuaJIT und Lua 5.4)
* Betriebssystem:

  * Windows: vollständig unterstützt
  * Linux / macOS: erfordert Anpassung des Datei-Scans (siehe Abschnitt Plattformhinweise)

Zusätzlich werden relative Anteile (Prozent) berechnet.

## Ausführung

Im Projektverzeichnis:

```sh
lua lua_file_stats.lua
```

Standardmäßig wird das aktuelle Verzeichnis rekursiv analysiert.

Ein alternatives Root-Verzeichnis kann angegeben werden:

```sh
lua lua_file_stats.lua path/to/project
```

Zusätzlich werden relative Anteile (Prozent) berechnet.

## Was wird analysiert

Pro Datei, Ordner und global:

* Gesamtzeilen
* Codezeilen (ohne Kommentare)
* Kommentarzeilen
* Annotationzeilen (`---@`)
* Leerzeilen
* Wörter in allen Kategorien

Zusätzlich werden relative Anteile (Prozent) berechnet.

Zusätzlich werden relative Anteile (Prozent) berechnet.

### Zeilenbasierte Kennzahlen

* L1: Codezeilen ohne Kommentare
* L2: Kommentarzeilen
* L3: Zeilen ohne Annotationen
* L4: Annotationzeilen
* L5: Leerzeilen



Zusätzlich werden relative Anteile (Prozent) berechnet.

* W1: Wörter im Code
* W2: Wörter ohne Annotationen
* W3: Wörter in Kommentaren
* W4: Wörter in Annotationen
* W5: Wörter in Leerzeilen (meist 0)

Alle Prozentwerte beziehen sich jeweils auf:

* Gesamtzeilen oder
* Gesamtwörter der betrachteten Einheit



Zusätzlich werden relative Anteile (Prozent) berechnet.

Mit dem Flag `--ratios` werden zusätzliche, abgeleitete Metriken ausgegeben.

```sh
lua lua_file_stats.lua --ratios
```

Diese beinhalten unter anderem:

* Kommentarquote pro Modul
* Annotationquote pro Modul
* Dokumentationsanteil (Kommentare + Annotationen)
* Effektiver Codeanteil
* Durchschnittliche Zeilen pro Datei
* Verhältnis Annotationen zu Kommentaren

Zusätzlich wird eine erklärende Notiz mit heuristischen Richtwerten ausgegeben.



Zusätzlich werden relative Anteile (Prozent) berechnet.

### Ausgabeformate

```sh
--percent-only
```

Nur Prozentwerte anzeigen.

```sh
--numbers-only
```

Nur absolute Zahlen anzeigen.

```sh
--colwidth=N
```

Spaltenbreite für Zahlen (Standard: 7).



Zusätzlich werden relative Anteile (Prozent) berechnet.

```sh
--fields=files,folders,summary
```

Beschränkt die Ausgabe auf bestimmte Tabellen.

Mögliche Werte:

* files
* folders
* summar
* summar
* summarZusätzlich werden relative Anteile (Prozent) berechnet.

---

### Einzeldatei analysieren

```sh
--file=path/to/file.lua
```

Analysiert nur eine einzelne Datei
Analysiert nur eine einzelne Datei
Analysiert nur eine einzelne DateiZusätzlich werden relative Anteile (Prozent) berechnet.

---

### Top-N Auswertungen

```sh
--topn=25
```

Anzahl der Einträge für Top-Listen.

```sh
--top-files-lines-only
```

Nur Top-Dateien nach Zeilenzahl anzeigen.

```sh
--top-files-words-only
```

Nur Top-Dateien nach Wortanzahl anzeigen.

Diese Flags unterdrücken alle anderen Ausgaben
Diese Flags unterdrücken alle anderen Ausgaben
Diese Flags unterdrücken alle anderen AusgabenZusätzlich werden relative Anteile (Prozent) berechnet.

---

### Reihenfolge der Ausgabe

```sh
--reverse
```

Gibt zuerst die Gesamtauswertung aus, danach Ordner- und Datei-Details
Gibt zuerst die Gesamtauswertung aus, danach Ordner- und Datei-Details
Gibt zuerst die Gesamtauswertung aus, danach Ordner- und Datei-DetailsZusätzlich werden relative Anteile (Prozent) berechnet.

---

## Interpretation der Ergebnisse

Typische Richtwerte für gut gepflegte Lua-Projekte:

* Kommentaranteil: 15–30 %
* Annotationanteil: 5–12 %
* Dokumentationsanteil gesamt: 20–40 %
* Codeanteil: 55–75 %
* Durchschnittliche Dateigröße: 80–200 Zeilen

Abweichungen vom globalen Durchschnitt sind meist aussagekräftiger als absolute Zahlen
Abweichungen vom globalen Durchschnitt sind meist aussagekräftiger als absolute Zahlen
Abweichungen vom globalen Durchschnitt sind meist aussagekräftiger als absolute ZahlenZusätzlich werden relative Anteile (Prozent) berechnet.

---

## Plattformhinweise

Der Dateiscan verwendet aktuell:

```sh
dir /S /B /A:-D
```

Das ist Windows-spezifisch.

Für Linux / macOS muss `get_lua_files` angepasst werden, z. B. auf:

```sh
find . -type f -name "*.lua"
```

Die restliche Logik ist plattformunabhängig
Die restliche Logik ist plattformunabhängig
Die restliche Logik ist plattformunabhängigZusätzlich werden relative Anteile (Prozent) berechnet.

---

## Typische Anwendungsfälle

* Analyse großer Neovim-Konfigurationen
* Bewertung von Plugin-Modulen
* Identifikation von Refactoring-Kandidaten
* Vergleich von Dokumentationsstilen zwischen Modulen
* Langfristige Pflege und Konsistenzkontrolle



Zusätzlich werden relative Anteile (Prozent) berechnet.
