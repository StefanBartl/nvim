---@module 'usrcmds.gather.lua.functions'
---@description Collects Lua function definitions using Tree-sitter with comprehensive pattern coverage

require("usrcmds.gather.@types")

local api = vim.api
local ts = vim.treesitter

local M = {}

--- Collect all function definitions from buffer using Tree-sitter
---@param bufnr integer Buffer number
---@return UsrCmds.Gather.Lua.ScanResult
function M.scan_buffer(bufnr)
  local matches = {}
  local errors = {}

  -- Validate buffer and filetype
  if not api.nvim_buf_is_valid(bufnr) then
    table.insert(errors, "Invalid buffer")
    return { matches = matches, errors = errors }
  end

  local ok, ft = pcall(api.nvim_get_option_value, "filetype", { buf = bufnr })
  if not ok or ft ~= "lua" then
    table.insert(errors, "Buffer is not a Lua file")
    return { matches = matches, errors = errors }
  end

  -- Get parser
  local parser_ok, parser = pcall(ts.get_parser, bufnr, "lua")
  if not parser_ok or not parser then
    table.insert(errors, "Failed to get Tree-sitter parser")
    return { matches = matches, errors = errors }
  end

  local tree_ok, trees = pcall(parser.parse, parser)
  if not tree_ok or not trees or #trees == 0 then
    table.insert(errors, "Failed to parse buffer")
    return { matches = matches, errors = errors }
  end

  local root = trees[1]:root()

  -- Comprehensive query covering all function definition patterns
  local query_ok, query = pcall(ts.query.parse, "lua", [[
    ; Top-level function declarations: function name()
    (function_declaration
      name: (identifier) @func)

    ; Local function declarations: local function name()
    (local_function
      name: (identifier) @func)

    ; Module/table method assignments: M.func = function()
    (assignment_statement
      (variable_list
        (dot_index_expression
          field: (identifier) @func))
      (expression_list
        (function_definition)))

    ; Simple variable assignments: local func = function()
    (assignment_statement
      (variable_list
        (identifier) @func)
      (expression_list
        (function_definition)))

    ; Table field functions: { func = function() }
    (field
      name: (identifier) @func
      value: (function_definition))
  ]])

  if not query_ok or not query then
    table.insert(errors, "Failed to compile Tree-sitter query")
    return { matches = matches, errors = errors }
  end

  -- Track seen functions to avoid duplicates
  local seen = {}

  -- Iterate over captures
  for _, node in query:iter_captures(root, bufnr) do
    local name = ts.get_node_text(node, bufnr)

    if name and name ~= "" and not seen[name] then
      seen[name] = true

      local row, col = node:range()

      table.insert(matches, {
        name = name,
        line = row + 1,  -- Convert to 1-based
        col = col,
        file = nil,
        context = nil,
      })
    end
  end

  -- Sort by name
  table.sort(matches, function(a, b)
    return a.name < b.name
  end)

  return { matches = matches, errors = errors }
end

--- Format matches for display in scratch buffer
---@param matches UsrCmds.Gather.Lua.Match[]
---@return string[]
local function format_matches(matches)
  local lines = {}

  for _, match in ipairs(matches) do
    table.insert(lines, match.name)
  end

  return lines
end

--- Run gatherer for current buffer
function M.run()
  local bufnr = api.nvim_get_current_buf()
  local result = M.scan_buffer(bufnr)

  -- Show errors if any
  if #result.errors > 0 then
    vim.notify(
      "Errors during function gathering:\n" .. table.concat(result.errors, "\n"),
      vim.log.levels.ERROR
    )
    return
  end

  -- Show results
  if #result.matches == 0 then
    vim.notify("No functions found in buffer", vim.log.levels.WARN)
    return
  end

  local ui = require("usrcmds.gather.lua.ui")
  local lines = format_matches(result.matches)
  ui.open_scratch(lines, "Functions (" .. #result.matches .. ")")
end

return M
