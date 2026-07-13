---@module 'config.telescope.history.keymaps'
--- Provides key mappings for Telescope history navigation.
--- History itself is owned by pickers.nvim (see config.telescope @brief); these
--- keymaps work with any conforming history.handler, not just a specific backend.

local M = {}

---Return mappings for insert and normal mode.
---@param actions table The actions table from telescope
---@return table
function M.get(actions)
  return {
    i = {
      ["<C-p>"] = actions.cycle_history_prev,
      ["<C-n>"] = actions.cycle_history_next,
      ["<PageUp>"] = actions.preview_scrolling_up,
      ["<PageDown>"] = actions.preview_scrolling_down,
    },
    n = {
      ["<PageUp>"] = actions.preview_scrolling_up,
      ["<PageDown>"] = actions.preview_scrolling_down,
    },
  }
end

return M
