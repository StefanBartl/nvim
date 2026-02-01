---@module 'config.neotree.watcher_quarantine.health'

local event_patch = require("config.neotree.utils.event_patch")

local M = {}

---Health check
function M.check()
  local results = {}

  -- Check event patch
  table.insert(results, {
    name = "FS Watch Callback Patch",
    status = event_patch.is_patched() and "✓" or "✗",
  })

  -- Check watcher quarantine
  local wq = require("config.neotree.watcher_quarantine")
  local healthy, reason = wq.health_check()
  table.insert(results, {
    name = "Watcher Quarantine",
    status = healthy and "✓" or "✗",
    reason = reason,
  })

  -- Print results
  local lines = { "=== Watcher Quarantine ===" }
  for _, r in ipairs(results) do
    local line = string.format("%s %s", r.status, r.name)
    if r.reason then
      line = line .. " (" .. r.reason .. ")"
    end
    table.insert(lines, line)
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

return M
