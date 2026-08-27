---@module 'config.neotest.telescope'
--- Telescope picker for Neotest actions.

local actions = require("config.neotest.actions")

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions_telescope = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

---@type Cfg.Neotest.Action[]
local ACTIONS = {
  { name = "Run nearest test", desc = "Execute test under cursor", fn = actions.run_nearest },
  { name = "Run file tests", desc = "Execute all tests in file", fn = actions.run_file },
  { name = "Run all tests", desc = "Execute full test suite", fn = actions.run_all },
  { name = "Debug nearest test", desc = "Debug test using DAP", fn = actions.debug_nearest },
  { name = "Toggle summary", desc = "Open or close summary", fn = actions.toggle_summary },
  { name = "Show output", desc = "Open test output", fn = actions.open_output },
  { name = "Toggle output panel", desc = "Toggle output panel", fn = actions.toggle_output_panel },
  { name = "Stop tests", desc = "Stop running tests", fn = actions.stop },
  { name = "Toggle watch mode", desc = "Toggle watch mode", fn = actions.toggle_watch },
}

function M.open()
  pickers
    .new({}, {
      prompt_title = "Neotest Actions",
      finder = finders.new_table({
        results = ACTIONS,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name,
            ordinal = entry.name,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(_, map)
        map("i", "<CR>", function(bufnr)
          local selection = action_state.get_selected_entry()
          actions_telescope.close(bufnr)
          if selection and selection.value and selection.value.fn then
            selection.value.fn()
          end
        end)
        return true
      end,
    })
    :find()
end

return M
