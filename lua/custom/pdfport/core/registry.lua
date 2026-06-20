---@module 'custom.pdfport.core.registry'
---@brief Backend and renderer registry for pdfport.
---@description
--- Maintains two independent registries: one for extraction backends
--- (pdftotext, marker, claude, ...) and one for output renderers
--- (buffer, terminal, system, float).
---
--- Registration is idempotent: re-registering the same id overwrites
--- the previous entry. All lookups are O(1) via direct table indexing.

local M = {}

-- #############################################################################
-- Backend registry
-- #############################################################################

---@type table<PdfPort.BackendId, PdfPort.Backend>
local _backends = {}

---@type PdfPort.BackendId[]
local _backend_order = {}

--- Register an extraction backend.
--- Registration order determines the fallback priority when using "auto" mode.
---@param backend PdfPort.Backend
---@return nil
function M.register_backend(backend)
  assert(type(backend) == "table", "backend must be a table")
  assert(type(backend.id) == "string" and backend.id ~= "", "backend.id must be a non-empty string")
  assert(type(backend.available) == "function", "backend.available must be a function")
  assert(type(backend.extract) == "function", "backend.extract must be a function")

  if not _backends[backend.id] then
    _backend_order[#_backend_order + 1] = backend.id
  end

  _backends[backend.id] = backend
end

--- Retrieve a backend by id.
---@param id PdfPort.BackendId
---@return PdfPort.Backend|nil
function M.get_backend(id)
  return _backends[id]
end

--- Returns all registered backends in registration order.
---@return PdfPort.Backend[]
function M.all_backends()
  local result = { [#_backend_order] = nil } -- pre-size
  for i = 1, #_backend_order do
    result[i] = _backends[_backend_order[i]]
  end
  return result
end

--- Returns the ids of all registered backends.
---@return PdfPort.BackendId[]
function M.backend_ids()
  local ids = { [#_backend_order] = nil }
  for i = 1, #_backend_order do
    ids[i] = _backend_order[i]
  end
  return ids
end

--- Returns true when a backend with the given id is registered.
---@param id PdfPort.BackendId
---@return boolean
function M.has_backend(id)
  return _backends[id] ~= nil
end

-- #############################################################################
-- Renderer registry
-- #############################################################################

---@type table<PdfPort.RendererMode, fun(result: PdfPort.Result, opts: PdfPort.RenderOpts): nil>
local _renderers = {}

--- Register an output renderer.
---@param mode PdfPort.RendererMode
---@param fn fun(result: PdfPort.Result, opts: PdfPort.RenderOpts): nil
---@return nil
function M.register_renderer(mode, fn)
  assert(type(mode) == "string" and mode ~= "", "mode must be a non-empty string")
  assert(type(fn) == "function", "renderer fn must be a function")
  _renderers[mode] = fn
end

--- Retrieve a renderer function by mode.
---@param mode PdfPort.RendererMode
---@return (fun(result: PdfPort.Result, opts: PdfPort.RenderOpts|PdfPort.InternalExtractOpts|PdfPort.OpenOpts): nil)|nil
function M.get_renderer(mode)
  return _renderers[mode]
end

--- Returns all registered renderer mode keys.
---@return PdfPort.RendererMode[]
function M.renderer_modes()
  local modes = {}
  for mode, _ in pairs(_renderers) do
    modes[#modes + 1] = mode
  end
  return modes
end

-- #############################################################################
-- Diagnostics
-- #############################################################################

--- Returns a human-readable summary of all registered backends and their
--- current availability status. Intended for :checkhealth and debug commands.
---@return string[]  Lines suitable for vim.notify or health output
function M.diagnostics()
  local lines = { "pdfport registry diagnostics", "" }
  lines[#lines + 1] = "Backends:"

  if #_backend_order == 0 then
    lines[#lines + 1] = "  (none registered)"
  else
    for i = 1, #_backend_order do
      local id = _backend_order[i]
      local b = _backends[id]
      local avail = (pcall(b.available) and b.available()) and "available" or "unavailable"
      lines[#lines + 1] = string.format("  [%d] %-16s  %s", i, id, avail)
    end
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "Renderers:"

  local modes = M.renderer_modes()
  if #modes == 0 then
    lines[#lines + 1] = "  (none registered)"
  else
    for _, mode in ipairs(modes) do
      lines[#lines + 1] = string.format("  %-12s", mode)
    end
  end

  return lines
end

return M
