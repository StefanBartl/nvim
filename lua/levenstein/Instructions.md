# levenstein visual module - instructions

## Dateien: ausführliche Version (Deutsch/Englisch + visual.lua)

Die folgenden drei Dateien ersetzen die bisherigen Sprachdateien und das Hauptskript. `lang_en.lua` und `lang_de.lua` enthalten ausführliche, mehrteilige Texte (Definition, Algorithmus, Matrix-Erklärung, Beispiel-Aufschlüsselung, Schlussfolgerungen). `visual.lua` lädt die gewünschte Sprache (default Englisch, `--de` für Deutsch), berechnet und druckt Matrizen, Alignment und zusätzlich eine ausführliche, didaktische Besprechung für das angezeigte Beispiel. Alle Lua-Kommentare sind in Englisch; Module starten mit vollständiger EmmyLua-Annotation.

## Hinweise zur Verwendung und Tests

 Dateien in Pfad `levenstein/` ablegen:

  * `levenstein/lang_en.lua`
  * `levenstein/lang_de.lua`
  * `levenstein/visual.lua`
* Aufruf (Standard Englisch):

  * `lua levenstein/visual.lua "kitten" "sitting"`
* Aufruf (Deutsch):

  * `lua levenstein/visual.lua "kitten" "sitting" --de`
* Bei direktem Ausführen zeigt das Skript:

  * die numerische DP-Matrix,
  * die Operationsmatrix,
  * den Backtrace / Alignment,
  * die numerische Distanz und
  * eine ausführliche, schrittweise Erklärung, die Definition, Algorithmusbeschreibung und pädagogische Hinweise enthält.

## Anmerkungen zur Lesbarkeit und Erweiterbarkeit

* Die Sprachdateien sind bewusst ausführlich gestaltet; sie können später durch `levenstein/lang_fr.lua` o.ä. ergänzt werden.
* Die Diskussionstexte sind so formuliert, dass sie für die meisten Beispiele passen—der Template-Abschnitt füllt einige konkrete Zellen-Werte ein und erklärt sie.
* Wenn gewünscht, kann das Skript erweitert werden, um:

  * mehrere alternative Backtraces bei Gleichständen auszugeben,
  * farbige Terminalausgabe in UTF-8-Terminals (optional),
  * HTML- oder Markdown-Export der Matrizen für Lehrmaterialien.

---

## Table of content

  - [Was man im Terminal sieht und wie man es interpretiert](#was-man-im-terminal-sieht-und-wie-man-es-interpretiert)
  - [Was man daraus folgern kann (Praktische Hinweise)](#was-man-daraus-folgern-kann-praktische-hinweise)
  - [Beispiele für schnelle Interpretation (konkret)](#beispiele-fr-schnelle-interpretation-konkret)
  - [Hinweise zur Nutzung](#hinweise-zur-nutzung)
  - [Ausführung](#ausfhrung)

---

## Was man im Terminal sieht und wie man es interpretiert

* Die Ausgaben sind in ASCII: die leere Präfix-Zelle ist mit `(empty)` beschriftet, sodass keine UTF-8/Font-Probleme auftreten.
* Die numerische DP-Matrix zeigt in Zeilen die Präfixe von String A und in Spalten die Präfixe von String B. Die Zelle unten rechts enthält die Gesamt-Edit-Distanz.
* Die Operationsmatrix zeigt für jede Zelle die **gewählte** Operation beim Füllen der Matrix:

  * `M` = match (kein Kostenaufwand), `S` = substitution (A→B, Kosten 1), `D` = deletion (Zeichen aus A entfernen), `I` = insertion (Zeichen in A einfügen).
* Die Backtrace-Sektion zeigt eine konkrete Ausrichtung (alignment) von A und B entlang einer optimalen Pfadwahl:

  * `A:` und `B:` zeigen die beiden ausgerichteten Strings (`-` repräsentiert Gap).
  * Die Marker-Zeile darunter markiert `^` für Substitution, `<` für Deletion und `>` für Insertion; bei Matches bleibt ein Leerzeichen.

## Was man daraus folgern kann (Praktische Hinweise)

* Eine kleine Zahl in der unteren rechten Zelle bedeutet, dass die Strings ähnlich sind; größere Zahlen bedeuten mehr Änderungen.
* Wenn die Operationen entlang der Hauptdiagonalen überwiegend `M` sind, dann sind die Strings gut ausgerichtet (viele gleiche Zeichen an denselben Positionen).
* Viele `I`- oder viele `D`-Operationen deuten auf Einfügungen/Löschungen hin (verschobene Sequenz oder zusätzliche/fehlende Zeichen).
* `S`-Operationen zeigen positionale Unterschiede (Zeichen stehen an vergleichbarer Position, unterscheiden sich aber).
* Die gezeigte Backtrace ist nur **eine** optimale Lösung bei möglichen Ties; die Implementation priorisiert Match/Substitute bei Gleichstand, um Alignments lesbarer zu machen.

## Beispiele für schnelle Interpretation (konkret)

* `kitten` vs `sitting`: Distanz 3 → mehrere Operationen (substitute k→s, substitute e→i, insert g) — strings sind teilweise ähnlich (t's in der Mitte bleiben erhalten), aber mehrere Änderungen nötig.
* `flaw` vs `lawn`: Distanz 2 → Zeichenverschiebung und Substitution; Alignment zeigt, ob ein Verschieben oder einzelne Substitutions-/Insert-Operationen günstiger sind.
* leere vs nicht-leere Strings: Distanz = Länge des nicht-leeren Strings; zeigt, dass nur Insert- bzw. Delete-Operationen nötig sind.

## Hinweise zur Nutzung

* Zum schnellen Testen direkt im Projektordner ausführen: `lua levenshtein_visual.lua "stringA" "stringB"`.
* Für scripting/automatisierte Nutzung: `local vis = require("levenshtein.visual"); vis.visualize("a","b")`.
* Wenn man mehrere mögliche Backtraces sehen möchte, kann man die Backtrace-Funktion erweitern, um bei Ties alternative Pfade zu verfolgen; derzeit wird für Lesbarkeit ein deterministischer Tie-Break verwendet.
* Sprachsupport: standardmäßig wird Englisch geladen (levenstein/lang_en.lua). Mit --de wird versucht, die deutschen Texte aus levenstein/lang_de.lua zu laden. Beide Sprachtabellen liegen separat, so dass weitere Sprachen später einfach per levenstein/lang_xx.lua ergänzt werden können.
* Cross-platform: alle sichtbaren Labels sind ASCII ((empty)), sodass keine Terminal-Encoding-Änderung notwendig ist.

## Ausführung

- Beispiel (englisch, default): lua levenstein/visual.lua "kitten" "sitting"
- Beispiel (deutsch): lua levenstein/visual.lua "kitten" "sitting" --de
- Falls die Dateien in einem anderen Ordner liegen oder der Modulpfad anders ist, sicherstellen, dass package.path so gesetzt ist, dass require("levenstein.lang_en") die Dateien findet (zum Beispiel: lua -e 'package.path = package.path .. ";./?/init.lua;./?.lua"' levenstein/visual.lua ...).

---
