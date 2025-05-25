---@module 'custom.mygrep.core.registry'
---@class ToolRegistry
---@brief Manages registration and invocation of grep tools.
---@description
--- This module acts as a central registry for all grep-compatible tools.
--- Each tool is identified by a unique name and is associated with a runner
--- function that can be called with Telescope options. Tools should be registered
--- during setup time, and can be invoked via `.run(name, opts)` at runtime.
---@field tools table<string, fun(opts: table|nil): nil> Stores tool-name to runner mappings
---@field register fun(name: string, runner: fun(opts: table|nil): nil): boolean Registers a new tool
---@field run fun(name: string, opts: table|nil): boolean|nil Runs a registered tool by name, returns success

local M = {}

--- Internal tool map
local tools = {}

--- Registers a new tool for usage via `.run()`
---@param name string Unique name of the tool (e.g., "live_grep", "multigrep")
---@param runner fun(opts: table|nil): nil The actual function to call when the tool is executed
---@return boolean success Whether the registration succeeded
function M.register(name, runner)
  assert(type(name) == "string", "Tool name must be a string")
  assert(type(runner) == "function", "Runner must be a function")

  if tools[name] then
    vim.notify(("Tool '%s' is already registered"):format(name), vim.log.levels.WARN)
    return false
  end

  tools[name] = runner
  return true
end

--- Invokes the tool associated with the given name
---@param name string The registered tool name
---@param opts table|nil Optional Telescope options
---@return boolean|nil success Whether the tool was found and run
function M.run(name, opts)
  if type(name) ~= "string" then
    vim.notify("[live_grep_memory] Tool name must be string", vim.log.levels.ERROR)
    return false
  end

  local runner = tools[name]
  if not runner then
    vim.notify(("[live_grep_memory] Unknown tool: %s"):format(name), vim.log.levels.ERROR)
    return false
  end

  local ok, err = pcall(runner, opts or {})
  if not ok then
    vim.notify(("[live_grep_memory] Error running tool '%s': %s"):format(name, err), vim.log.levels.ERROR)
    return false
  end

  return true
end

--- Returns all registered tool names (e.g. for dev/debug/testing)
---@return string[]
function M.list()
  local result = {}
  for name, _ in pairs(tools) do
    table.insert(result, name)
  end
  return result
end

return M