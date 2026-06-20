---@module 'mappings.editing'

local helpers = require("mappings.utils.line_renumbering.helpers")

local M = {}

-- ── Indent width per filetype ─────────────────────────────────
-- Add or change entries as needed. Unlisted filetypes get DEFAULT_INDENT.
local INDENT_BY_FT = {
  lua = 2,
  markdown = 2,
  javascript = 2,
  typescript = 2,
  css = 2,
  html = 2,
  python = 4,
  java = 4,
  go = 4,
  rust = 4,
  c = 4,
  cpp = 4,
}
local DEFAULT_INDENT = 2

vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    local w = INDENT_BY_FT[vim.bo.filetype] or DEFAULT_INDENT
    vim.bo.shiftwidth = w
    vim.bo.tabstop = w
    vim.bo.softtabstop = w
    vim.bo.expandtab = true
  end,
})

function M.setup()
  local map = vim.g.__map_helper

  -- Branch-aware redo/undo that survives auto-changes by plugins
  map("n", "<C-r>", "g+", { desc = "Redo (branch-aware)" })

  -- Insert blank lines
  map("n", "<leader><CR>", "o<Esc>k", { desc = "Insert blank line below" })
  map("n", "<CR>", "0i<CR><Esc>k", { desc = "Insert blank line" })

  -- Visual mode paste without overwriting the yank register
  map("x", "p", '"_dP', {
    noremap = true,
    silent = true,
    desc = "Paste over selection without yanking it",
  })

  -- Insert clipboard (+) literally, without triggering auto-indent doubling.
  -- NOTE: some terminals cannot encode <C-A-S-p>; if it never fires, the
  -- terminal/GUI is swallowing the chord, not this mapping.
  map("i", "<C-A-S-p>", "<C-r><C-o>+", {
    noremap = true,
    silent = true,
    desc = "Aus System-Zwischenablage im Insert-Modus einfügen",
  })

  -- ── Move lines ───────────────────────────────────────────────

  map("n", "<A-Up>", function()
    vim.cmd("m .-2")
    vim.cmd("normal! ==")
    helpers.maybe_renumber()
  end, { desc = "[Text] Move line up", noremap = true, silent = true })

  map("n", "<A-Down>", function()
    vim.cmd("m .+1")
    vim.cmd("normal! ==")
    helpers.maybe_renumber()
  end, { desc = "[Text] Move line down", noremap = true, silent = true })

  map(
    "i",
    "<A-Up>",
    "<C-o>:m .-2<CR><C-o>==",
    { desc = "[Text] Move line up", noremap = true, silent = true }
  )
  map(
    "i",
    "<A-Down>",
    "<C-o>:m .+1<CR><C-o>==",
    { desc = "[Text] Move line down", noremap = true, silent = true }
  )

  map(
    "v",
    "<A-Up>",
    ":m '<-2<CR>gv=gv",
    { desc = "[Text] Move selection up", noremap = true, silent = true }
  )
  map(
    "v",
    "<A-Down>",
    ":m '>+1<CR>gv=gv",
    { desc = "[Text] Move selection down", noremap = true, silent = true }
  )

  -- ── Indent / Outdent ─────────────────────────────────────────

  map("n", "<A-Right>", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local count = vim.v.count1
    for _ = 1, count do
      helpers.shift_line(bufnr, lnum, 1)
    end
    helpers.maybe_renumber()
  end, { desc = "[Text] Indent current line", noremap = true, silent = true })

  map("n", "<A-Left>", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local count = vim.v.count1
    for _ = 1, count do
      helpers.shift_line(bufnr, lnum, -1)
    end
    helpers.maybe_renumber()
  end, { desc = "[Text] Outdent current line", noremap = true, silent = true })

  map(
    "i",
    "<A-Right>",
    "<C-t>",
    { desc = "[Text] Indent line (insert)", noremap = true, silent = true }
  )
  map(
    "i",
    "<A-Left>",
    "<C-d>",
    { desc = "[Text] Outdent line (insert)", noremap = true, silent = true }
  )

  -- Reliable, repeatable visual (out)dent.
  -- The old version reselected with `gv`, which reuses the '<,'> columns. After
  -- a charwise selection is outdented the line gets shorter, those columns are
  -- clamped, and the cursor flips between the two ends on every press. We work
  -- purely on the line range and reselect LINEWISE so column clamping can no
  -- longer move the selection — indent is a whole-line operation anyway.
  local function visual_shift(direction)
    local count = vim.v.count1
    local s = vim.fn.line("'<")
    local e = vim.fn.line("'>")
    if s > e then
      s, e = e, s
    end
    for _ = 1, count do
      helpers.shift_range(s, e, direction)
    end
    helpers.maybe_renumber()
    -- Re-establish a clean linewise selection over the same lines.
    vim.api.nvim_win_set_cursor(0, { s, 0 })
    vim.cmd("normal! V")
    if e > s then
      vim.api.nvim_win_set_cursor(0, { e, 0 })
    end
  end

  map("v", "<A-Right>", function()
    visual_shift(1)
  end, { desc = "[Text] Indent selection", noremap = true, silent = true })

  map("v", "<A-Left>", function()
    visual_shift(-1)
  end, { desc = "[Text] Outdent selection", noremap = true, silent = true })

  -- AUDIT: löschen?

  -- -- Move selected lines (unchanged as requested)
  -- map("n", "<A-Up>", ":m .-2<CR>==", { desc = "[Text] Move line up", noremap = true, silent = true })
  -- map("n", "<A-Down>", ":m .+1<CR>==", { desc = "[Text] Move line down", noremap = true, silent = true })
  -- map("i", "<A-Up>", "<C-o>:m .-2<CR><C-o>==", { desc = "[Text] Move line up", noremap = true, silent = true })
  -- map("i", "<A-Down>", "<C-o>:m .+1<CR><C-o>==", { desc = "[Text] Move line down", noremap = true, silent = true })
  -- map("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "[Text] Move selection up", noremap = true, silent = true })
  -- map("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "[Text] Move selection down", noremap = true, silent = true })

  -- -- Indent / Outdent
  -- map("n", "<A-Right>", function()
  -- return string.rep(">>", vim.v.count1)
  -- end, { desc = "[Text] Indent current line", noremap = true, silent = true, expr = true })
  -- map("n", "<A-Left>", function()
  -- return string.rep("<<", vim.v.count1)
  -- end, { desc = "[Text] Outdent current line", noremap = true, silent = true, expr = true })
  -- map("i", "<A-Right>", "<C-t>", { desc = "[Text] Indent line (insert)", noremap = true, silent = true })
  -- map("i", "<A-Left>", "<C-d>", { desc = "[Text] Outdent line (insert)", noremap = true, silent = true })
  -- map("v", "<A-Right>", ">gv", { desc = "[Text] Indent selection", noremap = true, silent = true })
  -- map("v", "<A-Left>", "<gv", { desc = "[Text] Outdent selection", noremap = true, silent = true })
end

return M
