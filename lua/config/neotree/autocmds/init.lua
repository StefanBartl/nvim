---@module 'config.neotree.autocmds'

local neotree_statusline = require("config.neotree.window.disable_statusline")

local M = {}

---Setup autocmd for automatic statusline hiding
---@return nil
local function setup_disable_stl()
  local group = vim.api.nvim_create_augroup("NeoTreeStatuslineDisable", { clear = true })

  -- Disable on FileType event (most reliable)
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "neo-tree",
    callback = function()
      vim.wo.statusline = " "
    end,
  })

  -- Additional safety: disable on BufWinEnter
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(args)
      if vim.bo[args.buf].filetype == "neo-tree" then
        vim.wo.statusline = " "
      end
    end,
  })

  -- Fallback: periodic check for existing windows
  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = neotree_statusline.disable_for_neotree_buffers,
  })
end

function M.attach()
  setup_disable_stl() -- disable statusline in neotree windows
end

return M
