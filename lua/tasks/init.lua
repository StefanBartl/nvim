---@module 'tasks'
---@brief The wkdbook task engine: pure Lua, no UI, no notifications.
---@description
--- Open tasks live in the vault as one Markdown file each
--- (`<area>/ROADMAP/tasks/<slug>.md`); this namespace reads, ranks, indexes,
--- creates, changes, finishes and checks them. The editor commands
--- (`:MyPlugins tasks ...`) and the headless CLI (`scripts/tasks.lua`) are
--- front ends over these modules -- nothing here depends on either, so the
--- whole namespace can move into its own plugin unchanged.
---
--- Submodules are loaded on first access:
---  - `vault`  root, areas, paths, id/slug validation
---  - `model`  the task record, enums, ranking, filters
---  - `scan`   collect task files
---  - `index`  render and write `ROADMAP/TASKS.md`, the global export text
---  - `mutate` template, new, set, done
---  - `check`  the rule checker
---  - `staleness`  `--stale=refs`: tasks whose referenced files changed since `updated`
---  - `ci`     the vault gate for pipelines (check + index --check + md_lint)
---  - `cli`    the command-line front end
---
--- Not its job: prompts, pickers, notifications, key bindings.

local M = {}

local SUBMODULES = {
  vault = true,
  model = true,
  scan = true,
  index = true,
  mutate = true,
  check = true,
  staleness = true,
  ci = true,
  cli = true,
}

return setmetatable(M, {
  __index = function(t, key)
    if SUBMODULES[key] then
      local mod = require("tasks." .. key)
      rawset(t, key, mod)
      return mod
    end
    return nil
  end,
})
