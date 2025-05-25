---@module 'custom.mygrep.tools.multigrep'
---@class MultiGrepTool
---@brief Provides a glob-aware grep interface integrated with memory system.
---@description
--- This tool allows dual-input grep queries using ripgrep and glob patterns.
--- It uses Telescope's `new_async_job` interface to construct a dynamic search
--- command and integrates with the shared memory picker, including persistent
--- history, favorites, and undo.
---
---@field run fun(opts: table|nil): nil Launches the multigrep memory picker

local M = {}

-- Dependencies
local picker = require("custom.mygrep.core.picker")
local history = require("custom.mygrep.core.history")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")

--- Generates a ripgrep command from prompt input.
---@param prompt string The raw prompt input (expected: <pattern>  <glob>)
---@return string[]|nil The constructed ripgrep arguments
local function build_command(prompt)
  if type(prompt) ~= "string" or prompt == "" then
    return nil
  end

  local pieces = vim.split(prompt, "  ")
  local pattern = pieces[1]
  local glob = pieces[2]

  if not pattern or pattern == "" then
    return nil
  end

  local args = { "rg", "-e", pattern }

  if glob and glob ~= "" then
    table.insert(args, "-g")
    table.insert(args, glob)
  end

  vim.list_extend(args, {
    "--color=never",
    "--no-heading",
    "--with-filename",
    "--line-number",
    "--column",
    "--smart-case",
  })

  return args
end

--- Runs the multigrep tool via shared memory-enabled picker.
---@param opts table|nil
---@return nil
function M.run(opts)
  opts = opts or {}

  ---@type ToolState
  local state = history.load("multigrep")

  picker.open("multigrep", "Multi Grep (Memory)", function(input)
    local args = build_command(input)
    if not args then
      vim.notify("[multigrep] Invalid input, must be: <pattern>  <glob>", vim.log.levels.WARN)
      return
    end

    -- Add to history
    if not vim.tbl_contains(state.history, input) then
      table.insert(state.history, input)
    end

    history.save("multigrep", state)

    local ok = pcall(function()
      pickers.new(opts, {
        prompt_title = "Multi Grep",
        finder = finders.new_async_job {
          command_generator = function() return args end,
          entry_maker = make_entry.gen_from_vimgrep(opts),
          cwd = opts.cwd or vim.fn.getcwd(),
        },
        previewer = conf.grep_previewer(opts),
        sorter = sorters.empty(),
      }):find()
    end)

    if not ok then
      vim.notify("[multigrep] Failed to launch custom async picker", vim.log.levels.ERROR)
    end
  end, state)
end

return M