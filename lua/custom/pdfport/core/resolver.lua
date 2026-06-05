---@module 'custom.pdfport.core.resolver'
---@brief Backend selection and fallback chain resolution for pdfport.
---@description
--- Given a desired backend id (or "auto"), this module walks the configured
--- fallback chain and returns the first backend that reports itself as
--- available at runtime. The resolved result is NOT cached, because tool
--- availability can change (e.g. after installing a Python package) without
--- restarting Neovim. The availability check itself is cheap (cached in
--- platform.lua), so repeated calls are safe.

local registry = require("custom.pdfport.core.registry")

local M = {}

-- #############################################################################
-- Internal state (injected by init.lua after setup)
-- #############################################################################

---@type PdfPort.Config|nil
local _config = nil

--- Called once by pdfport.init after setup() to share the active config.
---@param config PdfPort.Config
---@return nil
function M._set_config(config)
  _config = config
end

-- #############################################################################
-- Resolution
-- #############################################################################

--- Returns the effective fallback chain.
--- When a specific backend id is given, the chain is [id, ...global_fallbacks].
--- When "auto" is given, the chain is the globally configured fallback list
--- followed by every registered backend in registration order.
---@param requested PdfPort.BackendId|"auto"|nil
---@return PdfPort.BackendId[]
local function build_chain(requested)
  local cfg = _config or {}
  local global_chain = cfg.fallback_chain or {}

  if requested and requested ~= "auto" then
    -- Prepend the explicitly requested backend; keep fallbacks as safety net
    local chain = { [#global_chain + 1] = nil }
    chain[1] = requested
    for i = 1, #global_chain do
      chain[i + 1] = global_chain[i]
    end
    return chain
  end

  if cfg.default_backend and cfg.default_backend ~= "auto" then
    -- Configured default takes priority
    local chain = { cfg.default_backend }
    for i = 1, #global_chain do
      if global_chain[i] ~= cfg.default_backend then
        chain[#chain + 1] = global_chain[i]
      end
    end
    return chain
  end

  -- Pure auto: use global chain, then append any registered backend not yet in list
  local seen = {}
  local chain = {}

  for i = 1, #global_chain do
    local id = global_chain[i]
    if not seen[id] then
      seen[id] = true
      chain[#chain + 1] = id
    end
  end

  -- Append registered backends that are not in the explicit chain
  local all_ids = registry.backend_ids()
  for i = 1, #all_ids do
    local id = all_ids[i]
    if not seen[id] then
      seen[id] = true
      chain[#chain + 1] = id
    end
  end

  return chain
end

--- Resolves and returns the first available backend for the given request.
---@param requested PdfPort.BackendId|"auto"|nil  Desired backend id or "auto"
---@return PdfPort.Backend|nil backend  First available backend, or nil
---@return string|nil error_msg         Human-readable error when no backend found
function M.resolve(requested)
  local chain = build_chain(requested)

  for i = 1, #chain do
    local id = chain[i]
    local backend = registry.get_backend(id)

    if backend then
      local ok, avail = pcall(backend.available)
      if ok and avail then
        return backend, nil
      end
    end
  end

  -- Build a useful error message listing what was tried
  local tried = table.concat(chain, ", ")
  return nil, string.format(
    "pdfport: no available backend found. Tried: [%s]", tried
  )
end

--- Returns all currently available backends, ordered by fallback chain priority.
---@return PdfPort.Backend[]
function M.available_backends()
  local chain = build_chain("auto")
  local result = {}

  for i = 1, #chain do
    local backend = registry.get_backend(chain[i])
    if backend then
      local ok, avail = pcall(backend.available)
      if ok and avail then
        result[#result + 1] = backend
      end
    end
  end

  return result
end

return M
