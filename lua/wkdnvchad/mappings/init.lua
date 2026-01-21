---@module 'wkdnvchad.mappings'

local lazy = require("lib.lazy")
local move_buf_tab = lazy.require("custom.functions.buf_win_tabs.move_buffer_to_tab").move_current_buffer_to_new_tab
local custom_tabufline = lazy.require("wkdnvchad.mappings.tabufline")
local map = lazy.require("lib.map")

local M = {}

local function get_count()
  return vim.v.count1
end

-- ---------------------------------------------------------------------------
--  Buffers
-- ---------------------------------------------------------------------------
---@return nil
local function attach_buffers()
  -- <Tab> -> next buffer, supports count (e.g. 3<Tab> moves 3 buffers forward)
  map("n", "<Tab>", function()
    local cnt = get_count()
    custom_tabufline.move_next_n(cnt)
  end, { desc = "[Buffers] Next" })

  -- <S-Tab> -> previous buffer, supports count (e.g. 2<S-Tab> moves 2 buffers back)
  map("n", "<S-Tab>", function()
    local cnt = get_count()
    custom_tabufline.move_prev_n(cnt)
  end, { desc = "[Buffers] Prev" })

  -- map("n", "<leader>bc", function()
  --   require("nvchad.tabufline").close_buffer()
  -- end, { desc = "[Buffers] Close" })

  -- <leader>bc -> close buffers: close `count` buffers starting from current
  -- Example: 2<leader>bc closes current and next buffer (if present).
  map("n", "<leader>bc", function()
    local cnt = get_count()
    custom_tabufline.close_n_buffers(cnt)
  end, { desc = "[Buffers] Close" })
end

-- ---------------------------------------------------------------------------
-- Tabs
-- ---------------------------------------------------------------------------
---@return nil
local function attach_tabs()
  map("n", "<leader>tr", function()
    require("nvchad.tabufline").move_buf(1)
  end, { desc = "[Tabs] Move tab right" })
  map("n", "<leader>tl", function()
    require("nvchad.tabufline").move_buf(-1)
  end, { desc = "[Tabs] Move tab left" })
  map("n", "<leader>tt", move_buf_tab, { desc = "[Tabs] Move current buffer to new tab" })
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------
---@param opts WkdNvC.Mappings.Modules
---@return nil
function M.setup(opts)
  opts = opts or {}

  if opts.all or opts.buffers then
    attach_buffers()
  end

  if opts.all or opts.tabs then
    attach_tabs()
  end
end

return M

