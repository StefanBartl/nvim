---@module 'custom.function_index'
---@brief Builds a list of all function definitions across multiple languages
---@description
--- Uses ripgrep to find function definitions without loading files as buffers
--- or relying on LSP. Supports Lua, Python, JavaScript/TypeScript, Go, Rust,
--- C/C++, Java, and Shell scripts.

local M = {}

---@type FunctionIndexConfig
local default_config = {
  enable_user_commands = true,
  enable_keymaps = false,
  default_scope = "cwd",
  keymaps = {
    telescope = "<leader>pf",
    fzf = "<leader>fF",
  },
}

---@type FunctionIndexConfig
local config = vim.deepcopy(default_config)

---Language-specific regex patterns for function detection
---@type table<string, string>
local PATTERNS = {
  lua = [[^\s*(local\s+)?function\s+[A-Za-z_][A-Za-z0-9_]*\s*\(|^\s*[A-Za-z0-9_.]+\s*=\s*function\s*\(]],
  python = [[^\s*def\s+[A-Za-z_][A-Za-z0-9_]*\s*\(|^\s*async\s+def\s+[A-Za-z_][A-Za-z0-9_]*\s*\(]],
  javascript = [[^\s*(async\s+)?function\s+[A-Za-z_$][A-Za-z0-9_$]*\s*\(|^\s*[A-Za-z_$][A-Za-z0-9_$]*\s*[:=]\s*(async\s+)?\([^)]*\)\s*=>|^\s*const\s+[A-Za-z_$][A-Za-z0-9_$]*\s*=\s*(async\s+)?function\s*\(]],
  typescript = [[^\s*(async\s+)?function\s+[A-Za-z_$][A-Za-z0-9_$]*\s*\(|^\s*[A-Za-z_$][A-Za-z0-9_$]*\s*[:=]\s*(async\s+)?\([^)]*\)\s*=>|^\s*const\s+[A-Za-z_$][A-Za-z0-9_$]*\s*=\s*(async\s+)?function\s*\(]],
  go = [[^\s*func\s+(\([^)]+\)\s+)?[A-Za-z_][A-Za-z0-9_]*\s*\(]],
  rust = [[^\s*(pub\s+)?(async\s+)?fn\s+[A-Za-z_][A-Za-z0-9_]*\s*(<[^>]+>)?\s*\(]],
  c = [[^\s*(static\s+|inline\s+|extern\s+)*[A-Za-z_][A-Za-z0-9_*\s]+\s+[A-Za-z_][A-Za-z0-9_]*\s*\([^;]*\)\s*\{]],
  cpp = [[^\s*(static\s+|inline\s+|virtual\s+|explicit\s+|constexpr\s+)*[A-Za-z_][A-Za-z0-9_*&<>\s:]+\s+[A-Za-z_][A-Za-z0-9_]*\s*\([^;]*\)\s*(const\s*)?\{]],
  java = [[^\s*(public|private|protected)?\s*(static\s+)?(final\s+)?[A-Za-z_<>]+\s+[A-Za-z_][A-Za-z0-9_]*\s*\(]],
  shell = [[^\s*(function\s+)?[A-Za-z_][A-Za-z0-9_]*\s*\(\s*\)\s*\{]],
}

---File extensions for each language
---@type table<string, string[]>
local FILE_PATTERNS = {
  lua = { "*.lua" },
  python = { "*.py" },
  javascript = { "*.js", "*.jsx", "*.mjs" },
  typescript = { "*.ts", "*.tsx" },
  go = { "*.go" },
  rust = { "*.rs" },
  c = { "*.c", "*.h" },
  cpp = { "*.cpp", "*.cc", "*.cxx", "*.hpp", "*.hh", "*.hxx" },
  java = { "*.java" },
  shell = { "*.sh", "*.bash", "*.zsh" },
}

---Detect function type (Local, Module, Anonymous) from text
---@param text string The function definition line
---@param lang string The language identifier
---@return string Single letter: L (Local), M (Module), A (Anonymous)
local function detect_function_type(text, lang)
  if lang == "lua" then
    if text:match("^%s*local%s+function") then
      return "L"
    elseif text:match("^%s*function%s+[A-Z]") or text:match("^%s*[A-Z][A-Za-z0-9_]*%.") then
      return "M"
    elseif text:match("=%s*function%s*%(") then
      return "A"
    end
  elseif lang == "python" then
    if text:match("^%s+def%s") then
      return "L"
    elseif text:match("^def%s") then
      return "M"
    end
  elseif lang == "javascript" or lang == "typescript" then
    if text:match("const%s") or text:match("let%s") or text:match("var%s") then
      return "L"
    elseif text:match("=>") then
      return "A"
    end
  end
  return "M"
end

---Extract function name from definition text
---@param text string The function definition line
---@param lang string The language identifier
---@return string The function name or "[anonymous]"
local function extract_function_name(text, lang)
  local name = nil

  if lang == "lua" then
    name = text:match("function%s+([A-Za-z_][A-Za-z0-9_%.:]*)%s*%(")
      or text:match("([A-Za-z_][A-Za-z0-9_%.:]*)%s*=%s*function")
  elseif lang == "python" then
    name = text:match("def%s+([A-Za-z_][A-Za-z0-9_]*)%s*%(")
  elseif lang == "javascript" or lang == "typescript" then
    name = text:match("function%s+([A-Za-z_$][A-Za-z0-9_$]*)%s*%(")
      or text:match("([A-Za-z_$][A-Za-z0-9_$]*)%s*[:=]%s*%(")
      or text:match("const%s+([A-Za-z_$][A-Za-z0-9_$]*)%s*=")
  elseif lang == "go" then
    name = text:match("func%s+%([^)]+%)%s+([A-Za-z_][A-Za-z0-9_]*)%s*%(")
      or text:match("func%s+([A-Za-z_][A-Za-z0-9_]*)%s*%(")
  elseif lang == "rust" then
    name = text:match("fn%s+([A-Za-z_][A-Za-z0-9_]*)%s*[<(]")
  elseif lang == "c" or lang == "cpp" then
    name = text:match("%s([A-Za-z_][A-Za-z0-9_]*)%s*%(")
  elseif lang == "java" then
    name = text:match("%s+([A-Za-z_][A-Za-z0-9_]*)%s*%(")
  elseif lang == "shell" then
    name = text:match("function%s+([A-Za-z_][A-Za-z0-9_]*)%s*%(")
      or text:match("([A-Za-z_][A-Za-z0-9_]*)%s*%(%)%s*{")
  end

  return name or "[anonymous]"
end

---Collect all function definitions with specified scope
---@param scope "cwd"|"buffer" Search scope
---@return table[] Array of {filename, lnum, col, text, lang, type, name}
local function collect_functions(scope)
  local all_patterns = {}
  local lang_lookup = {}

  for lang, pattern in pairs(PATTERNS) do
    table.insert(all_patterns, pattern)
    for _, ext_pattern in ipairs(FILE_PATTERNS[lang]) do
      lang_lookup[ext_pattern] = lang
    end
  end

  local combined_pattern = table.concat(all_patterns, "|")

  local globs = {}
  for _, patterns in pairs(FILE_PATTERNS) do
    for _, pat in ipairs(patterns) do
      table.insert(globs, "--glob")
      table.insert(globs, pat)
    end
  end

  local cmd = vim.list_extend({
    "rg",
    "--vimgrep",
    "--no-heading",
    "--pcre2",
  }, globs)

  table.insert(cmd, combined_pattern)

  -- Determine search path based on scope
  if scope == "buffer" then
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file == "" then
      vim.notify("Current buffer has no file", vim.log.levels.WARN)
      return {}
    end
    table.insert(cmd, current_file)
  else
    table.insert(cmd, ".")
  end

  local lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return {}
  end

  ---@type table[]
  local results = {}

  for _, line in ipairs(lines) do
    local file, lnum, col, text = line:match("([^:]+):(%d+):(%d+):(.*)")

    if file then
      local ext = file:match("%.([^%.]+)$")
      local lang = "unknown"

      for pattern, l in pairs(lang_lookup) do
        if pattern:match("%*%.(.+)") == ext then
          lang = l
          break
        end
      end

      local trimmed_text = vim.trim(text)
      local func_type = detect_function_type(trimmed_text, lang)
      local func_name = extract_function_name(trimmed_text, lang)

      results[#results + 1] = {
        filename = file,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = trimmed_text,
        lang = lang,
        type = func_type,
        name = func_name,
      }
    end
  end

  return results
end

---Telescope picker for function index
---@param scope "cwd"|"buffer"|nil Search scope (defaults to config.default_scope)
function M.telescope_functions_index(scope)
  scope = scope or config.default_scope

  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.notify("Telescope is not installed", vim.log.levels.ERROR)
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local action_layout = require("telescope.actions.layout")

  local entries = collect_functions(scope)

  local title = scope == "buffer" and "Function Index (Current Buffer)" or "Function Index (CWD)"

  pickers
    .new({}, {
      prompt_title = title,
      finder = finders.new_table({
        results = entries,
        entry_maker = function(e)
          -- Format: path:row  [L/M/A] function_name
          local display = string.format("%s:%d  [%s] %s", e.filename, e.lnum, e.type, e.name)

          return {
            value = e,
            display = display,
            ordinal = e.name .. " " .. e.filename,
            filename = e.filename,
            lnum = e.lnum,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        -- Toggle preview with <C-p>
        map("i", "<C-p>", action_layout.toggle_preview)
        map("n", "<C-p>", action_layout.toggle_preview)

        actions.select_default:replace(function()
          local sel = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          vim.cmd("edit " .. sel.filename)
          vim.api.nvim_win_set_cursor(0, { sel.lnum, 0 })
        end)

        return true
      end,
    })
    :find()
end

---FzfLua picker for function index
---@param scope "cwd"|"buffer"|nil Search scope (defaults to config.default_scope)
function M.fzf_functions_index(scope)
  scope = scope or config.default_scope

  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua is not installed", vim.log.levels.ERROR)
    return
  end

  local entries = collect_functions(scope)

  local lines = {}
  for _, e in ipairs(entries) do
    -- Format: path:row  [L/M/A] function_name
    lines[#lines + 1] = string.format("%s:%d  [%s] %s", e.filename, e.lnum, e.type, e.name)
  end

  local prompt_title = scope == "buffer" and "Functions (Buffer)> " or "Functions (CWD)> "

  fzf.fzf_exec(lines, {
    prompt = prompt_title,
    previewer = "builtin",
    actions = {
      ["default"] = function(sel)
        local file, lnum = sel[1]:match("([^:]+):(%d+)")
        if file and lnum then
          vim.cmd("edit " .. file)
          vim.api.nvim_win_set_cursor(0, { tonumber(lnum), 0 })
        end
      end,
      ["ctrl-p"] = function()
        -- FzfLua handles preview toggle internally with <F2>
        vim.notify("Use <F2> to toggle preview in fzf-lua", vim.log.levels.INFO)
      end,
    },
    winopts = {
      preview = {
        default = "builtin",
      },
    },
  })
end

---Setup function index with optional configuration
---@param opts FunctionIndexConfig|nil Optional configuration
function M.setup(opts)
  config = vim.tbl_deep_extend("force", default_config, opts or {})

  -- Load user actions
  if config.enable_user_commands or config.enable_keymaps then
    require("custom.function_index.user_actions").setup(config)
  end
end

return M
