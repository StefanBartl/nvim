---@module 'custom.pdfport.backends'
---@brief Loads and registers all built-in extraction backends.
---@description
--- Each backend lives in its own file under backends/.
--- This loader requires each file and registers the returned
--- PdfPort.Backend table in the central registry.
--- Registration order determines the default auto-resolution priority.

local registry = require("custom.pdfport.core.registry")

local M = {}

---@type { id: PdfPort.BackendId, module: string }[]
local BUILTIN_BACKENDS = {
  -- Fastest, no dependencies beyond poppler-utils
  { id = "pdftotext",  module = "custom.pdfport.backends.pdftotext"  },
  -- Good table support, Python-based
  { id = "pdfplumber", module = "custom.pdfport.backends.pdfplumber" },
  -- AI-assisted, high quality Markdown, local
  { id = "marker",     module = "custom.pdfport.backends.marker"     },
  -- IBM structured extraction, local
  { id = "docling",    module = "custom.pdfport.backends.docling"    },
  -- Local multimodal LLM (requires ollama daemon)
  { id = "ollama",     module = "custom.pdfport.backends.ollama"     },
  -- Remote Anthropic API (requires API key + internet)
  { id = "claude",     module = "custom.pdfport.backends.claude"     },
}

--- Loads and registers all built-in backends.
--- Backends that fail to load (missing module file) are silently skipped.
---@return nil
function M.load_all()
  for i = 1, #BUILTIN_BACKENDS do
    local entry = BUILTIN_BACKENDS[i]
    local ok, backend = pcall(require, entry.module)
    if ok and type(backend) == "table" then
      ---@cast backend PdfPort.Backend
      registry.register_backend(backend)
    end
  end
end

--- Loads and registers a single backend by module path.
---@param module_path string  Lua require path
---@return boolean ok
---@return string|nil error_msg
function M.load_custom(module_path)
  local ok, backend = pcall(require, module_path)
  if not ok then
    return false, string.format("pdfport: failed to load backend module '%s': %s", module_path, backend)
  end

  if type(backend) ~= "table" or type(backend.id) ~= "string" then
    return false, string.format("pdfport: module '%s' did not return a valid PdfPort.Backend", module_path)
  end

  registry.register_backend(backend)
  return true, nil
end

return M
