---@module 'config.neotree.usercmds'

local M = {}

---@return nil
function M.enable()
  local api = vim.api

  api.nvim_create_user_command("NeoTreeCheckHealth", function()
    require("config.neotree.checkhealth").check()
  end, {
    desc = "Run Neo-tree config health checks",
  })

  api.nvim_create_user_command("NeoTreeDebugSources", function()
    require("config.neotree.sources.switcher").debug_sources()
  end, { desc = "[Neo-tree] Debug source detection" })

  -- (pdfport-Usercmds entfernt: filetree.nvim's preview-Feature dispatcht PDFs
  -- via <Tab>/<CR> im Baum mit demselben pdfport-Backend.)
end

return M
