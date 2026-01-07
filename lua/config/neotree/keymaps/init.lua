---@module 'config.neotree.keymaps'
--- Centralized, buffer-local Neo-tree keymaps that override defaults consistently.

local safe_hide_preview = require("config.neotree.utils").safe_hide_preview
local watcher_quarantine = require("config.neotree.watcher_quarantine")

---@return table<string, any>
return {

  ["d"] = "noop", -- set in 'filesystem' to custom trash function

  --====================== Window Control =============================

  ["q"] = "close_window",
  ["?"] = "show_help",
  ["g?"] = "noop",

  --======= clear filter, preview and search highlight

  ["<Esc>"] = function(state)
    require("neo-tree.sources.filesystem").reset_search(state, true)
    require("neo-tree.sources.filesystem.lib.filter_external").cancel()
    safe_hide_preview(state)
    vim.cmd("nohlsearch")

    -- Exit quarantine if active
    if watcher_quarantine.is_quarantined() then
      watcher_quarantine.exit_quarantine()
    end
  end,

  --====================== Source Switching ===========================

  ['"'] = "next_source",
  ["!"] = "prev_source",
  ["<"] = "noop",

  --====================== Window Management ==========================

  ["R"] = "refresh",
  ["C"] = "close_node",
  ["z"] = "close_all_nodes",

  --======= resize helper

  ["w"] = {
    function(state)
      local normal = state.window.width
      local large = normal * 1.9
      local small = math.floor(normal / 1.6)
      local cur_width = state.win_width
      local new_width = normal
      if cur_width > normal then
        new_width = small
      elseif cur_width == normal then
        new_width = large
      end
      vim.cmd(new_width .. " wincmd |")
    end,
    desc = "Resize the neotree window",
  },

  --====================== Splits/Tabs (filesystem set this) ==========

  ["s"] = "noop",
  ["t"] = "noop",
}
