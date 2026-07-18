---@module 'config.neotree.keymaps'
--- Centralized, buffer-local Neo-tree keymaps that override defaults consistently.

local lazy = require("lib.lua.lazy")
-- Utility to safely hide the preview window without errors
local safe_hide_preview = require("config.neotree.utils").safe_hide_preview
local source_command = lazy.require("config.neotree.commands.source")

---@return table<string, any>
return {

  -- Default delete is disabled here; filesystem source overrides this with a custom trash handler
  ["d"] = "noop",

  --====================== Window Control =============================

  ["q"] = "close_window",
  ["?"] = "show_help",
  ["g?"] = "noop",

  --====================== Clear filter / preview / highlights ========

  ["<Esc>"] = {
    function(state)
      -- Reset filesystem search and active filters
      require("neo-tree.sources.filesystem").reset_search(state, true)
      require("neo-tree.sources.filesystem.lib.filter_external").cancel()

      -- Hide preview window if it is currently open
      safe_hide_preview()

      -- Clear any active search highlighting in the editor
      vim.cmd("nohlsearch")

      -- Watcher-quarantine exit is filetree.nvim's tree_reset feature's job now
      -- (buffer-local on the same <Esc>, see filetree/features/ui/tree_reset).
    end,
    desc = "Clear search, filters, preview, and highlights",
  },

  --====================== Source Switching ===========================

  ['"'] = function(_)
    source_command.next_source()
  end,
  ["!"] = function(_)
    source_command.prev_source()
  end,
  ["<"] = "noop",

  --====================== Window Management ==========================

  ["R"] = "refresh",
  ["C"] = "close_node",
  ["z"] = "close_all_nodes",
  ["W"] = "open_with_window_picker",

  --====================== Resize Helper ==============================

  ["w"] = {
    function(state)
      local win = vim.api.nvim_get_current_win()
      if not vim.api.nvim_win_is_valid(win) then
        return
      end

      -- Use buffer variable to track resize state
      local buf = vim.api.nvim_win_get_buf(win)
      local resize_state = vim.b[buf].neotree_resize_state or "normal"

      local base_width = (state and state.window and state.window.width) or 30
      local widths = {
        normal = base_width,
        large = math.floor(base_width * 1.9),
        small = math.floor(base_width / 1.6),
      }

      -- State transition
      local next_state = {
        normal = "large",
        large = "small",
        small = "normal",
      }

      local new_state = next_state[resize_state]
      local new_width = widths[new_state]

      vim.api.nvim_win_set_width(win, new_width)
      vim.b[buf].neotree_resize_state = new_state
    end,
    desc = "Resize the neotree window",
  },

  --====================== Splits / Tabs ==============================

  -- These are intentionally disabled here and enabled per-source
  ["s"] = "noop",
  ["t"] = "noop",
}
