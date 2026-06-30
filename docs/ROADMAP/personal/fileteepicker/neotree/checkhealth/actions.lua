---@module 'config.neotree.checkhealth.actions'
---@brief Action module health checks

local M = {}

function M.check()
  vim.health.start("Action Modules")

  local actions = {
    { name = "config.neotree.actions.traverse", desc = "Bi-directional navigation", required = true },
    { name = "config.neotree.actions.project_root", desc = "Project root detection", required = true },
    { name = "config.neotree.actions.grep_picker", desc = "Grep picker", required = true },
    { name = "config.neotree.actions.copy.entries", desc = "Copy entries", required = false },
    { name = "config.neotree.actions.copy.folders", desc = "Copy folders", required = false },
    { name = "config.neotree.actions.path.to_require", desc = "Path to require()", required = false },
    { name = "config.neotree.actions.info.node", desc = "Node info", required = false },
  }

  for _, action in ipairs(actions) do
    local ok = pcall(require, action.name)
    if ok then
      vim.health.ok(action.desc .. " available")
    elseif action.required then
      vim.health.error(action.desc .. " not available: " .. action.name)
    else
      vim.health.warn(action.desc .. " not available (optional)")
    end
  end

  -- Grep picker specific checks
  local ok_picker, picker = pcall(require, "config.neotree.actions.grep_picker")
  if ok_picker and picker.health_check then
    local healthy, message = picker.health_check()
    if healthy then
      vim.health.ok(message or "Pickers available")
    else
      vim.health.error(message or "No pickers available")
    end

    local status = picker.get_picker_status()
    vim.health.info("Picker status:")
    vim.health.info("  telescope: " .. (status.telescope and "✓" or "✗"))
    vim.health.info("  fzf-lua: " .. (status.fzf and "✓" or "✗"))
  end
end

return M
