---@module 'ui.ibl.hooks'
--- Unified UI hook utilities for colorscheme-safe highlights and plugin-specific hook registration.
--- This module centralizes:
---   1) Safe highlight definitions with `default=true` to avoid overriding themes.
---   2) ColorScheme autocommands with idempotent augroups.
---   3) Optional ibl (indent-blankline) hook registration for HIGHLIGHT_SETUP.
--- It is designed to be resilient even if plugins are not installed.
---
--- Usage examples:
---   local Hooks = require("ui.hooks")
---   Hooks.setup({
---     ibl = {
---       -- Remap highlight links if desired; defaults are shown
---       hl = { indent = "LineNr", whitespace = "NonText", scope = "CursorLineNr", alias_char_to_indent = true },
---       enable_hooks = true,  -- register ibl.hooks if available
---       enable_shim  = true,  -- also ensure ColorScheme shim (safety net)
---     },
---   })
---
---   -- Define an extra safe highlight at any time:
---   Hooks.safe_set_hl("LinkLike", { link = "Underlined", default = true })
---
---   -- Register any colorscheme callback:
---   Hooks.on_colorscheme(function() print("colors changed") end, "my_colors_cb")
---
--- Notes:
---   • All APIs are safe to call multiple times (idempotent).
---   • If ibl is missing, ibl-related functions are no-ops and return false.

local M = {}

--------------------------------------------------------------------------------
-- Internal state and helpers
--------------------------------------------------------------------------------

---@type _UiHooksState
local STATE = {
  augroups = {},
  ibl_registered = false,
  colorscheme_shim = false,
}

---Create or reuse a named augroup (idempotent).
---@param name string
---@return integer aug_id
function M.ensure_augroup(name)
  local id = STATE.augroups[name]
  if id and vim.api.nvim_get_autocmds then
    return id
  end
  local ok, new_id = pcall(vim.api.nvim_create_augroup, name, { clear = true })
  if ok and type(new_id) == "number" then
    STATE.augroups[name] = new_id
    return new_id
  end
  -- Fallback: try again without clear, or return 0 if all fails
  local ok2, new_id2 = pcall(vim.api.nvim_create_augroup, name, {})
  if ok2 and type(new_id2) == "number" then
    STATE.augroups[name] = new_id2
    return new_id2
  end
  return 0
end

---Safely set a highlight, catching errors; defaults to { default = true } to avoid clobbering themes.
---@param name string
---@param val table
---@return boolean ok
function M.safe_set_hl(name, val)
  local opts = vim.tbl_extend("keep", val or {}, { default = true })
  local ok = pcall(vim.api.nvim_set_hl, 0, name, opts)
  return ok
end

---Register a function to run on ColorScheme (idempotent by name).
---@param cb fun():nil
---@param desc string?  -- optional descriptive name
---@return integer autocmd_id
function M.on_colorscheme(cb, desc)
  local group = M.ensure_augroup("ui_hooks_colors")
  local ok, id = pcall(vim.api.nvim_create_autocmd, "ColorScheme", {
    group = group,
    pattern = "*",
    callback = function()
      pcall(cb)
    end,
    desc = desc or "ui.hooks ColorScheme callback",
  })
  return ok and (id or 0) or 0
end

--------------------------------------------------------------------------------
-- ibl-specific helpers (optional)
--------------------------------------------------------------------------------

---Apply (or re-apply) the canonical ibl highlight links.
---@param spec UiHooksIblHl|nil
---@return nil
function M.apply_ibl_highlights(spec)
  spec = spec or {}
  local indent     = spec.indent or "LineNr"
  local whitespace = spec.whitespace or "NonText"
  local scope      = spec.scope or "CursorLineNr"
  local alias_char = (spec.alias_char_to_indent ~= false) -- default true

  M.safe_set_hl("IblIndent",     { link = indent })
  M.safe_set_hl("IblWhitespace", { link = whitespace })
  M.safe_set_hl("IblScope",      { link = scope })
  if alias_char then
    M.safe_set_hl("IblChar",     { link = "IblIndent" })
  end
end

---Register ibl.hooks HIGHLIGHT_SETUP if ibl is present.
---@param spec UiHooksIblHl|nil
---@return boolean registered
function M.register_ibl_highlight_setup(spec)
  if STATE.ibl_registered then
    return true
  end
  local ok_hooks, hooks = pcall(require, "ibl.hooks")
  if not ok_hooks or not hooks or not hooks.type or not hooks.type.HIGHLIGHT_SETUP then
    return false
  end
  hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    M.apply_ibl_highlights(spec)
  end)
  STATE.ibl_registered = true
  return true
end

---Ensure a ColorScheme shim that creates ibl highlight groups even if plugins run later.
---@param spec UiHooksIblHl|nil
---@return integer autocmd_id
function M.ensure_ibl_colorscheme_shim(spec)
  if STATE.colorscheme_shim then
    return 0
  end
  local id = M.on_colorscheme(function()
    M.apply_ibl_highlights(spec)
  end, "ui.hooks ibl highlight shim")
  STATE.colorscheme_shim = true
  return id
end

--------------------------------------------------------------------------------
-- Public setup
--------------------------------------------------------------------------------

---Setup all requested hooks according to the provided config.
---@param cfg UiHooksConfig|nil
---@return nil
function M.setup(cfg)
  cfg = cfg or {}
  local ibl_cfg = cfg.ibl or {}

  -- If ibl is installed, try to register its highlight hook.
  if ibl_cfg.enable_hooks ~= false then
    pcall(M.register_ibl_highlight_setup, ibl_cfg.hl)
  end

  -- Independently, install a ColorScheme shim as a safety net (default: enabled).
  if ibl_cfg.enable_shim ~= false then
    M.ensure_ibl_colorscheme_shim(ibl_cfg.hl)
  end
end

--------------------------------------------------------------------------------
-- Convenience: eager call for themes already loaded
--------------------------------------------------------------------------------

---Re-apply highlights immediately (useful after module load when a colorscheme is already active).
---@param cfg UiHooksConfig|nil
---@return nil
function M.reapply_now(cfg)
  cfg = cfg or {}
  local ibl_cfg = cfg.ibl or {}
  M.apply_ibl_highlights(ibl_cfg.hl)
end

return M
