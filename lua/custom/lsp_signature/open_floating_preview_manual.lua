---@module 'custom.lsp_signature.open_floating_preview_manual'
local api = vim.api

---@param lines string[]
return function(lines)
  if not lines or vim.tbl_isempty(lines) then return nil end

  -- Trim leading/trailing empty lines
  while #lines > 0 and lines[1] == "" do table.remove(lines, 1) end
  while #lines > 0 and lines[#lines] == "" do table.remove(lines, #lines) end
  if #lines == 0 then return nil end

  -- Berechne Breite
  local width = 0
  for _, ln in ipairs(lines) do
    local w = vim.fn.strwidth(ln)
    if w > width then width = w end
  end
  local max_width = math.floor(vim.o.columns * 0.6)
  if width > max_width then width = max_width end

  local height = #lines
  local row = 1
  local cursor_win_row = vim.fn.winline()
  if vim.o.lines - cursor_win_row < (#lines + 4) then
    row = -(#lines + 1)
  end

  -- Scratch Buffer erzeugen
  local bufnr = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  api.nvim_buf_set_option(bufnr, "modifiable", false)
  api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  api.nvim_buf_set_option(bufnr, "filetype", "lsp_signature")

  -- Floating Window erzeugen
  local opts = {
    relative = "cursor",
    row = row,
    col = 0,
    width = width,
    height = height,
    focusable = true,
    style = "minimal",
    border = "rounded",
  }
  local winid = api.nvim_open_win(bufnr, true, opts)

  -- <Esc> schließen
  api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", "<Cmd>close<CR>", { noremap = true, silent = true })

  -- Auto-close Events
  local group_name = "LspSignaturePopup_" .. tostring(winid)
  local aug_id = api.nvim_create_augroup(group_name, { clear = true })
  api.nvim_create_autocmd(
    { "CursorMoved", "CursorMovedI", "BufHidden", "BufLeave", "InsertEnter", "WinScrolled" },
    {
      group = aug_id,
      once = true,
      callback = function()
        if api.nvim_win_is_valid(winid) then
          pcall(api.nvim_win_close, winid, true)
        end
        pcall(api.nvim_del_augroup_by_id, aug_id)
      end,
    }
  )

  return bufnr, winid
end
