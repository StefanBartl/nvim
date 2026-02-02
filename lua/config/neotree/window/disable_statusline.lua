---@module 'config.neotree.window.disable_statusline'
---@brief Disables the statusline for neo-tree windows only

local M = {}

---Disable statusline in neo-tree windows
---@return nil
function M.disable_for_neotree_buffers()
  -- Find all neo-tree windows in current tabpage
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
        -- Window-local statusline override
        vim.wo[win].statusline = " "
      end
    end
  end
end

return M
