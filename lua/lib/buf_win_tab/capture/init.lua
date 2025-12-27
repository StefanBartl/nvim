---@module 'lib.buf_win_tab.capture'
---Deterministic capture of buffers and windows created by Ex commands.
---Supports async creation, timeouts, multi-object capture and User events.

local api = vim.api
local uv = vim.uv

local M = {}

-- Default configuration
local DEFAULT_TIMEOUT = 300
local DEFAULT_INTERVAL = 20

---Capture current editor state
---@return table<integer, true>, table<integer, true>
local function snapshot_state()
  local wins = {}
  for _, win in ipairs(api.nvim_list_wins()) do
    wins[win] = true
  end

  local bufs = {}
  for _, buf in ipairs(api.nvim_list_bufs()) do
    bufs[buf] = true
  end

  return wins, bufs
end

---Compute delta between two snapshots
---@param before table<integer, true>
---@param after integer[]
---@return integer[]
local function delta(before, after)
  local out = {}
  for _, id in ipairs(after) do
    if not before[id] then
      out[#out + 1] = id
    end
  end
  return out
end

---Apply tags to buffers and windows
---@param result BufWinCapture.Results
---@param tag BufWinCapture.Tag|nil
local function apply_tags(result, tag)
  if not tag then
    return
  end

  if tag.buf then
    for _, buf in ipairs(result.bufs) do
      vim.b[buf].custom_tag = tag.buf
    end
  end

  if tag.win then
    for _, win in ipairs(result.wins) do
      vim.w[win].custom_tag = tag.win
    end
  end
end

---Emit User autocommand
---@param result BufWinCapture.Results
local function emit_event(result)
  api.nvim_exec_autocmds("User", {
    pattern = "BufWinCapture",
    data = result,
  })
end

---Public API: capture buffers and windows created by an Ex command
---@param cmd string
---@param opts BufWinCapture.Opts|nil
---@param cb fun(result: BufWinCapture.Results)|nil
---@return BufWinCapture.Results|nil
function M.capture(cmd, opts, cb)
  if type(cmd) ~= "string" then
    vim.notify("[lib.buf_win_tab.capture] cmd must be a string", vim.log.levels.ERROR)
    return nil
  end

  opts = opts or {}

  local timeout = opts.timeout or DEFAULT_TIMEOUT
  local interval = opts.interval or DEFAULT_INTERVAL

  local wins_before, bufs_before = snapshot_state()

  -- Execute command
  vim.cmd(cmd)

  local start = uv.now()
  local timer = uv.new_timer()
  if not timer then
    vim.notify("[BufWinCapture] timer is nil", 4)
    return nil
  end

  ---@cast timer uv.uv_timer_t

  local function poll()
    local wins_after = api.nvim_list_wins()
    local bufs_after = api.nvim_list_bufs()

    local new_wins = delta(wins_before, wins_after)
    local new_bufs = delta(bufs_before, bufs_after)

    if #new_wins > 0 or #new_bufs > 0 then
      timer:stop()
      timer:close()

      local result = {
        wins = new_wins,
        bufs = new_bufs,
      }

      apply_tags(result, opts.tag)

      if opts.emit_event then
        emit_event(result)
      end

      if cb then
        cb(result)
        return
      end

      return
    end

    if uv.now() - start >= timeout then
      timer:stop()
      timer:close()

      local result = {
        wins = {},
        bufs = {},
      }

      if opts.emit_event then
        emit_event(result)
      end

      if cb then
        cb(result)
      end
    end
  end

  timer:start(0, interval, vim.schedule_wrap(poll))

  -- Async path returns nothing immediately
  if cb then
    return nil
  end

  -- Sync fallback: block until timeout
  local deadline = uv.now() + timeout
  while uv.now() < deadline do
    vim.wait(interval)
    local wins_after = api.nvim_list_wins()
    local bufs_after = api.nvim_list_bufs()

    local new_wins = delta(wins_before, wins_after)
    local new_bufs = delta(bufs_before, bufs_after)

    if #new_wins > 0 or #new_bufs > 0 then
      local result = {
        wins = new_wins,
        bufs = new_bufs,
      }

      apply_tags(result, opts.tag)

      if opts.emit_event then
        emit_event(result)
      end

      return result
    end
  end

  return {
    wins = {},
    bufs = {},
  }
end

return M
