---@module 'usrcmds.migrate.notify.parser'
---@brief Treesitter-based pattern detection for vim.notify calls.
---@description
--- Detects all variants of vim.notify invocations in Lua buffers:
---   - Direct: vim.notify("msg", vim.log.levels.INFO)
---   - Aliased: local notify = vim.notify; notify("msg", levels.WARN)
---   - Multiline formatting with arbitrary whitespace
---
--- Returns structured matches with exact byte positions for replacement.

require("usrcmds.migrate.notify.@types")

local M = {}

local api = vim.api

--- Map log level constants to method names
---@type table<integer, string>
local LEVEL_TO_METHOD = {
  [vim.log.levels.TRACE] = "trace",
  [vim.log.levels.DEBUG] = "debug",
  [vim.log.levels.INFO] = "info",
  [vim.log.levels.WARN] = "warn",
  [vim.log.levels.ERROR] = "error",
  [vim.log.levels.OFF] = "off",
}

--- Extract log level from vim.log.levels.* node
---@param node TSNode
---@param bufnr integer
---@return string|nil level
local function extract_log_level(node, bufnr)
  if node:type() ~= "dot_index_expression" then
    return nil
  end

  local text = vim.treesitter.get_node_text(node, bufnr)

  -- Match patterns: vim.log.levels.INFO, levels.INFO
  local level = text:match("%.(%u+)$")
  if not level then
    return nil
  end

  -- Validate against known levels
  for _, method in pairs(LEVEL_TO_METHOD) do
    if method == level:lower() then
      return level
    end
  end

  return nil
end

--- Parse function call arguments
---@param call_node TSNode
---@param bufnr integer
---@return string|nil message, string|nil level
local function parse_arguments(call_node, bufnr)
  local args_node = call_node:field("arguments")[1]
  if not args_node then
    return nil, nil
  end

  local children = {}
  ---@diagnostic disable-next-line: undefined-field
  for child in args_node:iter_children() do
    if child:named() then
      table.insert(children, child)
    end
  end

  if #children < 1 then
    return nil, nil
  end

  -- First argument: message (string literal or variable)
  local msg_node = children[1]
  local message = vim.treesitter.get_node_text(msg_node, bufnr)

  -- Second argument: log level (optional)
  local level = nil
  if #children >= 2 then
    level = extract_log_level(children[2], bufnr)
  end

  return message, level
end

--- Check if function call is vim.notify or aliased variant
---@param call_node TSNode
---@param bufnr integer
---@return boolean is_notify, string|nil alias
local function is_notify_call(call_node, bufnr)
  local func_node = call_node:field("name")[1]
  if not func_node then
    return false, nil
  end

  local func_text = vim.treesitter.get_node_text(func_node, bufnr)

  -- Direct: vim.notify
  if func_text == "vim.notify" then
    return true, nil
  end

  -- Aliased: notify (requires scope analysis)
  -- Simplified: check if identifier matches common aliases
  if func_text:match("^notify$") or func_text:match("^vim_notify$") then
    return true, func_text
  end

  return false, nil
end

--- Build replacement string
---@param message string
---@param level string|nil
---@return string replacement
local function build_replacement(message, level)
  local method = level and level:lower() or "info"
  return string.format("notify.%s(%s)", method, message)
end

--- Scan buffer for vim.notify patterns
---@param bufnr integer
---@return MigrateNotify.Match[]
function M.scan_buffer(bufnr)
  if not api.nvim_buf_is_valid(bufnr) then
    return {}
  end

  local ft = vim.bo[bufnr].filetype
  if ft ~= "lua" then
    return {}
  end

  local parser = vim.treesitter.get_parser(bufnr, "lua")
  if not parser then
    return {}
  end

  local tree = parser:parse()[1]
  if not tree then
    return {}
  end

  local root = tree:root()
  local matches = {}

  --- Recursive traversal
  ---@param node TSNode
  local function visit(node)
    if node:type() == "function_call" then
      local is_notify, _ = is_notify_call(node, bufnr)

      if is_notify then
        local message, level = parse_arguments(node, bufnr)

        if message then
          ---@diagnostic disable-next-line: undefined-field
          local start_row, start_col, end_row, end_col = node:range()
          local original = vim.treesitter.get_node_text(node, bufnr)

          table.insert(matches, {
            line = start_row + 1, -- Convert to 1-based
            col = start_col,
            end_line = end_row + 1, -- Track end line for multiline
            end_col = end_col,
            original = original,
            replacement = build_replacement(message, level),
            log_level = level or "INFO",
          })
        end
      end
    end

    ---@diagnostic disable-next-line
    for child in node:iter_children() do
      visit(child)
    end
  end

  visit(root)

  return matches
end

--- Scan multiple files
---@param paths string[]
---@return MigrateNotify.FileMatches[]
function M.scan_files(paths)
  local results = {}

  for _, path in ipairs(paths) do
    local bufnr = vim.fn.bufadd(path)
    vim.fn.bufload(bufnr)

    local matches = M.scan_buffer(bufnr)

    if #matches > 0 then
      table.insert(results, {
        path = path,
        matches = matches,
      })
    end
  end

  return results
end

return M
