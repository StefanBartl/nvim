---@module 'levenstein.lang_en'
--- English language strings and long-form explanatory sections for the
--- Levenshtein visualizer. This file provides multi-paragraph text blocks
--- so the main script can print a detailed, didactic discussion for each example.
---
--- Keep each value as a string. Long text is OK and will be printed as-is.
local M = {
  title_compute = "Compute Levenshtein: a='%s' b='%s'",

  -- Short section headers used by the visualizer
  dp_intro = "DP numeric matrix (rows = prefix of A, columns = prefix of B):",
  ops_intro = "Operation matrix (single letters indicate chosen operation per cell):",
  backtrace_intro = "Backtrace and alignment (one optimal path):",
  legend = "Legend: M=match, S=substitution (^), D=deletion (<), I=insertion (>)",
  distance_label = "Levenshtein distance",

  -- Detailed explanatory texts
  definition = [[
Definition
The Levenshtein distance between two strings is the minimum number of single-character
edits (insertions, deletions or substitutions) required to change one string into the other.
It is a metric commonly used in approximate string matching, spell checking, and bioinformatics.
]],

  algorithm_explanation = [[
Algorithm (dynamic programming)
1. We build a two-dimensional table (matrix) dp with (|A|+1) rows and (|B|+1) columns.
   - dp[i][j] stores the minimal edit distance between the prefix A[1..i] and B[1..j].
2. Base cases:
   - dp[0][j] = j (transform empty A into B[1..j] with j insertions).
   - dp[i][0] = i (transform A[1..i] into empty B with i deletions).
3. Recurrence for i>0, j>0:
   - cost = 0 if A[i] == B[j], otherwise 1.
   - dp[i][j] = min(
       dp[i-1][j] + 1,        -- deletion (remove A[i])
       dp[i][j-1] + 1,        -- insertion (insert B[j] into A)
       dp[i-1][j-1] + cost    -- substitution (A[i] -> B[j])
     )
4. The final distance is dp[|A|][|B|].
This dynamic programming approach runs in O(|A| * |B|) time and uses O(|A| * |B|) space.
]],

  matrix_explanation = [[
How to read the matrices
- DP numeric matrix: rows correspond to prefixes of A (including the empty prefix),
  columns to prefixes of B. The cell dp[i][j] contains the minimal edit distance
  to transform A[1..i] into B[1..j].
- Operation matrix: for each cell the chosen operation while filling the matrix is shown:
  M = match (no cost), S = substitution, D = deletion, I = insertion.
- Backtrace: starting at dp[|A|][|B|], follow predecessors (diagonal/up/left) to reconstruct
  one optimal sequence of edits. The printed alignment shows gaps with '-' and marks
  substitutions/deletions/insertions with symbols (^, <, >) for clarity.
]],

  step_by_step_template = [[
Step-by-step analysis for the example A = '%s' and B = '%s'

1) Base initialization
- The first row shows the cost of converting empty A into prefixes of B (all insertions).
- The first column shows the cost of converting prefixes of A into empty B (all deletions).

2) Filling a few representative cells manually (illustration)
- Look at dp[row=%d, col=%d]: prefixes A[1..%d] = '%s' and B[1..%d] = '%s'
  The chosen operation and resulting minimal cost are visible in the DP and operation matrices.

3) Backtrace interpretation
- The backtrace alignment displayed above is one optimal sequence of edits.
- Each '^' marks a substitution (or a match if characters are equal).
- Each '<' marks a deletion from A (character removed).
- Each '>' marks an insertion into A (character from B inserted).

4) What the final distance means
- The bottom-right cell (dp[%d][%d]) equals %d, meaning %s.
]],

  pedagogical_conclusions = [[
Pedagogical conclusions and practical hints
- Small distance: strings are similar; large distance: many edits required.
- Patterns:
  * Many 'M' entries along the main diagonal indicate matching characters in corresponding positions.
  * Runs of 'I' or 'D' indicate insertions or deletions — often when a short substring is missing or extra.
  * Substitutions 'S' often appear when characters differ but are aligned positionally.
- For teaching: try pairs where length differences are small and where characters shift (e.g., transpositions
  are not minimal operations for Levenshtein — they require deletions + insertions unless using a different metric).
- Extensions: Damerau–Levenshtein includes adjacent transpositions; weighted edits assign different costs.
]],

  usage_hint = "Usage: lua levenstein/visual.lua \"stringA\" \"stringB\"  (add --de for German output)",

  examples_footer = [[
Each example prints:
- the numeric DP matrix,
- the operation matrix (chosen op per cell),
- an explicit backtrace alignment,
- the numerical distance, and
- a structured explanation tailored to the example.

Run with other words to see how the matrices and the alignment change.
]]
}

return M
