---@module 'custom.mygrep'
---@class LiveGrepMemory
---@brief Entry point for grep tools with persistent memory integration.
---@description
--- Entry point that registers built-in tools and initializes keymaps.
--- Users should load this module once in their plugin config.
---
---@field open fun(tool: string, opts?: table): boolean|nil Opens the named grep tool with optional Telescope options

-- Tool registry
local registry = require("custom.mygrep.core.registry")

-- Built-in tool implementations
local live_grep = require("custom.mygrep.tools.live_grep")
local multigrep = require("custom.mygrep.tools.multigrep")

local M = {}

--- Opens a grep tool by its registered name.
---@param tool string Tool name (must have been registered via .register)
---@param opts table|nil Optional Telescope options to pass
---@return boolean|nil success
function M.open(tool, opts)
  assert(type(tool) == "string" and tool ~= "", "tool must be a valid string")
  return registry.run(tool, opts)
end

--- Registers built-in tools and sets up default keymaps.
---@return nil
local function initialize()
  local ok = pcall(function()
    registry.register("live_grep", live_grep.run)
    registry.register("multigrep", multigrep.run)
  end)
  if not ok then
    vim.notify("[mygrep] Failed to register built-in tools", vim.log.levels.ERROR)
  end

  pcall(function()
    local km = require("custom.mygrep.keymaps")
    if type(km.setup) == "function" then
      km.setup(M.open)
    end
  end)

  pcall(function()
    local cmd = require("custom.mygrep.usercommands")
    if type(cmd.setup) == "function" then
      cmd.setup(M.open)
    end
  end)
end

initialize()
return M
