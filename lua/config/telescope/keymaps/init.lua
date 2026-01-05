---@module 'config.telescope.keymaps'
---Centralized Telescope keymaps (preview scrolling, window navigation, ergonomics)

local M = {}

---Return Telescope mappings table
---@param actions table telescope.actions
---@return table
function M.get(actions)
  return {
    i = {
      -- Horizontal preview scrolling (builtin actions)
      ["<M-Right>"] = actions.preview_scrolling_right,
      ["<M-Left>"] = actions.preview_scrolling_left,
    },
    n = {
      -- Same mappings for normal mode
      ["<M-Right>"] = actions.preview_scrolling_right,
      ["<M-Left>"] = actions.preview_scrolling_left,
    },
  }
end

return M
