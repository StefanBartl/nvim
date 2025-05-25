---@module 'custom.mygrep.tools.live_grep'
---@class LiveGrepTool
---@brief Wraps Telescope’s builtin live_grep with memory support.
---@description
--- This tool is the default implementation using Telescope’s builtin `live_grep`.
--- It integrates seamlessly with memory tracking, including persistent history,
--- favorites, and undo stack. This module acts as an entry point for registering
--- the live_grep tool into the memory system.
---
---@field run fun(opts: table|nil): nil Executes the live_grep picker wrapped with memory features

local M = {}

-- Dependencies
local builtin = require("telescope.builtin")
local picker = require("custom.mygrep.core.picker")
local history = require("custom.mygrep.core.history")

--- Runs the live_grep picker with memory-enabled wrapper.
---@param opts table|nil Optional Telescope options
---@return nil
function M.run(opts)
  opts = opts or {}

  ---@type ToolState
  local state = history.load("live_grep")

  picker.open("live_grep", "Live Grep (Memory)", function(input)
    if type(input) ~= "string" or input == "" then
      vim.notify("[live_grep] Invalid input, aborting", vim.log.levels.WARN)
      return
    end

    -- Save query to history
    if not vim.tbl_contains(state.history, input) then
      table.insert(state.history, input)
    end

    history.save("live_grep", state)

    local ok = pcall(function()
      builtin.live_grep(vim.tbl_extend("force", opts, {
        default_text = input,
      }))
    end)

    if not ok then
      vim.notify("[live_grep] Failed to launch builtin.live_grep", vim.log.levels.ERROR)
    end
  end, state)
end

return M