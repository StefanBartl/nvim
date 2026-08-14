---@module 'bindings.usrcmds.context_open.scan'
--- Line- and buffer-wide target scanning, shared by two callers:
---   - `context_open.open()`'s fallback when nothing sits directly under the
---     cursor (searches the rest of the current line)
---   - `context_open.list()` / M-O (searches the whole buffer)
--- Built on `open.viewer.scan` (open.nvim's own link/URL/path extractor)
--- rather than a second implementation of the same regexes, plus one entry
--- per markdown table and one per gopath-resolvable import/require/include
--- line (see `gopath_import_candidates` for why it stops at import lines
--- and does not probe every identifier in the buffer).

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

---Lines that look like an import/require/include statement across the
---languages gopath.nvim's `languages` config table knows about. A cheap,
---deliberately approximate pre-filter -- see `gopath_import_candidates` for
---why the actual resolution stays scoped to just these lines.
---@internal
local IMPORT_PATTERNS = {
  "^%s*import%s",
  "^%s*from%s+%S+%s+import%s",
  "require%s*%(",
  "require%s+[\"']",
  '^%s*#include%s*[<"]',
  "^%s*use%s+",
  "^%s*using%s+",
}

---Column (0-indexed) to place the cursor on for `gopath.resolve()` to see
---the actual module/path token, not the `import`/`require`/`use` keyword
---itself -- landing on the keyword resolves to nonsense (e.g. "local", the
---preceding Lua keyword, treated as a bogus non-existent file). Prefers the
---first quote or `<` on the line (covers `require("x")`, `import "x"`,
---`#include <x>`/`"x"`, `@import("x")`); falls back to the first non-space
---character after the matched keyword for unquoted styles (Rust `use`,
---Python `import`, C# `using`).
---@internal
---@param line string
---@return integer|nil col  nil when the line doesn't look like an import at all
local function import_target_col(line)
  for _, pat in ipairs(IMPORT_PATTERNS) do
    local s, e = line:find(pat)
    if s then
      local quote = line:find("[\"'<]", s)
      if quote then
        return quote
      end
      local rest = line:sub(e + 1)
      local ws = rest:match("^%s*") or ""
      return e + #ws
    end
  end
  return nil
end

---gopath-resolvable import/require/include lines in `bufnr`.
---
---Unlike every other M-O source, this genuinely moves the real cursor:
---`gopath.resolve()` has no position-parameter API, it always reads
---`nvim_win_get_cursor` internally (see gopath.nvim's `resolve_at_cursor`).
---The original cursor position is restored once scanning finishes.
---
---Deliberately scoped to lines that look like an import rather than every
---token in the buffer: this config runs gopath in `mode = "hybrid"`
---(`order = {"lsp","treesitter","builtin"}`, `lsp_timeout_ms = 200`), so a
---resolve() that falls through to the LSP stage costs a real synchronous
---round-trip. Import lines are almost always caught by gopath's cheap
---filetoken/linepath steps before that stage is ever reached; probing every
---identifier in a code file would not be, and could block M-O opening on
---dozens of LSP calls.
---@internal
---@param bufnr integer
---@return ContextOpen.Candidate[]
local function gopath_import_candidates(bufnr)
  if bufnr ~= vim.api.nvim_get_current_buf() then
    return {} -- resolve_at_cursor only ever sees the current window/buffer
  end
  local ok_gopath, gopath = pcall(require, "gopath")
  if not ok_gopath then
    return {}
  end

  local win = vim.api.nvim_get_current_win()
  local original = vim.api.nvim_win_get_cursor(win)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local out = {}
  for lnum, line in ipairs(lines) do
    local col = import_target_col(line)
    if col then
      if pcall(vim.api.nvim_win_set_cursor, win, { lnum, col }) then
        local ok_res, res = pcall(gopath.resolve)
        -- `exists == false` is gopath's own last-resort "raw cfile, nothing
        -- actually found" fallback (see gopath.resolve's step 6) -- not
        -- worth surfacing as an openable target.
        if ok_res and res and res.exists ~= false then
          out[#out + 1] = {
            label = ("%d: gopath  %s"):format(lnum, res.path or res.subject or "?"),
            lnum = lnum,
            col = col,
            run = function()
              gopath.commands.resolve_and_open("edit")
            end,
          }
        end
      end
    end
  end

  pcall(vim.api.nvim_win_set_cursor, win, original)
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
  vim.list_extend(out, gopath_import_candidates(bufnr))

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
