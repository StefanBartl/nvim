---@module 'mappings.buf_win_tab'

local M = {}

local move_buf_tab = require("custom.functions.buf_win_tabs.move_buffer_to_tab").move_current_buffer_to_new_tab
local terminal_lib = require("lib.terminals")
local is_terminal_buf, delete_terminal_buf = terminal_lib.is_terminal_buf, terminal_lib.delete_terminal_buf

--- Helper to get the effective count (defaults to 1)
--- @return integer
local function get_count()
  -- vim.v.count1 returns 1 when no count is supplied, otherwise the supplied count
  return vim.v.count1
end

--- Move to the next buffer `n` times.
--- @param n integer
local function move_next_n(n)
  -- require the project-specific tabufline next function
  local ok, tabufline = pcall(require, "custom.tabufline")
  if not ok or type(tabufline.next) ~= "function" then
    -- If the custom module is not available, try nvchad's tabufline as fallback
    local ok2, nv = pcall(require, "nvchad.tabufline")
    if ok2 and type(nv.next) == "function" then
      for _ = 1, n do
        pcall(nv.next)
      end
    end
    return
  end

  for _ = 1, n do
    pcall(tabufline.next)
  end
end

--- Move to the previous buffer `n` times.
--- @param n integer
local function move_prev_n(n)
  local ok, tabufline = pcall(require, "custom.tabufline")
  if not ok or type(tabufline.prev) ~= "function" then
    local ok2, nv = pcall(require, "nvchad.tabufline")
    if ok2 and type(nv.prev) == "function" then
      for _ = 1, n do
        pcall(nv.prev)
      end
    end
    return
  end

  for _ = 1, n do
    pcall(tabufline.prev)
  end
end

--- Close the current buffer, and repeat `count` times.
--- The semantics: calling the close function repeatedly will close the current buffer,
--- then the newly current buffer, etc. This yields closing N consecutive buffers
--- starting from the current one (if available).
--- @param n integer
local function close_n_buffers(n)
  -- prefer nvchad.tabufline.close_buffer if available (as in the user's sample)
  local ok, tabufline = pcall(require, "nvchad.tabufline")
  if not ok or type(tabufline.close_buffer) ~= "function" then
    -- fallback: try custom.close_buffer
    local ok2, custom = pcall(require, "custom.tabufline")
    if ok2 and type(custom.close) == "function" then
      for _ = 1, n do
        pcall(custom.close)
      end
    end
    return
  end

  for _ = 1, n do
    -- protect against errors and missing next buffer
    pcall(tabufline.close_buffer)
  end
end

function M.setup()
  local map = vim.g.__map_helper

  -- ---------------------------------------------------------------------------
  --  Buffers
  -- ---------------------------------------------------------------------------

  map("n", "<leader>bn", "<cmd>enew<CR>", { desc = "[Buffers] New" })
  -- map("n", "<tab>", function()
  --   require("custom.tabufline").next()
  -- end, { desc = "[Buffers] Next" })

  -- <Tab> -> next buffer, supports count (e.g. 3<Tab> moves 3 buffers forward)
  map("n", "<Tab>", function()
    local cnt = get_count()
    move_next_n(cnt)
  end, { desc = "[Buffers] Next" })

  -- map("n", "<s-tab>", function()
  --   require("custom.tabufline").prev()
  -- end, { desc = "[Buffers] Prev" })

  -- <S-Tab> -> previous buffer, supports count (e.g. 2<S-Tab> moves 2 buffers back)
  map("n", "<S-Tab>", function()
    local cnt = get_count()
    move_prev_n(cnt)
  end, { desc = "[Buffers] Prev" })

  -- map("n", "<leader>bc", function()
  --   require("nvchad.tabufline").close_buffer()
  -- end, { desc = "[Buffers] Close" })

  -- <leader>bc -> close buffers: close `count` buffers starting from current
  -- Example: 2<leader>bc closes current and next buffer (if present).
  map("n", "<leader>bc", function()
    local cnt = get_count()
    close_n_buffers(cnt)
  end, { desc = "[Buffers] Close" })

  map("n", "<leader>bx", function()
    local current = vim.api.nvim_get_current_buf()
    if is_terminal_buf(current) then
      delete_terminal_buf(current)
    else
      vim.api.nvim_buf_delete(current, { force = false })
    end
  end, { desc = "[Buffers] Close current, go to next" })

  -- ---------------------------------------------------------------------------
  -- Windows
  -- ---------------------------------------------------------------------------

  map("n", "<leader><Esc>", function()
    vim.cmd("qa!")
  end, { desc = "[Wimdows] Force quit all" })

  -- Window closing
  map({ "n", "v" }, "<leader>q", "<Cmd>close!<CR>", { desc = "[Windows] Close window" })
  map("i", "<leader>q", "<C-o><Cmd>close<CR>", { desc = "[Windows] Close window (insert)" })
  map("t", "<leader>q", "<C-\\><C-n><Cmd>close<CR>", { desc = "[Windows] Close window (terminal)" })

  -- Window movement
  map("n", "<C-h>", "<C-w>h", { desc = "[Window] Jump left" })
  map("n", "<C-l>", "<C-w>l", { desc = "[Window] Jump right" })
  map("n", "<C-j>", "<C-w>j", { desc = "[Window] Jump down" })
  map("n", "<C-k>", "<C-w>k", { desc = "[Window] Jump up" })

  local resize_guarded = require("lib.buf_win_tab.resize_guarded")
  local exclude_filetypes = { "terminal" }
  local exclude_names = { ".*lazygit.*" }

  -- WICHTIG: Der vierte Parameter (lhs) muss übergeben werden!
  vim.keymap.set(
    { "n", "t" },
    "<S-h>",
    resize_guarded.create("vertical resize -5", exclude_filetypes, exclude_names, "<S-h>"),
    { desc = "[Window] Resize narrower" }
  )

  vim.keymap.set(
    { "n", "t" },
    "<S-l>",
    resize_guarded.create("vertical resize +5", exclude_filetypes, exclude_names, "<S-l>"),
    { desc = "[Window] Resize wider" }
  )

  vim.keymap.set(
    { "n", "t" },
    "<S-k>",
    resize_guarded.create("resize +5", exclude_filetypes, exclude_names, "<S-k>"),
    { desc = "[Window] Resize taller" }
  )

  vim.keymap.set(
    { "n", "t" },
    "<S-j>",
    resize_guarded.create("resize -5", exclude_filetypes, exclude_names, "<S-j>"),
    { desc = "[Window] Resize shorter" }
  )

  map("n", "<leader>zm", function()
    require("utils.window_zoom").zoom_toggle()
  end, { desc = "[Window] Zoom toggle." })

  -- ---------------------------------------------------------------------------
  -- Tabs
  -- ---------------------------------------------------------------------------

  map("n", "<leader>tn", "<cmd>tabnext<CR>", { desc = "[Tabs] Next tab" })
  map("n", "<leader>tp", "<cmd>tabprevious<CR>", { desc = "[Tabs] Previous tab" })
  map("n", "<leader>tc", "<cmd>tabnew<CR>", { desc = "[Tabs] New tab" })
  map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "[Tabs] Close tab" })
  map("n", "<leader>tr", function()
    require("nvchad.tabufline").move_buf(1)
  end, { desc = "[Tabs] Move tab right" })
  map("n", "<leader>tl", function()
    require("nvchad.tabufline").move_buf(-1)
  end, { desc = "[Tabs] Move tab left" })
  map("n", "<leader>tt", move_buf_tab, { desc = "[Tabs] Move current buffer to new tab" })
end

return M
