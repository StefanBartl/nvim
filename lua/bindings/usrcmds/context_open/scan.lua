---@module 'bindings.usrcmds.context_open.scan'
--- Line- and buffer-wide target scanning, shared by two callers:
---   - `context_open.open()`'s fallback when nothing sits directly under the
---     cursor (searches the rest of the current line)
---   - `context_open.list()` / M-O (searches the whole buffer)
--- Built on `open.viewer.scan` (open.nvim's own link/URL/path extractor)
--- rather than a second implementation of the same regexes, plus one entry
--- per markdown table. Does NOT include gopath-resolvable code identifiers --
--- there is no cheap whole-buffer API for those, and a flat list of every
--- resolvable symbol in a code file would not make a usable picker anyway.

local util = require("bindings.usrcmds.context_open.util")

local M = {}

---@internal
---@param bufnr integer
---@return table  Lib.Harvest.Source-shaped
local function source_for_buffer(bufnr)
  return {
    lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    first = 1,
    file = vim.api.nvim_buf_get_name(bufnr),
    bufnr = bufnr,
  }
end

---Turn one `open.viewer.scan` link into a context_open candidate, tagging
---images/PDFs with their dedicated action instead of the generic open.nvim
---dispatch.
---@internal
---@param lk table  OpenNvim.Viewer.Link
---@return ContextOpen.Candidate
local function candidate_from_link(lk)
  local label = ("%d: %s"):format(lk.lnum, lk.display)

  local ok_img, images_resolve = pcall(require, "images.resolve")
  if not lk.is_url and ok_img and images_resolve.is_image(lk.raw_target) then
    return {
      label = "image  " .. label,
      lnum = lk.lnum,
      col = lk.col,
      run = function()
        require("images").show(lk.target)
      end,
    }
  end

  if not lk.is_url and lk.raw_target and lk.raw_target:lower():match("%.pdf$") then
    return {
      label = "pdf    " .. label,
      lnum = lk.lnum,
      col = lk.col,
      run = function()
        vim.cmd("PdfPort text " .. vim.fn.fnameescape(lk.target))
      end,
    }
  end

  return {
    label = (lk.is_url and "url    " or "path   ") .. label,
    lnum = lk.lnum,
    col = lk.col,
    run = function()
      util.ensure_loaded("open.nvim")
      local ok_ctx, context = pcall(require, "open.context")
      local ok_reg, registry = pcall(require, "open.registry")
      local ok_cfg, config = pcall(require, "open.config")
      if not (ok_ctx and ok_reg and ok_cfg) then
        return
      end
      local cfg = config.get()
      local key = lk.is_url and cfg.default_browser or cfg.default_filemanager
      local ctx = context.resolve("path=" .. lk.target, key)
      if ctx then
        registry.dispatch(key, ctx)
      end
    end,
  }
end
M.candidate_from_link = candidate_from_link

---One entry per markdown table in `bufnr`.
---@internal
---@param bufnr integer
---@return ContextOpen.Candidate[]
local function table_candidates(bufnr)
  local ft = vim.bo[bufnr].filetype
  if ft ~= "markdown" and ft ~= "mdx" and ft ~= "md" then
    return {}
  end

  local ok, parser = pcall(require, "markdown.tableview.parser")
  if not ok then
    return {}
  end

  local out = {}
  for _, tbl in ipairs(parser.get_tables(bufnr)) do
    out[#out + 1] = {
      label = ("%d: table  toggle table view (%d row(s))"):format(
        tbl.start_line,
        #(tbl.rows or {})
      ),
      lnum = tbl.start_line,
      col = 0,
      run = function()
        vim.cmd("TableViewToggle")
      end,
    }
  end
  return out
end

---Every openable target in `bufnr`, sorted by line.
---@param bufnr integer|nil
---@return ContextOpen.Candidate[]
function M.buffer_targets(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  util.ensure_loaded("open.nvim")

  local out = {}
  local ok, viewer_scan = pcall(require, "open.viewer.scan")
  if ok then
    local links =
      viewer_scan.from_source(source_for_buffer(bufnr), { paths = true, code_fences = true })
    for _, lk in ipairs(links) do
      out[#out + 1] = candidate_from_link(lk)
    end
  end

  vim.list_extend(out, table_candidates(bufnr))

  table.sort(out, function(a, b)
    return (a.lnum or 0) < (b.lnum or 0)
  end)
  return out
end

---Every openable target on line `lnum` of the current buffer -- the M-o
---fallback when nothing is directly under the cursor.
---@param lnum integer
---@return ContextOpen.Candidate[]
function M.line_targets(lnum)
  util.ensure_loaded("open.nvim")
  local ok, viewer_scan = pcall(require, "open.viewer.scan")
  if not ok then
    return {}
  end

  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
  local base_dir = vim.fn.expand("%:p:h")
  local links = viewer_scan.from_line(line, lnum, { paths = true, base_dir = base_dir })

  local out = {}
  for _, lk in ipairs(links) do
    out[#out + 1] = candidate_from_link(lk)
  end
  return out
end

return M
