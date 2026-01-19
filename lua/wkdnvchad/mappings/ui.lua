---@module 'wkdnvchad.mappings.ui'

local move_buf_tab = require("custom.functions.buf_win_tabs.move_buffer_to_tab").move_current_buffer_to_new_tab
local terminal_lib = require("lib.terminals")
local tabufline_helpers = require("wkdnvchad.mappings.helpers.tabufline")

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  -- ---------------------------------------------------------------------------
  --  Buffers
  -- ---------------------------------------------------------------------------

  map("n", "<leader>bn", "<cmd>enew<CR>", { desc = "[Buffers] New" })

  -- <Tab> -> next buffer, supports count (e.g. 3<Tab> moves 3 buffers forward)
  map("n", "<Tab>", function()
    tabufline_helpers.move_next_n(vim.v.count1)
  end, { desc = "[Buffers] Next" })

  -- <S-Tab> -> previous buffer, supports count (e.g. 2<S-Tab> moves 2 buffers back)
  map("n", "<S-Tab>", function()
    tabufline_helpers.move_prev_n(vim.v.count1)
  end, { desc = "[Buffers] Prev" })

  -- map("n", "<leader>bc", function()
  --   require("nvchad.tabufline").close_buffer()
  -- end, { desc = "[Buffers] Close" })

  -- <leader>bc -> close buffers: close `count` buffers starting from current
  -- Example: 2<leader>bc closes current and next buffer (if present).
  map("n", "<leader>bc", function()
    tabufline_helpers.close_n_buffers(vim.v.count1)
  end, { desc = "[Buff.ers] Close" })

  map("n", "<leader>bx", function()
    local current = vim.api.nvim_get_current_buf()
    if terminal_lib.is_terminal_buf(current) then
      tabufline_helpers.delete_terminal_buf(current)
    else
      vim.api.nvim_buf_delete(current, { force = false })
    end
  end, { desc = "[Buffers] Close current, go to next" })

  -- ---------------------------------------------------------------------------
  -- Tabs
  -- ---------------------------------------------------------------------------

  map("n", "<leader>tr", function()
    require("nvchad.tabufline").move_buf(1)
  end, { desc = "[Tabs] Move tab right" })
  map("n", "<leader>tl", function()
    require("nvchad.tabufline").move_buf(-1)
  end, { desc = "[Tabs] Move tab left" })
  map("n", "<leader>tt", move_buf_tab, { desc = "[Tabs] Move current buffer to new tab" })
end

return M

