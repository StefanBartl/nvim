---@module 'custom.mygrep'
---@class LiveGrepMemory
---@brief Entry point for grep tools with persistent memory integration.
---@description
--- This module serves as the central registry and entry point for executing memory-enabled
--- grep tools. It supports dynamic tool registration, encapsulates tool state management,
--- and delegates UI interactions to reusable picker logic. Users can invoke specific tools
--- via `.open(tool_name, opts)` or predefine mappings for rapid access.

---@field open fun(tool: string, opts?: table): boolean|nil Opens the named grep tool with optional Telescope options

local M = {}

-- Tool registry
local registry = require("custom.mygrep.core.registry")

-- Tool implementations
local live_grep = require("custom.mygrep.tools.live_grep")
local multigrep = require("custom.mygrep.tools.multigrep")

-- Register default tools at module load time
local function register_builtins()
  registry.register("live_grep", live_grep.run)
  registry.register("multigrep", multigrep.run)
end

--- Opens a grep tool by its registered name.
---@param tool string Tool name (must have been registered via .register)
---@param opts table|nil Optional Telescope options to pass
---@return boolean|nil success Whether the tool was found and launched
function M.open(tool, opts)
  assert(type(tool) == "string" and tool ~= "", "tool must be a valid string")
  return registry.run(tool, opts)
end

-- Register built-in tools now
local ok = pcall(register_builtins)
if not ok then
  vim.notify("[mygrep] Failed to register built-in tools", vim.log.levels.ERROR)
end

return M