local M = {}

M.show_command_history = function()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values

  local history = vim.fn.execute("history :") -- Returns the command history
  local lines = {}
  for line in history:gmatch("[^\r\n]+") do
    -- Remove leading numbers (e.g. " 1 :wq")
    local cleaned = line:match("^%s*%d+%s+(.*)$")
      if cleaned then
    table.insert(lines, 1, cleaned) -- insert at the beginning instead of at the end
  end
  end

  pickers.new({}, {
    prompt_title = "Command History",
    finder = finders.new_table {
      results = lines,
    },
    sorter = conf.generic_sorter({}),

    attach_mappings = function(_, map)
      actions.select_default:replace(function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection or not selection[1] then return end

        local cmd = selection[1]
        actions.close(prompt_bufnr)

        vim.schedule(function()
          -- Setzt den Befehl in die Eingabezeile, aber führt ihn nicht aus
          vim.fn.feedkeys(":" .. cmd, "n")
        end)
      end)
      return true
    end

  }):find()
end

return M