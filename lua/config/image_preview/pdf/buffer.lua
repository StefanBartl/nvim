---@module 'config.image_preview.pdf.buffer'
--- Open PDFs as page-rendered images in a dedicated scratch buffer/split.
--- Renders pages to PNG via ImageMagick (convert/identify) or Poppler (pdftoppm/pdfinfo).
--- Displays a window-local statusline "PDF X/Y" and provides paging keymaps.
--- Fixes:
---   * Ensure buffer is modifiable when writing initial lines
---   * Force opaque white background for rasterized pages (no alpha)

---@class PdfPreviewConfig
---@field open_mode '"vsplit"'|'"split"'|'"tab"'
---@field density integer
---@field notify boolean
---@field clear_on_leave boolean
---@field backend '"image_preview"'
---@field bg_hex string|nil                -- optional, default "#ffffff"

local M = {}

-- ===== Utilities =============================================================

--- Check if an executable exists in $PATH.
---@param bin string
---@return boolean
local function has_exec(bin)
  return vim.fn.executable(bin) == 1
end

--- Make a per-window PNG path (avoids collisions across windows).
---@param winid integer
---@return string
local function png_path_for(winid)
  local cache = vim.fn.stdpath("cache")
  return ("%s/pdf_preview_%d.png"):format(cache, winid)
end

--- Lowercase-safe endswith.
---@param p string
---@param ext string
---@return boolean
local function endswith(p, ext)
  p = (p or ""):lower()
  return p:sub(-#ext) == ext
end

--- Is a PDF?
---@param path string
---@return boolean
local function is_pdf(path)
  return endswith(path, ".pdf")
end

--- Read total page count of a PDF (identify → pdfinfo).
---@param pdf string
---@return integer|nil
local function read_page_count(pdf)
  if has_exec("identify") then
    local out = vim.fn.systemlist({ "identify", "-format", "%n", pdf })
    if vim.v.shell_error == 0 and out[1] then
      local n = tonumber(out[1])
      if n and n > 0 then return n end
    end
  end
  if has_exec("pdfinfo") then
    local lines = vim.fn.systemlist({ "pdfinfo", pdf })
    if vim.v.shell_error == 0 then
      for _, line in ipairs(lines) do
        local n = tonumber(line:match("^Pages:%s+(%d+)$"))
        if n and n > 0 then return n end
      end
    end
  end
  return nil
end

--- Force-white background helper.
---@param cfg PdfPreviewConfig
---@return string
local function get_bg_hex(cfg)
  -- Always white unless overridden via cfg.bg_hex
  return (cfg and cfg.bg_hex) or "#ffffff"
end

--- Render one page (0-based) to a PNG with opaque background.
--- Tries ImageMagick first; falls back to Poppler and fixes alpha via convert if present.
---@param pdf string
---@param page integer
---@param out_png string
---@param density integer
---@param cfg PdfPreviewConfig
---@return boolean ok, string|nil err
local function render_page(pdf, page, out_png, density, cfg)
  local bg = get_bg_hex(cfg)

  if has_exec("convert") then
    -- Important: order of operations to drop alpha and flatten onto white
    local cmd = {
      "convert",
      "-density", tostring(density),
      ("%s[%d]"):format(pdf, page),
      "-background", bg,
      "-alpha", "remove",
      "-alpha", "off",
      "-flatten",
      "-strip",
      ("PNG24:%s"):format(out_png), -- 24-bit, no alpha
    }
    local _ = vim.fn.system(cmd)
    if vim.v.shell_error == 0 then return true end
    return false, "convert failed"
  end

  if has_exec("pdftoppm") then
    local base = out_png:gsub("%.png$", "")
    local cmd = { "pdftoppm", "-png", "-f", tostring(page + 1), "-l", tostring(page + 1), pdf, base }
    local _ = vim.fn.system(cmd)
    local produced = base .. ".png"
    if vim.v.shell_error ~= 0 or vim.fn.filereadable(produced) ~= 1 then
      return false, "pdftoppm failed"
    end
    if has_exec("convert") then
      local fix = {
        "convert",
        produced,
        "-background", bg,
        "-alpha", "remove",
        "-alpha", "off",
        "-flatten",
        "-strip",
        ("PNG24:%s"):format(out_png),
      }
      local _2 = vim.fn.system(fix)
      if vim.v.shell_error == 0 then return true end
      vim.fn.rename(produced, out_png) -- fallback to pdftoppm output
      return true
    else
      vim.fn.rename(produced, out_png)
      return true
    end
  end

  return false, "no renderer (need convert or pdftoppm)"
end

--- Set a window-local statusline "name  %=  PDF X/Y".
---@param win integer
---@param name string
---@param page integer
---@param total integer
local function set_win_statusline(win, name, page, total)
  if vim.w[win].__pdf_stl_saved == nil then
    vim.w[win].__pdf_stl_saved = vim.wo[win].statusline
  end
  local base = vim.fn.fnamemodify(name, ":t")
  vim.wo[win].statusline = (" %s %%= PDF %d/%d "):format(base, page + 1, total)
end

--- Restore the previous window-local statusline for win.
---@param win integer
local function restore_win_statusline(win)
  local prev = vim.w[win].__pdf_stl_saved
  if prev ~= nil then
    vim.wo[win].statusline = prev
    vim.w[win].__pdf_stl_saved = nil
  else
    vim.wo[win].statusline = ""
  end
end

-- ===== Buffer/Window management =============================================

---@class PdfBufState
---@field src string
---@field page integer
---@field pages integer
---@field density integer
---@field png string
---@field win integer
---@field bufnr integer

--- Create/open the window for preview according to config.
---@param cfg PdfPreviewConfig
---@return integer win
local function open_window(cfg)
  local cur = vim.api.nvim_get_current_win()
  if cfg.open_mode == "split" then
    vim.cmd("belowright split")
  elseif cfg.open_mode == "tab" then
    vim.cmd("tabnew")
  else
    vim.cmd("vertical rightbelow split")
  end
  local win = vim.api.nvim_get_current_win()
  -- Return focus to original after creating split
  vim.api.nvim_set_current_win(cur)
  return win
end

--- Initialize scratch buffer in a window and return bufnr.
--- Fix: set modifiable=true while writing initial content, then lock again.
---@param win integer
---@return integer bufnr
local function init_scratch_buffer(win)
  local bufnr = vim.api.nvim_create_buf(false, true) -- listed=false, scratch=true
  vim.api.nvim_win_set_buf(win, bufnr)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "pdfpreview"
  vim.bo[bufnr].modifiable = true         -- allow writing the initial line
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "[PDF preview]" })
  vim.bo[bufnr].modifiable = false        -- lock it again
  return bufnr
end

--- Render current page and display via image_preview.nvim.
---@param st PdfBufState
---@param notify boolean
---@param cfg PdfPreviewConfig
local function render_and_show(st, notify, cfg)
  local ok, err = render_page(st.src, st.page, st.png, st.density, cfg)
  if not ok then
    restore_win_statusline(st.win)
    if notify then
      vim.notify(("PDF render failed: %s"):format(err or "unknown"), vim.log.levels.ERROR)
    end
    return
  end
  local ok_ip, ip = pcall(require, "image_preview")
  if not ok_ip then
    restore_win_statusline(st.win)
    vim.notify("image_preview.nvim not found", vim.log.levels.ERROR)
    return
  end
  -- Pin cursor to (1,1) for a stable overlay origin
  vim.api.nvim_win_call(st.win, function()
    pcall(vim.api.nvim_win_set_cursor, st.win, { 1, 1 })
    ip.PreviewImage(st.png)
  end)
  set_win_statusline(st.win, st.src, st.page, st.pages)
  if notify then
    vim.notify(("Page %d/%d"):format(st.page + 1, st.pages), vim.log.levels.INFO, { title = "PDF Preview" })
  end
end

--- Attach buffer-local keymaps for paging and quit.
---@param st PdfBufState
---@param cfg PdfPreviewConfig
local function attach_buf_keymaps(st, cfg)
  local opts = { buffer = st.bufnr, nowait = true, silent = true }
  vim.keymap.set("n", "<PageDown>", function()
    if st.page < st.pages - 1 then
      st.page = st.page + 1
      render_and_show(st, cfg.notify, cfg)
    else
      set_win_statusline(st.win, st.src, st.page, st.pages)
    end
  end, opts)
  vim.keymap.set("n", "<PageUp>", function()
    if st.page > 0 then
      st.page = st.page - 1
      render_and_show(st, cfg.notify, cfg)
    else
      set_win_statusline(st.win, st.src, st.page, st.pages)
    end
  end, opts)
  vim.keymap.set("n", "q", function()
    if cfg.clear_on_leave then
      restore_win_statusline(st.win)
    end
    if vim.api.nvim_win_is_valid(st.win) then
      pcall(vim.api.nvim_win_close, st.win, true)
    end
  end, opts)
  vim.keymap.set("n", "r", function()
    render_and_show(st, cfg.notify, cfg)
  end, opts)
end

-- ===== Public API ===========================================================

---@type PdfPreviewConfig
local default_cfg = {
  open_mode = "vsplit",
  density = 150,
  notify = true,
  clear_on_leave = true,
  backend = "image_preview",
  bg_hex = "#ffffff",  -- force pure white background by default
}

---@param cfg PdfPreviewConfig|nil
function M.setup(cfg)
  M.cfg = vim.tbl_deep_extend("force", {}, default_cfg, cfg or {})

  vim.api.nvim_create_user_command("PdfOpen", function(opts)
    local path = opts.args ~= "" and opts.args or vim.api.nvim_buf_get_name(0)
    if not is_pdf(path) then
      vim.notify("PdfOpen: not a PDF: " .. (path or ""), vim.log.levels.WARN)
      return
    end
    M.open(path)
  end, { nargs = "?", complete = "file" })

  vim.api.nvim_create_user_command("PdfNextPage", function()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "pdfpreview" then return end
    vim.api.nvim_feedkeys(vim.keycode("<PageDown>"), "n", false)
  end, {})

  vim.api.nvim_create_user_command("PdfPrevPage", function()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "pdfpreview" then return end
    vim.api.nvim_feedkeys(vim.keycode("<PageUp>"), "n", false)
  end, {})
end

--- Open a PDF path in a dedicated preview window/buffer.
---@param path string
function M.open(path)
  local cfg = M.cfg or default_cfg
  if not is_pdf(path) then
    vim.notify("pdf_preview.open: not a PDF: " .. tostring(path), vim.log.levels.WARN)
    return
  end
  if not (has_exec("convert") or has_exec("pdftoppm")) then
    vim.notify("Need ImageMagick (convert) or Poppler (pdftoppm)", vim.log.levels.ERROR)
    return
  end

  local win = open_window(cfg)
  local buf = init_scratch_buffer(win)
  local pages = read_page_count(path) or 1
  ---@type PdfBufState
  local st = {
    src = path,
    page = 0,
    pages = pages,
    density = cfg.density,
    png = png_path_for(win),
    win = win,
    bufnr = buf,
  }

  attach_buf_keymaps(st, cfg)
  render_and_show(st, cfg.notify, cfg)

  if cfg.clear_on_leave then
    vim.api.nvim_create_autocmd({ "WinClosed", "BufWipeout" }, {
      buffer = buf,
      once = true,
      callback = function()
        if vim.api.nvim_win_is_valid(win) then
          restore_win_statusline(win)
        end
      end,
    })
  end
end

--- Helper for Neo-tree: open current node if it's a PDF, else return false.
---@param state table
---@return boolean handled
function M.open_from_neotree(state)
  local node = state.tree:get_node()
  local path = node and (node.path or node:get_id()) or ""
  if is_pdf(path) then
    M.open(path)
    return true
  end
  return false
end

return M
