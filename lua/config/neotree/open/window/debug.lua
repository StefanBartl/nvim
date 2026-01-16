---@module 'config.neotree.open.window.debug'

local M = {}

---Force-reset all neo-tree window state
---@return nil
function M.force_reset_state()
  local state = require("config.neotree.state.windows")
  local tree_state = require("config.neotree.state.tree")
  local controller = require("config.neotree.open.window.controller")

  -- Clear busy guard
  controller.clear_busy_guard()

  -- Reset window state
  state.set_closed("force_reset")

  -- Reset tree state
  tree_state.reset()

  -- Close all neo-tree buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end

  vim.notify("[neo-tree] State forcefully reset", vim.log.levels.INFO)
end

---Show current state for debugging
---@return nil
function M.show_debug_state()
  local state = require("config.neotree.state.windows")
  local tree_state = require("config.neotree.state.tree")

  local info = {
    window_state = {
      open = state.is_open(),
      position = state.get_position(),
    },
    tree_state = {
      node_id = tree_state.get_node(),
      expanded_count = vim.tbl_count(tree_state.get_expanded()),
    },
    neo_tree_buffers = {},
    neo_tree_windows = {},
  }

  -- Find neo-tree buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
      table.insert(info.neo_tree_buffers, buf)
    end
  end

  -- Find neo-tree windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
        table.insert(info.neo_tree_windows, win)
      end
    end
  end

  vim.print(info)
end

return M
