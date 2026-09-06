---@module 'config.neotree.usercmds'
--- `:NeoTreeCheckHealth` -- runs `config.neotree.checkhealth` as a real
--- command instead of only through `:checkhealth`.

local usercmd = require("lib.nvim.bindings.usercmd")

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

  -- (pdfport usercmds removed: filetree.nvim's preview feature dispatches PDFs
  -- via <Tab>/<CR> in the tree using the same pdfport backend.)
end

return M
