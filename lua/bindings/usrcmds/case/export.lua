---@module 'bindings.usrcmds.case.export'
--- Bundles a case's markdown (`Summary.md`/`Notes.md`/`Research/`/
--- `Replies/`) into one PDF (ROADMAP.md's `:Cases export`). Two external
--- tools, neither reimplemented: `pandoc` converts the bundled markdown to
--- standalone HTML — tables, nested lists, links, all the things a
--- hand-rolled converter would get wrong — then a headless Chrome/Edge
--- (already installed on this machine, no LaTeX/wkhtmltopdf/weasyprint
--- needed) prints that HTML to PDF via `--print-to-pdf`.
---
--- `pdfport.nvim` was the plugin ROADMAP.md originally named for this, but
--- its API only reads/opens existing PDFs (`M.open`/`M.extract`) — no
--- generation path at all, so it isn't used here.

local collect_recursive = require("lib.nvim.fs.collect_recursive")
local read = require("lib.nvim.fs.read")
local write_to_file = require("lib.nvim.fs.write.to_file")

local M = {}

local uv = vim.uv or vim.loop

--- Common install locations, checked after `executable()` — a headless
--- browser is not something users typically add to PATH themselves.
local BROWSER_CANDIDATES = {
  "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
  "C:/Program Files/Microsoft/Edge/Application/msedge.exe",
}

---@return string|nil
local function find_browser()
  if vim.fn.executable("chrome") == 1 then
    return "chrome"
  end
  if vim.fn.executable("msedge") == 1 then
    return "msedge"
  end
  for _, exe in ipairs(BROWSER_CANDIDATES) do
    if vim.fn.filereadable(exe) == 1 then
      return exe
    end
  end
  return nil
end

---@param entry Lib.Case.RegistryEntry
---@param m Lib.Case.Meta|nil
---@return string
local function bundle_markdown(entry, m)
  local parts = {
    ("# Case %s%s"):format(entry.short, (m and m.title) and (" - " .. m.title) or ""),
  }

  ---@param title string
  ---@param path string
  local function add_section(title, path)
    local content = read(path)
    if content then
      parts[#parts + 1] = "\n## " .. title .. "\n"
      parts[#parts + 1] = content
    end
  end

  add_section("Summary", entry.dir .. "/Summary.md")
  add_section("Notes", entry.dir .. "/Notes.md")

  ---@param title string
  ---@param dir string
  local function add_dir(title, dir)
    local st = uv.fs_stat(dir)
    if not (st and st.type == "directory") then
      return
    end
    local files = {}
    for _, f in ipairs(collect_recursive.files(dir)) do
      if f:match("%.md$") then
        files[#files + 1] = f
      end
    end
    table.sort(files)
    for _, f in ipairs(files) do
      add_section(title .. " / " .. vim.fn.fnamemodify(f, ":t:r"), f)
    end
  end

  add_dir("Research", entry.dir .. "/Research")
  add_dir("Replies", entry.dir .. "/Replies")

  return table.concat(parts, "\n")
end

---@class Lib.Case.ExportResult
---@field ok boolean
---@field path string|nil  Absolute PDF path, set on success.
---@field err string|nil

--- Async: `on_done` fires exactly once, from whichever step stops the
--- pipeline (a missing tool, a pandoc/browser failure, or success). Never
--- touches `vim.api`/`notify` itself — both external processes report
--- through `vim.system`'s own callback, which runs off the main loop, so
--- the caller is the one that has to `vim.schedule` anything UI-facing.
---@param entry Lib.Case.RegistryEntry
---@param m Lib.Case.Meta|nil
---@param on_done fun(result: Lib.Case.ExportResult)
function M.export(entry, m, on_done)
  if vim.fn.executable("pandoc") ~= 1 then
    -- The reason and the install command come out of docs/install.json
    -- rather than being restated here -- `lines` (not `check`) because this
    -- error travels back through `on_done`, and a notification alongside it
    -- would say the same thing twice. Falls back to the bare sentence when
    -- lib.nvim.deps is unavailable.
    local ok_rt, rt = pcall(require, "lib.nvim.deps.require_tool")
    local err = ok_rt and table.concat(rt.lines("nvim", "pandoc"), " ")
      or "pandoc not found on PATH"
    on_done({ ok = false, err = err .. " (just installed? restart nvim)" })
    return
  end
  local browser = find_browser()
  if not browser then
    on_done({ ok = false, err = "no Chrome/Edge found for headless PDF printing" })
    return
  end

  local md = bundle_markdown(entry, m)
  local tmp_md = vim.fn.tempname() .. ".md"
  local tmp_html = vim.fn.tempname() .. ".html"
  local pdf_path = entry.dir .. "/Export.pdf"

  local ok_write, werr = write_to_file(tmp_md, md)
  if not ok_write then
    on_done({ ok = false, err = "could not write bundled markdown: " .. tostring(werr) })
    return
  end

  vim.system({ "pandoc", tmp_md, "-s", "-o", tmp_html }, { text = true }, function(pandoc_result)
    if pandoc_result.code ~= 0 then
      uv.fs_unlink(tmp_md)
      on_done({ ok = false, err = "pandoc failed: " .. (pandoc_result.stderr or "unknown error") })
      return
    end

    vim.system({
      browser,
      "--headless",
      "--disable-gpu",
      "--no-pdf-header-footer",
      "--print-to-pdf=" .. pdf_path,
      tmp_html,
    }, { text = true }, function(browser_result)
      uv.fs_unlink(tmp_md)
      uv.fs_unlink(tmp_html)

      if browser_result.code ~= 0 or not uv.fs_stat(pdf_path) then
        on_done({
          ok = false,
          err = "pdf printing failed: " .. (browser_result.stderr or "unknown error"),
        })
        return
      end
      on_done({ ok = true, path = pdf_path })
    end)
  end)
end

return M
