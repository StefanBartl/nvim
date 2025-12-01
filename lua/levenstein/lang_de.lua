---@module 'levenstein.lang_de'
--- Deutsche Sprachstrings für den Levenshtein-Visualizer.
--- Diese Datei enthält alle Texte in Deutsch; bleibt separat, damit weitere Sprachen später
--- einfach ergänzt werden können.
local M = {
  title_compute = "Levenshtein berechnen: a='%s' b='%s'",
  dp_intro = "DP numerische Matrix (Zeilen = Präfix von A, Spalten = Präfix von B):",
  ops_intro = "Operationsmatrix (Einbuchstaben-Code zeigt gewählte Operation pro Zelle):",
  backtrace_intro = "Backtrace und Ausrichtung (ein optimaler Pfad):",
  legend = "Legende: M=Match, S=Substitution (^), D=Deletion (<), I=Insertion (>)",
  note_distance = "Hinweis: Die Zelle unten-rechts der DP-Matrix enthält die gesamte Edit-Distanz.",
  note_tiebreak = "      Die Operationsmatrix bevorzugt Match/Substitute bei Gleichstand für lesbarere Alignments.",
  examples_hint = "Zum Visualisieren eines eigenen Paars: lua levenstein/visual.lua \"stringA\" \"stringB\"",
  usage_de_flag = "Nutze --de, um deutschsprachige Texte zu aktivieren (Datei: levenstein/lang_de.lua).",
  ascii_empty = "(empty)",
}

return M
