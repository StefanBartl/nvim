---@module 'custom.repo_pickers.select.telescope'
--- Adapter to select a repository via Telescope, if installed.

local fs = require("custom.repo_pickers.fs")

local M = {}

--- Try to open a Telescope picker. Returns false if Telescope is unavailable.
--- @param cfg RepoPickersConfig
--- @param repos RepoDir[]
--- @param on_choice fun(dir:RepoDir)
--- @return boolean handled
function M.select(cfg, repos, on_choice)
  local function sreq(name) local ok, mod = pcall(require, name); return ok and mod or nil end

  local pickers = sreq("telescope.pickers")
  local finders = sreq("telescope.finders")
  local conf = sreq("telescope.config")
  local actions = sreq("telescope.actions")
  local action_state = sreq("telescope.actions.state")

  if not (pickers and finders and conf and actions and action_state) then
    return false
  end

  ---@type string[]
  local labels = { [#repos] = "" }
  for i = 1, #repos do labels[i] = fs.label_of(cfg, repos[i]) end

  pickers.new({}, {
    prompt_title = "Repositories",
    finder = finders.new_table({ results = labels }),
    sorter = conf.values.generic_sorter({}),
    attach_mappings = function(_, _)
      actions.select_default:replace(function(bufnr)
        actions.close(bufnr)
        local selection = action_state.get_selected_entry()
        local idx = selection and selection.index
        if type(idx) == "number" and repos[idx] then
          on_choice(repos[idx])
        end
      end)
      return true
    end,
  }):find()

  return true
end

return M

