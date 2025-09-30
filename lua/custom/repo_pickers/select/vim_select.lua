---@module 'custom.repo_pickers.select.vim_select'
--- Adapter to select a repository via vim.ui.select.

local fs = require("custom.repo_pickers.fs")

local M = {}

--- Present items via vim.ui.select and return chosen directory to callback.
--- @param cfg RepoPickersConfig
--- @param repos RepoDir[]
--- @param on_choice fun(dir:RepoDir)
--- @return nil
function M.select(cfg, repos, on_choice)
  ---@type string[]
  local items = { [#repos] = "" } -- preallocate for performance (array part sized)
  for i = 1, #repos do
    items[i] = fs.label_of(cfg, repos[i])
  end

  vim.ui.select(items, { prompt = "Select repository" }, function(_, idx)
    if type(idx) == "number" and repos[idx] then
      on_choice(repos[idx])
    end
  end)
end

return M

