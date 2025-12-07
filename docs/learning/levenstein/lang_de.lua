---@module 'levenstein.lang_de'
--- Deutsche Sprachstrings und ausführliche Erklärungen für den Levenshtein-Visualizer.
--- Diese Datei enthält längere, mehrteilige Texte, die die Matritzen, den Algorithmus
--- und eine schrittweise Besprechung des Beispiels erklären.
local M = {
  title_compute = "Levenshtein berechnen: a='%s' b='%s'",

  dp_intro = "DP numerische Matrix (Zeilen = Präfix von A, Spalten = Präfix von B):",
  ops_intro = "Operationsmatrix (Einbuchstaben-Code zeigt gewählte Operation pro Zelle):",
  backtrace_intro = "Backtrace und Ausrichtung (ein optimaler Pfad):",
  legend = "Legende: M=Match, S=Substitution (^), D=Deletion (<), I=Insertion (>)",
  distance_label = "Levenshtein Distanz",

  definition = [[
Definition
Die Levenshtein-Distanz zwischen zwei Zeichenketten ist die minimale Anzahl
einzelner Zeichenoperationen (Einfügen, Löschen, Ersetzen), um die eine Zeichenkette
in die andere zu überführen. Sie wird in Rechtschreibkorrektur, Suchalgorithmen
und der Bioinformatik zur Ähnlichkeitsmessung verwendet.
]],

  algorithm_explanation = [[
Algorithmus (dynamische Programmierung)
1. Erzeuge eine zweidimensionale Tabelle (Matrix) dp mit (|A|+1) Zeilen und (|B|+1) Spalten.
   - dp[i][j] speichert die minimale Edit-Distanz zwischen Präfix A[1..i] und B[1..j].
2. Basisfälle:
   - dp[0][j] = j (leeres A → B[1..j] mittels j Einfügungen).
   - dp[i][0] = i (A[1..i] → leeres B mittels i Löschungen).
3. Rekurrenz für i>0, j>0:
   - cost = 0 falls A[i] == B[j], sonst 1.
   - dp[i][j] = min(
       dp[i-1][j] + 1,        -- Löschen (A[i] entfernen)
       dp[i][j-1] + 1,        -- Einfügen (B[j] in A einfügen)
       dp[i-1][j-1] + cost    -- Ersetzen (A[i] -> B[j])
     )
4. Die gesuchte Distanz ist dp[|A|][|B|].
Die Laufzeit beträgt O(|A| * |B|) und der Speicherbedarf O(|A| * |B|).
]],

  matrix_explanation = [[
Wie man die Matrizen liest
- DP-Matrix (Zahlen): Zeilen sind Präfixe von A (inkl. leerem Präfix), Spalten sind Präfixe von B.
  Die Zelle dp[i][j] enthält die minimale Anzahl an Operationen, um A[1..i] in B[1..j] zu überführen.
- Operationsmatrix: pro Zelle wird die beim Befüllen gewählte Operation angezeigt:
  M = Match (kein Kosten), S = Substitution, D = Deletion, I = Insertion.
- Backtrace: Beginne bei dp[|A|][|B|] und folge Vorgängern (diagonal / oben / links), um eine optimale
  Sequenz von Operationen zu rekonstruieren. Die Darstellung verwendet '-' für Gaps und Markierungen
  (^, <, >) für Substitutions, Deletions und Insertions.
]],

  step_by_step_template = [[
Schritt-für-Schritt-Analyse für das Beispiel A = '%s' und B = '%s'

1) Basisinitialisierung
- Die erste Zeile zeigt die Kosten, um leeres A in Präfixe von B zu überführen (nur Einfügungen).
- Die erste Spalte zeigt die Kosten, um Präfixe von A in leeres B zu überführen (nur Löschungen).

2) Einzelne Zellen interpretieren (Beispielhaft)
- Betrachte dp[row=%d, col=%d]: Präfix A[1..%d] = '%s' und B[1..%d] = '%s'
  Die gewählte Operation und der resultierende minimale Kostenwert lassen sich in den Matrizen ablesen.

3) Backtrace erklären
- Die angezeigte Backtrace-Ausrichtung ist eine mögliche optimale Editfolge.
- '^' markiert Substitution (oder Match, wenn Zeichen gleich sind).
- '<' markiert Löschung (aus A entfernt).
- '>' markiert Einfügung (aus B in A eingefügt).

4) Bedeutung der Enddistanz
- Die untere rechte Zelle dp[%d][%d] ist %d; das bedeutet %s.
]],

  pedagogical_conclusions = [[
Pädagogische Schlussfolgerungen und praktische Hinweise
- Kleine Distanz = hohe Ähnlichkeit; große Distanz = viele Änderungen erforderlich.
- Muster:
  * Viele 'M' entlang der Hauptdiagonale zeigen gleiche Zeichen an korrespondierenden Positionen.
  * Längere Folge von 'I' oder 'D' deutet auf eingefügte oder gelöschte Teiler (verschobene Sequenzen).
  * 'S' weist auf positionsgleiche, aber unterschiedliche Zeichen hin.
- Für Lehrzwecke: Paare wählen, die nur kleine Verschiebungen oder einzelne Substitutionen haben,
  dann sind die Matrizen übersichtlich. Für Transpositionen ist Levenshtein nicht optimal (Damerau–Levenshtein
  erlaubt Transpositions als einzelne Operation).
- Erweiterungen: unterschiedliche Kosten pro Operation (weighted edits), oder Damerau-Erweiterung.
]],

  usage_hint = "Benutzung: lua levenstein/visual.lua \"stringA\" \"stringB\"  (mit --de deutsche Ausgabe)",

  examples_footer = [[
Jedes Beispiel zeigt:
- die numerische DP-Matrix,
- die Operationsmatrix (gewählte Operation pro Zelle),
- einen Backtrace und die explizite Ausrichtung,
- die numerische Distanz, und
- eine strukturierte, beispielspezifische Erklärung.

Führt weitere Paare aus, um zu sehen, wie Matrizen und Backtraces sich ändern.
]]
}

return M
