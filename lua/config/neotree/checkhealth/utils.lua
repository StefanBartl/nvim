---@module 'config.neotree.checkhealth.utils'
---@brief Utility module health checks

local M = {}

function M.check()
  vim.health.start("Utility Modules")

  -- General utils
  local ok_utils = pcall(require, "config.neotree.utils")
  if ok_utils then
    vim.health.ok("General utilities loaded")
  else
    vim.health.error("General utilities not loadable")
  end

  -- Node utils
  local ok_node = pcall(require, "config.neotree.utils.node")
  if ok_node then
    vim.health.ok("Node utilities loaded")
  else
    vim.health.error("Node utilities not loadable")
  end

  -- utils.buffer / utils.tree / utils.platform were removed: only ever used
  -- by dead actions/* modules (save/*, copy/entries|folders) already gone
  -- or checkhealth-probed only, no live caller left.
end

return M
