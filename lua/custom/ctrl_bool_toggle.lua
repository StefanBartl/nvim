---@module 'custom.ctrl_bool_toggle'
--- Toggle booleans (true/false) with <C-a>/<C-x> in Normal mode.
--- If no boolean is under the cursor, fall back to native number
--- increment/decrement behavior. Case is preserved (true/false, True/False, TRUE/FALSE).

---@class _BoolHit
---@field s integer  -- start byte index (0-based, inclusive)
---@field e integer  -- end byte index (0-based, exclusive)
---@field txt string -- matched text

local M = {}

--- Find a boolean token that covers the cursor on the current line.
--- Recognizes: true/false, True/False, TRUE/FALSE as whole words.
--- Uses Vim regex + byte indices (fast and UTF-8 safe for slicing).
--- @return _BoolHit|nil
local function find_bool_at_cursor()
  -- Cursor: row is 1-based; col is 0-based (bytes)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local pat = [[\<\(true\|false\|True\|False\|TRUE\|FALSE\)\>]]

  -- Iterate all matches in the line and pick the one spanning the cursor col
  local start_at = 0
  while true do
    ---@type string|integer, integer, integer
    local m = vim.fn.matchstrpos(line, pat, start_at) -- {match, start, end}
    local txt, s, e = m[1], m[2], m[3]
    if s == -1 then
      return nil
    end
    if col >= s and col < e then
      return { s = s, e = e, txt = txt }
    end
    start_at = e
  end
end

--- Toggle boolean text preserving case.
--- @param txt string
--- @return string
local function toggle_bool_text(txt)
  if txt == "true"  then return "false" end
  if txt == "false" then return "true"  end
  if txt == "True"  then return "False" end
  if txt == "False" then return "True"  end
  if txt == "TRUE"  then return "FALSE" end
  if txt == "FALSE" then return "TRUE"  end
  return txt
end

--- Try to toggle boolean under cursor in the current buffer.
--- Returns true if a toggle was performed, false if nothing changed.
--- @return boolean
local function toggle_bool_here()
  -- Only act on modifiable normal buffers
  if vim.bo.buftype ~= "" or not vim.bo.modifiable or vim.bo.readonly then
    return false
  end

  local hit = find_bool_at_cursor()
  if not hit then
    return false
  end

  local row0 = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-based row
  local new  = toggle_bool_text(hit.txt)
  if new == hit.txt then
    return false
  end

  -- Replace the matched range [s, e) on the current line
  vim.api.nvim_buf_set_text(0, row0, hit.s, row0, hit.e, { new })
  return true
end

--- Feed a native key (non-remapped) to Neovim.
--- @param lhs string
local function feed_native(lhs)
  local keys = vim.keycode(lhs)
  -- mode "n" => non-remap, as-if typed in Normal mode; no recursion
  vim.api.nvim_feedkeys(keys, "n", false)
end

--- Set up Normal-mode mappings for <C-a>/<C-x>.
--- No expr mapping (avoids textlock). If no toggle, fall back to native key.
--- @return nil
function M.setup()
  vim.keymap.set("n", "<C-a>", function()
    if not toggle_bool_here() then
      feed_native("<C-a>")
    end
  end, { silent = true, desc = "Increment number or toggle boolean" })

  vim.keymap.set("n", "<C-x>", function()
    if not toggle_bool_here() then
      feed_native("<C-x>")
    end
  end, { silent = true, desc = "Decrement number or toggle boolean" })
end

return M

