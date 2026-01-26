---@module 'wkdoptions.hl_config.core.state'
--- Centralized state management for highlight features.
--- Replaces scattered global tables with a single, queryable state container.

local M = {}

--- Per-window mode cache to avoid redundant tint updates
---@type table<integer, string>
local mode_by_win = {}

--- Feature enable flags (derived from config, but cached for fast access)
---@type table<string, boolean>
local features = {}

--- Namespace handles (created once, reused)
---@type table<string, integer>
local namespaces = {}

--- Autocmd group handles
---@type table<string, integer>
local augroups = {}

---@nodiscard
---@param win integer
---@return string|nil
function M.get_win_mode(win)
  return mode_by_win[win]
end

---@param win integer
---@param mode string
---@return nil
function M.set_win_mode(win, mode)
  mode_by_win[win] = mode
end

---@param win integer
---@return nil
function M.clear_win_mode(win)
  mode_by_win[win] = nil
end

---@nodiscard
---@param name string
---@return boolean
function M.is_enabled(name)
  return features[name] == true
end

---@param name string
---@param enabled boolean
---@return nil
function M.set_enabled(name, enabled)
  features[name] = enabled
end

---@nodiscard
---@param name string
---@return integer
function M.get_namespace(name)
  if not namespaces[name] then
    namespaces[name] = vim.api.nvim_create_namespace("myopt_" .. name)
  end
  return namespaces[name]
end

---@nodiscard
---@param name string
---@param clear? boolean
---@return integer
function M.get_augroup(name, clear)
  if not augroups[name] then
    augroups[name] = vim.api.nvim_create_augroup("myopt_" .. name, { clear = clear ~= false })
  end
  return augroups[name]
end

--- Initialize features from config (call once during enable())
---@param cfg WKDOptions.HL_CFG
---@return nil
function M.init_from_config(cfg)
  features = {
    line = cfg.enable_line,
    column = cfg.enable_column,
    color_persist = cfg.color_persist,
    yank_flash = cfg.enable_yank_flash,
    put_flash = cfg.enable_put_flash,
    signcolumn_tint = cfg.enable_signcolumn_tint,
    terminal_palette = cfg.enable_terminal_palette,
    mode_colors = cfg.enable_insert_submode_colors,
    current_word = cfg.enable_current_word,
    indent_scope = cfg.enable_indent_scope,
    breadcrumbs = cfg.enable_breadcrumbs,
    diff_peek = cfg.enable_diff_peek,
    cword_occurrences = (cfg.cword_occurrences or {}).enabled,
  }
end

--- Reset all state (useful for tests/reload)
---@return nil
function M.reset()
  mode_by_win = {}
  features = {}
  -- namespaces/augroups persist across reloads
end

return M
