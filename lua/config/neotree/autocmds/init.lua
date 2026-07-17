---@module 'config.neotree.autocmds'

local neotree_statusline = require("config.neotree.window.disable_statusline")
local Autocmd = require("lib.nvim.autocmd")

local M = {}

---Setup autocmd for automatic statusline hiding
---@return nil
local function setup_disable_stl()
  local group = vim.api.nvim_create_augroup("NeoTreeStatuslineDisable", { clear = true })

  -- Disable on FileType event (most reliable)
  Autocmd.create("FileType", function()
    vim.wo.statusline = " "
  end, {
    group = group,
    pattern = "neo-tree",
  })

  -- Additional safety: disable on BufWinEnter
  Autocmd.create("BufWinEnter", function(args)
    if vim.bo[args.buf].filetype == "neo-tree" then
      vim.wo.statusline = " "
    end
  end, {
    group = group,
  })

  -- Fallback: periodic check for existing windows
  Autocmd.create("WinEnter", neotree_statusline.disable_for_neotree_buffers, {
    group = group,
  })
end

function M.attach()
  setup_disable_stl() -- disable statusline in neotree windows
end

return M
