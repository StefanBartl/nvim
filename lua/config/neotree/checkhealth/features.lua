---@module 'config.neotree.checkhealth.features'
---@brief Optional feature health checks

local M = {}

function M.check()
  vim.health.start("Optional Features")

  -- Trash/undo, current_hl, and watcher_quarantine were removed: filetree.nvim's
  -- `trash`, `current_hl`, and `watcher_quarantine` features own all three now
  -- (see keymaps/filesystem/init.lua's header comment and plugins/personal/
  -- init.lua's filetree.nvim setup). Their health is checked via `:checkhealth
  -- filetree` instead.
  vim.health.info(
    "Trash / current_hl / watcher_quarantine: owned by filetree.nvim, see :checkhealth filetree"
  )
end

return M
