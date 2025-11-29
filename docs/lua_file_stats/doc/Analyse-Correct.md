rsache — kurz analytisch
Die Zahlen addieren sich zu >100%, weil Kategorien nicht disjunkt sind. In der aktuellen Implementierung werden Zeilen mit *Code und inline-Kommentar* gleichzeitig als „lines_without_comments“ (Code-Anteil) **und** als „comment_lines“ gezählt — das führt bei Summen zu Überschuss. Außerdem sind Annotationen (`annotation_lines`) ein Teilmengen von `comment_lines`, werden also ebenfalls doppelt gezählt, wenn man nicht explizit ausschließt. Ergebnis: Addiert man `Code + Comments + Annotations + Whitespace` (so wie im Alternate-Printer erwartet), entstehen Überlappungen.

Was man braucht (konkrete Definitionen, damit Summen 100% ergeben)
Man muss Kategorien so definieren, dass sie sich gegenseitig ausschließen (partitionieren). Vorschlag, präzise und leicht nachvollziehbar:

Zeilen-Partition (mutually exclusive):

* whitespace_lines = Zeilen, die nur aus Whitespace bestehen.
* annotation_lines = alle Zeilen, bei denen der Kommentar-Teil eine Annotation ist (z. B. `---@...`) — *egal ob comment-only oder inline*.
* comment_only_lines = Zeilen, die **nur** Kommentar sind (Kommentar vorhanden, aber kein Code), **und** keine Annotation (Annotationen bereits gezählt).
* code_only_lines = Zeilen, die Code enthalten **und** keinen Kommentar.
* code_with_comment_lines = Zeilen, die sowohl Code als auch Kommentar enthalten **und** die Kommentar-Teil ist **keine** Annotation.

Für viele Zwecke (z. B. Printer mit vier Spalten Code/Comments/Annotations/Whitespace) kann man diese Partition weiter zusammenfassen:

* Lines.Code = code_only_lines + code_with_comment_lines
* Lines.Comments = comment_only_lines
* Lines.Annotations = annotation_lines
* Lines.Whitespace = whitespace_lines

Wörter-Partition (mutually exclusive, summiert auf total_words):

* words_in_blank
* words_in_annotations (Annotation-Wörter)
* words_in_comments_only = words_in_comments - words_in_annotations  (Wörter in Kommentar-bereichen, ohne Annotations)
* words_in_code = total_words - words_in_comments - words_in_blank  (oder safer: words_without_comments, falls korrekt gezählt)

Warum das konsistent ist:
Wörter in Annotationen sind Teil der Kommentarwörter; zur Disjunktheit müssen sie herausgezogen und separat ausgewiesen. Für Zeilen: Annotation-Zeilen können inline (mit Code) oder comment-only sein — für die Partition nimmt man Annotationen als eigene Kategorie (daher Annotations Vorrang bei Klassifikation).

Konkrete Änderungen — Analyzer erweitern (minimal, robust)
Aktuell fehlen Counter für `comment_only_lines` und `code_with_comment_lines` (bzw. `code_only_lines`). Ergänze diese lokalen Zähler im `analyze_file`-Loop und setze sie an den passenden Stellen.

Patch-Schnipsel — wo die Inkremente hinmüssen (Lua, innerhalb der vorhandenen Logik; nur die relevanten Stellen):

```lua
-- neue lokale Zähler initialisieren (neben anderen)
local code_only_lines = 0
local code_with_comment_lines = 0
local comment_only_lines = 0
local annotation_only_lines = 0   -- annotation + no code
local annotation_inline_lines = 0 -- annotation + code

local words_in_code = 0
local words_in_comments_only = 0
-- words_in_annotations exists already (words_in_annotations)
```

Dann innerhalb des Branches, in dem `comment_part` und `code_part` bestimmt werden:

```lua
-- Case: comment_part ~= "" (line has a comment)
if comment_part ~= "" then
    -- check if there is code as well
    local has_code = code_part:match("%S") ~= nil

    -- is this comment an annotation?
    local is_annot = is_annotation_comment(comment_part)

    -- update counts for comment vs code vs annotation (disjoint assignment)
    if is_annot then
        if has_code then
            annotation_inline_lines = annotation_inline_lines + 1
            words_in_annotations = words_in_annotations + count_words(comment_part)
        else
            annotation_only_lines = annotation_only_lines + 1
            words_in_annotations = words_in_annotations + count_words(comment_part)
        end
        -- If annotation lines contain code (annotation_inline_lines), also count code words below.
    else
        if has_code then
            code_with_comment_lines = code_with_comment_lines + 1
            words_in_code = words_in_code + count_words(code_part)
            words_in_comments_only = words_in_comments_only + 0 -- comment part not comment-only
        else
            comment_only_lines = comment_only_lines + 1
            words_in_comments_only = words_in_comments_only + count_words(comment_part)
        end
    end

    -- always increment generic comment_lines and words_in_comments for backward compat
    comment_lines = comment_lines + 1
    words_in_comments = words_in_comments + count_words(comment_part)

    -- If has_code, also increment code counters for words/lines where appropriate:
    if has_code then
        -- But do NOT increment code_only_lines here
        words_without_comments = words_without_comments + count_words(code_part)
        lines_without_comments = lines_without_comments + 1
    end
else
    -- no comment_part: pure code line
    code_only_lines = code_only_lines + 1
    lines_without_comments = lines_without_comments + 1
    lines_without_annotations = lines_without_annotations + 1
    words_in_code = words_in_code + count_words(code_part)
    words_without_comments = words_without_comments + count_words(code_part)
end
```

Hinweis: Zusätzlich `in_block_comment`-Zweig anpassen — Block-Kommentare gelten als comment_only (keine Code-Anteile). Wenn Annotationen innerhalb Block-Comments erlaubt sind, behandeln wie `annotation_only_lines`.

Formeln für den Alternate-Printer (so berechnet man disjunkte Prozentfelder)
Wenn der Analyzer die oben genannten Zähler liefert, berechne:

Für Zeilen (total = stats.total_lines):

```
whitespace = stats.blank_lines
annotations = stats.annotation_only_lines + stats.annotation_inline_lines
comments = stats.comment_only_lines
code = total - whitespace - annotations - comments
```

(Einfacher: code = stats.code_only_lines + stats.code_with_comment_lines, falls man beide trackt)

Für Wörter (total_words = stats.total_words):

```
words_annotations = stats.words_in_annotations
words_comments = (stats.words_in_comments or 0) - words_annotations
words_whitespace = stats.words_in_blank or 0
words_code = total_words - words_annotations - words_comments - words_whitespace
-- alternativ: words_code = stats.words_without_comments  (nur wenn dieser Counter korrekt ist)
```

Warum das die Summe 100% ergibt
Weil jede Zeile und jedes Wort genau einer dieser Kategorien zugewiesen wird (Partition). Keine Überlappung mehr: Inline-Kommentare werden bei Zeilen entweder der Code-Kategorie (wenn man Code-priorisiert) oder man entscheidet, sie aufzuteilen; die oben gewählte Partition zählt inline-Zeilen als Code (für Lines.Code) und als Annotation (wenn Annotation), während reine comment-only Zeilen zählen zu Comments. Wichtig ist nur: dieselbe Zeile darf nicht gleichzeitig als comment_only_lines und code_only_lines gezählt werden.

Mögliche alternative Strategien (je nachdem, was man darstellen möchte)

* Man kann inline-Zeilen halb aufteilen (z. B. 50/50) — das ist seltener sinnvoll.
* Man kann „Comments“ in Printer als Summe aus comment_only_lines + fraction(code_with_comment_lines) — aber explizit und dokumentiert.

Praktische To-Do-Liste zum Fix (konkret, schnell ausführbar)

1. Analyzer erweitern: neue Zähler einbauen (siehe Code-Schnipsel oben) und korrekt inkrementieren. Testen, indem man pro Datei die neuen Zähler ausgibt.
2. Printer_alternate anpassen: statt direkte Verwendung von `lines_without_comments` und `comment_lines` die disjunkte Formeln verwenden (oben aufgeführt).
3. Unit-Test: Für eine kleine Testdatei mit z.B.

   * 1 blank line
   * 2 code-only lines
   * 1 comment-only line
   * 1 code+inline-comment line
   * 1 annotation-only line
     verifizieren, dass Lines.Code + Lines.Comments + Lines.Annotations + Lines.Whitespace == total_lines.
4. Optional: Bei Wort-Berechnung analog prüfen (Summe == total_words).

Debug-Hilfen zum Einbauen (temporär)

* In `analyze_file` am Ende `print(vim`? not available) — stattdessen `io.write`/`print` oder logging in eine Datei:

```lua
print("DEBUG:", filepath,
  "total", total_lines,
  "code_only", code_only_lines,
  "code_with_comment", code_with_comment_lines,
  "comment_only", comment_only_lines,
  "annotation_only", annotation_only_lines,
  "annotation_inline", annotation_inline_lines,
  "blank", blank_lines)
```

* Für Wörter analog.

Konkrete Anpassung im Printer_alternate (so berechnet man die Prozentwerte ohne Analyzer-Refactor)
Falls man den Analyzer kurzfristig nicht ändern will, kann der Printer versuchen, disjunkte Werte aus den vorhandenen Countern zu rekonstruieren — das ist aber fehleranfälliger. Beispiel (falls Analyzer liefert only: total_lines, blank_lines, comment_lines, annotation_lines, lines_without_comments):

```
-- approximate but may be inconsistent if analyzer counted overlaps:
annotations = stats.annotation_lines
whitespace = stats.blank_lines
-- comment_only ~ comment_lines - (lines_with_inline_comments) -> unknown
-- code = lines_without_comments  (but this excludes code in lines with inline comments)
-- Sauber geht nur mit Analyzer-Erweiterung
```

Deshalb: **Empfehlung** — Analyzer erweitern (kleiner, lokal, sicher).

Zusammenfassung (one-liner)
Der Fehler entsteht durch überlappende Zählweisen (inline-Kommentare zählen gleichzeitig als Kommentar- und Code-Zeile). Lösung: Analyzer so erweitern, dass er disjunkte Kategorien (comment_only / code_with_comment / code_only / annotation_only / annotation_inline / blank) liefert, und Printer die exakten, disjunkten Formeln verwendet — dann summieren die Prozentspalten exakt auf 100%.

