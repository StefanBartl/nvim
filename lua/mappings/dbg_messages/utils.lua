---@module 'mappings.dbg_messages.utils'

local api = vim.api
local nvim_buf_is_valid = api.nvim_buf_is_valid
local nvim_win_is_valid = api.nvim_win_is_valid

-- Forward decls
---@private
---@param win DbgMsgs.Win
---@return boolean
---@diagnostic disable-next-line
local function at_bottom(win)
  return false
end

---@private
---@param win DbgMsgs.Win
---@param row integer
---@return boolean
---@diagnostic disable-next-line
local function safe_win_set_cursor(win, row)
  return false
end

---@private
---@param buf DbgMsgs.Buf
---@return boolean
---@diagnostic disable-next-line
local function is_target_view(buf)
  return false
end

---@private
---@param win DbgMsgs.Win
---@param attempts integer
---@param retry_delay integer
---@diagnostic disable-next-line
local function ensure_bottom(win, attempts, retry_delay) end

-- Check if window cursor already sits at the last line
function at_bottom(win)
  if not (win and nvim_win_is_valid(win)) then
    return true
  end
  local ok_buf, buf = pcall(api.nvim_win_get_buf, win)
  if not ok_buf or not (buf and nvim_buf_is_valid(buf)) then
    return true
  end
  local last = api.nvim_buf_line_count(buf)
  local row = api.nvim_win_get_cursor(win)[1]
  return row >= last
end

-- Set cursor to target row in a specific window
function safe_win_set_cursor(win, row)
  if not (win and nvim_win_is_valid(win)) then
    return false
  end
  local ok_buf, buf = pcall(api.nvim_win_get_buf, win)
  if not ok_buf or not (buf and nvim_buf_is_valid(buf)) then
    return false
  end
  return pcall(api.nvim_win_set_cursor, win, { math.max(1, row), 0 })
end

-- Identify messages/noice buffers strictly by filetype (avoid filename heuristics)
function M.is_target_view(buf)
  if not (buf and nvim_buf_is_valid(buf)) then
    return false
  end
  local ok_ft, ft = pcall(function()
    return vim.bo[buf].filetype
  end)
  if not ok_ft then
    return false
  end
  if ft == "messages" then
    return true
  end
  if ft == "noice" then
    local ok_bt, bt = pcall(function()
      return vim.bo[buf].buftype
    end)
    return ok_bt and (bt == "nofile" or bt == "")
  end
  return false
end

-- Move cursor to bottom with retries for late content
function M.ensure_bottom(win, attempts, retry_delay)
  if not (win and nvim_win_is_valid(win)) then
    return
  end
  attempts = attempts or 1
  retry_delay = retry_delay or 60

  local ok_buf, buf = pcall(api.nvim_win_get_buf, win)
  if not ok_buf or not (buf and nvim_buf_is_valid(buf)) then
    return
  end

  local last = math.max(1, api.nvim_buf_line_count(buf))
  safe_win_set_cursor(win, last)

  if attempts > 1 and not at_bottom(win) then
    vim.defer_fn(function()
      if win and nvim_win_is_valid(win) then
        ensure_bottom(win, attempts - 1, retry_delay)
      end
    end, retry_delay)
  end
end


return {}
