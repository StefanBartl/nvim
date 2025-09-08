---@module 'config.image_preview.pdf.buffer'
---@brief Open PDFs as page-rendered images in a scratch buffer/split with paging keymaps.
---@description
--- This module renders PDF pages to PNG (via ImageMagick `convert` or Poppler `pdftoppm`/`pdfinfo`)
--- and displays them using `image_preview.nvim` inside a dedicated scratch buffer. It keeps focus
--- in the origin window if configured, shows a window-local statusline ("PDF X/Y"), and provides
--- paging keymaps. It applies defensive checks (type guards, handle validation), follows the
--- project's review checklist, and minimizes low-level notifications.
---
--- Public API:
---   require('config.image_preview.pdf.buffer').setup({ ... })
---   require('config.image_preview.pdf.buffer').open('/path/to/file.pdf')
---   require('config.image_preview.pdf.buffer').open_from_neotree(state)
---
--- Commands:
---   :PdfOpen [file]     -- open current buffer file or given file if it's a PDF
---   :PdfNextPage        -- go to next page within a pdfpreview buffer
---   :PdfPrevPage        -- go to previous page within a pdfpreview buffer
---
--- Notes:
---   * Either ImageMagick (convert, identify) or Poppler (pdftoppm, pdfinfo) must be present.
---   * PNGs are written to stdpath('cache'); per-window filenames avoid collisions.


-- Somewhere in your keymaps
-- vim.keymap.set("n", "<leader>op", function()
--   local nt = require("neo-tree.sources.manager")
--   local state = nt.get_state("filesystem")
--   require("config.image_preview.pdf.buffer").open_from_neotree(state)
-- end, { desc = "Open PDF preview for Neo-tree node" })



---@alias PdfOpenMode "vsplit"|"split"|"tab"
---@alias PdfRendererBackend "image_preview"

---@class PdfPreviewConfig
---@field open_mode PdfOpenMode                 -- where to open the preview
---@field focus boolean                         -- keep focus in the new window (true) or stay (false)
---@field density integer                       -- render DPI
---@field notify boolean                        -- user notifications on page changes/errors
---@field clear_on_leave boolean                -- restore statusline and optionally cleanup
---@field backend? PdfRendererBackend            -- future extension; currently fixed
---@field bg_hex string                         -- opaque background color for PNG (e.g. "#ffffff")
---@field cleanup_png boolean                   -- remove generated PNG when closing the window

---@class PdfBufState
---@field src string
---@field page integer
---@field pages integer
---@field density integer
---@field png string
---@field win integer
---@field bufnr integer

local M = {}

-- =============================================================================
-- Utilities (type guards, OS integration)
-- =============================================================================

--- Return true if an executable exists in $PATH.
---@param bin string
---@return boolean
local function has_exec(bin)
  return vim.fn.executable(bin) == 1
end

--- Ensure a directory exists (mkdir -p).
---@param dir string
---@return boolean ok
local function ensure_dir(dir)
  if type(dir) ~= "string" or dir == "" then return false end
  return vim.fn.mkdir(dir, "p") == 1 or vim.fn.isdirectory(dir) == 1
end

--- Make a per-window PNG path (avoids collisions across windows).
---@param winid integer
---@return string
local function png_path_for(winid)
  local cache = vim.fn.stdpath("cache")
  ensure_dir(cache) -- best-effort
  return ("%s/pdf_preview_%d.png"):format(cache, winid)
end

--- Case-insensitive endswith.
---@param p string
---@param ext string
---@return boolean
local function endswith(p, ext)
  if type(p) ~= "string" or type(ext) ~= "string" then return false end
  if #p < #ext then return false end
  p = p:lower()
  return p:sub(-#ext) == ext
end

--- Is a readable local PDF path?
---@param path string
---@return boolean
local function is_pdf_file(path)
  if not endswith(path or "", ".pdf") then return false end
  return vim.fn.filereadable(path) == 1
end

--- Read total page count using pdfinfo (preferred) or identify.
---@param pdf string
---@return integer|nil
local function read_page_count(pdf)
  if has_exec("pdfinfo") then
    local lines = vim.fn.systemlist({ "pdfinfo", pdf })
    if vim.v.shell_error == 0 then
      for i = 1, #lines do
        local n = tonumber((lines[i] or ""):match("^Pages:%s+(%d+)%s*$"))
        if n and n > 0 then return n end
      end
    end
  end
  if has_exec("identify") then
    local out = vim.fn.systemlist({ "identify", "-format", "%n", pdf })
    if vim.v.shell_error == 0 and type(out[1]) == "string" then
      local n = tonumber(out[1])
      if n and n > 0 then return n end
    end
  end
  return nil
end

--- Clamp a numeric value to [lo, hi].
---@param v number
---@param lo number
---@param hi number
---@return number
local function clamp(v, lo, hi)
  if type(v) ~= "number" then return lo end
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

-- =============================================================================
-- Rendering
-- =============================================================================

-- Return a valid opaque background color; fallback to white.
---@param cfg PdfPreviewConfig|nil
---@return string
local function get_bg_hex(cfg)
  -- Accept only non-empty strings, otherwise default to white.
  local s = (cfg and cfg.bg_hex) or "#ffffff"
  if type(s) == "string" and s ~= "" then
    return s
  end
  return "#ffffff"
end


--- Render one page (0-based) to a PNG with opaque background.
---@param pdf string
---@param page integer
---@param out_png string
---@param density integer
---@param cfg PdfPreviewConfig
---@return boolean ok, string|nil err
local function render_page(pdf, page, out_png, density, cfg)
  local bg = get_bg_hex(cfg)

  local function convert_bin()
    local os = vim.loop.os_uname().sysname
    if os == "Windows_NT" and has_exec("magick") then return "magick" end
    return has_exec("convert") and "convert" or nil
  end

  -- Try ImageMagick / magick first
  local conv = convert_bin()
  if conv then
    local cmd = {
      conv,
      "-density", tostring(density),
      ("%s[%d]"):format(pdf, page),           -- 0-based page index for IM
      "-background", bg, "-alpha", "remove", "-alpha", "off",
      "-flatten", "-strip",
      ("PNG24:%s"):format(out_png),
    }
    _ = vim.fn.system(cmd)
    if vim.v.shell_error == 0 then return true end
  end

  -- Fallback: Poppler
  if has_exec("pdftoppm") then
    local base = out_png:gsub("%.png$", "")
    local cmd = { "pdftoppm", "-png", "-f", tostring(page + 1), "-l", tostring(page + 1), pdf, base }
    _ = vim.fn.system(cmd)
    local produced = string.format("%s-%d.png", base, page + 1)  -- correct filename
    if vim.v.shell_error ~= 0 or vim.fn.filereadable(produced) ~= 1 then
      return false, "pdftoppm failed"
    end
    if conv then
      local fix = {
        conv, produced,
        "-background", bg, "-alpha", "remove", "-alpha", "off",
        "-flatten", "-strip",
        ("PNG24:%s"):format(out_png),
      }
      _ = vim.fn.system(fix)
      if vim.v.shell_error == 0 then return true end
      pcall(vim.fn.rename, produced, out_png)
      return true
    else
      pcall(vim.fn.rename, produced, out_png)
      return true
    end
  end

  return false, conv and "convert failed" or "no renderer (need convert/magick or pdftoppm)"
end

-- =============================================================================
-- Window/Buffer management
-- =============================================================================

--- Set a window-local statusline "name  %=  PDF X/Y".
---@param win integer
---@param name string
---@param page integer
---@param total integer
local function set_win_statusline(win, name, page, total)
  if vim.w[win].__pdf_stl_saved == nil then
    vim.w[win].__pdf_stl_saved = vim.wo[win].statusline
  end
  local base = vim.fn.fnamemodify(name or "", ":t")
  vim.wo[win].statusline = (" %s %%= PDF %d/%d "):format(base, page + 1, total)
end

--- Restore previous window-local statusline.
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

--- Create/open the preview window according to config.
---@param cfg PdfPreviewConfig
---@return integer|nil win
local function open_window(cfg)
  local origin = vim.api.nvim_get_current_win()
  local mode = (cfg and cfg.open_mode) or "vsplit"

  if mode == "split" then
    vim.cmd("belowright split")
  elseif mode == "tab" then
    vim.cmd("tabnew")
  else
    vim.cmd("vsplit")
    vim.cmd("wincmd L") -- far right; drop if undesired
  end

  local win = vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then return nil end

  if cfg and cfg.focus == false then
    if vim.api.nvim_win_is_valid(origin) then
      vim.api.nvim_set_current_win(origin) -- keep focus (e.g., stay in Neo-tree)
    end
  end
  return win
end

--- Initialize a scratch buffer in a window and return its handle.
---@param win integer
---@return integer|nil bufnr
local function init_scratch_buffer(win)
  if not vim.api.nvim_win_is_valid(win) then return nil end
  local bufnr = vim.api.nvim_create_buf(false, true) -- listed=false, scratch=true
  vim.api.nvim_win_set_buf(win, bufnr)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "pdfpreview"
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "[PDF preview]" }) ---@type string[]
  vim.bo[bufnr].modifiable = false
  return bufnr
end

--- Render current page and display via image_preview.nvim in window st.win.
---@param st PdfBufState
---@param notify boolean
---@param cfg PdfPreviewConfig
local function render_and_show(st, notify, cfg)
  if not (vim.api.nvim_win_is_valid(st.win) and vim.api.nvim_buf_is_valid(st.bufnr)) then
    return
  end

  local ok, err = render_page(st.src, st.page, st.png, st.density, cfg)
  if not ok then
    restore_win_statusline(st.win)
    if notify then
      vim.notify(("PDF render failed: %s"):format(err or "unknown"), vim.log.levels.ERROR)
    end
    return
  end

  local ok_ip, ip = pcall(require, "image_preview")
  if not ok_ip or type(ip) ~= "table" or type(ip.PreviewImage) ~= "function" then
    restore_win_statusline(st.win)
    if notify then
      vim.notify("image_preview.nvim not found or incompatible", vim.log.levels.ERROR)
    end
    return
  end

  -- Draw inside the target window without stealing global focus.
  if vim.api.nvim_win_is_valid(st.win) then
    vim.api.nvim_win_call(st.win, function()
      pcall(vim.api.nvim_win_set_cursor, st.win, { 1, 1 })
      pcall(ip.PreviewImage, st.png)
    end)
  end

  set_win_statusline(st.win, st.src, st.page, st.pages)
  if notify then
    vim.notify(("Page %d/%d"):format(st.page + 1, st.pages), vim.log.levels.INFO, { title = "PDF Preview" })
  end
end

--- Attach buffer-local keymaps for paging, refresh, and quit.
---@param st PdfBufState
---@param cfg PdfPreviewConfig
local function attach_buf_keymaps(st, cfg)
  if not vim.api.nvim_buf_is_valid(st.bufnr) then return end
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

  -- Alternatives when terminal intercepts PageUp/Down
  vim.keymap.set("n", "]p", function()
    if st.page < st.pages - 1 then
      st.page = st.page + 1
      render_and_show(st, cfg.notify, cfg)
    end
  end, opts)
  vim.keymap.set("n", "[p", function()
    if st.page > 0 then
      st.page = st.page - 1
      render_and_show(st, cfg.notify, cfg)
    end
  end, opts)

  -- Refresh current page
  vim.keymap.set("n", "r", function()
    render_and_show(st, cfg.notify, cfg)
  end, opts)

  -- Quit this preview window
  vim.keymap.set("n", "q", function()
    if cfg.clear_on_leave then
      restore_win_statusline(st.win)
    end
    if cfg.cleanup_png and type(st.png) == "string" and st.png ~= "" then
      pcall(vim.fn.delete, st.png)
    end
    if vim.api.nvim_win_is_valid(st.win) then
      pcall(vim.api.nvim_win_close, st.win, true)
    end
  end, opts)
end

-- =============================================================================
-- Public API
-- =============================================================================

---@type PdfPreviewConfig
local default_cfg = {
  open_mode = "vsplit",
  focus = false,
  density = 150,
  notify = true,
  clear_on_leave = true,
  backend = "image_preview",
  bg_hex = "#ffffff",
  cleanup_png = false,
}

--- Configure the module.
---@param cfg PdfPreviewConfig|nil
---@return nil
function M.setup(cfg)
  M.cfg = vim.tbl_deep_extend("force", {}, default_cfg, cfg or {})

  vim.api.nvim_create_user_command("PdfOpen", function(opts)
    local path = (opts.args ~= "" and opts.args) or vim.api.nvim_buf_get_name(0)
    if not is_pdf_file(path) then
      vim.notify("PdfOpen: not a readable PDF: " .. (path or ""), vim.log.levels.WARN)
      return
    end
    M.open(path)
  end, { nargs = "?", complete = "file" })

  vim.api.nvim_create_user_command("PdfNextPage", function()
    local win = vim.api.nvim_get_current_win()
    if not vim.api.nvim_win_is_valid(win) then return end
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "pdfpreview" then return end
    vim.api.nvim_feedkeys(vim.keycode("]p"), "n", false)
  end, {})

  vim.api.nvim_create_user_command("PdfPrevPage", function()
    local win = vim.api.nvim_get_current_win()
    if not vim.api.nvim_win_is_valid(win) then return end
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "pdfpreview" then return end
    vim.api.nvim_feedkeys(vim.keycode("[p"), "n", false)
  end, {})
end

--- Open a PDF path in a dedicated preview window/buffer.
---@param path string
---@return nil
function M.open(path)
  local cfg = M.cfg or default_cfg
  if type(path) ~= "string" or path == "" then
    vim.notify("pdf_preview.open: missing path", vim.log.levels.WARN)
    return
  end
  if not is_pdf_file(path) then
    vim.notify("pdf_preview.open: not a readable PDF: " .. tostring(path), vim.log.levels.WARN)
    return
  end
  if not (has_exec("convert") or has_exec("pdftoppm")) then
    vim.notify("Need ImageMagick (convert) or Poppler (pdftoppm)", vim.log.levels.ERROR)
    return
  end

  local win = open_window(cfg)
  if not win then
    vim.notify("Failed to create preview window", vim.log.levels.ERROR)
    return
  end

  local buf = init_scratch_buffer(win)
  if not buf then
    vim.notify("Failed to create preview buffer", vim.log.levels.ERROR)
    return
  end

  local pages = read_page_count(path) or 1
  local density = clamp(tonumber(cfg.density) or 150, 72, 600)

  ---@type PdfBufState
  local st = {
    src = path,
    page = 0,
    pages = pages,
    density = density,
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
        if cfg.cleanup_png and type(st.png) == "string" and st.png ~= "" then
          pcall(vim.fn.delete, st.png)
        end
      end,
    })
  end
end

--- Helper for Neo-tree: open current node if it's a PDF, else return false.
---@param state table
---@return boolean handled
function M.open_from_neotree(state)
  local ok = state and state.tree and type(state.tree.get_node) == "function"
  if not ok then return false end
  local node = state.tree:get_node()
  local path = node and (node.path or (type(node.get_id) == "function" and node:get_id()) or "") or ""
  if is_pdf_file(path) then
    M.open(path)
    return true
  end
  return false
end

return M
