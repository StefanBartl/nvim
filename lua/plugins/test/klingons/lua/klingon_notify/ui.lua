---@module 'klingon_notify.ui'
--- UI primitives: floating window renderer and notify dispatcher.
--- Provides a tiny, dependency-free floating window with
--- “close on any key”, plus integration with nvim-notify if available.

---@class KlingonFloatOpts
---@field border       string|table  -- Any valid nvim border value
---@field pad_left     integer
---@field pad_right    integer
---@field pad_top      integer
---@field pad_bottom   integer
---@field zindex       integer
---@field timeout_ms   integer       -- Auto-close timeout; 0 to disable
---@field winblend     integer       -- 0..100, transparency
---@field highlight    string        -- Window highlight group
---@field title        string|nil    -- Optional window title
---@field title_pos    "left"|"center"|"right"|nil

---@class KlingonNotifyDispatch
---@field level integer
---@field title string
---@field message string

local Ui = {}

--- Internal helper: close window+buffer safely.
---@param win integer
---@param buf integer
local function safe_close(win, buf)
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

--- Create a floating window showing `lines` and close on any key or after timeout.
---@param lines string[]  -- pre-wrapped lines to display
---@param hl_group string -- default highlight for lines
---@param opts KlingonFloatOpts
---@return integer win  @as integer
function Ui.open_float(lines, hl_group, opts)
  -- Create ephemeral scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "klingon_notify")

  -- Compute width/height based on content
  local function str_width(s)
    return vim.fn.strdisplaywidth(s)
  end
  local maxw = 0
  for _, l in ipairs(lines) do
    local w = str_width(l)
    if w > maxw then maxw = w end
  end

  local pad_l  = opts.pad_left or 1
  local pad_r  = opts.pad_right or 1
  local pad_t  = opts.pad_top or 0
  local pad_b  = opts.pad_bottom or 0

  local width  = math.max(1, maxw + pad_l + pad_r)
  local height = math.max(1, #lines + pad_t + pad_b)

  -- Position near top-right by default
  local cols   = vim.o.columns
  local rows   = vim.o.lines - vim.o.cmdheight
  local col    = math.max(0, cols - width - 2)
  local row    = math.max(0, 1)

  local win    = vim.api.nvim_open_win(buf, false, {
    relative  = "editor",
    style     = "minimal",
    border    = opts.border or "rounded",
    width     = width,
    height    = height,
    col       = col,
    row       = row,
    noautocmd = true,
    zindex    = opts.zindex or 150,
    title     = opts.title,
    title_pos = opts.title_pos,
  })
  vim.api.nvim_win_set_option(win, "winhl", "Normal:" .. (opts.highlight or "Normal"))
  vim.api.nvim_win_set_option(win, "winblend", opts.winblend or 0)

  -- Fill buffer (apply a single highlight group to all lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Map a few common keys for closing
  local function map_close(lhs)
    vim.keymap.set({ "n", "i", "v" }, lhs, function()
      safe_close(win, buf)
    end, { buffer = buf, silent = true, nowait = true })
  end
  map_close("<Esc>")
  map_close("q")
  map_close("<CR>")
  map_close("<Space>")

  -- Close on any key while window is focused (global on_key with a namespace)
  local ns = vim.api.nvim_create_namespace("klingon_notify_onkey")
  vim.on_key(function()
    if not (win and vim.api.nvim_win_is_valid(win)) then
      return vim.on_key(nil, ns)
    end
    if vim.api.nvim_get_current_win() == win then
      vim.on_key(nil, ns)
      safe_close(win, buf)
    end
  end, ns)

  -- Auto-close timer
  local timeout = opts.timeout_ms or 1500
  if timeout > 0 then
    vim.defer_fn(function()
      safe_close(win, buf)
      vim.on_key(nil, ns)
    end, timeout)
  end

  return win
end

--- Notify dispatcher using nvim-notify if available, falling back to vim.notify.
---@param spec KlingonNotifyDispatch
function Ui.notify(spec)
  local ok, notify = pcall(require, "notify")
  if ok and type(notify) == "function" then
    notify(spec.message, spec.level, {
      title = spec.title,
      timeout = 1500,
      -- Intentionally minimal; users may configure nvim-notify styles separately.
    })
  else
    vim.notify(spec.title .. " " .. spec.message, spec.level)
  end
end

return Ui
