---@module 'config.neotree.event_handlers'
---@brief Neo-tree unified event handlers configuration

local notify = require("lib.notify").create("[cfg.neotree.event_handlers]")

local M = {}

local api = vim.api
local nvim_win_is_valid = api.nvim_win_is_valid

---@type table[] Cfg.NeoTree.EventHandler[]
M.handlers = {
  -- Cursor unsichtbar machen, wenn Neo-tree-Fenster betreten wird
  {
    event = "neo_tree_buffer_enter",
    handler = function()
      -- Effekt: der Cursor ist im Neo-tree-Fenster unsichtbar, obwohl das Fenster fokussiert ist
      vim.cmd("highlight! Cursor blend=100")
    end,
  },

  -- Cursor wieder sichtbar machen, wenn Neo-tree-Fenster verlassen wird
  {
    event = "neo_tree_buffer_leave",
    handler = function()
      vim.cmd("highlight! Cursor guibg=#5f87af blend=0")
    end,
  },

  -- Vor dem Öffnen merken, aus welchem Fenster Neo-tree aufgerufen wurde
  {
    event = "neo_tree_window_before_open",
    ---@diagnostic disable-next-line: unused-local
    handler = function(args)
      if not M._prev_win then
        M._prev_win = api.nvim_get_current_win()
      end
    end,
  },

  -- Nach dem Öffnen Fokus zurück auf vorheriges Fenster setzen (außer bei Float)
  {
    event = "neo_tree_window_after_open",
    handler = function(args)
      local function is_float(winid)
        if not nvim_win_is_valid(winid) then
          return false
        end
        local cfg = api.nvim_win_get_config(winid)
        return cfg.relative ~= "" and cfg.relative ~= nil
      end

      if not args.winid or not nvim_win_is_valid(args.winid) then
        return
      end
      if is_float(args.winid) then
        return
      end
      if M._prev_win and nvim_win_is_valid(M._prev_win) then
        vim.schedule(function()
          local ok = pcall(api.nvim_set_current_win, M._prev_win)
          if not ok then
            notify.debug("set_current_win failed")
          end
        end)
      end
    end,
  },
}

-- Speichert das vorherige Fenster für Fokus-Management
M._prev_win = nil

return M.handlers
