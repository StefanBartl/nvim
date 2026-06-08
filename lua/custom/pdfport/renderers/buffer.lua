-- =============================================================================
-- lua/custom/pdfport/renderers/buffer.lua
-- =============================================================================
---@module 'custom.pdfport.renderers.buffer'
---@brief Renders extracted PDF text into a Neovim scratch buffer.
---@description
--- Creates a new scratch buffer with filetype=markdown (or =text for plain
--- output) and writes the extracted content into it. The buffer is not tied
--- to any file on disk and will be discarded when closed.
---
--- Split behavior is controlled by opts.split:
---   "vsplit" (default), "split", "tab", or nil (current window)

local M = {}

--- Returns a deduplicated buffer name for the given PDF path.
---@param path string  Original PDF path
---@return string
local function buf_name(path)
  local stem = vim.fn.fnamemodify(path, ":t:r")
  return string.format("pdfport://%s", stem)
end

--- Opens or reuses a scratch buffer for the given PDF.
---@param name string  Buffer name
---@return integer bufnr
local function get_or_create_buf(name)
  -- Search for an existing buffer with this name
  for _, nr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(nr) then
      if vim.api.nvim_buf_get_name(nr) == name then
        return nr
      end
    end
  end

  -- Create a new scratch buffer
  local nr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(nr, name)
  return nr
end

---@param result PdfPort.Result
---@param opts PdfPort.RenderOpts
---@return nil
function M.render(result, opts)
  local path   = opts.path or ""
  local name   = buf_name(path)
  local bufnr  = get_or_create_buf(name)
  local split  = opts.split or "vsplit"
  local focus  = opts.focus ~= false  -- default: focus=true

  -- Determine filetype from result format
  local ft = (result.format == "markdown") and "markdown" or "text"

  -- Write lines into buffer
  local lines = vim.split(result.text or "", "\n", { plain = true })
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(bufnr, "filetype", ft)
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)

  -- Add a header comment line at the top (decorative, not written to file)
  local header = string.format(
    "<!-- pdfport: %s | backend: %s | format: %s -->",
    vim.fn.fnamemodify(path, ":t"),
    result.backend,
    result.format
  )
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { header, "" })
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- Open the buffer in a window
  if split == "tab" then
    vim.cmd("tabnew")
    vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), bufnr)
  elseif split == "split" then
    vim.cmd("split")
    vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), bufnr)
  elseif split == "vsplit" then
    vim.cmd("vsplit")
    vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), bufnr)
  else
    -- Replace current window's buffer
    vim.api.nvim_win_set_buf(0, bufnr)
  end

  if not focus then
    vim.cmd("wincmd p")  -- return to previous window
  end
end

return M
