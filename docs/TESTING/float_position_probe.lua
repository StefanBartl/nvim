-- docs/TESTING/float_position_probe.lua — does a float's REPORTED position
-- match where it is actually drawn?
--
-- **Open your file tree first**, then:
--   :luafile docs/TESTING/float_position_probe.lua
--
-- Opens a bordered float exactly like the hover does (`relative = "cursor"`)
-- and draws a test card into it through the same path the hover uses
-- (`images.anchor.draw`). Two possible outcomes, and they mean opposite
-- things:
--
--   * card sits INSIDE the frame  -> the reported position is correct and
--     images.nvim's whole chain is fine. The offset seen in real hovers must
--     then come from something else about those floats (size, timing,
--     a second float), not from position arithmetic.
--
--   * card sits BESIDE the frame  -> `nvim_win_get_position` is reporting a
--     position the float is not actually drawn at, with a file tree open.
--     That is the bug, and it is upstream of everything measured so far.
--
-- Why this and not the column probe: that one compared a marker placed at a
-- BUFFER column against a card drawn at a SCREEN column, which differ by the
-- file tree's width — so it could never have answered this question. Here
-- both the frame and the card come from the same reported number, so they
-- either agree or they do not.
--
-- Press q to clear.

local ok_term, term = pcall(require, "images.terminal")
local ok_anchor, anchor = pcall(require, "images.anchor")
local ok_card, testcard = pcall(require, "images.testcard")
if not (ok_term and ok_anchor and ok_card) then
  vim.notify("[float_position_probe] images.nvim not fully loaded — open an image buffer first", vim.log.levels.ERROR)
  return
end

local COLS, ROWS = 40, 12
local card, err = testcard.write(COLS, ROWS, require("images.scale").CELL_ASPECT)
if not card then
  vim.notify("[float_position_probe] could not build test card: " .. tostring(err), vim.log.levels.ERROR)
  return
end

local start_win = vim.api.nvim_get_current_win()
local start_pos = vim.api.nvim_win_get_position(start_win)
local cursor = vim.api.nvim_win_get_cursor(start_win)

local buf = vim.api.nvim_create_buf(false, true)
local fwin = vim.api.nvim_open_win(buf, false, {
  relative = "cursor",
  row = 1,
  col = 0,
  width = COLS,
  height = ROWS,
  style = "minimal",
  border = "rounded",
  focusable = false,
  noautocmd = true,
})

local fpos = vim.api.nvim_win_get_position(fwin)

-- Same call the hover makes, so nothing here is a special case.
anchor.draw(fwin, "full", card, { defer = true })

local function cleanup()
  pcall(term.clear)
  if vim.api.nvim_win_is_valid(fwin) then pcall(vim.api.nvim_win_close, fwin, true) end
  pcall(os.remove, card)
end

vim.keymap.set("n", "q", cleanup, { buffer = vim.api.nvim_win_get_buf(start_win), nowait = true })

vim.defer_fn(function()
  local report = {
    "── float_position_probe ────────────────────",
    ("screen              : columns=%d lines=%d"):format(vim.o.columns, vim.o.lines),
    ("current window at   : row=%d col=%d  (0 col = no split/tree to its left)")
      :format(start_pos[1], start_pos[2]),
    ("cursor in window    : line=%d col=%d"):format(cursor[1], cursor[2]),
    ("float REPORTED at   : row=%d col=%d  content=%dx%d"):format(fpos[1], fpos[2], COLS, ROWS),
    "",
    "LOOK AT THE SCREEN:",
    "  card INSIDE the frame  -> reported position is correct",
    "  card BESIDE the frame  -> the float is not where it says it is",
    "",
    "Press q to clear.",
  }
  vim.notify(table.concat(report, "\n"), vim.log.levels.INFO)
end, 600)
