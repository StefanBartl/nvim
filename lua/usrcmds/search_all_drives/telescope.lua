---@module 'usrcmds.search_all_drives.telescope'
--- Telescope command wrapper for usrcmds.search_all_drives.
--- Exposes the returned tabs as selectable Telescope entries.

local search_all_drives = require("usrcmds.search_all_drives")

---@param opts table|nil
local function open(opts)
  opts = opts or {}

  local builtin = require("telescope.builtin")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local tabs = search_all_drives.build_tabs(builtin)

  pickers.new(opts, {
    prompt_title = "Search all drives",
    finder = finders.new_table({
      results = tabs,
      entry_maker = function(tab)
        return {
          value = tab,
          display = tab.name,
          ordinal = tab.name,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry and entry.value and entry.value.tele_func then
          entry.value.tele_func()
        end
      end)
      return true
    end,
  }):find()
end

return {
  open = open,
}

