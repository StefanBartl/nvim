-- docs/TESTING/column_scale_probe.lua — is the placement error constant or
-- proportional to the column?
--
--   :luafile docs/TESTING/column_scale_probe.lua
--
-- Draws the SAME test card at four columns, each on its own row, with a text
-- marker on the line above showing where that card's left edge belongs.
-- Then look at the screen:
--
--   * every card displaced by the SAME amount  -> constant offset.
--     `display.terminal_padding` can compensate it. Calibrate and done.
--   * displacement GROWS from top to bottom    -> proportional error.
--     terminal_padding CANNOT fix it: it adds a fixed number of cells, and
--     what is needed is a scale correction.
--
-- Press `q` in the probe buffer to clear the images and close it.
--
-- Two things this has to get right, both learned the hard way:
--   * `wrap` off — a full-width marker line otherwise wraps and the marker
--     column no longer means anything.
--   * the draw must happen a tick LATER than filling the buffer. Neovim
--     repaints everything that turned dirty since the last return to its
--     main loop, so drawing in the same tick puts the image out and then
--     paints the buffer's cells straight over it. Same reason
--     `images.anchor` has a `defer` option.

local ok_term, term = pcall(require, "images.terminal")
if not ok_term then
  vim.notify("[column_scale_probe] images.nvim not loaded — open an image buffer first", vim.log.levels.ERROR)
  return
end

local ok_card, testcard = pcall(require, "images.testcard")
if not ok_card then
  vim.notify("[column_scale_probe] images.testcard unavailable", vim.log.levels.ERROR)
  return
end

local COLS, ROWS = 12, 6
local card, err = testcard.write(COLS, ROWS, require("images.scale").CELL_ASPECT)
if not card then
  vim.notify("[column_scale_probe] could not build test card: " .. tostring(err), vim.log.levels.ERROR)
  return
end

-- Columns spread across the screen; the last still leaves room for the card.
local targets = {}
for _, frac in ipairs({ 0.05, 0.3, 0.55, 0.8 }) do
  local c = math.floor(vim.o.columns * frac)
  targets[#targets + 1] = math.max(1, math.min(c, vim.o.columns - COLS - 2))
end

local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buf)

-- One line per screen row, each exactly as wide as the screen. `wrap` is
-- turned off below, so a marker at column N really sits at column N.
local lines = {}
for i = 1, vim.o.lines do
  lines[i] = string.rep(" ", vim.o.columns)
end

---Overwrite `line` with `text` starting at 1-based cell `col`.
---@param line string
---@param col integer
---@param text string
---@return string
local function place(line, col, text)
  local head = line:sub(1, col - 1)
  if #head < col - 1 then head = head .. string.rep(" ", col - 1 - #head) end
  return head .. text .. line:sub(col + #text)
end

for i, col in ipairs(targets) do
  local marker_row = 2 + (i - 1) * (ROWS + 2)
  lines[marker_row] = place(lines[marker_row], col, ("|<- col %d, card starts here"):format(col))
end

vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
vim.bo[buf].modifiable = false
vim.bo[buf].bufhidden = "wipe"

local win = vim.api.nvim_get_current_win()
vim.wo[win].wrap = false -- critical: see header
vim.wo[win].number = false
vim.wo[win].relativenumber = false
vim.wo[win].signcolumn = "no"
vim.wo[win].foldcolumn = "0"
vim.wo[win].list = false
vim.api.nvim_win_set_cursor(win, { 1, 0 })

local function cleanup()
  pcall(term.clear)
  pcall(os.remove, card)
end

vim.keymap.set("n", "q", function()
  cleanup()
  pcall(vim.api.nvim_buf_delete, buf, { force = true })
end, { buffer = buf, nowait = true, desc = "column_scale_probe: clear and close" })

-- Draw a tick later, once Neovim has painted the buffer we just filled.
vim.schedule(function()
  if not vim.api.nvim_buf_is_valid(buf) then return end

  local report = { "── column_scale_probe ──────────────────────" }
  report[#report + 1] = ("screen: columns=%d lines=%d  card=%dx%d cells")
    :format(vim.o.columns, vim.o.lines, COLS, ROWS)

  for i, col in ipairs(targets) do
    local marker_row = 2 + (i - 1) * (ROWS + 2)
    -- images.terminal.draw takes 1-based screen cells. The card goes on the
    -- row directly below its marker, starting at the marker's own column.
    local ok = term.draw(card, marker_row + 1, col, COLS, ROWS)
    report[#report + 1] = ("  #%d sent row=%-3d col=%-4d  (marker on row %d)  ok=%s")
      :format(i, marker_row + 1, col, marker_row, tostring(ok))
  end

  report[#report + 1] = ""
  report[#report + 1] = "Each card's LEFT EDGE should line up with the '|' above it."
  report[#report + 1] = "Same error on all four -> CONSTANT.  Growing downwards -> PROPORTIONAL."
  report[#report + 1] = "Press q to clear."

  -- Deferred again: a notification is a window too, and one opening in the
  -- same tick as the draw would paint over the cards it is describing.
  vim.defer_fn(function()
    vim.notify(table.concat(report, "\n"), vim.log.levels.INFO)
  end, 400)
end)
