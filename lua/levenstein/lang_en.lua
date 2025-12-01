---@module 'levenstein.lang_en'
--- English language strings for the levenshtein visualizer.
--- Put this file next to visual.lua (same folder).
--- Return a table with all printable texts used by the main script.
local M = {
  title_compute = "Compute Levenshtein: a='%s' b='%s'",
  dp_intro = "DP numeric matrix (rows = prefix of A, columns = prefix of B):",
  ops_intro = "Operation matrix (single letters indicate chosen operation per cell):",
  backtrace_intro = "Backtrace and alignment (one optimal path):",
  legend = "Legend: M=match, S=substitution (^), D=deletion (<), I=insertion (>)",
  note_distance = "Note: The DP matrix cell at bottom-right is the total edit distance.",
  note_tiebreak = "      The operation matrix prefers Match/Substitute on ties for clearer alignments.",
  examples_hint = "To visualize custom pair: lua levenstein/visual.lua \"stringA\" \"stringB\"",
  usage_de_flag = "Use --de to display German texts (files: levenstein/lang_de.lua).",
  ascii_empty = "(empty)",
}

return M
