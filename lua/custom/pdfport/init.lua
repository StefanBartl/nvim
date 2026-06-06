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
  local function create(name, fn, desc)
    vim.api.nvim_create_user_command(name, fn, { desc = desc, nargs = "?" })
  end

  -- :PdfPort [path]  – open current file or given path with mode picker
  create("PdfPort", function(args)
    local path = args.args ~= "" and args.args or vim.api.nvim_buf_get_name(0)
    if not path or path == "" then
      vim.notify("PdfPort: no file path", vim.log.levels.ERROR)
      return
    end

    local hover = require("lib.ui.hover_select")
    local choices = {
      { label = "buffer  – plain text (auto)",     mode = "buffer",   backend = nil       },
      { label = "buffer  – pdftotext",             mode = "buffer",   backend = "pdftotext" },
      { label = "buffer  – marker (Markdown AI)",  mode = "buffer",   backend = "marker"  },
      { label = "buffer  – docling",               mode = "buffer",   backend = "docling" },
      { label = "buffer  – Claude API",            mode = "buffer",   backend = "claude"  },
      { label = "buffer  – Ollama",                mode = "buffer",   backend = "ollama"  },
      { label = "float   – auto",                  mode = "float",    backend = nil       },
      { label = "terminal image preview",          mode = "terminal", backend = nil       },
      { label = "system application",              mode = "system",   backend = nil       },
    }

    local items = { [#choices] = nil }
    for i, c in ipairs(choices) do
      items[i] = c.label
    end

    hover.open({
      title    = "pdfport – open as",
      items    = items,
      auto_width = true,
      on_select = function(_, idx)
        local c = choices[idx]
        if not c then return end
        M.open({ path = path, mode = c.mode, backend_id = c.backend, focus = true })
      end,
    })
  end, "Open a PDF with pdfport (mode picker)")

  -- :PdfPortText [path]
  create("PdfPortText", function(args)
    local path = args.args ~= "" and args.args or vim.api.nvim_buf_get_name(0)
    M.open({ path = path, mode = "buffer", focus = true })
  end, "Extract PDF text into a buffer")

  -- :PdfPortFloat [path]
  create("PdfPortFloat", function(args)
    local path = args.args ~= "" and args.args or vim.api.nvim_buf_get_name(0)
    M.open({ path = path, mode = "float", focus = true })
  end, "Extract PDF text into a floating window")

  -- :PdfPortSystem [path]
  create("PdfPortSystem", function(args)
    local path = args.args ~= "" and args.args or vim.api.nvim_buf_get_name(0)
    M.open({ path = path, mode = "system" })
  end, "Open PDF in system application")

  -- :PdfPortTerminal [path]
  create("PdfPortTerminal", function(args)
    local path = args.args ~= "" and args.args or vim.api.nvim_buf_get_name(0)
    M.open({ path = path, mode = "terminal" })
  end, "Render PDF pages in terminal")

  -- :PdfPortHealth
  create("PdfPortHealth", function(_)
    vim.cmd("checkhealth pdfport")
  end, "Run pdfport health checks")
end

return M
