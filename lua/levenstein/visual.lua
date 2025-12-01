---@module 'levenstein.visual'
--- Cross-platform Lua module / script that computes Levenshtein distance and prints
--- ASCII-friendly visualizations for matrix, operations and one optimal backtrace.
--- Language strings are loaded from separate files (levenstein/lang_en.lua and levenstein/lang_de.lua)
--- so additional languages can be added by creating new lang_*.lua files.
---
--- Usage (shell):
---   lua levenstein/visual.lua "kitten" "sitting"
---   lua levenstein/visual.lua "kitten" "sitting" --de
---   lua levenstein/visual.lua        # runs builtin examples (default English)
---
--- Comments and identifiers are English per project convention.

local M = {}

-- Localize column width; adjust if very long input strings are expected.
local COLW = 8

-- Create a 2D numeric matrix with given rows and cols, initialized to 0.
-- Returns the matrix as a table of tables where indices start at 1.
local function make_matrix(rows, cols)
  local mat = {}
  for i = 1, rows do
    mat[i] = {}
    for j = 1, cols do
      mat[i][j] = 0
    end
  end
  return mat
end

-- Compute Levenshtein DP matrix and op matrix.
local function compute_levenshtein(a, b)
  local na = #a
  local nb = #b

  local dp = make_matrix(na + 1, nb + 1)
  local ops = make_matrix(na + 1, nb + 1)

  -- initialize first row and column
  for i = 1, na + 1 do
    dp[i][1] = i - 1
    ops[i][1] = (i == 1) and " " or "D"
  end
  for j = 1, nb + 1 do
    dp[1][j] = j - 1
    ops[1][j] = (j == 1) and " " or "I"
  end

  -- fill matrix
  for i = 2, na + 1 do
    for j = 2, nb + 1 do
      local ca = a:sub(i - 1, i - 1)
      local cb = b:sub(j - 1, j - 1)
      local cost = (ca == cb) and 0 or 1

      local deletion = dp[i - 1][j] + 1
      local insertion = dp[i][j - 1] + 1
      local substitution = dp[i - 1][j - 1] + cost

      local best = deletion
      local op = "D"
      if insertion < best then
        best = insertion
        op = "I"
      end
      if substitution < best then
        best = substitution
        op = (cost == 0) and "M" or "S"
      elseif substitution == best then
        -- prefer match/substitution for clearer alignment on ties
        if cost == 0 then
          op = "M"
        end
      end

      dp[i][j] = best
      ops[i][j] = op
    end
  end

  local distance = dp[na + 1][nb + 1]
  return dp, ops, distance
end

-- Print the DP numeric matrix with ASCII-friendly headers.
-- Fix: print exactly (#b + 1) header columns so data columns align correctly.
local function print_dp_matrix(L, a, b, dp)
  local empty_label = L.ascii_empty

  -- header: print the empty-prefix label then each char of b
  io.write(string.format("%" .. COLW .. "s", empty_label))
  for j = 1, #b do
    io.write(string.format("%" .. COLW .. "s", b:sub(j, j)))
  end
  io.write("\n")

  -- rows: for i=1..#a+1 print row label then dp values for j=1..#b+1
  for i = 1, #a + 1 do
    local row_label = (i == 1) and empty_label or a:sub(i - 1, i - 1)
    io.write(string.format("%" .. COLW .. "s", row_label))
    for j = 1, #b + 1 do
      io.write(string.format("%" .. COLW .. "d", dp[i][j]))
    end
    io.write("\n")
  end
end

-- Print operation matrix with exactly matching column alignment.
local function print_ops_matrix(L, a, b, ops)
  local empty_label = L.ascii_empty

  io.write(string.format("%" .. COLW .. "s", empty_label))
  for j = 1, #b do
    io.write(string.format("%" .. COLW .. "s", b:sub(j, j)))
  end
  io.write("\n")

  for i = 1, #a + 1 do
    local row_label = (i == 1) and empty_label or a:sub(i - 1, i - 1)
    io.write(string.format("%" .. COLW .. "s", row_label))
    for j = 1, #b + 1 do
      local v = ops[i][j] or " "
      io.write(string.format("%" .. COLW .. "s", v))
    end
    io.write("\n")
  end
end

-- Backtrace one optimal path and produce aligned strings and edit ops.
local function backtrace(a, b, dp)
  local i = #a + 1
  local j = #b + 1

  local aligned_a = {}
  local aligned_b = {}
  local edits = {}

  while not (i == 1 and j == 1) do
    local current = dp[i][j]
    local from_diag = (i > 1 and j > 1) and dp[i - 1][j - 1] or nil
    local from_up = (i > 1) and dp[i - 1][j] or nil
    local from_left = (j > 1) and dp[i][j - 1] or nil

    local ca = (i > 1) and a:sub(i - 1, i - 1) or nil
    local cb = (j > 1) and b:sub(j - 1, j - 1) or nil

    if from_diag and current == from_diag + ((ca == cb) and 0 or 1) then
      table.insert(aligned_a, 1, ca or "")
      table.insert(aligned_b, 1, cb or "")
      if ca == cb then
        table.insert(edits, 1, "M")
      else
        table.insert(edits, 1, "S")
      end
      i = i - 1
      j = j - 1
    elseif from_up and current == from_up + 1 then
      table.insert(aligned_a, 1, ca or "")
      table.insert(aligned_b, 1, "-")
      table.insert(edits, 1, "D")
      i = i - 1
    elseif from_left and current == from_left + 1 then
      table.insert(aligned_a, 1, "-")
      table.insert(aligned_b, 1, cb or "")
      table.insert(edits, 1, "I")
      j = j - 1
    else
      -- safety fallback: break to avoid infinite loop; this should not happen
      break
    end
  end

  return table.concat(aligned_a), table.concat(aligned_b), edits
end

-- Print alignment with markers and legend.
local function print_alignment(L, aligned_a, aligned_b, edits)
  io.write("A: " .. aligned_a .. "\n")
  io.write("B: " .. aligned_b .. "\n")
  local markers = {}
  for idx, op in ipairs(edits) do
    if op == "M" then
      markers[#markers + 1] = " "
    elseif op == "S" then
      markers[#markers + 1] = "^"
    elseif op == "D" then
      markers[#markers + 1] = "<"
    elseif op == "I" then
      markers[#markers + 1] = ">"
    else
      markers[#markers + 1] = "?"
    end
  end
  io.write("   " .. table.concat(markers) .. "\n\n")
  io.write(L.legend .. "\n")
end

-- High-level visualize function that prints dp, ops, alignment and short notes.
local function visualize(L, a, b)
  io.write(string.format(L.title_compute .. "\n\n", a, b))
  local dp, ops, distance = compute_levenshtein(a, b)

  io.write(L.dp_intro .. "\n")
  print_dp_matrix(L, a, b, dp)
  io.write("\n" .. L.ops_intro .. "\n")
  print_ops_matrix(L, a, b, ops)
  io.write("\n" .. L.backtrace_intro .. "\n")
  local aligned_a, aligned_b, edits = backtrace(a, b, dp)
  print_alignment(L, aligned_a, aligned_b, edits)
  io.write(string.format("Levenshtein distance = %d\n\n", distance))
  io.write(L.note_distance .. "\n")
  io.write(L.note_tiebreak .. "\n\n")
end

-- Expose functions for require() usage.
M.compute_levenshtein = compute_levenshtein
M.visualize = visualize
M.backtrace = backtrace

-- Builtin examples. Use explicit length-known table annotation for LuaLS.
---@type { {a:string, b:string} }
local examples = {
  { a = "kitten", b = "sitting" },
  { a = "flaw", b = "lawn" },
  { a = "gumbo", b = "gambol" },
  { a = "", b = "abc" },
  { a = "abc", b = "" },
}

-- Language loader: default English; if --de is present, attempt to load German.
local function load_language()
  local use_de = false
  for i = 1, #arg do
    if arg[i] == "--de" then
      use_de = true
      break
    end
  end

  local ok, L
  if use_de then
    ok, L = pcall(require, "levenstein.lang_de")
    if not ok then
      -- fall back to English if German file not present
      ok, L = pcall(require, "levenstein.lang_en")
    end
  else
    ok, L = pcall(require, "levenstein.lang_en")
    if not ok then
      -- try German if English not present
      ok, L = pcall(require, "levenstein.lang_de")
    end
  end

  -- final fallback: small hard-coded English table (should not be needed)
  if not ok or type(L) ~= "table" then
    L = {
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
  end

  return L
end

-- Check if the script is executed directly
if pcall(debug.getlocal, 4, 1) == false then
  local L = load_language()

  if #arg >= 2 then
    -- Check for --de in args
    local a, b
    local filtered_args = {}
    for i = 1, #arg do
      if arg[i] ~= "--de" then
        table.insert(filtered_args, arg[i])
      end
    end
    a = filtered_args[1] or ""
    b = filtered_args[2] or ""
    visualize(L, a, b)
  else
    -- run builtin examples
    for i = 1, #examples do
      local pair = examples[i]
      visualize(L, pair.a, pair.b)
    end
    io.write(L.examples_hint .. "\n")
    io.write(L.usage_de_flag .. "\n")
  end
end


return M
