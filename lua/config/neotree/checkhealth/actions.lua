---@module 'config.neotree.checkhealth.actions'
---@brief Action module health checks

local M = {}

function M.check()
  vim.health.start("Action Modules")

  -- traverse, project_root, grep_picker, path.to_require and info.node were
  -- removed: filetree.nvim owns tree_traverse / project_root / grep_in_dir /
  -- lua_require_copy / node_info now (see plugins/personal/init.lua's
  -- filetree.nvim setup). pdfport is the only remaining config-owned action,
  -- bound via config.neotree.usercmds.
  local actions = {
    { name = "config.neotree.actions.pdfport", desc = "PDF port opener", required = false },
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
end

return M
