---@module 'custom.function_index.core.parser'
---@brief Parses ripgrep output into structured function entries
---@description
--- This module handles parsing of ripgrep's --vimgrep output format
--- and transforms raw matches into structured FunctionEntry objects.
--- Includes validation, error handling, and signature extraction.

local M = {}

local patterns_mod = require("custom.function_index.core.patterns")

--- Parse a single line of ripgrep --vimgrep output
--- Format: "filename:line:column:text"
---@param line string # Raw line from ripgrep
---@return RipgrepResult|nil
local function parse_vimgrep_line(line)
  if type(line) ~= "string" or line == "" then
    return nil
  end

  -- Split on first three colons to handle filenames with colons
  local parts = {}
  local start_idx = 1

  for i = 1, 3 do
    local colon_pos = line:find(":", start_idx, true)
    if not colon_pos then
      return nil
    end
    parts[i] = line:sub(start_idx, colon_pos - 1)
    start_idx = colon_pos + 1
  end

  parts[4] = line:sub(start_idx) -- Remaining text

  local filename, lnum_str, col_str, text = parts[1], parts[2], parts[3], parts[4]

  -- Validate numeric fields
  local lnum = tonumber(lnum_str)
  local col = tonumber(col_str)

  if not lnum or not col then
    return nil
  end

  return {
    filename = filename,
    lnum = lnum,
    col = col,
    text = vim.trim(text),
  }
end

--- Extract function name from text using basic heuristics
---@param text string # Raw matched text
---@param language string
---@return string|nil # Function name or nil
local function extract_function_name(text, language)
  if language == "lua" then
    -- Try different Lua patterns
    local name = text:match("function%s+([A-Za-z_][A-Za-z0-9_.]*)")
      or text:match("([A-Za-z_][A-Za-z0-9_.]*)%s*=%s*function")
    return name
  end

  if language == "python" then
    return text:match("def%s+([A-Za-z_][A-Za-z0-9_]*)")
  end

  if language == "javascript" or language == "typescript" then
    return text:match("function%s+([A-Za-z_$][A-Za-z0-9_$]*)")
      or text:match("const%s+([A-Za-z_$][A-Za-z0-9_$]*)%s*=")
      or text:match("([A-Za-z_$][A-Za-z0-9_$]*)%s*%(")
  end

  if language == "go" then
    return text:match("func%s+%(.-%)%s+([A-Za-z_][A-Za-z0-9_]*)")
      or text:match("func%s+([A-Za-z_][A-Za-z0-9_]*)")
  end

  if language == "rust" then
    return text:match("fn%s+([A-Za-z_][A-Za-z0-9_]*)")
  end

  if language == "c" or language == "cpp" then
    return text:match("([A-Za-z_][A-Za-z0-9_]*)%s*%(")
  end

  if language == "java" then
    return text:match("[%s%w]+%s+([A-Za-z_][A-Za-z0-9_]*)%s*%(")
  end

  if language == "ruby" then
    return text:match("def%s+(?:self%.)?([A-Za-z_][A-Za-z0-9_?!]*)")
  end

  if language == "php" then
    return text:match("function%s+([A-Za-z_][A-Za-z0-9_]*)")
  end

  return nil
end

--- Extract clean function signature from text
---@param text string # Raw matched text
---@param func_name string # Already extracted function name
---@return string # Cleaned signature (e.g., "foo(x, y)")
local function extract_signature(text, func_name)
  -- Find opening parenthesis after function name
  local name_pos = text:find(func_name, 1, true)
  if not name_pos then
    return func_name .. "()"
  end

  local paren_start = text:find("%(", name_pos)
  if not paren_start then
    return func_name .. "()"
  end

  -- Find matching closing parenthesis
  local depth = 1
  local paren_end = nil

  for i = paren_start + 1, #text do
    local char = text:sub(i, i)
    if char == "(" then
      depth = depth + 1
    elseif char == ")" then
      depth = depth - 1
      if depth == 0 then
        paren_end = i
        break
      end
    end
  end

  if not paren_end then
    return func_name .. "(...)"
  end

  local params = text:sub(paren_start + 1, paren_end - 1)
  params = vim.trim(params)

  -- Simplify params (remove types, defaults, etc.)
  if #params > 40 then
    params = params:sub(1, 37) .. "..."
  end

  return func_name .. "(" .. params .. ")"
end

--- Detect language from filename extension
---@param filename string
---@return string|nil
local function detect_language(filename)
  local ext = filename:match("%.([^%.]+)$")
  if not ext then
    return nil
  end

  local ext_to_lang = {
    lua = "lua",
    py = "python",
    pyw = "python",
    js = "javascript",
    jsx = "javascript",
    mjs = "javascript",
    ts = "typescript",
    tsx = "typescript",
    go = "go",
    rs = "rust",
    c = "c",
    h = "c",
    cpp = "cpp",
    cc = "cpp",
    cxx = "cpp",
    hpp = "cpp",
    hh = "cpp",
    hxx = "cpp",
    java = "java",
    rb = "ruby",
    php = "php",
  }

  return ext_to_lang[ext:lower()]
end

--- Parse ripgrep output lines into function entries
---@param lines string[] # Output from ripgrep
---@param enabled_languages table<string, boolean>
---@return FunctionEntry[] # Parsed entries
---@return string[] # Errors encountered
function M.parse_ripgrep_output(lines, enabled_languages)
  if type(lines) ~= "table" then
    return {}, { "Invalid input: expected table of strings" }
  end

  local entries = {}
  local errors = {}

  for i, line in ipairs(lines) do
    local rg_result = parse_vimgrep_line(line)

    if rg_result then
      local language = detect_language(rg_result.filename)

      if language and enabled_languages[language] then
        local func_name = extract_function_name(rg_result.text, language)

        if func_name then
          local func_type = patterns_mod.infer_func_type(rg_result.text, language)
          local signature = extract_signature(rg_result.text, func_name)

          entries[#entries + 1] = {
            filename = rg_result.filename,
            lnum = rg_result.lnum,
            col = rg_result.col,
            text = rg_result.text,
            func_name = func_name,
            func_type = func_type,
            language = language,
            signature = signature,
          }
        else
          errors[#errors + 1] = string.format(
            "Could not extract function name from line %d: %s",
            i,
            line
          )
        end
      end
    else
      errors[#errors + 1] = string.format("Failed to parse line %d: %s", i, line)
    end
  end

  return entries, errors
end

--- Validate a function entry
---@param entry any
---@return boolean # true if valid
---@return string|nil # Error message if invalid
function M.validate_entry(entry)
  if type(entry) ~= "table" then
    return false, "Entry must be a table"
  end

  if type(entry.filename) ~= "string" or entry.filename == "" then
    return false, "Invalid filename"
  end

  if type(entry.lnum) ~= "number" or entry.lnum < 1 then
    return false, "Invalid line number"
  end

  if type(entry.col) ~= "number" or entry.col < 1 then
    return false, "Invalid column number"
  end

  if type(entry.func_name) ~= "string" or entry.func_name == "" then
    return false, "Invalid function name"
  end

  if type(entry.language) ~= "string" or entry.language == "" then
    return false, "Invalid language"
  end

  return true, nil
end

return M
