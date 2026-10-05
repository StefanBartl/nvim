---@module 'bindings.usrcmds.plugin_repos.sync_status'
---@brief The statusline hint of `:MyPlugins sync`: how many repos are still unresolved.
---@description
--- `sync:2` while the last sync left two repos unresolved (a skipped one does not count, the
--- user decided about it), nothing when everything is clear or no sync ever ran.
---
--- A statusline redraws on nearly every keystroke, so `render()` only reads a number. The
--- number comes from the saved result (`sync_state`): read once, shortly after the first render,
--- and again whenever a sync, a re-check or a skip saved a new result (`sync.lua` calls
--- `refresh()`). The text is not sent through the `plugin_progress` channel on purpose: that
--- one shows what is running, this one what is left over.
---
--- Wiring (host statusline): add `"sync_issues"` to the `order` and
--- `sync_issues = function() return require("bindings.usrcmds.plugin_repos.sync_status").render() end`
--- to the `modules` (see `lua/config/ui_statusline/variant.lua`).

local state = require("bindings.usrcmds.plugin_repos.sync_state")
local classify = require("bindings.usrcmds.plugin_repos.sync_classify")

local M = {}

---State file the delayed first read uses (nil: the real one). The specs point it elsewhere.
---@type string|nil
M.state_path = nil

---nil = not read yet.
---@type integer|nil
local count = nil
local scheduled = false

---Unresolved problems (not skipped) of the saved result, as the statusline shows them.
---@param records MyPlugins.SyncRecord[]
---@return integer
function M.unresolved(records)
  local n = 0
  for _, r in ipairs(records) do
    if classify.is_problem(r.state) and not r.skipped then
      n = n + 1
    end
  end
  return n
end

---Read the saved result again.
---@param path? string  State file (specs).
function M.refresh(path)
  local data = state.load({ path = path })
  local n = data and M.unresolved(data.records) or 0
  local changed = n ~= count
  count = n
  if changed then
    pcall(vim.cmd, "redrawstatus")
  end
end

---@return integer
function M.count()
  return count or 0
end

---Forget what was read (specs).
function M.reset()
  count, scheduled = nil, false
end

---The statusline text: empty, or ` sync:N `.
---@return string
function M.render()
  if count == nil then
    if not scheduled then
      scheduled = true
      vim.schedule(function()
        M.refresh(M.state_path)
      end)
    end
    return ""
  end
  if count == 0 then
    return ""
  end
  return (" %%#DiagnosticWarn#sync:%d "):format(count)
end

return M
