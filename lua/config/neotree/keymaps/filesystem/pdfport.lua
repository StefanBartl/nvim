---@module 'config.neotree.keymaps.filesystem.pdfport'
---@brief pdfport-Keymaps für den Neo-tree Filesystem-Source.
---@description
--- Dieses Modul wird in config/neotree/keymaps/filesystem/init.lua
--- als weiteres Modul eingebunden.
---
--- Keymaps:
---   <Tab>  → wenn auf PDF: pdfport quick open (buffer, pdftotext)
---            wenn auf Nicht-PDF: normales Neo-tree toggle_preview
---   <CR>   → wenn auf PDF: pdfport quick open
---            wenn auf Nicht-PDF: normales Neo-tree open
---   gP     → pdfport Modus-Picker (immer, unabhängig vom Typ)
---
--- Damit überschreiben wir NUR die PDF-spezifischen Fälle; für alle anderen
--- Nodes bleibt das Standardverhalten exakt erhalten.

local notify     = require("lib.notify").create("[cfg.neotree.keymaps.fs.pdfport]")
local node_utils = require("config.neotree.utils.node")
local pdfport_action = require("config.neotree.actions.pdfport")

-- Hilfsfunktion: gibt true zurück, wenn der aktuelle Node eine PDF ist.
---@param state Cfg.NeoTree.State
---@return boolean
local function current_node_is_pdf(state)
  local node = node_utils.get_current(state)
  if not node then return false end
  local path, _ = node_utils.get_path(node)
  return type(path) == "string" and path:lower():match("%.pdf$") ~= nil
end

---@type table<string, any>
return {

  -- <Tab>: PDF → pdfport quick; Nicht-PDF → toggle_preview (Original)
  ["<Tab>"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      if current_node_is_pdf(state) then
        pdfport_action.open_quick(state)
        return
      end

      -- Original-Verhalten: toggle_preview
      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype ~= "neo-tree" then return end

      if not pcall(state.commands.toggle_preview, state) then
        local ok, preview = pcall(require, "neo-tree.sources.common.preview")
        if ok and preview.hide then preview.hide() end
      end
    end,
    desc = "PDF: pdfport quick open (pdftotext) | Andere: Preview toggle",
  },

  -- <CR>: PDF → pdfport quick; Nicht-PDF → normales open / expand
  ["<CR>"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      if current_node_is_pdf(state) then
        pdfport_action.open_quick(state)
        return
      end

      -- Original-Verhalten aus filesystem/files.lua
      local node = node_utils.get_current(state)
      if not node then
        notify.info("Kein Node unter dem Cursor")
        return
      end

      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype ~= "neo-tree" then
        notify.warn("Nicht in einem Neo-tree Fenster")
        return
      end

      -- Safe hide preview (optionally, wie im Original)
      local utils_ok, utils = pcall(require, "config.neotree.utils")
      if utils_ok and utils.safe_hide_preview then
        utils.safe_hide_preview()
      end

      if node.type == "directory" or (node.has_children and not node.is_expanded) then
        state.commands.toggle_node(state)
        return
      end

      if pcall(require, "window-picker") then
        if not pcall(state.commands.open_with_window_picker, state) then
          pcall(state.commands.open, state)
        end
      else
        pcall(state.commands.open, state)
      end
    end,
    desc = "PDF: pdfport quick open (pdftotext) | Andere: expand / open",
  },

  -- pdf: Immer pdfport Modus-Picker (nur bei PDF sinnvoll, aber kein Fehler bei anderen)
  -- ["PDF"] = {
    -- ---@param state Cfg.NeoTree.State
    -- function(state)
      -- pdfport_action.open(state)
    -- end,
    -- desc = "pdfport: Modus-Picker für PDF-Node öffnen",
  -- },
}
