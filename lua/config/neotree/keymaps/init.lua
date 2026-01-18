---@module 'config.neotree.keymaps'
--- Centralized, buffer-local Neo-tree keymaps that override defaults consistently.

-- Utility to safely hide the preview window without errors
local safe_hide_preview = require("config.neotree.utils").safe_hide_preview

-- Watcher quarantine helper to temporarily suppress filesystem events
local watcher_quarantine = require("config.neotree.watcher_quarantine")

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

      -- Exit watcher quarantine mode if it is currently active
      if watcher_quarantine.is_quarantined() then
        watcher_quarantine.exit_quarantine()
      end
    end,
    desc = "Clear search, filters, preview, highlights, and exit watcher quarantine",
  },

  --====================== Source Switching ===========================

  ['"'] = "next_source",
  ["!"] = "prev_source",
  ["<"] = "noop",

  --====================== Window Management ==========================

  ["R"] = "refresh",
  ["C"] = "close_node",
  ["z"] = "close_all_nodes",
  ["W"] = "open_with_window_picker",

  --====================== Resize Helper ==============================

  ["w"] = {
    function(state)
      -- Base width of the Neo-tree window
      local normal = state.window.width

      -- Precomputed target widths
      local large = normal * 1.9
      local small = math.floor(normal / 1.6)

      -- Current window width
      local cur_width = state.win_width
      local new_width = normal

      -- Cycle between normal -> large -> small
      if cur_width > normal then
        new_width = small
      elseif cur_width == normal then
        new_width = large
      end

      -- Apply new width
      vim.cmd(new_width .. " wincmd |")
    end,
    desc = "Resize the neotree window",
  },

  --====================== Splits / Tabs ==============================

  -- These are intentionally disabled here and enabled per-source
  ["s"] = "noop",
  ["t"] = "noop",
}
