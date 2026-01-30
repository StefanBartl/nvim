---@module 'wkdoptions.hl_config.features.current_word'
--- Underline the word under cursor using window-local matchaddpos().
--- Only affects the single occurrence containing the cursor (low noise).

local lazy = require("lib.lazy")
local State = lazy.require("wkdoptions.hl_config.core.state")
local Highlights = lazy.require("wkdoptions.hl_config.core.highlights")
local is_ui = lazy.require("wkdoptions.hl_config.utils.skip").std_skip

local M = {}

--- Clear previous window-local match
---@return nil
local function clear_match()
  if vim.w._myopt_cword_id then
    pcall(vim.fn.matchdelete, vim.w._myopt_cword_id)
    vim.w._myopt_cword_id = nil
  end
end

--- Update underline for current word at cursor
---@return nil
function M.update()
  clear_match()

  -- Skip in insert mode
  if vim.fn.mode():find("i") then
    return
  end

  if is_ui(0) then
    return
  end

  -- Get word under cursor
  local ok, word = pcall(vim.fn.expand, "<cword>")
  if not ok or type(word) ~= "string" or #word < 2 then
    return
  end

  -- Get cursor position (1-based lnum, 0-based byte col)
  local pos = vim.api.nvim_win_get_cursor(0)
  local lnum, cbyte = pos[1], pos[2]

  local ok_line, line = pcall(vim.api.nvim_get_current_line)
  if not ok_line or type(line) ~= "string" then
    return
  end

  -- Build word-boundary pattern (very nomagic)
  local esc_word = vim.fn.escape(word, "\\")
  local pat = "\\V\\<" .. esc_word .. "\\>"

  -- Find the match containing the cursor on current line
  local start, s_at, e_at = 0, nil, nil
  while true do
    local ok_match, match_res = pcall(vim.fn.matchstrpos, line, pat, start)
    if not ok_match then
      break
    end

    local _, s, e = unpack(match_res)
    if s == -1 then
      break
    end

    if s <= cbyte and cbyte < e then
      s_at, e_at = s, e
      break
    end

    start = s + 1
  end

  if not s_at then
    return
  end

  -- Convert to 1-based column for matchaddpos
  local col1 = s_at + 1
  local len = e_at - s_at

  -- Ensure highlight group exists
  Highlights.ensure_hl("CursorWord", { underline = true })

  -- Add window-local match
  local ok_add, id = pcall(vim.fn.matchaddpos, "CursorWord", { { lnum, col1, len } }, 10)
  if ok_add and type(id) == "number" then
    vim.w._myopt_cword_id = id
  end
end

--- Install autocmds
---@param _cfg WKDOptions.HL_CFG
---@return nil
---@diagnostic disable-next-line: unused-local
function M.enable(_cfg)
  local aug = State.get_augroup("CWord", true)

  if not State.is_enabled("current_word") then
    -- Feature disabled: ensure match is cleared
    pcall(clear_match)
    return
  end

  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    group = aug,
    callback = M.update,
    desc = "Underline current word (window-local)",
  })

  vim.api.nvim_create_autocmd({ "InsertEnter", "BufLeave", "WinLeave" }, {
    group = aug,
    callback = clear_match,
    desc = "Clear current-word underline",
  })
end

return M
