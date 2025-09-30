---@module 'custom.repo_pickers.select.fzf'
--- Adapter to select a repository via fzf-lua, if installed.

local fs = require("custom.repo_pickers.fs")

local M = {}

--- Try to open an fzf-lua list. Returns false if fzf-lua is unavailable.
--- @param cfg RepoPickersConfig
--- @param repos RepoDir[]
--- @param on_choice fun(dir:RepoDir)
--- @return boolean handled
function M.select(cfg, repos, on_choice)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok or not fzf then
    return false
  end

  ---@type string[]
  local labels = { [#repos] = "" }
  for i = 1, #repos do labels[i] = fs.label_of(cfg, repos[i]) end

  fzf.fzf_exec(labels, {
    prompt = "Repos> ",
    actions = {
      ["default"] = function(selected)
        local first = selected and selected[1]
        if not first then return end
        -- Resolve display -> index -> repo path
        for i = 1, #labels do
          if labels[i] == first then
            local dir = repos[i]
            if dir then on_choice(dir) end
            break
          end
        end
      end,
    },
    fzf_opts = { ["--no-multi"] = true },
  })

  return true
end

return M

