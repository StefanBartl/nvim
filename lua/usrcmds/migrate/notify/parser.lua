---@module 'usrcmds.migrate.notify.parser'
---@brief Robust detection for vim.notify calls
---@description
--- Strict matching rules:
---   - ONLY match: vim.notify(..., vim.log.levels.LEVEL)
---   - SKIP: notify.level(...) - already migrated
---   - SKIP: any other notify variants

require("usrcmds.migrate.notify.@types")

local M = {}

local api = vim.api
local ts = vim.treesitter

---@type table<string, string>
local LEVEL_MAP = {
  TRACE = "trace",
  DEBUG = "debug",
  INFO  = "info",
  WARN  = "warn",
  ERROR = "error",
}

--------------------------------------------------------------------------------
-- Strict detection
--------------------------------------------------------------------------------

---Check if this is vim.notify (STRICT: not notify.level or other variants)
---@param node TSNode
---@param bufnr integer
---@return boolean
local function is_vim_notify(node, bufnr)
  local name = node:field("name")[1]
  if not name then
    return false
  end

  local text = ts.get_node_text(name, bufnr)

  -- STRICT: Only accept exactly "vim.notify"
  -- Reject:
  --   - "notify.info", "notify.warn", etc (already migrated)
  --   - "notify" alone
  --   - any other variant
  if text ~= "vim.notify" then
    return false
  end

  return true
end

---Extract vim.log.levels.<LEVEL>
---@param node TSNode
---@param bufnr integer
---@return string|nil
local function extract_level(node, bufnr)
  if node:type() ~= "dot_index_expression" then
    return nil
  end

  local text = ts.get_node_text(node, bufnr)

  -- STRICT: Must be exactly vim.log.levels.LEVEL
  local level = text:match("^vim%.log%.levels%.([A-Z]+)$")

  if level and LEVEL_MAP[level] then
    return level
  end

  return nil
end

---Parse arguments: message, level, optional opts
---@param call TSNode
---@param bufnr integer
---@return string|nil, string|nil, string|nil
local function parse_args(call, bufnr)
  local args = call:field("arguments")[1]
  if not args then
    return nil, nil, nil
  end

  local named = {}
  for child in args:iter_children() do
    if child:named() then
      table.insert(named, child)
    end
  end

  -- Need at least message + level
  if #named < 2 then
    return nil, nil, nil
  end

  local msg = ts.get_node_text(named[1], bufnr)
  local level = extract_level(named[2], bufnr)

  if not level then
    return nil, nil, nil
  end

  -- Optional third argument (opts table)
  local opts = nil
  if #named >= 3 then
    opts = ts.get_node_text(named[3], bufnr)
  end

  return msg, level, opts
end

---Build replacement string
---@param msg string
---@param level string
---@param opts string|nil
---@return string
local function build_replacement(msg, level, opts)
  local method = LEVEL_MAP[level]

  if opts then
    return string.format("notify.%s(%s, %s)", method, msg, opts)
  end

  return string.format("notify.%s(%s)", method, msg)
end

--------------------------------------------------------------------------------
-- Scanner
--------------------------------------------------------------------------------

---@param bufnr integer
---@return MigrateNotify.Match[]
function M.scan_buffer(bufnr)
  if not api.nvim_buf_is_valid(bufnr) then
    return {}
  end

  if vim.bo[bufnr].filetype ~= "lua" then
    return {}
  end

  local parser = ts.get_parser(bufnr, "lua")
  if not parser then
    return {}
  end

  local tree = parser:parse()[1]
  if not tree then
    return {}
  end

  local root = tree:root()
  local matches = {}

  local function visit(node)
    if node:type() == "function_call" then
      if is_vim_notify(node, bufnr) then
        local msg, level, opts = parse_args(node, bufnr)

        if msg and level then
          local sr, sc, er, ec = node:range()

          table.insert(matches, {
            line = sr + 1,        -- 1-based
            col = sc,             -- 0-based (start)
            end_line = er + 1,    -- 1-based
            end_col = ec,         -- 0-based (exclusive end from TS)
            original = ts.get_node_text(node, bufnr),
            replacement = build_replacement(msg, level, opts),
            log_level = level,
          })
        end
      end
    end

    for child in node:iter_children() do
      visit(child)
    end
  end

  visit(root)
  return matches
end

return M
