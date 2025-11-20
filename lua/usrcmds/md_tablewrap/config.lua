---@module 'usrcmds.md_tablewrap.config'
--- Configuration normalization and defaults for md.tablewrap.
--- This module performs strict type- and bounds-checking and returns
--- a normalized, immutable copy of the configuration for use by other modules.

local M = {}

local normalize = require("lib.normalize")

---@type MDTableWrapConfig
local DEFAULTS = {
  inner_pad = 1,
  outer_left = 3,
  outer_right = 3,
  auto_width = true, -- legacy switch (kept for compatibility)
  width_mode = "equal", -- "auto" | "equal" | "minflex"
  max_col_width = nil,
  min_col_width = 8,
  wrap_all_default = false,
  on_save_enabled = false,
}

---@param user table|nil
---@return boolean ok, MDTableWrapConfig|nil cfg, string|nil err
function M.normalize(user)
  if user == nil then
    return true, vim.deepcopy(DEFAULTS), nil
  end
  if type(user) ~= "table" then
    return false, nil, "options must be a table"
  end

  local cfg = vim.deepcopy(DEFAULTS)

  -- integers
  if user.inner_pad ~= nil then
    normalize.apply_nonneg_int(cfg, "inner_pad", user.inner_pad)
  end
  if user.outer_left ~= nil then
    normalize.apply_nonneg_int(cfg, "outer_left", user.outer_left)
  end
  if user.outer_right ~= nil then
    normalize.apply_nonneg_int(cfg, "outer_right", user.outer_right)
  end
  if user.min_col_width ~= nil then
    normalize.apply_pos_int(cfg, "min_col_width", user.min_col_width)
  end

  -- booleans
  if user.auto_width ~= nil then
    normalize.apply_bool(cfg, "auto_width", user.auto_width)
  end
  if user.wrap_all_default ~= nil then
    normalize.apply_bool(cfg, "wrap_all_default", user.wrap_all_default)
  end
  if user.on_save_enabled ~= nil then
    normalize.apply_bool(cfg, "on_save_enabled", user.on_save_enabled)
  end

  -- width_mode (beeinflusst auto_width)
  if user.width_mode ~= nil then
    if type(user.width_mode) ~= "string" then
      return false, nil, "width_mode must be a string"
    end
    local m = user.width_mode
    if m ~= "auto" and m ~= "equal" and m ~= "minflex" then
      return false, nil, "width_mode must be one of: auto|equal|minflex"
    end
    cfg.width_mode = m
    cfg.auto_width = (m == "auto")
  end

  -- legacy: auto_width ohne width_mode setzt width_mode implizit
  if user.width_mode == nil and user.auto_width ~= nil then
    -- N.apply_bool hat schon in cfg geschrieben; lese konsistent aus cfg
    cfg.width_mode = cfg.auto_width and "auto" or "equal"
  end

  -- max_col_width erlaubt nil (abschalten) oder eine positive Zahl;
  -- zusätzlich kompatibel zu false → „unset“
  if user.max_col_width ~= nil then
    if user.max_col_width == false then
      cfg.max_col_width = nil
    else
      -- schreibt nur bei gültigem int; bleibt sonst beim bisherigen Wert
      normalize.apply_pos_int(cfg, "max_col_width", user.max_col_width)
    end
  end

  -- Sanity: max ≥ min, falls beide gesetzt
  if cfg.max_col_width and cfg.min_col_width and cfg.max_col_width < cfg.min_col_width then
    cfg.max_col_width = cfg.min_col_width
  end

  return true, cfg, nil
end

---@return MDTableWrapConfig
function M.defaults()
  return vim.deepcopy(DEFAULTS)
end

return M
