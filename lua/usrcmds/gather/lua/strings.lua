---@module 'usrcmds.gather.lua.strings'
---@description Collects all Lua string literals using Tree-sitter

require("usrcmds.gather.@types")

local api = vim.api
local ts = vim.treesitter

local M = {}

--- Scan buffer for string literals
---@param bufnr integer
---@return UsrCmds.Gather.Lua.ScanResult
function M.scan_buffer(bufnr)
  local matches = {}
  local errors = {}

  -- Validate buffer
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

  -- Query for string literals
  local query_ok, query = pcall(ts.query.parse, "lua", [[
    (string) @str
  ]])

  if not query_ok or not query then
    table.insert(errors, "Failed to compile Tree-sitter query")
    return { matches = matches, errors = errors }
  end

  -- Track seen strings to avoid duplicates
  local seen = {}

  -- Collect matches
  for _, node in query:iter_captures(root, bufnr) do
    local text = ts.get_node_text(node, bufnr)

    if text and not seen[text] then
      seen[text] = true

      local row, col = node:range()

      table.insert(matches, {
        name = text,
        line = row + 1,
        col = col,
        file = nil,
        context = nil,
      })
    end
  end

  -- Sort by string content
  table.sort(matches, function(a, b)
    return a.name < b.name
  end)

  return { matches = matches, errors = errors }
end

--- Format matches for display
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

  if #result.errors > 0 then
    vim.notify(
      "Errors during string gathering:\n" .. table.concat(result.errors, "\n"),
      vim.log.levels.ERROR
    )
    return
  end

  if #result.matches == 0 then
    vim.notify("No strings found in buffer", vim.log.levels.WARN)
    return
  end

  local ui = require("usrcmds.gather.lua.ui")
  local lines = format_matches(result.matches)
  ui.open_scratch(lines, "Strings (" .. #result.matches .. ")")
end

return M
