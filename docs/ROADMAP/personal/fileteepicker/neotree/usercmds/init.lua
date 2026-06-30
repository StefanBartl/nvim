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

  -- ── pdfport-Integration ──────────────────────────────────────────────────

  -- :NeoTreePdfPort  →  pdfport Modus-Picker für aktuellen Neo-tree Node
  api.nvim_create_user_command("NeoTreePdfPort", function()
    local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
    if not ok_mgr then
      vim.notify("[NeoTreePdfPort] neo-tree.sources.manager nicht verfügbar", vim.log.levels.ERROR)
      return
    end

    local state = manager.get_state("filesystem")
    if not state then
      vim.notify("[NeoTreePdfPort] Kein aktiver Neo-tree Filesystem-State", vim.log.levels.WARN)
      return
    end

    require("config.neotree.actions.pdfport").open(state)
  end, {
    desc = "pdfport: Modus-Picker für aktuellen Neo-tree Node (PDF)",
  })

  -- :NeoTreePdfPortQuick  →  pdfport direkt mit pdftotext für aktuellen Node
  api.nvim_create_user_command("NeoTreePdfPortQuick", function()
    local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
    if not ok_mgr then
      vim.notify("[NeoTreePdfPortQuick] neo-tree.sources.manager nicht verfügbar", vim.log.levels.ERROR)
      return
    end

    local state = manager.get_state("filesystem")
    if not state then
      vim.notify("[NeoTreePdfPortQuick] Kein aktiver Neo-tree Filesystem-State", vim.log.levels.WARN)
      return
    end

    require("config.neotree.actions.pdfport").open_quick(state)
  end, {
    desc = "pdfport: PDF-Node direkt als Text öffnen (pdftotext, kein Picker)",
  })
end

return M
