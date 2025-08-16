---@module 'klingon_notify.ui'
--- UI primitives: floating window renderer and notify dispatcher.
--- Provides a tiny, dependency-free floating window with
--- “close on any key”, plus integration with nvim-notify if available.

local Ui = {}


-- ensure we pass clean line items (no embedded newlines) to nvim_buf_set_lines
local function normalize_lines(input)
  if type(input) == "string" then
    return vim.split(input, "\n", { plain = true })
  end
  local out = {}
  for _, s in ipairs(input or {}) do
    if type(s) ~= "string" then
      s = tostring(s)
    end
    if s:find("\n", 1, true) then
      for _, sub in ipairs(vim.split(s, "\n", { plain = true })) do
        table.insert(out, sub)
      end
    else
      table.insert(out, s)
    end
  end
  if #out == 0 then out = { "" } end
  return out
end


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
---@param lines string[]|string  -- lines or single string (may contain \n)
---@param hl_group string|nil    -- optional highlight group for all lines
---@param opts KlingonFloatOpts
---@return integer win
function Ui.open_float(lines, hl_group, opts)
  opts = opts or {}

  -- 1) Normalize content (no embedded newlines for nvim_buf_set_lines)
  lines = normalize_lines(lines)

  -- 2) Padding
  local pad_l = opts.pad_left   or 1
  local pad_r = opts.pad_right  or 1
  local pad_t = opts.pad_top    or 0
  local pad_b = opts.pad_bottom or 0

  -- 3) Compute width/height based on visible width
  local function str_width(s) return vim.fn.strdisplaywidth(s) end
  local maxw = 0
  for _, l in ipairs(lines) do
    local w = str_width(l)
    if w > maxw then maxw = w end
  end

  local width  = math.max(1, maxw + pad_l + pad_r)
  local height = math.max(1, #lines + pad_t + pad_b)

  -- Optional clamps
  if opts.max_width  then width  = math.min(width,  opts.max_width)  end
  if opts.max_height then height = math.min(height, opts.max_height) end

  -- Clamp to screen
  local cols = vim.o.columns
  local rows = vim.o.lines - vim.o.cmdheight
  width  = math.min(width,  math.max(1, cols - 2))
  height = math.min(height, math.max(1, rows - 2))

  -- 4) Position (default: top-right); allow overrides
  local col = opts.col
  local row = opts.row
  if not col or not row then
    col = math.max(0, cols - width - 2)
    row = math.max(0, 1)
  end

  -- 5) Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype  = "klingon_notify"

  -- Build padded content
  local padded = {}
  for _ = 1, pad_t do table.insert(padded, "") end
  local left_pad = string.rep(" ", pad_l)
  for _, l in ipairs(lines) do
    table.insert(padded, left_pad .. l)
  end
  for _ = 1, pad_b do table.insert(padded, "") end

  -- Fill buffer
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, padded)
  vim.bo[buf].modifiable = false

  -- Optional: apply a single HL group to all lines (best-effort)
  if hl_group and type(hl_group) == "string" then
    for i = 0, #padded - 1 do
      pcall(vim.api.nvim_buf_add_highlight, buf, -1, hl_group, i, 0, -1)
    end
  end

  -- 6) Create window (focus optional)
  local enter = opts.focus_on_open == true
  local win = vim.api.nvim_open_win(buf, enter, {
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

  -- Window visuals
  local blend = opts.winblend or 0
  if blend < 0 then blend = 0 elseif blend > 100 then blend = 100 end
  pcall(vim.api.nvim_win_set_option, win, "winhl", "Normal:" .. (opts.highlight or "Normal"))
  pcall(vim.api.nvim_win_set_option, win, "winblend", blend)

  -- 7) Close helpers
  local function map_close(lhs)
    vim.keymap.set({ "n", "i", "v" }, lhs, function()
      safe_close(win, buf)
    end, { buffer = buf, silent = true, nowait = true })
  end

  -- Only install buffer-local keys if we focused the float
  if enter then
    map_close("<Esc>")
    map_close("q")
    map_close("<CR>")
    map_close("<Space>")
  end

  -- Global close on any key (default true)
  local close_on_any = (opts.close_on_any_key ~= false)
  local ns = vim.api.nvim_create_namespace("klingon_notify_onkey")

  if close_on_any then
    vim.on_key(function()
      -- guard + clean up regardless of success
      vim.on_key(nil, ns)
      if win and vim.api.nvim_win_is_valid(win) then
        safe_close(win, buf)
      end
    end, ns)
  else
    -- Only close when the float is focused
    vim.on_key(function()
      if not (win and vim.api.nvim_win_is_valid(win)) then
        return vim.on_key(nil, ns)
      end
      if vim.api.nvim_get_current_win() == win then
        vim.on_key(nil, ns)
        safe_close(win, buf)
      end
    end, ns)
  end

  -- Safety: clear on_key if buffer/window is wiped some other way
  vim.api.nvim_create_autocmd({ "BufWipeout", "WinClosed" }, {
    buffer = buf,
    once = true,
    callback = function()
      vim.on_key(nil, ns)
    end,
  })

  -- 8) Auto-close
  local timeout = opts.timeout_ms or 1500
  if timeout > 0 then
    vim.defer_fn(function()
      vim.on_key(nil, ns)
      safe_close(win, buf)
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
