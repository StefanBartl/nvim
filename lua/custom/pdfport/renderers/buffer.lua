---@module 'custom.pdfport.renderers.buffer'
---@brief Renders extracted PDF text into a Neovim scratch buffer.
---@description
--- Creates a scratch buffer with filetype=markdown (or =text for plain output)
--- and writes the extracted content into it. The buffer is not tied to any
--- file on disk and is hidden (not wiped) when left, mirroring the behaviour
--- of `:e <path>` so the previous buffer stays alive in the buffer list.
---
--- Split behaviour is controlled by opts.split:
---   nil / "current" : replace the current editor window (default, `:e`-style)
---   "vsplit"        : open to the right of the current editor window
---   "split"         : open below the current editor window
---   "tab"           : open in a new tab
---
--- In every case, `ensure_editor_win()` is called first so that Neo-tree and
--- floating windows are never used as the target.

local M = {}

-- ── Helpers ───────────────────────────────────────────────────────────────────

--- Returns a deduplicated scratch-buffer name derived from the PDF path.
---@param path string
---@return string
local function buf_name(path)
  local stem = vim.fn.fnamemodify(path, ":t:r")
  return string.format("pdfport://%s", stem)
end

--- Returns an existing valid scratch buffer with the given name, or creates one.
---@param name string
---@return integer bufnr
local function get_or_create_buf(name)
  for _, nr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(nr) then
      if vim.api.nvim_buf_get_name(nr) == name then
        return nr
      end
    end
  end
  local nr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(nr, name)
  return nr
end

--- Strips a trailing carriage return from a single line.
--- Applied element-wise after vim.split() so that empty lines are preserved.
---@param line string
---@return string
local function strip_cr(line)
  local result = line:gsub("\r$", "")
  return result
end

--- Switches the current window to the "best" normal editor window – i.e.
--- not Neo-tree and not a floating window.  Returns the previous window id so
--- the caller can decide whether to switch back (focus=false).
---
--- Background: vsplit / win_set_buf always act on the *current* window.  When
--- Neo-tree is focused the split ends up between Neo-tree and the editor, which
--- is never what the user wants.
---
---@return integer orig_win  Window id before the switch (0 = no switch needed)
local function ensure_editor_win()
  local cur_win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_win_get_buf(cur_win)
  local cur_ft  = vim.bo[cur_buf].filetype
  local cur_cfg = vim.api.nvim_win_get_config(cur_win)

  -- Already in a plain editor window – nothing to do.
  local is_neotree = cur_ft == "neo-tree"
  local is_float   = cur_cfg.relative ~= ""
  if not is_neotree and not is_float then
    return 0
  end

  -- Walk all windows in this tab (reverse order = rightmost / bottommost first)
  -- and pick the first normal editor window.
  local wins = vim.api.nvim_tabpage_list_wins(0)
  for i = #wins, 1, -1 do
    local w = wins[i]
    if w ~= cur_win and vim.api.nvim_win_is_valid(w) then
      local wbuf = vim.api.nvim_win_get_buf(w)
      local wcfg = vim.api.nvim_win_get_config(w)
      local wft  = vim.bo[wbuf].filetype
      if wcfg.relative == "" and wft ~= "neo-tree" then
        vim.api.nvim_set_current_win(w)
        return cur_win
      end
    end
  end

  -- No suitable window found – Neovim will split wherever it wants.
  return 0
end

-- ── Public API ────────────────────────────────────────────────────────────────

---@param result PdfPort.Result
---@param opts   PdfPort.OpenOpts
---@return nil
function M.render(result, opts)
  local path  = opts.path or ""
  local name  = buf_name(path)
  local bufnr = get_or_create_buf(name)

  -- Normalise split value: nil and "current" both mean "replace current window".
  local split = opts.split
  if split == "current" or split == nil or split == "" then
    split = "current"
  end

  local focus = opts.focus ~= false  -- default: true

  -- Derive filetype from extraction format.
  local ft = (result.format == "markdown") and "markdown" or "text"

  -- Prepare lines: split on \n then strip residual \r (CRLF artefacts).
  local raw_lines = vim.split(result.text or "", "\n", { plain = true })
  local lines     = { [#raw_lines] = "" }
  for i = 1, #raw_lines do
    lines[i] = strip_cr(raw_lines[i])
  end

  -- Write content into the scratch buffer.
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- Buffer metadata.  bufhidden="hide" (not "wipe") so the previous buffer
  -- stays alive in the buffer list, identical to `:e <path>` behaviour.
  vim.api.nvim_buf_set_option(bufnr, "buftype",   "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(bufnr, "filetype",  ft)
  vim.api.nvim_buf_set_option(bufnr, "swapfile",  false)

  -- Decorative header comment prepended as the very first lines.
  local header = strip_cr(string.format(
    "<!-- pdfport: %s | backend: %s | format: %s -->",
    vim.fn.fnamemodify(path, ":t"),
    result.backend,
    result.format
  ))
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { header, "" })
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- ── Window placement ──────────────────────────────────────────────────────
  -- Always ensure we start from a real editor window before any split/set_buf.
  local orig_win = ensure_editor_win()

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
    -- "current": replace the buffer shown in the current window, just like
    -- `:e <path>` would.  The previous buffer is NOT deleted.
    vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), bufnr)
  end

  -- Restore focus to the original window when focus=false and we had to
  -- move away (e.g. Neo-tree was focused, we opened a vsplit, and the caller
  -- wants Neo-tree to keep focus).
  if not focus then
    if orig_win ~= 0 and vim.api.nvim_win_is_valid(orig_win) then
      vim.api.nvim_set_current_win(orig_win)
    else
      vim.cmd("wincmd p")
    end
  end
end

return M
