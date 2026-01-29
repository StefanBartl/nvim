---@module 'wkdnvchad.config'
--- Central configuration loader with statusline variant selection.
--- Loads base46 config once and applies selected statusline variant.

local notify = require("lib.notify").create("[wkdnvchad.config]")

local M = {}

-- ============================================================================
-- STATUSLINE VARIANT SELECTION
-- ============================================================================
-- Change this to switch between statusline variants:
-- "normal"   -> Default NvChad statusline (no customization)
-- "base"     -> Minimal custom statusline (cursor + cwd + progress)
-- "lspbased" -> LSP-aware breadcrumbs + enhanced modules
-- "custom"   -> Your legacy custom breadcrumbs implementation
-- ============================================================================

---@type "normal"|"base"|"lspbased"|"custom"|"custom_light"|"custom_minimal"
M.STATUSLINE_VARIANT = "normal"

-- ============================================================================
-- Config Assembly
-- ============================================================================

---Load the selected statusline config
---@return table
local function load_statusline_config()
  local variant = M.STATUSLINE_VARIANT
  local config_path = "wkdnvchad.config.statusline." .. variant

  local ok, config = pcall(require, config_path)
  if not ok then
    notify.warn(
      string.format(
        "[wkdnvchad.config] Failed to load statusline variant '%s': %s\nFalling back to 'normal'",
        variant,
        tostring(config)
      )
    )
    return require("wkdnvchad.config.statusline.normal")
  end

  return config
end

---Setup complete configuration
---@param user_opts? table Optional user overrides for base46
---@return table
function M.setup(user_opts)
  user_opts = user_opts or {}

  -- 1. Load base46 config (centralized)
  local base46_config = require("wkdnvchad.config.base46")

  -- 2. Allow user overrides for base46
  if user_opts.base46 then
    base46_config = vim.tbl_deep_extend("force", base46_config, user_opts.base46)
  end

  -- 3. Load selected statusline variant
  local statusline_config = load_statusline_config()

  -- 4. Assemble final config
  local config = {
    base46 = base46_config,
    ui = statusline_config.ui or {},
  }

  -- 5. Run variant-specific setup if present
  if type(statusline_config.setup) == "function" then
    local setup_ok, setup_err = pcall(statusline_config.setup, config)
    if not setup_ok then
      notify.error(
        string.format("[wkdnvchad.config] Statusline setup failed: %s", tostring(setup_err))
      )
    end
  end

  -- Remove diagnostic backgrounds
  local ok_diag, diag_err = pcall(function()
    require("wkdnvchad.ui.highlights.diagnostics").setup()
  end)

  if not ok_diag then
    notify.warn("[config] Diagnostic highlight setup failed: " .. tostring(diag_err))
  end

  return config
end

---Get current statusline variant
---@return string
function M.get_variant()
  return M.STATUSLINE_VARIANT
end

return M
