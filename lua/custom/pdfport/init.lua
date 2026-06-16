---@module 'custom.pdfport'
---@brief Public API entry point for pdfport.
---@description
--- pdfport is a Neovim module that extracts and displays PDF content
--- using a pluggable backend/renderer architecture.
---
--- [README.md](custom/pdfport/docs/README.md)
--- Quick start:
---
---   require("custom.pdfport").setup({
---     default_backend = "auto",
---     fallback_chain  = { "pdftotext", "marker", "docling", "claude" },
---   })
---
--- Open a PDF from Lua:
---
---   require("custom.pdfport").open({
---     path       = "/path/to/file.pdf",
---     mode       = "buffer",  -- "buffer"|"float"|"terminal"|"system"
---     backend_id = "marker",  -- optional; nil = auto
---   })
---
--- Extract text only (without rendering):
---
---   require("custom.pdfport").extract({
---     path       = "/path/to/file.pdf",
---     max_pages  = 5,
---     __callback = function(result) ... end,
---   })

local M = {}

-- #############################################################################
-- Default configuration
-- #############################################################################

---@type PdfPort.Config
local DEFAULT_CONFIG = {
  default_backend = "auto",
  fallback_chain  = {
    "pdftotext",
    "pdfplumber",
    "marker",
    "docling",
    "ollama",
    "claude",
  },
  extract_opts = {
    max_pages   = nil,
    timeout_ms  = 30000,
  },
  render_opts = {
    mode   = "buffer",
    split  = "vsplit",
    focus  = true,
  },
  claude_api_key = nil, -- falls back to $ANTHROPIC_API_KEY
  ollama_host    = "http://localhost:11434",
  ollama_model   = "llava",
  debug          = false,
}

---@type PdfPort.Config
local _config = vim.deepcopy(DEFAULT_CONFIG)

---@type boolean
local _initialized = false

-- #############################################################################
-- Setup
-- #############################################################################

--- Initializes pdfport with user-provided configuration.
--- Must be called once before using open() or extract().
---@param user_config? PdfPort.Config
---@return nil
function M.setup(user_config)
  _config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, user_config or {})

  -- Share config with sub-modules that need it
  require("custom.pdfport.core.resolver")._set_config(_config)
  require("custom.pdfport.core.dispatcher")._set_config(_config)

  -- Share API key with claude backend if loaded
  local ok_claude, claude = pcall(require, "custom.pdfport.backends.claude")
  if ok_claude and type(claude._set_config) == "function" then
    claude._set_config(_config)
  end

  -- Load and register all built-in backends
  require("custom.pdfport.backends").load_all()

  -- Register built-in renderers
  local reg = require("custom.pdfport.core.registry")

  local ok_buf,  buf_mod  = pcall(require, "custom.pdfport.renderers.buffer")
  local ok_flt,  flt_mod  = pcall(require, "custom.pdfport.renderers.float")
  local ok_sys,  sys_mod  = pcall(require, "custom.pdfport.renderers.system")
  local ok_term, term_mod = pcall(require, "custom.pdfport.renderers.terminal")

  if ok_buf  then reg.register_renderer("buffer",   buf_mod.render)  end
  if ok_flt  then reg.register_renderer("float",    flt_mod.render)  end
  if ok_sys  then reg.register_renderer("system",   sys_mod.render)  end
  if ok_term then reg.register_renderer("terminal", term_mod.render) end

  -- Register user commands
  M._register_commands()

  _initialized = true

  if _config.debug then
    vim.notify("pdfport: initialized", vim.log.levels.DEBUG)
  end
end

-- #############################################################################
-- Public API
-- #############################################################################

--- Opens a PDF file using the specified mode and backend.
--- If setup() has not been called, it is called with defaults.
---@param opts PdfPort.OpenOpts
---@return nil
function M.open(opts)
  if not _initialized then
    M.setup()
  end

  assert(type(opts) == "table", "pdfport.open: opts must be a table")
  assert(type(opts.path) == "string" and opts.path ~= "", "pdfport.open: opts.path must be a non-empty string")

  require("custom.pdfport.core.dispatcher").open(opts)
end

--- Extracts text from a PDF and delivers it to a callback.
--- Does not render anything; useful for integrations (telescope, fzf).
---@param opts PdfPort.InternalExtractOpts
---@return nil
function M.extract(opts)
  if not _initialized then
    M.setup()
  end

  assert(type(opts) == "table", "pdfport.extract: opts must be a table")
  assert(type(opts.path) == "string", "pdfport.extract: opts.path must be a string")
  assert(type(opts.__callback) == "function", "pdfport.extract: opts.__callback must be a function")

  require("custom.pdfport.core.dispatcher").dispatch(opts, opts.__callback)
end

--- Returns the active configuration (read-only copy).
---@return PdfPort.Config
function M.config()
  return vim.deepcopy(_config)
end

--- Returns the Neo-tree integration module.
---@return table  Module with commands() and keymaps()
function M.neotree()
  return require("custom.pdfport.integrations.neotree")
end

--- Returns the Telescope integration module.
---@return table  Module with previewer() and filetype_hook
function M.telescope()
  return require("custom.pdfport.integrations.telescope")
end

--- Returns the fzf-lua integration module.
---@return table  Module with preview_fn()
function M.fzf()
  return require("custom.pdfport.integrations.fzf")
end

--- Registers a custom backend.
---@param backend PdfPort.Backend
---@return nil
function M.register_backend(backend)
  require("custom.pdfport.core.registry").register_backend(backend)
end

-- #############################################################################
-- User commands
-- #############################################################################

--- Registers Neovim user commands for pdfport.
---@return nil
function M._register_commands()
  -- Autocompletion: gibt Dateien/Verzeichnisse passend zum aktuellen Argument zurück,
  -- mit PDF-Vorschlag wenn kein Argument geschrieben wurde (cfile-Konvention).
  ---@param arg_lead string
  ---@return string[]
  local function complete_pdf_path(arg_lead)
    if arg_lead == "" then
      -- Zeige cfile als ersten Vorschlag
      local cfile = vim.fn.expand("<cfile>")
      if cfile and cfile ~= "" and vim.fn.filereadable(cfile) == 1 then
        return { cfile }
      end
      return {}
    end
    -- Standard-Dateisystem-Completion (Verzeichnisse + Dateien)
    local completions = vim.fn.glob(arg_lead .. "*", false, true)
    -- PDFs oben hinstellen
    local pdfs, rest = {}, {}
    for _, p in ipairs(completions) do
      if p:lower():match("%.pdf$") then
        pdfs[#pdfs + 1] = p
      else
        rest[#rest + 1] = p
      end
    end
    vim.list_extend(pdfs, rest)
    return pdfs
  end

  -- Gemeinsamer Pfad-Resolver:
  --   1. Explizites Argument (args.args)
  --   2. Wort unter Cursor (<cfile>)
  --   3. Aktueller Buffer-Name
  ---@param args table  vim.api.nvim_create_user_command callback args
  ---@return string|nil path
  local function resolve_path(args)
    -- Explizites Argument hat höchste Priorität
    if args.args and args.args ~= "" then
      return vim.fn.expand(args.args)
    end

    -- cfile: Pfad unter dem Cursor (funktioniert in jedem Buffer,
    -- also auch in Quickfix, Terminal, normalem Text usw.)
    local cfile = vim.fn.expand("<cfile>")
    if cfile and cfile ~= "" then
      -- Absoluten Pfad versuchen; wenn nicht lesbar → trotzdem weitergeben
      local abs = vim.fn.fnamemodify(cfile, ":p")
      if vim.fn.filereadable(abs) == 1 then
        return abs
      end
      -- Relativer Pfad direkt prüfen
      if vim.fn.filereadable(cfile) == 1 then
        return cfile
      end
    end

    -- Fallback: aktueller Buffer
    local buf_name = vim.api.nvim_buf_get_name(0)
    if buf_name and buf_name ~= "" then
      return buf_name
    end

    return nil
  end

  local cmd_opts_base = { nargs = "?", complete = complete_pdf_path }

  -- ── :PdfPort [path]  – interaktiver Modus-Picker ────────────────────────
  vim.api.nvim_create_user_command("PdfPort", function(args)
    local path = resolve_path(args)
    if not path or path == "" then
      vim.notify("PdfPort: Kein Dateipfad gefunden (Argument, cfile oder Buffer)", vim.log.levels.ERROR)
      return
    end

    local hover_ok, hover = pcall(require, "lib.ui.hover_select")
    local choices = {
      { label = "buffer  – plain text (auto)",    mode = "buffer",   backend = nil          },
      { label = "buffer  – pdftotext",            mode = "buffer",   backend = "pdftotext"  },
      { label = "buffer  – marker (Markdown AI)", mode = "buffer",   backend = "marker"     },
      { label = "buffer  – docling",              mode = "buffer",   backend = "docling"    },
      { label = "buffer  – Claude API",           mode = "buffer",   backend = "claude"     },
      { label = "buffer  – Ollama",               mode = "buffer",   backend = "ollama"     },
      { label = "float   – auto",                 mode = "float",    backend = nil          },
      { label = "terminal image preview",         mode = "terminal", backend = nil          },
      { label = "system application",             mode = "system",   backend = nil          },
    }

    local items = { [#choices] = nil }
    for i, c in ipairs(choices) do items[i] = c.label end

    local on_select = function(_, idx)
      local c = choices[idx]
      if not c then return end
      M.open({ path = path, mode = c.mode, backend_id = c.backend, focus = true })
    end

    if hover_ok then
      hover.open({
        title     = "pdfport – open as",
        items     = items,
        auto_width = true,
        on_select = on_select,
      })
    else
      -- Fallback: vim.ui.select
      vim.ui.select(items, { prompt = "pdfport – open as:" }, function(_, idx)
        if idx then on_select(nil, idx) end
      end)
    end
  end, vim.tbl_extend("force", cmd_opts_base, {
    desc = "pdfport: PDF öffnen (Modus-Picker). Nutzt Argument, cfile oder aktuellen Buffer.",
  }))

  -- ── :PdfPortText [path]  – plain text in Buffer ──────────────────────────
  vim.api.nvim_create_user_command("PdfPortText", function(args)
    local path = resolve_path(args)
    if not path or path == "" then
      vim.notify("PdfPortText: Kein Dateipfad gefunden", vim.log.levels.ERROR)
      return
    end
    M.open({ path = path, mode = "buffer", focus = true })
  end, vim.tbl_extend("force", cmd_opts_base, {
    desc = "pdfport: PDF-Text in Buffer extrahieren (pdftotext, auto).",
  }))

  -- ── :PdfPortFloat [path] ────────────────────────────────────────────────
  vim.api.nvim_create_user_command("PdfPortFloat", function(args)
    local path = resolve_path(args)
    if not path or path == "" then
      vim.notify("PdfPortFloat: Kein Dateipfad gefunden", vim.log.levels.ERROR)
      return
    end
    M.open({ path = path, mode = "float", focus = true })
  end, vim.tbl_extend("force", cmd_opts_base, {
    desc = "pdfport: PDF-Text im Float-Fenster anzeigen.",
  }))

  -- ── :PdfPortSystem [path] ────────────────────────────────────────────────
  vim.api.nvim_create_user_command("PdfPortSystem", function(args)
    local path = resolve_path(args)
    if not path or path == "" then
      vim.notify("PdfPortSystem: Kein Dateipfad gefunden", vim.log.levels.ERROR)
      return
    end
    M.open({ path = path, mode = "system" })
  end, vim.tbl_extend("force", cmd_opts_base, {
    desc = "pdfport: PDF mit System-Anwendung öffnen.",
  }))

  -- ── :PdfPortTerminal [path] ──────────────────────────────────────────────
  vim.api.nvim_create_user_command("PdfPortTerminal", function(args)
    local path = resolve_path(args)
    if not path or path == "" then
      vim.notify("PdfPortTerminal: Kein Dateipfad gefunden", vim.log.levels.ERROR)
      return
    end
    M.open({ path = path, mode = "terminal" })
  end, vim.tbl_extend("force", cmd_opts_base, {
    desc = "pdfport: PDF als Bild im Terminal rendern.",
  }))

  -- ── :PdfPortHealth ───────────────────────────────────────────────────────
  vim.api.nvim_create_user_command("PdfPortHealth", function(_)
    vim.cmd("checkhealth pdfport")
  end, { desc = "pdfport: Health-Check ausführen." })
end



return M
