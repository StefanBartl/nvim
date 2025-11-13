---@module 'mappings.lsp_signature.open_floating_preview'
local api = vim.api

---@param lines string[]
---@return integer?, integer?
return function(lines)
  if not lines or vim.tbl_isempty(lines) then return nil end

  while #lines > 0 and lines[1] == "" do table.remove(lines, 1) end
  while #lines > 0 and lines[#lines] == "" do table.remove(lines, #lines) end
  if #lines == 0 then return nil end

  local width = 0
  for _, ln in ipairs(lines) do
    local w = vim.fn.strwidth(ln)
    if w > width then width = w end
  end
  local max_width = math.floor(vim.o.columns * 0.6)
  if width > max_width then width = max_width end

  local bufnr = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
  api.nvim_set_option_value("modifiable", false, { buf = bufnr })
  api.nvim_set_option_value("filetype", "lsp_signature", { buf = bufnr })

  local row = 1
  local cursor_win_row = vim.fn.winline()
  if vim.o.lines - cursor_win_row < (#lines + 4) then row = -(#lines + 1) end

  local opts = {
    relative = "cursor",
    row = row,
    col = 0,
    width = width,
    height = #lines,
    focusable = true,       -- Popup kann den Fokus bekommen
    style = "minimal",
    border = "rounded",
  }

  local winid = api.nvim_open_win(bufnr, true, opts) -- set to true to allow focus

  -- Map <Esc> in popup buffer to close window
  api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", "<Cmd>close<CR>", { nowait = true, noremap = true, silent = true })

  return bufnr, winid
end
