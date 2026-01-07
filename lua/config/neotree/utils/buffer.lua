---@module 'config.neotree.utils.buffer'
---@brief Buffer validation and context utilities

local M = {}

---Check if buffer is a valid, normal file buffer
---@param bufnr integer|nil Buffer number (0 or nil = current)
---@return boolean
function M.is_valid_file_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return false
  end

  -- Skip special buffer types
  local buftype = vim.bo[bufnr].buftype
  if buftype ~= "" then
    return false
  end

  -- Must be listed
  if not vim.bo[bufnr].buflisted then
    return false
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if not name or name == "" then
    return false
  end

  return vim.fn.filereadable(name) == 1
end

---Get buffer context for reveal/navigation operations
---@param bufnr integer|nil
---@return {buf:integer, file:string, dir:string}|nil
function M.get_buffer_context(bufnr)
  if not M.is_valid_file_buffer(bufnr) then
    return nil
  end

  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  local dir = vim.fn.fnamemodify(file, ":p:h")

  return {
    buf = bufnr,
    file = file,
    dir = dir,
  }
end

---Find last usable file buffer (excluding special buffers)
---@param exclude_win integer|nil Window to exclude
---@return integer|nil bufnr, integer|nil win
function M.find_last_normal_buffer(exclude_win)
  local wins = vim.api.nvim_tabpage_list_wins(0)

  for i = #wins, 1, -1 do
    local win = wins[i]
    if win ~= exclude_win and vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if M.is_valid_file_buffer(buf) then
        return buf, win
      end
    end
  end

  return nil, nil
end

---Close all buffers related to a path (for file operations)
---@param path string Path to close buffers for
function M.close_related_buffers(path)
  local normalized = vim.fn.resolve(path):gsub("\\", "/")

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name ~= "" then
        local norm_buf = vim.fn.resolve(buf_name):gsub("\\", "/")
        if norm_buf:sub(1, #normalized) == normalized or norm_buf == normalized then
          pcall(vim.api.nvim_buf_delete, buf, { force = true, unload = true })
        end
      end
    end
  end
end

return M
