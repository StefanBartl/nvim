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

  -- Track seen functions to avoid duplicates
  local seen = {}

  -- Recursive function to traverse the syntax tree
  local function visit(node)
    local node_type = node:type()

    -- Pattern 1: function declarations (function name() / local function name())
    if node_type == "function_declaration" then
      local name_nodes = node:field("name")
      if name_nodes and #name_nodes > 0 then
        local name = ts.get_node_text(name_nodes[1], bufnr)
        if name and not seen[name] then
          seen[name] = true
          local row, col = name_nodes[1]:range()
          table.insert(matches, {
            name = name,
            line = row + 1,
            col = col,
            file = nil,
            context = nil,
          })
        end
      end
    end

    -- Pattern 2: assignments with function_definition
    if node_type == "assignment_statement" then
      local var_list = node:field("left")
      local expr_list = node:field("right")

      if var_list and expr_list and #var_list > 0 and #expr_list > 0 then
        local var_node = var_list[1]
        local expr_node = expr_list[1]

        -- Check if right side is a function_definition
        if expr_node:type() == "function_definition" then
          local name = nil
          local row, col = 0, 0

          -- Extract name based on left side type
          if var_node:type() == "identifier" then
            -- Simple: func = function()
            name = ts.get_node_text(var_node, bufnr)
            row, col = var_node:range()

          elseif var_node:type() == "dot_index_expression" then
            -- Dot notation: M.func = function()
            local field_nodes = var_node:field("field")
            if field_nodes and #field_nodes > 0 then
              name = ts.get_node_text(field_nodes[1], bufnr)
              row, col = field_nodes[1]:range()
            end
          end

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
        end
      end
    end

    -- Pattern 3: table fields with function values
    if node_type == "field" then
      local name_nodes = node:field("name")
      local value_nodes = node:field("value")

      if name_nodes and value_nodes and #name_nodes > 0 and #value_nodes > 0 then
        if value_nodes[1]:type() == "function_definition" then
          local name = ts.get_node_text(name_nodes[1], bufnr)
          if name and not seen[name] then
            seen[name] = true
            local row, col = name_nodes[1]:range()
            table.insert(matches, {
              name = name,
              line = row + 1,
              col = col,
              file = nil,
              context = nil,
            })
          end
        end
      end
    end

    -- Recursively visit children
    for child in node:iter_children() do
      visit(child)
    end
  end

  -- Start traversal
  visit(root)

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
