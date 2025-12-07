---@module 'levenstein.visual'
--- Main visualizer script for Levenshtein distance.
--- - Loads language strings from levenstein.lang_en or levenstein.lang_de
--- - Computes DP and operation matrices
--- - Prints detailed matrices, alignment, and an extended pedagogical discussion
--- This script is intended to be run directly: `lua levenstein/visual.lua "a" "b" [--de]`

-- English comments kept throughout code; output language depends on loaded language file.

local M = {}

-- Utility: safe require for language files in same folder
local function try_require(name)
  local ok, mod = pcall(require, name)
  if ok and type(mod) == "table" then
    return mod
  end
  return nil
end

-- Load language table (default English, --de for German)
local function load_language_table()
  -- Default English fallback
  local fallback = {
    title_compute = "Compute Levenshtein: a='%s' b='%s'",
    dp_intro = "DP numeric matrix (rows = prefix of A, columns = prefix of B):",
    ops_intro = "Operation matrix (single letters indicate chosen operation per cell):",
    backtrace_intro = "Backtrace and alignment (one optimal path):",
    legend = "Legend: M=match, S=substitution (^), D=deletion (<), I=insertion (>)",
    distance_label = "Levenshtein distance",
    definition = "Definition (missing language file)",
    algorithm_explanation = "Algorithm explanation (missing language file)",
    matrix_explanation = "Matrix explanation (missing language file)",
    step_by_step_template = "Step-by-step template (missing language file)",
    pedagogical_conclusions = "Conclusions (missing language file)",
    usage_hint = "Usage: lua levenstein/visual.lua \"A\" \"B\" [--de]",
    examples_footer = ""
  }

  -- detect --de flag in arg
  local use_de = false
  if arg then
    for i = 1, #arg do
      if arg[i] == "--de" then use_de = true; break end
    end
  end

  if use_de then
    -- local de = try_require("levenstein.lang_de")
    local de = try_require("lua.levenstein.lang_de")
    if de then return de end
  else
    -- local en = try_require("levenstein.lang_en")
    local en = try_require("lua.levenstein.lang_en")
    if en then return en end
  end

  -- Attempt other file if primary not found
  if use_de then
    -- local en = try_require("levenstein.lang_en")
    local en = try_require("lua.levenstein.lang_en")
    if en then return en end
  else
    -- local de = try_require("levenstein.lang_de")
    local de = try_require("lua.levenstein.lang_de")
    if de then return de end
  end

  return fallback
end

-- Create empty numeric matrix of size (n+1)x(m+1)
local function make_matrix(n, m, fill)
  local mat = {}
  for i = 0, n do
    mat[i] = {}
    for j = 0, m do
      mat[i][j] = fill
    end
  end
  return mat
end

-- Compute DP matrix and operation matrix.
-- Returns dp, ops where dp[i][j] numeric, ops[i][j] in {"M","S","D","I"," "}
local function compute_matrices(a, b)
  local n, m = #a, #b
  local dp = make_matrix(n, m, 0)
  local ops = make_matrix(n, m, " ")

  -- base cases
  for i = 0, n do
    dp[i][0] = i
    ops[i][0] = (i == 0) and " " or "D"
  end
  for j = 0, m do
    dp[0][j] = j
    ops[0][j] = (j == 0) and " " or "I"
  end

  -- fill
  for i = 1, n do
    for j = 1, m do
      local ca = a:sub(i,i)
      local cb = b:sub(j,j)
      local cost = (ca == cb) and 0 or 1

      local del = dp[i-1][j] + 1
      local ins = dp[i][j-1] + 1
      local sub = dp[i-1][j-1] + cost

      local best = del
      local op = "D"
      if ins < best then best = ins; op = "I" end
      if sub < best then best = sub; op = (cost==0) and "M" or "S"
      elseif sub == best then
        if cost == 0 then op = "M" end
      end

      dp[i][j] = best
      ops[i][j] = op
    end
  end

  return dp, ops
end

-- Backtrace one optimal alignment from dp and ops.
local function backtrace(_, ops, a, b)
  local i, j = #a, #b
  local aligned_a = {}
  local aligned_b = {}
  local markers = {}

  while not (i == 0 and j == 0) do
    local op = ops[i][j]
    -- When at edges, ops[i][0] or ops[0][j] contain D/I respectively.
    if op == "M" or op == "S" then
      table.insert(aligned_a, 1, a:sub(i,i))
      table.insert(aligned_b, 1, b:sub(j,j))
      table.insert(markers, 1, (op == "M") and " " or "^")
      i = i - 1
      j = j - 1
    elseif op == "D" then
      table.insert(aligned_a, 1, a:sub(i,i))
      table.insert(aligned_b, 1, "-")
      table.insert(markers, 1, "<")
      i = i - 1
    elseif op == "I" then
      table.insert(aligned_a, 1, "-")
      table.insert(aligned_b, 1, b:sub(j,j))
      table.insert(markers, 1, ">")
      j = j - 1
    else
      -- Safety: if op is " " (at [0][0]) but loop not terminated, break
      break
    end
  end

  return table.concat(aligned_a), table.concat(aligned_b), table.concat(markers)
end

-- Pretty-print numeric DP matrix with ASCII header '(empty)'
local function print_dp_matrix(L, a, b, dp)
  print("\n" .. L.dp_intro)
  io.write(string.format("%8s", "(empty)"))
  for j = 1, #b do io.write(string.format("%8s", b:sub(j,j))) end
  io.write("\n")
  for i = 0, #a do
    io.write(string.format("%8s", (i==0) and "(empty)" or a:sub(i,i)))
    for j = 0, #b do
      io.write(string.format("%8d", dp[i][j]))
    end
    io.write("\n")
  end
end

-- Pretty-print operation matrix
local function print_ops_matrix(L, a, b, ops)
  print("\n" .. L.ops_intro)
  io.write(string.format("%8s", "(empty)"))
  for j = 1, #b do io.write(string.format("%8s", b:sub(j,j))) end
  io.write("\n")
  for i = 0, #a do
    io.write(string.format("%8s", (i==0) and "(empty)" or a:sub(i,i)))
    for j = 0, #b do
      io.write(string.format("%8s", ops[i][j]))
    end
    io.write("\n")
  end
end

-- Print backtrace, alignment, legend and numeric distance
local function print_backtrace_and_notes(L, dp, ops, a, b)
  print("\n" .. L.backtrace_intro)
  local Aalign, Balign, markers = backtrace(dp, ops, a, b)
  print("A: " .. Aalign)
  print("B: " .. Balign)
  print("   " .. markers)
  print("\n" .. L.legend)
  print(string.format("%s = %d", L.distance_label, dp[#a][#b]))
end

-- Compose and print a long-form, example-specific pedagogical discussion
local function print_detailed_discussion(L, a, b, dp)
  -- Print global definition and algorithm once per example
  print("\n--\n")
  print(L.definition)
  print(L.algorithm_explanation)
  print(L.matrix_explanation)

  -- Find a representative cell for step-by-step hint (choose middle cell)
  local rep_i = math.max(1, math.floor(#a / 2))
  local rep_j = math.max(1, math.floor(#b / 2))
  -- Fill step-by-step template with example-specific values
  local step_text = string.format(
    L.step_by_step_template,
    a, b,
    rep_i, rep_j, rep_i, (a:sub(1, rep_i) or ""), rep_j, (b:sub(1, rep_j) or ""),
    #a, #b, dp[#a][#b],
    (dp[#a][#b] == 0) and "the strings are identical" or ("this minimum number of single-character edits is required to transform A into B")
  )
  print(step_text)

  print(L.pedagogical_conclusions)
  print("\n" .. L.examples_footer)
end

-- High-level visualize function: matrices, backtrace, and didactic text
local function visualize(L, a, b)
  print(string.format(L.title_compute, a, b))
  local dp, ops = compute_matrices(a, b)
  print_dp_matrix(L, a, b, dp)
  print_ops_matrix(L, a, b, ops)
  print_backtrace_and_notes(L, dp, ops, a, b)
  print_detailed_discussion(L, a, b, dp)
end

-- Examples table annotated for LuaLS / type clarity
-- ---@type { {a:string, b:string} }
local examples = {
  { a = "kitten", b = "sitting" },
  { a = "flaw", b = "lawn" },
  { a = "gumbo", b = "gambol" },
  { a = "", b = "abc" },
  { a = "abc", b = "" },
}

-- Execution guard: run when executed directly via 'lua visual.lua ...'
if pcall(debug.getlocal, 4, 1) == false then
  local L = load_language_table()

  -- Collect CLI args, strip --de if present
  local inputs = {}
  if arg then
    for i = 1, #arg do
      if arg[i] ~= "--de" then table.insert(inputs, arg[i]) end
    end
  end

  if #inputs >= 2 then
    local a, b = inputs[1], inputs[2]
    visualize(L, a, b)
  else
    for i = 1, #examples do
      visualize(L, examples[i].a, examples[i].b)
    end
    print("\n" .. L.usage_hint)
  end
end

return M
