---@module 'config.harpoon.preview'
--- Preview a Harpoon entry in a read-only floating window backed by one
--- reusable scratch buffer. Entry point `:Harpoon preview <n>` (mapped to
--- <M-1>..<M-9> in bindings.mappings.harpoon). Cursor restores from the shada
--- `'"` mark, falling back to the Harpoon context; `q` closes it. Large files
--- are capped (see MAX_BYTES / MAX_LINES).

local notify = require("lib.nvim.notify").create("[config.harpoon.preview]")
local window = require("lib.nvim.window")

local M = {}

local uv = vim.uv or vim.loop

local MAX_BYTES = 1.5 * 1024 * 1024 -- ~1.5MB cap for full read
local MAX_LINES = 4000 -- head lines when file is large

local STATE = {
  buf = nil, -- scratch buffer id
  win = nil, -- preview window id
}

local function resolve_layout()
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
---@return string[]|nil lines
---@return boolean|nil truncated  True when the line cap actually cut the file
--- short, so the caller can say so instead of showing a preview that simply
--- stops. `nil` alongside a `nil` result, and `false` for a file read whole.
local function read_file_lines(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end

  local fd = uv.fs_open(path, "r", 420) -- 0644
  if not fd then
    return nil
  end
  local st = uv.fs_fstat(fd)
  uv.fs_close(fd)
  if not st then
    return nil
  end

  -- Large file → head-only via readfile (far fewer temp strings)
  if st.size and st.size > MAX_BYTES then
    local ok, lines = pcall(vim.fn.readfile, path, "", MAX_LINES)
    if not ok then
      return nil
    end
    -- `readfile` with a max count gives back exactly that many lines when it
    -- hit the cap, so a short result means the file simply ended first and
    -- nothing was actually cut.
    return lines, #lines >= MAX_LINES
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
  return vim.split(data, "\r?\n", { plain = false }), false
end

--- Ensure a single reusable scratch buffer and window.
---@return integer buf, integer win
local function ensure_preview_window()
  if
    STATE.win
    and vim.api.nvim_win_is_valid(STATE.win)
    and STATE.buf
    and vim.api.nvim_buf_is_valid(STATE.buf)
  then
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

  window.nice_quit(STATE.win, { force = true })

  return STATE.buf, STATE.win
end

--- Public: open file preview and optionally place the cursor.
---@param path string
---@param row integer|nil  -- 1-based
---@param col integer|nil  -- 0-based
---@return nil
function M.open_preview_for(path, row, col)
  local lines, truncated = read_file_lines(path)
  if not lines then
    notify.warn("[harpoon preview] cannot read file: " .. tostring(path))
    return
  end

  -- UI-02: a capped preview says so. The marker goes in the buffer rather
  -- than into a notification because that is where the cut actually is --
  -- scrolling to a preview that just stops looks exactly like a file that
  -- just ends, and a toast would nag on every preview of the same big file.
  if truncated then
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("--- preview truncated at %d lines (file is larger than %d KB) ---"):format(
      MAX_LINES,
      MAX_BYTES / 1024
    )
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

---@param entry integer|table
---@return nil
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

return M
