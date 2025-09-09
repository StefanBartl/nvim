---@module 'config.harpoon.preview'
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

local M = {}

local uv = vim.uv or vim.loop

--- Read a file fully into a Lua table of lines.
---@param path string
---@return string[]|nil
local function read_file_lines(path)
  local fd = uv.fs_open(path, "r", 420)
  if not fd then return nil end
  local st = uv.fs_fstat(fd)
  if not st then uv.fs_close(fd); return nil end
  local data = uv.fs_read(fd, st.size, 0)
  uv.fs_close(fd)
  if type(data) ~= "string" then return nil end
  local lines = {} ---@type string[]
  -- Split while keeping simple semantics; Neovim handles final EOL display fine.
  for s in data:gmatch("([^\r\n]*)\r?\n?") do
    lines[#lines + 1] = s
  end
  -- Drop the trailing empty capture from the pattern if present
  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines, #lines)
  end
  return lines
end

--- Resolve last cursor position for a file using the shada '" mark.
--- This does not open a window; it loads the buffer hidden and queries the mark.
---@param path string
---@return integer, integer
local function last_cursor_from_shada(path)
  local bufnr = vim.fn.bufadd(path)
  pcall(vim.fn.bufload, bufnr)
  local row, col = 1, 0
  pcall(function()
    vim.api.nvim_buf_call(bufnr, function()
      local pos = vim.fn.getpos([[""]]) -- returns {bufnum, lnum, col, off}
      if type(pos) == "table" and pos[2] and pos[3] then
        if pos[2] > 0 then row = pos[2] end
        if pos[3] >= 0 then col = pos[3] - 1 end -- getpos col is 1-based
      end
    end)
  end)
  return row, col
end

--- Fallback to Harpoon context if available.
---@param it table|string
---@return integer, integer
local function cursor_from_item_context(it)
  if type(it) == "table" and type(it.context) == "table" then
    local r = tonumber(it.context.row) or 1
    local c = tonumber(it.context.col) or 0
    if r < 1 then r = 1 end
    if c < 0 then c = 0 end
    return r, c
  end
  return 1, 0
end

--- Compute full-screen floating window dimensions.
---@return table
local function fullscreen_float()
  local columns = vim.o.columns
  local lines   = vim.o.lines
  local cmdh    = vim.o.cmdheight
  -- Reserve command-line + statusline spaces
  local width   = columns
  local height  = lines - cmdh - 1
  return {
    relative = "editor",
    style    = "minimal",
    row      = 0,
    col      = 0,
    width    = math.max(1, width),
    height   = math.max(1, height),
    border   = "none",
    zindex   = 150,
  }
end

--- Open a preview window for a given file path and position.
---@param path string
---@param row integer
---@param col integer
local function open_preview_for(path, row, col)
  local lines = read_file_lines(path)
  if not lines then
    vim.notify("[harpoon-preview] cannot read file: " .. path, vim.log.levels.WARN)
    return
  end

  -- Create an unlisted scratch buffer, fill it, and set filetype for highlighting.
  local buf = vim.api.nvim_create_buf(false, true) -- listed=false, scratch=true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype  = "nofile"
  vim.bo[buf].bufhidden= "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false    -- prevent edits
  vim.bo[buf].readonly   = true     -- show as read-only

  -- Detect and apply filetype from filename
  local ft = vim.filetype.match({ filename = path }) or ""
  if ft ~= "" then
    vim.bo[buf].filetype = ft
  end

  -- Open full-screen floating window
  local win = vim.api.nvim_open_win(buf, true, fullscreen_float())
  -- Reasonable window-local options for a preview feel
  vim.wo[win].wrap       = false
  vim.wo[win].number     = true
  vim.wo[win].relativenumber = false
  vim.wo[win].cursorline = true
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldenable = false
  vim.wo[win].winhighlight = "Normal:Normal,FloatBorder:Normal"

  -- Position cursor
  pcall(vim.api.nvim_win_set_cursor, win, { row, col })

  -- Map 'q' in this buffer to close the preview window
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true, silent = true })
end

--- Open Harpoon item at index in preview mode.
---@param idx integer
local function open_index(idx)
  local ok, harpoon = pcall(require, "harpoon")
  if not ok then return end
  local list = harpoon:list()
  if type(list) ~= "table" or type(list.items) ~= "table" then return end
  local it = list.items[idx]
  if not it then return end
  local path = (type(it) == "table") and it.value or tostring(it)
  if type(path) ~= "string" or path == "" then return end

  -- Determine cursor: prefer last position from shada, fallback to harpoon context
  local row, col = last_cursor_from_shada(path)
  if row == 1 and col == 0 then
    local r2, c2 = cursor_from_item_context(it)
    row, col = r2, c2
  end

  open_preview_for(path, row, col)
end

--- Install Alt+1..Alt+9 mappings.
---@return nil
function M.install_alt_number_maps()
  for i = 1, 9 do
    local lhs = ("<M-%d>"):format(i)
    vim.keymap.set("n", lhs, function() open_index(i) end, {
      desc = ("Harpoon preview %d (full-screen, 'q' to close)"):format(i),
      silent = true,
    })
  end
end

return M

