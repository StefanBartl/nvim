---@module 'custom.function_index.core.patterns'
---@brief Language-specific regex patterns for function detection
---@description
--- This module defines PCRE2-compatible regex patterns for detecting
--- function definitions across multiple programming languages.
--- Each pattern is optimized for ripgrep and includes capture groups
--- for extracting function names and signatures.

local M = {}

--- Language pattern definitions
--- Each pattern includes:
---   - language: Language identifier
---   - pattern: PCRE2 regex for ripgrep
---   - func_type: Default function type (can be overridden)
---   - name_capture: Index of capture group for function name
---   - signature_capture: Optional index for full signature
---@type LanguagePattern[]
local patterns = {
  -- #####################################################################
  -- Lua
  -- #####################################################################
  {
    language = "lua",
    pattern = [[^\s*local\s+function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "local",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "lua",
    pattern = [[^\s*function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "global",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "lua",
    pattern = [[^\s*function\s+([A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "module",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "lua",
    pattern = [[^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*function\s*\(([^)]*)\)]],
    func_type = "anonymous",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "lua",
    pattern = [[^\s*([A-Za-z_][A-Za-z0-9_.]+)\s*=\s*function\s*\(([^)]*)\)]],
    func_type = "module",
    name_capture = 1,
    signature_capture = 2,
  },

  -- #####################################################################
  -- Python
  -- #####################################################################
  {
    language = "python",
    pattern = [[^\s*def\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "global",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "python",
    pattern = [[^\s*async\s+def\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "global",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "python",
    pattern = [[^\s+def\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "method",
    name_capture = 1,
    signature_capture = 2,
  },

  -- #####################################################################
  -- JavaScript/TypeScript
  -- #####################################################################
  {
    language = "javascript",
    pattern = [[^\s*function\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*\(([^)]*)\)]],
    func_type = "global",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "javascript",
    pattern = [[^\s*export\s+function\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*\(([^)]*)\)]],
    func_type = "exported",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "javascript",
    pattern = [[^\s*const\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*=\s*(?:async\s*)?\(([^)]*)\)\s*=>]],
    func_type = "anonymous",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "javascript",
    pattern = [[^\s*([A-Za-z_$][A-Za-z0-9_$]*)\s*\(([^)]*)\)\s*\{]],
    func_type = "method",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "typescript",
    pattern = [[^\s*export\s+function\s+([A-Za-z_$][A-Za-z0-9_$]*)<[^>]*>\s*\(([^)]*)\)]],
    func_type = "exported",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "typescript",
    pattern = [[^\s*function\s+([A-Za-z_$][A-Za-z0-9_$]*)<[^>]*>\s*\(([^)]*)\)]],
    func_type = "global",
    name_capture = 1,
    signature_capture = 2,
  },

  -- #####################################################################
  -- Go
  -- #####################################################################
  {
    language = "go",
    pattern = [[^\s*func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "global",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "go",
    pattern = [[^\s*func\s+\([^)]+\)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "method",
    name_capture = 1,
    signature_capture = 2,
  },

  -- #####################################################################
  -- Rust
  -- #####################################################################
  {
    language = "rust",
    pattern = [[^\s*fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "local",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "rust",
    pattern = [[^\s*pub\s+fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "exported",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "rust",
    pattern = [[^\s+fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "method",
    name_capture = 1,
    signature_capture = 2,
  },

  -- #####################################################################
  -- C/C++
  -- #####################################################################
  {
    language = "c",
    pattern = [[^\s*(?:static\s+)?(?:inline\s+)?[A-Za-z_][A-Za-z0-9_*\s]+\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)\s*\{]],
    func_type = "global",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "cpp",
    pattern = [[^\s*(?:virtual\s+)?(?:static\s+)?(?:inline\s+)?[A-Za-z_][A-Za-z0-9_:*\s<>]+\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "global",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "cpp",
    pattern = [[^\s*([A-Za-z_][A-Za-z0-9_]*)::\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "method",
    name_capture = 2,
    signature_capture = 3,
  },

  -- #####################################################################
  -- Java
  -- #####################################################################
  {
    language = "java",
    pattern = [[^\s*(?:public|private|protected)?\s*(?:static\s+)?(?:final\s+)?[A-Za-z_<>[\]+\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "method",
    name_capture = 1,
    signature_capture = 2,
  },

  -- #####################################################################
  -- Ruby
  -- #####################################################################
  {
    language = "ruby",
    pattern = [[^\s*def\s+([A-Za-z_][A-Za-z0-9_?!]*)\s*\(([^)]*)\)]],
    func_type = "global",
    name_capture = 1,
    signature_capture = 2,
  },
  {
    language = "ruby",
    pattern = [[^\s*def\s+self\.([A-Za-z_][A-Za-z0-9_?!]*)\s*\(([^)]*)\)]],
    func_type = "method",
    name_capture = 1,
    signature_capture = 2,
  },

  -- #####################################################################
  -- PHP
  -- #####################################################################
  {
    language = "php",
    pattern = [[^\s*(?:public|private|protected)?\s*function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)]],
    func_type = "method",
    name_capture = 1,
    signature_capture = 2,
  },
}

--- Get all patterns for enabled languages
---@param enabled_languages table<string, boolean>
---@return LanguagePattern[]
function M.get_patterns(enabled_languages)
  local result = {}

  for _, pat in ipairs(patterns) do
    if enabled_languages[pat.language] then
      result[#result + 1] = pat
    end
  end

  return result
end

--- Build a combined regex pattern for ripgrep
--- Joins all enabled patterns with OR operator
---@param enabled_languages table<string, boolean>
---@return string # Combined PCRE2 pattern
function M.build_combined_pattern(enabled_languages)
  -- Note: This function is deprecated in favor of per-language searches
  -- It's kept for backwards compatibility
  local enabled_patterns = M.get_patterns(enabled_languages)
  local parts = {}

  for _, pat in ipairs(enabled_patterns) do
    parts[#parts + 1] = "(" .. pat.pattern .. ")"
  end

  if #parts == 0 then
    return ""
  end

  return table.concat(parts, "|")
end

--- Get file extensions for enabled languages
---@param enabled_languages table<string, boolean>
---@return string[] # List of extensions (e.g., {"lua", "py", "js"})
function M.get_extensions(enabled_languages)
  local ext_map = {
    lua = { "lua" },
    python = { "py", "pyw" },
    javascript = { "js", "jsx", "mjs" },
    typescript = { "ts", "tsx" },
    go = { "go" },
    rust = { "rs" },
    c = { "c", "h" },
    cpp = { "cpp", "cc", "cxx", "hpp", "hh", "hxx" },
    java = { "java" },
    ruby = { "rb" },
    php = { "php" },
  }

  local result = {}
  local seen = {}

  for lang, exts in pairs(ext_map) do
    if enabled_languages[lang] then
      for _, ext in ipairs(exts) do
        if not seen[ext] then
          result[#result + 1] = ext
          seen[ext] = true
        end
      end
    end
  end

  return result
end

--- Determine function type from matched text (heuristic)
--- Used as fallback when pattern doesn't specify type
---@param text string # Matched line
---@param language string
---@return string # Function type
function M.infer_func_type(text, language)
  -- Lua-specific heuristics
  if language == "lua" then
    if text:match("^%s*local%s+function") then
      return "local"
    elseif text:match("^%s*function%s+[A-Za-z_][A-Za-z0-9_]*%.[A-Za-z_]") then
      return "module"
    elseif text:match("^%s*function%s+") then
      return "global"
    elseif text:match("=%s*function%s*%(") then
      return "anonymous"
    end
  end

  -- Python-specific
  if language == "python" then
    if text:match("^%s+def%s+") then
      return "method"
    elseif text:match("^%s*async%s+def") then
      return "global"
    end
  end

  -- JavaScript/TypeScript
  if language == "javascript" or language == "typescript" then
    if text:match("^%s*export%s+function") then
      return "exported"
    elseif text:match("=>") then
      return "anonymous"
    end
  end

  return "unknown"
end

return M
