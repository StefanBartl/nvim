---@module 'bindings.usrcmds.context_open.providers'
--- Cursor-context providers for `context_open.open()` (M-o / :ContextOpen).
--- Each provider is `fun(signals: OpenNvim.Signals): ContextOpen.Candidate[]`
--- -- read-only detection, zero to many candidates, never throws (callers
--- pcall it anyway as a second line of defence).
---@see bindings.usrcmds.context_open.README for the full design rationale.

local util = require("bindings.usrcmds.context_open.util")

local M = {}

---@class ContextOpen.Candidate
---@field label string
---@field lnum? integer
---@field col? integer
---@field run fun()

-- ---------------------------------------------------------------------------
-- open.nvim -- browser / filemanager / notepad / split / vsplit / tab / …
-- ---------------------------------------------------------------------------

---Whether open.nvim's own signals contain anything for it to work with.
---Deliberately excludes the "nothing found, fall back to reveal-buffer-in-
---filemanager" case: that catch-all isn't really "something under the
---cursor", and treating it as a candidate would make `#candidates > 0`
---always true, permanently disabling the line-search fallback below.
---@internal
---@param signals table
---@return boolean
local function has_open_target(signals)
  if signals.tree_path then
    return true
  end
  if signals.cfile and signals.cfile ~= "" then
    return true
  end
  if signals.cword and signals.cword ~= "" then
    return true
  end
  return false
end

---Extensions a more specific provider already owns (images.nvim, pdfport.nvim):
---open.nvim's generic split/vsplit/tab candidates for these would just load
---raw image/PDF bytes into a text buffer, which nobody wants.
---@internal
---@param path string|nil
---@return boolean
local function owned_extension(path)
  if not path then
    return false
  end
  local ext = path:match("%.([%w]+)$")
  if not ext then
    return false
  end
  ext = ext:lower()
  if ext == "pdf" then
    return true
  end
  local ok, images_cfg = pcall(function()
    return require("images.config").get()
  end)
  if ok and images_cfg.extensions then
    for _, e in ipairs(images_cfg.extensions) do
      if e:lower() == ext then
        return true
      end
    end
  end
  return false
end

---@param signals table
---@return ContextOpen.Candidate[]
function M.open_nvim(signals)
  if not has_open_target(signals) then
    return {}
  end

  util.ensure_loaded("open.nvim")
  local ok_ctx, context = pcall(require, "open.context")
  local ok_reg, registry = pcall(require, "open.registry")
  if not (ok_ctx and ok_reg) then
    return {}
  end

  if owned_extension(signals.cfile_path) then
    return {}
  end

  local out = {}
  for _, key in ipairs(context.candidate_targets(signals)) do
    local handler = registry.get(key)
    if handler then
      out[#out + 1] = {
        label = ("open: %s — %s"):format(key, handler.desc),
        run = function()
          local ctx = context.resolve(nil, key, signals)
          if ctx then
            registry.dispatch(key, ctx)
          end
        end,
      }
    end
  end
  return out
end

-- ---------------------------------------------------------------------------
-- gopath.nvim -- gF equivalent
-- ---------------------------------------------------------------------------

---@param _signals table
---@return ContextOpen.Candidate[]
function M.gopath(_signals)
  local ok, gopath = pcall(require, "gopath")
  if not ok then
    return {}
  end

  local res = gopath.resolve()
  if not res then
    return {}
  end

  local what = res.path or res.subject or "target"
  return {
    {
      label = ("gopath: open %s (%s)"):format(what, res.kind or "?"),
      run = function()
        gopath.commands.resolve_and_open("edit")
      end,
    },
  }
end

-- ---------------------------------------------------------------------------
-- markdown.nvim -- TableView toggle
-- ---------------------------------------------------------------------------

---@param _signals table
---@return ContextOpen.Candidate[]
function M.markdown_table(_signals)
  local ft = vim.bo.filetype
  if ft ~= "markdown" and ft ~= "mdx" and ft ~= "md" then
    return {}
  end
  if vim.fn.exists(":TableViewToggle") ~= 2 then
    return {}
  end

  local ok, parser = pcall(require, "markdown.tableview.parser")
  if not ok then
    return {}
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  for _, tbl in ipairs(parser.get_tables(0)) do
    if line >= tbl.start_line and line <= tbl.end_line then
      return {
        {
          label = "markdown: toggle table view",
          run = function()
            vim.cmd("TableViewToggle")
          end,
        },
      }
    end
  end
  return {}
end

-- ---------------------------------------------------------------------------
-- images.nvim -- show image under cursor
-- ---------------------------------------------------------------------------

---@param _signals table
---@return ContextOpen.Candidate[]
function M.images(_signals)
  local ok, resolve = pcall(require, "images.resolve")
  if not ok then
    return {}
  end

  local target = resolve.under_cursor()
  if not target then
    return {}
  end

  return {
    {
      label = "images: show image",
      run = function()
        require("images").hover()
      end,
    },
  }
end

-- ---------------------------------------------------------------------------
-- pdfport.nvim -- PDF under cursor: system viewer, or extract to buffer
-- ---------------------------------------------------------------------------

---Pure filesystem check -- deliberately does NOT require pdfport.nvim's own
---modules, so detection works even before the (cmd-only, not ft-gated)
---plugin has ever been loaded.
---@internal
---@param signals table
---@return string|nil abs
local function pdf_path_under_cursor(signals)
  local candidate = signals.cfile_path or signals.cfile
  if not candidate or candidate == "" then
    return nil
  end
  local abs = vim.fn.fnamemodify(vim.fn.expand(candidate), ":p")
  if not abs:lower():match("%.pdf$") then
    return nil
  end
  if vim.uv.fs_stat(abs) then
    return abs
  end
  return nil
end

---@param signals table
---@return ContextOpen.Candidate[]
function M.pdfport(signals)
  local path = pdf_path_under_cursor(signals)
  if not path then
    return {}
  end

  return {
    {
      label = "open: default — system PDF viewer",
      run = function()
        util.ensure_loaded("open.nvim")
        local ok_ctx, context = pcall(require, "open.context")
        local ok_reg, registry = pcall(require, "open.registry")
        if not (ok_ctx and ok_reg) then
          return
        end
        local ctx = context.resolve("path=" .. path, "default")
        if ctx then
          registry.dispatch("default", ctx)
        end
      end,
    },
    {
      label = "pdfport: extract text to buffer",
      run = function()
        vim.cmd("PdfPort text " .. vim.fn.fnameescape(path))
      end,
    },
  }
end

-- ---------------------------------------------------------------------------
-- Aggregation
-- ---------------------------------------------------------------------------

--- Deliberate, fixed order -- also the ambiguity picker's display order.
--- gopath and the file-type-specific providers (markdown/images/pdfport)
--- come before open.nvim's generic candidates, so a specific match outranks
--- "reveal in file manager" at a glance.
M.ORDER = { M.gopath, M.markdown_table, M.images, M.pdfport, M.open_nvim }

---Run every provider against `signals`, concatenating their candidates.
---@param signals table
---@return ContextOpen.Candidate[]
function M.collect(signals)
  local out = {}
  for _, provider in ipairs(M.ORDER) do
    local ok, candidates = pcall(provider, signals)
    if ok and candidates then
      for _, c in ipairs(candidates) do
        out[#out + 1] = c
      end
    end
  end
  return out
end

return M
