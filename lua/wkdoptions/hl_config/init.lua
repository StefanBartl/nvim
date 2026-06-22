---@module 'wkdoptions.hl_config'
--- Visual/UX feature orchestrator (refactored for modularity, safety, and performance).
--- This module delegates to specialized feature modules and uses centralized state management.
---
--- Architecture:
---   - core/state: centralized state + namespace/augroup registry
---   - core/highlights: safe HL application with error guards
---   - features/*: isolated feature modules (cursorline, flash, mode_tint, etc.)
---   - utils/*: shared utilities (winhighlight, large_file, separator, skip)
---   - breadcrumbs/*: winbar + context logic
---
--- Performance optimizations:
---   - Memoization for fs_stat, separator resolution, winhighlight parsing
---   - Lazy loading of heavy modules (breadcrumbs, cword_occurrences)
---   - Per-window mode cache to avoid redundant updates
---   - Type guards and pcall wrapping on all API calls
---
--- Key principles:
---   - Single Responsibility: each module does one thing
---   - Defensive programming: validate all inputs, guard all API calls
---   - Explicitness: no hidden state, clear data flow
---   - Testability: pure functions where possible, state accessible for inspection

local lazy = require("lib.lua.lazy")
local C = lazy.require("wkdoptions.config")

---@type WKDOptions.HL_CFG
local cfg = C.get_cfg().highlight

-- Core
local State = lazy.require("wkdoptions.hl_config.core.state")
local Highlights = lazy.require("wkdoptions.hl_config.core.highlights")

-- Utils
local is_ui = lazy.require("wkdoptions.hl_config.utils.skip").std_skip

-- Features (all available, loaded on enable)
local CursorLine = lazy.require("wkdoptions.hl_config.features.cursorline")
local ModeTint = lazy.require("wkdoptions.hl_config.features.mode_tint")
local Flash = lazy.require("wkdoptions.hl_config.features.flash")
local SigncolTint = lazy.require("wkdoptions.hl_config.features.signcolumn_tint")
local TermPalette = lazy.require("wkdoptions.hl_config.features.terminal_palette")
local CurrentWord = lazy.require("wkdoptions.hl_config.features.current_word")
local IndentScope = lazy.require("wkdoptions.hl_config.features.indent_scope")
local DiffPeek = lazy.require("wkdoptions.hl_config.features.diff_peek")

-- Breadcrumbs
local Breadcrumbs = lazy.require("wkdoptions.hl_config.breadcrumbs")

-- Special modules (already exist, kept as-is for now)
local PathCache = lazy.require("wkdoptions.hl_config.path_cache")
local CwordOcc = lazy.require("wkdoptions.hl_config.cword_occurrences")

local M = {}

--- Apply all highlight groups
---@return nil
local function apply_highlights()
  local errors = Highlights.apply_all(cfg.colors)

  if next(errors) then
    local notify = require("lib.nvim.notify").create("[hl_config]")
    for _, err in pairs(errors) do
      notify.warn(err)
    end
  end
end

--- Handle per-window activation/deactivation
---@return nil
local function activate_window()
  if is_ui(0) then
    CursorLine.deactivate()
    return
  end

  CursorLine.activate(cfg, nil)
end

---@return nil
local function deactivate_window()
  CursorLine.deactivate()
end

--- Re-apply after config change (called by :MyHlSet)
---@param key string
---@return nil
local function after_set(key)
  -- Color table changes
  if key:match("^colors%.") then
    apply_highlights()
    activate_window()
    return
  end

  -- CursorLine/Column
  if key == "enable_line" or key == "enable_column" or key == "min_colored_file_kb" then
    State.set_enabled("line", cfg.enable_line)
    State.set_enabled("column", cfg.enable_column)
    activate_window()
    return
  end

  -- Color persist
  if key == "color_persist" then
    State.set_enabled("color_persist", cfg.color_persist)
    M.ensure_color_persist()
    return
  end

  -- Flash features
  if key == "enable_yank_flash" or key == "enable_put_flash" or key == "map_put_flash" then
    State.set_enabled("yank_flash", cfg.enable_yank_flash)
    State.set_enabled("put_flash", cfg.enable_put_flash)
    Flash.enable(cfg)
    return
  end

  -- SignColumn tint
  if key == "enable_signcolumn_tint" then
    State.set_enabled("signcolumn_tint", cfg.enable_signcolumn_tint)
    SigncolTint.enable(cfg)
    return
  end

  -- Terminal palette
  if key == "enable_terminal_palette" then
    State.set_enabled("terminal_palette", cfg.enable_terminal_palette)
    TermPalette.enable(cfg)
    return
  end

  -- Current word
  if key == "enable_current_word" then
    State.set_enabled("current_word", cfg.enable_current_word)
    CurrentWord.enable(cfg)
    return
  end

  -- Mode colors
  if key == "enable_insert_submode_colors" then
    State.set_enabled("mode_colors", cfg.enable_insert_submode_colors)
    ModeTint.enable(cfg)
    return
  end

  -- Breadcrumbs
  if key == "enable_breadcrumbs" or key:match("^breadcrumbs_") then
    State.set_enabled("breadcrumbs", cfg.enable_breadcrumbs)
    Breadcrumbs.refresh()
    return
  end

  -- Cword occurrences
  if key:match("^cword_occurrences%.") then
    CwordOcc.refresh()
    return
  end

  -- Indent scope
  if key == "enable_indent_scope" then
    State.set_enabled("indent_scope", cfg.enable_indent_scope)
    IndentScope.refresh_current()
    return
  end

  -- Diff peek
  if key == "enable_diff_peek" then
    State.set_enabled("diff_peek", cfg.enable_diff_peek)
    DiffPeek.enable(cfg)
    return
  end

  -- Large file threshold (affects multiple features)
  if key == "large_file_kb" then
    IndentScope.refresh_current()
    activate_window()
    return
  end
end

--- Install ColorScheme autocmd if color_persist is enabled
---@return nil
function M.ensure_color_persist()
  local aug = State.get_augroup("ColorPersist", true)

  if not State.is_enabled("color_persist") then
    return
  end

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = aug,
    callback = function()
      apply_highlights()
      activate_window()
      if State.is_enabled("breadcrumbs") then
        Breadcrumbs.refresh()
      end
      if State.is_enabled("indent_scope") then
        IndentScope.refresh_current()
      end
    end,
    desc = "Re-apply highlights after colorscheme change",
  })
end

--- Install per-window activation autocmds
---@return nil
local function ensure_window_autocmds()
  local aug = State.get_augroup("PerWindow", true)

  vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
    group = aug,
    callback = activate_window,
    desc = "Activate highlights for active window",
  })

  vim.api.nvim_create_autocmd({ "WinLeave" }, {
    group = aug,
    callback = deactivate_window,
    desc = "Dim highlights for inactive windows",
  })

  vim.api.nvim_create_autocmd({ "BufReadPost", "TextChanged", "TextChangedI" }, {
    group = aug,
    callback = function()
      if vim.wo.cursorline then
        activate_window()
      end
    end,
    desc = "Re-check column highlight on size changes",
  })
end

--- Main entry point
---@return nil
function M.enable()
  -- Initialize state from config
  State.init_from_config(cfg)

  -- Apply highlights
  apply_highlights()

  -- Enable features (each checks State.is_enabled internally)
  CwordOcc.enable()
  PathCache.ensure_autocmds()

  Flash.enable(cfg)
  SigncolTint.enable(cfg)
  TermPalette.enable(cfg)
  CurrentWord.enable(cfg)
  ModeTint.enable(cfg)
  DiffPeek.enable(cfg)

  -- Conditional features
  if State.is_enabled("breadcrumbs") then
    Breadcrumbs.enable(cfg)
  end

  if State.is_enabled("indent_scope") then
    IndentScope.enable(cfg)
  end

  -- Autocmds
  M.ensure_color_persist()
  ensure_window_autocmds()

  -- Subscribe to config changes
  C.on_after_set("highlight", after_set)

  -- Register user commands
  require("wkdoptions.commands").register_highlight_commands({
    after_set = after_set,
    show_table = cfg,
    names = { set = "WKDOptionsHLSet", show = "WKDOptionsHLShow", list = "WKDOptionsHLList" },
  })

 require("wkdoptions.commands").register_highlight_debug_command({
    mod = require("wkdoptions.hl_config.breadcrumbs.ctx"),
    sepfn = require("wkdoptions.hl_config.utils.separator").resolve,
    names = { debug = "WKDOptionsHLDebugCtx" },
  })
end

return M
