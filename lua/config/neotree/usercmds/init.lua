---@module 'config.neotree.usercmds'
--- `:NeoTreeCheckHealth` -- runs `config.neotree.checkhealth` as a real
--- command instead of only through `:checkhealth`.

local usercmd = require("lib.nvim.usercmd")

local M = {}

---@return nil
function M.enable()
  usercmd.create("NeoTreeCheckHealth", function()
    require("config.neotree.checkhealth").check()
  end, {
    desc = "Run Neo-tree config health checks",
  })

  usercmd.create("NeoTreeDebugSources", function()
    require("config.neotree.sources.switcher").debug_sources()
  end, { desc = "[Neo-tree] Debug source detection" })

  -- (pdfport-Usercmds entfernt: filetree.nvim's preview-Feature dispatcht PDFs
  -- via <Tab>/<CR> im Baum mit demselben pdfport-Backend.)
end

return M
