---@module 'bindings.mappings.buf_win_tab'
--- Buffer, window and tab keymaps: `<leader>b*` for buffers (new, close-and-go-
--- next), `<leader>q`/`<leader>Q` for quitting, and `<C-h/j/k/l>` for window
--- navigation.

local M = {}

local lib = require("lib")
local is_terminal_buf, delete_terminal_buf = lib.is_terminal_buf, lib.delete_terminal_buf

---@return nil
function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  -- ---------------------------------------------------------------------------
  --  Buffers
  -- ---------------------------------------------------------------------------
  map("n", "<leader>bn", "<cmd>enew<CR>", { desc = "[Buffers] New" })
  -- map("n", "<tab>", function()
  --   require("config.tabufline").next()
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
  end, { desc = "[Windows] Force quit all" })

  -- Window closing
  map({ "n", "v" }, "<leader>q", "<Cmd>close!<CR>", { desc = "[Windows] Close window" })
  map("i", "<leader>q", "<C-o><Cmd>close<CR>", { desc = "[Windows] Close window (insert)" })
  map("t", "<leader>q", "<C-\\><C-n><Cmd>close<CR>", { desc = "[Windows] Close window (terminal)" })

  -- Window movement
  map("n", "<C-h>", "<C-w>h", { desc = "[Window] Jump left" })
  map("n", "<C-l>", "<C-w>l", { desc = "[Window] Jump right" })
  map("n", "<C-j>", "<C-w>j", { desc = "[Window] Jump down" })
  map("n", "<C-k>", "<C-w>k", { desc = "[Window] Jump up" })

  local resize_guarded = require("lib.nvim.buf_win_tab.resize_guarded")
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

  -- One press moves 5 columns/rows; a count scales that step rather than
  -- repeating the keypress, so `3<S-l>` widens by 15 in one go instead of
  -- three separate resizes (which redraw three times and, at a boundary,
  -- stop somewhere different).
  --
  -- Built per keypress via the function form of `resize_guarded.create`:
  -- `vim.v.count1` is only meaningful while the key is being handled, so it
  -- cannot be baked into a fixed command string at mapping time.
  local RESIZE_STEP = 5

  ---@param prefix string  e.g. "vertical resize" or "resize"
  ---@param sign string    "+" or "-"
  ---@return fun(): string
  local function resize_cmd(prefix, sign)
    return function()
      return ("%s %s%d"):format(prefix, sign, vim.v.count1 * RESIZE_STEP)
    end
  end

  map(
    { "n", "t" },
    "<S-h>",
    resize_guarded.create(
      resize_cmd("vertical resize", "-"),
      exclude_filetypes,
      exclude_names,
      "<S-h>"
    ),
    { desc = "[Window] Resize narrower" }
  )

  map(
    { "n", "t" },
    "<S-l>",
    resize_guarded.create(
      resize_cmd("vertical resize", "+"),
      exclude_filetypes,
      exclude_names,
      "<S-l>"
    ),
    { desc = "[Window] Resize wider" }
  )

  map(
    { "n", "t" },
    "<S-k>",
    resize_guarded.create(resize_cmd("resize", "+"), exclude_filetypes, exclude_names, "<S-k>"),
    { desc = "[Window] Resize taller" }
  )

  map(
    { "n", "t" },
    "<S-j>",
    resize_guarded.create(resize_cmd("resize", "-"), exclude_filetypes, exclude_names, "<S-j>"),
    { desc = "[Window] Resize shorter" }
  )

  map("n", "<leader>zm", function()
    require("bindings.mappings.utils.window_zoom").zoom_toggle()
  end, { desc = "[Window] Zoom toggle." })

  -- ---------------------------------------------------------------------------
  -- Tabs
  -- ---------------------------------------------------------------------------
  -- A count moves that many tabs, wrapping -- `3<leader>tn` is three forward.
  --
  -- The offset is computed here instead of being handed to the Ex-command,
  -- because every count form of `:tabnext` is *absolute*: `:tabnext 2` and
  -- `:2tabnext` both jump to tab page 2 (like `2gt`), and `:tabnext +2` is
  -- E475 in Neovim. Only bare `:tabnext` moves relatively. `:tabprevious
  -- {count}` does take a relative count, but spelling one direction as a
  -- native count and the other as arithmetic would make a symmetric pair of
  -- keys read as if they worked differently.
  ---@param offset integer Tab pages to move; negative moves left. Wraps.
  local function tab_step(offset)
    local total = vim.fn.tabpagenr("$")
    -- Lua's `%` is non-negative for a positive divisor, so this wraps in both
    -- directions without a separate case for going left past the first tab.
    vim.cmd("tabnext " .. ((vim.fn.tabpagenr() - 1 + offset) % total + 1))
  end

  map("n", "<leader>tn", function()
    tab_step(vim.v.count1)
  end, { desc = "[Tabs] Next tab" })
  map("n", "<leader>tp", function()
    tab_step(-vim.v.count1)
  end, { desc = "[Tabs] Previous tab" })
  map("n", "<leader>tc", "<cmd>tabnew<CR>", { desc = "[Tabs] New tab" })
  map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "[Tabs] Close tab" })
end

return M
