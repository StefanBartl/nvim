---@module 'levenstein.visual'
--- Visual, cross-platform, detailed Levenshtein distance computation.
--- Provides numeric DP matrix, operation matrix, backtrace, alignment,
--- legend, and explanatory notes.
--- Supports English (default) and German (--de) via language files.

local M = {}

-- Load language strings from separate files
local function load_language()
    local en = {
        compute = "Compute Levenshtein",
        dp_matrix_title = "DP numeric matrix (rows = prefix of A, columns = prefix of B):",
        op_matrix_title = "Operation matrix (single letters indicate chosen operation per cell):",
        backtrace_title = "Backtrace and alignment (one optimal path):",
        legend = "Legend: M=match, S=substitution (^), D=deletion (<), I=insertion (>))",
        distance = "Levenshtein distance",
        note1 = "Note: The DP matrix cell at bottom-right is the total edit distance.",
        note2 = "      The operation matrix prefers Match/Substitute on ties for clearer alignments.",
        examples_hint = "To visualize custom pair: lua visual.lua \"stringA\" \"stringB\"",
        usage_de_flag = "Use --de flag for German language output"
    }
    local de = {
        compute = "Levenshtein berechnen",
        dp_matrix_title = "DP numerische Matrix (Zeilen = Präfix von A, Spalten = Präfix von B):",
        op_matrix_title = "Operationsmatrix (Einbuchstaben-Code zeigt gewählte Operation pro Zelle):",
        backtrace_title = "Backtrace und Ausrichtung (ein optimaler Pfad):",
        legend = "Legende: M=Match, S=Substitution (^), D=Deletion (<), I=Insertion (>)",
        distance = "Levenshtein Distanz",
        note1 = "Hinweis: Die Zelle unten-rechts der DP-Matrix enthält die gesamte Edit-Distanz.",
        note2 = "      Die Operationsmatrix bevorzugt Match/Substitute bei Gleichstand für lesbarere Alignments.",
        examples_hint = "Um ein eigenes Paar zu visualisieren: lua visual.lua \"StringA\" \"StringB\"",
        usage_de_flag = "Benutzen Sie --de für deutsche Ausgabe"
    }

    -- Default English
    local selected = en
    if arg then
        for _, v in ipairs(arg) do
            if v == "--de" then
                selected = de
                break
            end
        end
    end
    return selected
end

-- Compute Levenshtein distance with DP and operation matrices
local function levenshtein(a, b)
    local n, m = #a, #b
    local dp = {}
    local op = {}
    for i = 0, n do
        dp[i] = {}
        op[i] = {}
        for j = 0, m do
            dp[i][j] = 0
            op[i][j] = ""
        end
    end

    for i = 0, n do dp[i][0] = i; op[i][0] = "D" end
    for j = 0, m do dp[0][j] = j; op[0][j] = "I" end
    op[0][0] = " "

    for i = 1, n do
        for j = 1, m do
            local cost = (a:sub(i,i) == b:sub(j,j)) and 0 or 1
            local del = dp[i-1][j]+1
            local ins = dp[i][j-1]+1
            local sub = dp[i-1][j-1]+cost

            dp[i][j] = math.min(del, ins, sub)

            if dp[i][j] == sub then
                op[i][j] = (cost==0) and "M" or "S"
            elseif dp[i][j] == del then
                op[i][j] = "D"
            else
                op[i][j] = "I"
            end
        end
    end

    return dp, op
end

-- Backtrace for one optimal path
local function backtrace(op, a, b)
    local i, j = #a, #b
    local Apath, Bpath = {}, {}
    local arrows = {}

    while i>0 or j>0 do
        local o = op[i][j]
        if o == "M" or o == "S" then
            table.insert(Apath, 1, a:sub(i,i))
            table.insert(Bpath, 1, b:sub(j,j))
            table.insert(arrows, 1, (o=="M") and "^" or "^")
            i = i-1
            j = j-1
        elseif o == "D" then
            table.insert(Apath, 1, a:sub(i,i))
            table.insert(Bpath, 1, "-")
            table.insert(arrows, 1, "<")
            i = i-1
        elseif o == "I" then
            table.insert(Apath, 1, "-")
            table.insert(Bpath, 1, b:sub(j,j))
            table.insert(arrows, 1, ">")
            j = j-1
        else
            break
        end
    end

    return table.concat(Apath), table.concat(Bpath), table.concat(arrows, " ")
end

-- Pretty-print DP or operation matrix
local function print_matrix(title, matrix, a, b)
    print("\n"..title)
    io.write(string.format("%7s", "(empty)"))
    for j = 1, #b do
        io.write(string.format("%7s", b:sub(j,j)))
    end
    print()
    for i = 0, #a do
        io.write(string.format("%7s", (i==0) and "(empty)" or a:sub(i,i)))
        for j = 0, #b do
            io.write(string.format("%7s", matrix[i][j]))
        end
        print()
    end
end

-- Visualize function: all output
local function visualize(L, a, b)
    print("\n"..L.compute..": a='"..a.."' b='"..b.."'")
    local dp, op = levenshtein(a,b)
    print_matrix(L.dp_matrix_title, dp, a, b)
    print_matrix(L.op_matrix_title, op, a, b)
    local Apath,Bpath,arrows = backtrace(op,a,b)
    print("\n"..L.backtrace_title)
    print("A: "..Apath)
    print("B: "..Bpath)
    print("   "..arrows)
    print("\n"..L.legend)
    print(L.distance.." = "..dp[#a][#b])
    print(L.note1)
    print(L.note2)
end

-- Example inputs
local examples = {
    {a="kitten", b="sitting"},
    {a="flaw", b="lawn"},
    {a="gumbo", b="gambol"},
    {a="", b="abc"},
    {a="abc", b=""}
}

-- Run if executed directly
if pcall(debug.getlocal, 4, 1) == false then
    local L = load_language()
    if #arg >= 2 then
        local filtered_args = {}
        for i = 1, #arg do
            if arg[i] ~= "--de" then
                table.insert(filtered_args, arg[i])
            end
        end
        local a = filtered_args[1] or ""
        local b = filtered_args[2] or ""
        visualize(L, a, b)
    else
        for i = 1, #examples do
            visualize(L, examples[i].a, examples[i].b)
        end
        io.write("\n"..L.examples_hint.."\n")
        io.write(L.usage_de_flag.."\n")
    end
end

return M
