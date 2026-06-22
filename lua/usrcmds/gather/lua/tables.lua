---@module 'usrcmds.gather.lua.tables'
---@description Collects Lua table names with recursive nested table detection

local notify = require("lib.nvim.notify").create("[usrcmds.gather.lua.tables]")

require("usrcmds.gather.@types")

local api = vim.api
local ts = vim.treesitter

local M = {}

--- Build full path for nested table assignments
---@param node TSNode
---@param bufnr integer
---@return string|nil path
local function build_table_path(node, bufnr)
  local parts = {}
  local current = node

  -- Walk up the tree to build the full path
  while current do
    local node_type = current:type()

    if node_type == "dot_index_expression" then
      -- Extract field name
      local field_node = current:field("field")[1]
      if field_node then
        local field_text = ts.get_node_text(field_node, bufnr)
        table.insert(parts, 1, field_text)
      end

      -- Move to table part
      local table_node = current:field("table")[1]
      if table_node and table_node:type() == "identifier" then
        local table_text = ts.get_node_text(table_node, bufnr)
        table.insert(parts, 1, table_text)
        break
      end

      current = table_node
    elseif node_type == "identifier" then
      local text = ts.get_node_text(current, bufnr)
      table.insert(parts, 1, text)
      break
    else
      local par = current:parent()
      if par then
        current = par
      else
        notify.debug("current parent node is nil")
      end
    end
  end

  if #parts > 0 then
    return table.concat(parts, ".")
  end

  return nil
end

--- Scan buffer for table definitions
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

  -- Query for various table patterns
  local query_ok, query = pcall(
    ts.query.parse,
    "lua",
    [[
    ; Simple table assignments: local t = {}
    (assignment_statement
      (variable_list
        (identifier) @name)
      (expression_list
        (table_constructor)))

    ; Dot-index table assignments: state.win = {}
    (assignment_statement
      (variable_list
        (dot_index_expression) @path)
      (expression_list
        (table_constructor)))

    ; Table fields: { field = {} }
    (field
      name: (identifier) @field_name
      value: (table_constructor))
  ]]
  )

  if not query_ok or not query then
    table.insert(errors, "Failed to compile Tree-sitter query")
    return { matches = matches, errors = errors }
  end

  -- Track seen tables
  local seen = {}

  -- Collect matches
  for id, node in query:iter_captures(root, bufnr) do
    local capture_name = query.captures[id]
    local row, col = node:range()

    if capture_name == "name" then
      -- Simple identifier
      local name = ts.get_node_text(node, bufnr)

      if name and not seen[name] then
        seen[name] = true
        table.insert(matches, {
          name = name,
          line = row + 1,
          col = col,
          file = nil,
          context = nil,
        })
      end
    elseif capture_name == "path" then
      -- Dot-index expression (nested table)
      local path = build_table_path(node, bufnr)

      if path and not seen[path] then
        seen[path] = true
        table.insert(matches, {
          name = path,
          line = row + 1,
          col = col,
          file = nil,
          context = "nested",
        })
      end
    elseif capture_name == "field_name" then
      -- Table field
      local name = ts.get_node_text(node, bufnr)

      -- Try to get parent table context
      local parent = node:parent()
      while parent and parent:type() ~= "assignment_statement" do
        parent = parent:parent()
      end

      local context = nil
      if parent then
        local var_list = parent:field("variable_list")[1]
        if var_list then
          context = ts.get_node_text(var_list, bufnr)
        end
      end

      local full_name = context and (context .. "." .. name) or name

      if not seen[full_name] then
        seen[full_name] = true
        table.insert(matches, {
          name = full_name,
          line = row + 1,
          col = col,
          file = nil,
          context = context,
        })
      end
    end
  end

  -- Sort by name
  table.sort(matches, function(a, b)
    return a.name < b.name
  end)

  return { matches = matches, errors = errors }
end

--- Format matches for display
---@param matches UsrCmds.Gather.Lua.Match[]
---@param mode UsrCmds.Gather.Lua.ScanMode
---@return string[]
local function format_matches(matches, mode)
  local lines = {}

  for _, match in ipairs(matches) do
    local line_str

    if mode == "cwd" and match.file then
      -- CWD mode: relative_path:line:col: name
      local rel_path = vim.fn.fnamemodify(match.file, ":~:.")
      line_str = string.format("%s:%d:%d: %s", rel_path, match.line, match.col, match.name)
    else
      -- Buffer mode: line:col: name
      line_str = string.format("%d:%d: %s", match.line, match.col, match.name)
    end

    table.insert(lines, line_str)
  end

  return lines
end

--- Run gatherer for current buffer
function M.run()
  local bufnr = api.nvim_get_current_buf()
  local result = M.scan_buffer(bufnr)

  if #result.errors > 0 then
    notify.error("Errors during table gathering:\n" .. table.concat(result.errors, "\n"))
    return
  end

  if #result.matches == 0 then
    notify.warn("No tables found in buffer")
    return
  end

  local ui = require("usrcmds.gather.lua.ui")
  local lines = format_matches(result.matches, "buffer")
  ui.open_scratch(lines, "Tables (" .. #result.matches .. ")")
end

return M
