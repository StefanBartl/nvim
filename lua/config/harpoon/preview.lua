---@module 'config.harpoon.preview'
--- Memory-safe preview with a single reusable scratch buffer/window.
--- Preview-open Harpoon entries in a full-screen floating window.
--- - Triggered via Alt+<number> (Alt+1..Alt+9)
--- - Opens a read-only, non-modifiable preview that fills the editor
--- - Cursor jumps to the last known position (shada '" mark), fallback to Harpoon context
--- - Scrollable like a normal buffer; press 'q' to close the preview
--- - Does not disturb the current window layout (uses a floating window)
---
--- Notes:
--- - This creates a scratch "nofile" buffer showing the file's content.
--- - We detect & set 'filetype' for highlighting.
--- - We do not change buffer-local options of the real file buffer.
--- - If your terminal does not send <M-1>.. <M-9>, consider mapping alternate keys.

local notify = require("lib.notify").create("[config.harpoon.preview]")

local M = {}

local uv = vim.uv or vim.loop

local MAX_BYTES = 1.5 * 1024 * 1024 -- ~1.5MB cap for full read
local MAX_LINES = 4000 -- head lines when file is large

local STATE = {
  buf = nil, -- scratch buffer id
  win = nil, -- preview window id
}

local function resolve_layout()
  -- Try to reuse an existing project helper:
  local ok, layouts = pcall(require, "config.harpoon.preview_layout")
  if ok and type(layouts.fullscreen_float) == "function" then
    return layouts.fullscreen_float()
  end

  local w = math.floor(vim.o.columns * 0.7)
  local h = math.floor(vim.o.lines * 0.7)
  return {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = math.max(40, w),
    height = math.max(8, h),
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - w) / 2),
  }
end

--- Read file lines efficiently with size/line cap.
---@param path string
---@return string[]|nil
local function read_file_lines(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end

  local fd = uv.fs_open(path, "r", 420) -- 0644
  if not fd then
    return nil
  end
  ---@diagnostic disable-next-line fs_stat exists in uv library
  local st = uv.fs_fstat(fd)
  uv.fs_close(fd)
  if not st then
    return nil
  end

  -- Large file → head-only via readfile (far fewer temp strings)
  if st.size and st.size > MAX_BYTES then
    local ok, lines = pcall(vim.fn.readfile, path, "", MAX_LINES)
    return ok and lines or nil
  end

  -- Small enough → read whole file, then split once
  local fd2 = uv.fs_open(path, "r", 420)
  if not fd2 then
    return nil
  end
  local data = uv.fs_read(fd2, st.size, 0)
  uv.fs_close(fd2)
  if type(data) ~= "string" then
    return nil
  end

  -- Use regex split to honour CRLF
  return vim.split(data, "\r?\n", { plain = false })
end

--- Ensure a single reusable scratch buffer and window.
---@return integer buf, integer win
local function ensure_preview_window()
  if STATE.win and vim.api.nvim_win_is_valid(STATE.win) and STATE.buf and vim.api.nvim_buf_is_valid(STATE.buf) then
    return STATE.buf, STATE.win
  end

  -- (Re)create buffer + window
  if not (STATE.buf and vim.api.nvim_buf_is_valid(STATE.buf)) then
    STATE.buf = vim.api.nvim_create_buf(false, true) -- scratch, listed=false
    vim.bo[STATE.buf].buftype = "nofile"
    vim.bo[STATE.buf].swapfile = false
    vim.bo[STATE.buf].bufhidden = "wipe"
  end

  local cfg = resolve_layout()
  STATE.win = vim.api.nvim_open_win(STATE.buf, true, cfg)
  vim.wo[STATE.win].wrap = true
  vim.wo[STATE.win].cursorline = true

  -- Identify buffer for external autocmd guards
  vim.b[STATE.buf]._harpoon_preview = true

  pcall(vim.keymap.set, "n", "q", function()
    if STATE.win and vim.api.nvim_win_is_valid(STATE.win) then
      vim.api.nvim_win_close(STATE.win, true)
    end
  end, { buffer = STATE.buf, nowait = true, silent = true, desc = "Close Harpoon preview" })

  return STATE.buf, STATE.win
end

--- Public: open file preview and optionally place the cursor.
---@param path string
---@param row integer|nil  -- 1-based
---@param col integer|nil  -- 0-based
function M.open_preview_for(path, row, col)
  local lines = read_file_lines(path)
  if not lines then
    notify.warn("[harpoon preview] cannot read file: " .. tostring(path))
    return
  end

  -- Clamp cursor safely
  local total = #lines
  row = (type(row) == "number" and row or 1)
  col = (type(col) == "number" and col or 0)
  if row < 1 then
    row = 1
  end
  if row > total then
    row = total
  end
  if col < 0 then
    col = 0
  end

  local buf, win = ensure_preview_window()

  -- Write content while modifiable, set filetype before freezing
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local ft = vim.filetype.match({ filename = path }) or ""
  if ft ~= "" then
    vim.bo[buf].filetype = ft
  end

  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  -- Try to place the cursor; ignore if window vanished mid-flight
  if vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_set_cursor, win, { row, col })
  end
end

function M.open_index(entry)
  if type(entry) == "number" then
    -- resolve harpoon item by index and tail-call ourselves
    local ok, harpoon = pcall(require, "harpoon")
    if not ok then
      return
    end
    local list = harpoon:list()
    if type(list) ~= "table" or type(list.items) ~= "table" then
      return
    end
    local it = list.items[entry]
    if not it then
      notify.info(("[harpoon-preview] no item at index %d"):format(entry))
      return
    end
    return M.open_index(it)
  end

  if type(entry) == "table" and type(entry.value) == "string" then
    M.open_preview_for(entry.value, entry.row or 1, entry.col or 0)
  elseif type(entry) == "string" then
    M.open_preview_for(entry, 1, 0)
  end
end

--- Install Alt+1..Alt+9 mappings.
function M.install_alt_number_maps()
  for i = 1, 9 do
    local lhs = ("<M-%d>"):format(i)
    vim.keymap.set("n", lhs, function()
      M.open_index(i)
    end, {
      desc = ("Harpoon preview %d (full-screen, 'q' to close)"):format(i),
      silent = true,
    })
  end
end

return M
