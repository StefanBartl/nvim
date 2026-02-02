---@module 'plugins.neotree'
---@brief Neo-tree variant loader for lazy.nvim
---@description
--- Central entrypoint for all Neo-tree variants.
--- Exactly one variant is selected via a symbolic key and loaded dynamically.
--- Variants may live outside /plugins and may even use non-.lua extensions.

-- ============================================================================
-- Variant selection
-- ============================================================================

---@alias NeoTreeVariantKey
---| "default"
---| "wo_sources"
---| "standard"
---| "stub"

---@type NeoTreeVariantKey
local ACTIVE_VARIANT = "default"

-- ============================================================================
-- Variant registry
-- ============================================================================

local folder = vim.fn.stdpath("config") .. "/lua/plugins/neotree_variants"

---@type table<NeoTreeVariantKey, string>
local VARIANTS = {
  default = folder .. "/neotree.lua",
  wo_sources = folder .. "/neotree_wo_sources.lua",
  standard = folder .. "/neotree_standard.lua",
  stub = folder .. "/neotree_stub.lua",
}

-- ============================================================================
-- Loader
-- ============================================================================

---@param path string
---@return any
local function load_variant(path)
  -- loadfile executes the file in an isolated chunk
  local chunk, err = loadfile(path)
  if not chunk then
    error("[neotree] failed to load variant: " .. err)
  end

  return chunk()
end

---@return any
local function resolve_and_load()
  local path = VARIANTS[ACTIVE_VARIANT]
  if not path then
    error("[neotree] unknown variant: " .. tostring(ACTIVE_VARIANT))
  end

  return load_variant(path)
end

-- ============================================================================
-- lazy.nvim spec passthrough
-- ============================================================================

-- The loaded variant is expected to return either:
-- 1. a lazy.nvim plugin spec table
-- 2. or a list of plugin specs
return resolve_and_load()
