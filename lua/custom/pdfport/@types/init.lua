---@meta
---@module 'custom.pdfport.types'
---@brief EmmyLua type definitions for the pdfport module.
---@description
--- Central type registry for all pdfport interfaces.
--- Every sub-module references these types via the @types path so that
--- the source files remain free of annotation clutter.

-- #############################################################################
-- Backend types
-- #############################################################################

---@alias PdfPort.BackendId
---| "pdftotext"   -- poppler-utils CLI tool
---| "pdfplumber"  -- Python pdfplumber library
---| "marker"      -- marker-pdf AI-assisted extraction
---| "docling"     -- IBM docling structured extraction
---| "claude"      -- Anthropic Claude API (remote)
---| "ollama"      -- Local ollama multimodal model
---| string        -- Custom/third-party backend identifier

---@class PdfPort.BackendCapabilities
---@field markdown boolean          -- Can produce Markdown output
---@field tables boolean            -- Reliably extracts tables
---@field ocr boolean               -- Works on scanned/image PDFs
---@field remote boolean            -- Requires network access
---@field gpu_optional boolean      -- Can use GPU but does not require it

---@class PdfPort.Backend
---@field id PdfPort.BackendId                         -- Unique identifier
---@field name string                                  -- Human-readable label
---@field capabilities PdfPort.BackendCapabilities
---@field available? fun(): boolean                     -- Runtime availability check
---@field extract? fun(path: string, opts: PdfPort.InternalExtractOpts): PdfPort.Result|nil

--- Extended backend class for backends that cache their last result internally.
--- Use this as the type for `M` in backends that write to `M._last_result`.
---@class PdfPort.StatefulBackend : PdfPort.Backend
---@field _last_result? PdfPort.Result  -- Cached result of the most recent extraction

--- Extended backend class for backends that accept runtime configuration injection
--- (e.g. claude, ollama which need an API key or host from the global config).
---@class PdfPort.ConfigurableBackend : PdfPort.Backend
---@field _set_config? fun(config: PdfPort.Config): nil  -- Called by init after setup()

---@class PdfPort.ExtractOpts
---@field pages? integer[]          -- Page numbers to extract (1-based), nil = all
---@field max_pages? integer        -- Hard limit on pages processed
---@field prompt? string            -- Custom prompt for AI backends
---@field model? string             -- Model override for AI backends (ollama/claude)
---@field timeout_ms? integer       -- Extraction timeout in milliseconds

--- Internal extension of ExtractOpts used when a backend is invoked through
--- the dispatcher. The __callback field carries the delivery function and is
--- never part of the public-facing API surface.
---@class PdfPort.InternalExtractOpts : PdfPort.ExtractOpts
---@field __callback? fun(result: PdfPort.Result): nil  -- Async delivery callback

-- #############################################################################
-- Renderer types
-- #############################################################################

---@alias PdfPort.RendererMode
---| "buffer"    -- Scratch buffer with filetype=markdown
---| "terminal"  -- Terminal image/text rendering (ueberzug++, chafa, kitty)
---| "system"    -- Open in system application (xdg-open, open)
---| "float"     -- Floating window with extracted text

---@class PdfPort.RenderOpts
---@field mode PdfPort.RendererMode
---@field backend_id? PdfPort.BackendId       -- Force specific backend; nil = auto-resolve
---@field split? "vsplit"|"split"|"tab"       -- For buffer mode
---@diagnostic disable-next-line
---@field float_opts? vim.api.keyset.win_config -- For float mode
---@field terminal_tool? "ueberzug"|"chafa"|"kitty"|"imgcat" -- For terminal mode
---@field focus? boolean                      -- Focus opened window after render
---@field pages? integer[]                    -- Page numbers to render (terminal mode)

--- Full open request: combines path, render options and extract options.
--- This is the type passed through dispatcher.open() and into renderers.
---@class PdfPort.OpenOpts : PdfPort.RenderOpts
---@field path string          -- Absolute path to the PDF file
---@field max_pages? integer   -- Forwarded to the extraction backend
---@field prompt? string       -- Custom prompt for AI backends
---@field model? string        -- Model override for AI backends
---@field timeout_ms? integer  -- Per-call timeout override

-- #############################################################################
-- Result types
-- #############################################################################

---@alias PdfPort.ResultStatus
---| "ok"      -- Extraction succeeded
---| "error"   -- Extraction failed
---| "partial" -- Partial result (e.g. timeout hit, some pages missing)

---@class PdfPort.Result
---@field status PdfPort.ResultStatus
---@field text string|nil          -- Extracted text content (nil on error)
---@field format "plain"|"markdown" -- Output format of text
---@field backend PdfPort.BackendId -- Backend that produced this result
---@field pages_processed integer|nil
---@field error string|nil         -- Error message if status ~= "ok"

-- #############################################################################
-- Integration types
-- #############################################################################

---@class PdfPort.NeoTreeCommand
---@field name string
---@field fn fun(state: table): nil

---@class PdfPort.TelescopePreviewOpts
---@field backend_id? PdfPort.BackendId
---@field max_pages? integer

---@class PdfPort.FzfPreviewOpts
---@field backend_id? PdfPort.BackendId
---@field max_pages? integer

-- #############################################################################
-- Config types
-- #############################################################################

---@class PdfPort.Config
---@field default_backend PdfPort.BackendId|"auto"  -- "auto" = first available
---@field fallback_chain PdfPort.BackendId[]         -- Ordered fallback list
---@field extract_opts PdfPort.ExtractOpts           -- Global extraction defaults
---@field render_opts PdfPort.RenderOpts             -- Global render defaults
---@field claude_api_key? string                     -- API key for Claude backend
---@field ollama_host? string                        -- Ollama host (default: localhost:11434)
---@field ollama_model? string                       -- Ollama model (default: llava)
---@field debug boolean                              -- Enable debug notifications

return {}
