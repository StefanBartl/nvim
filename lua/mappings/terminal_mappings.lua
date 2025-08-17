---@module 'mappings.terminal'

local M = {}

function M.setup()
  local map = vim.g.__map_helper
  map("t", "<Esc>", "<C-\\><C-n>", { desc = "[Terminals] Exit terminal mode" })
  map("t", "<C-c>", "<C-\\><C-n>", { desc = "[Terminals] Exit terminal mode" })

  --- Toggle NvChad UI terminal in a vertical split with ~1/3 screen width.
  --- Works from normal & terminal mode; robustly enforces width after opening.
  ---@type fun():nil
  local function toggle_vterm_one_third()
    -- Load NvChad term module defensively
    local ok, term = pcall(require, "nvchad.term")
    if not ok then return end

    -- Desired width in columns (1/3 of total), with a sane minimum
    local cols = math.max(20, math.floor(vim.o.columns / 3))

    -- Attempt to pass size via function args (supported per maintainer comment).
    -- If your local version ignores this, we still hard-set the width below.
    term.toggle({ pos = "vsp", id = "vtoggleTerm", size = cols })

    -- Defer to let the window appear, then force exact width as fallback
    vim.schedule(function()
      -- Only act if we’re actually on a terminal buffer now (toggle might have closed it)
      if vim.bo.buftype ~= "terminal" then return end
      local win = vim.api.nvim_get_current_win()
      pcall(vim.api.nvim_win_set_width, win, cols)
    end)
  end
  vim.keymap.set({ "n", "t" }, "<A-v>", toggle_vterm_one_third,
    { desc = "[Term] Toggle vertical (1/3 width)" })

  map({ "n", "t" }, "<A-h>",
    function()
      local ok, nt = pcall(require, "nvchad.term"); if ok then nt.toggle { pos = "sp", id = "htoggleTerm" } end
    end, { desc = "[Term] Toggle horizontal" })
  map({ "n", "t" }, "<A-i>",
    function()
      local ok, nt = pcall(require, "nvchad.term"); if ok then nt.toggle { pos = "float", id = "floatTerm" } end
    end, { desc = "[Term] Toggle floating" })
end

return M
