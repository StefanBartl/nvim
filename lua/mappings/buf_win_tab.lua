---@module 'mappings.buf_win_tab'

local M = {}

local terminal_lib = require("lib.terminals")
local is_terminal_buf, delete_terminal_buf = terminal_lib.is_terminal_buf, terminal_lib.delete_terminal_buf

---@return nil
function M.setup()
  local map = vim.g.__map_helper

  -- ---------------------------------------------------------------------------
  --  Buffers
  -- ---------------------------------------------------------------------------
  map("n", "<leader>bn", "<cmd>enew<CR>", { desc = "[Buffers] New" })
  -- map("n", "<tab>", function()
  --   require("custom.tabufline").next()
  -- end, { desc = "[Buffers] Next" })

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
  map("n", "<leader>Q", function()
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
  local exclude_filetypes = {
    "terminal",
    "TelescopePrompt",
    "TelescopeResults",
    "fzf",
    "neo-tree",
    "NvimTree",
    "oil",
    "Trouble",
    "qf", -- quickfix window
  }
  local exclude_names = { ".*lazygit.*" }

  map(
    { "n", "t" },
    "<S-h>",
    resize_guarded.create("vertical resize -5", exclude_filetypes, exclude_names, "<S-h>"),
    { desc = "[Window] Resize narrower" }
  )

  map(
    { "n", "t" },
    "<S-l>",
    resize_guarded.create("vertical resize +5", exclude_filetypes, exclude_names, "<S-l>"),
    { desc = "[Window] Resize wider" }
  )

  map(
    { "n", "t" },
    "<S-k>",
    resize_guarded.create("resize +5", exclude_filetypes, exclude_names, "<S-k>"),
    { desc = "[Window] Resize taller" }
  )

  map(
    { "n", "t" },
    "<S-j>",
    resize_guarded.create("resize -5", exclude_filetypes, exclude_names, "<S-j>"),
    { desc = "[Window] Resize shorter" }
  )

  map("n", "<leader>zm", function()
    require("mappings.utils.window_zoom").zoom_toggle()
  end, { desc = "[Window] Zoom toggle." })

  -- ---------------------------------------------------------------------------
  -- Tabs
  -- ---------------------------------------------------------------------------
  map("n", "<leader>tn", "<cmd>tabnext<CR>", { desc = "[Tabs] Next tab" })
  map("n", "<leader>tp", "<cmd>tabprevious<CR>", { desc = "[Tabs] Previous tab" })
  map("n", "<leader>tc", "<cmd>tabnew<CR>", { desc = "[Tabs] New tab" })
  map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "[Tabs] Close tab" })

end

return M
