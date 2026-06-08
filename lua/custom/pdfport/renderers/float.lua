-- =============================================================================
-- lua/custom/pdfport/renderers/float.lua
-- =============================================================================
---@module 'custom.pdfport.renderers.float'
---@brief Renders extracted PDF text in a centered floating window.

local float_mod = {}

---@param result PdfPort.Result
---@param opts PdfPort.RenderOpts
---@return nil
function float_mod.render(result, opts)
  local lines = vim.split(result.text or "", "\n", { plain = true })
  local ft    = (result.format == "markdown") and "markdown" or "text"

  -- Calculate dimensions: 80% of editor
  local width  = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row    = math.floor((vim.o.lines - height) / 2)
  local col    = math.floor((vim.o.columns - width) / 2)

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "filetype", ft)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")

  local float_cfg = vim.tbl_deep_extend("force", {
    relative = "editor",
    width    = width,
    height   = height,
    row      = row,
    col      = col,
    style    = "minimal",
    border   = "rounded",
    title    = string.format(" pdfport: %s ", vim.fn.fnamemodify(opts.path or "", ":t")),
    title_pos = "center",
  }, opts.float_opts or {})

  local win = vim.api.nvim_open_win(bufnr, true, float_cfg)
  vim.api.nvim_win_set_option(win, "wrap", true)
  vim.api.nvim_win_set_option(win, "linebreak", true)

  -- Close float with q or <Esc>
  local close_keys = { "q", "<Esc>" }
  for _, key in ipairs(close_keys) do
    vim.api.nvim_buf_set_keymap(bufnr, "n", key, "", {
      noremap  = true,
      silent   = true,
      callback = function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end,
    })
  end
end

return float_mod
