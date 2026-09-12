---@module 'autocmds.general'
--- Centralized, toggleable autocmd suite with safe defaults and idempotent setup.
--- Each feature can be enabled/disabled via the `enable(cfg)` entry point.
--- Guards are included to avoid side effects in unsupported contexts.
local M = {}

local helpers = require("autocmds.general.helpers")
local DEFAULTS = require("autocmds.general.defaults").get_defaults()
local Autocmd = require("lib.nvim.bindings.autocmd")

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---@param cfg AutoCmds.General.Cfg|nil
---@return nil
function M.enable(cfg)
  cfg = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), cfg or {})

  -- Kitty spacing tweaks used to live here too (VimEnter/VimLeavePre),
  -- duplicating autocmds.terminals' own kitty feature -- same events, same
  -- `:silent !kitty @ set-spacing ...` mechanism, both enabled at once in
  -- autocmds/init.lua, so the command ran twice on every startup/exit.
  -- Removed 2026-09-12; autocmds.terminals is the one owner now (it already
  -- used lib.nvim.terminal.is_kitty, the shared detector, rather than this
  -- module's own hand-rolled one).

  -- 1) Cursorline only in the active window
  if cfg.cursorline.enable then
    local grp_show = helpers.augroup((cfg.group_name or "autocmds_general") .. "_cursorline_show")
    Autocmd.create(cfg.cursorline.show_events, function(event)
      -- Only enable cursorline for "normal" buffers (empty buftype).
      if vim.bo[event.buf].buftype == "" then
        vim.opt_local.cursorline = true
      end
    end, {
      group = grp_show,
      desc = "Enable cursorline in the active window on relevant events",
    })

    local grp_hide = helpers.augroup((cfg.group_name or "autocmds_general") .. "_cursorline_hide")
    Autocmd.create(cfg.cursorline.hide_events, function()
      vim.opt_local.cursorline = false
    end, {
      group = grp_hide,
      desc = "Disable cursorline in inactive windows or insert mode",
    })
  end

  -- Jump-to-last-location used to live here too (BufReadPost), duplicating
  -- autocmds.text's own last_loc feature. Never actually double-fired --
  -- this one was disabled in autocmds/init.lua's config, text's was the one
  -- enabled -- but two implementations for a feature only one of them ran
  -- is exactly the kind of drift worth removing rather than leaving as dead
  -- weight. Removed 2026-09-12; autocmds.text is the one owner now (native
  -- autocmd `pattern` filtering instead of a runtime `vim.tbl_contains`
  -- check, plus `min_line`).

  -- 2) Redirect spurious [No Name] buffers left behind by a close, to a real
  --    buffer if one exists (BufDelete/BufWipeout, WinClosed)
  if cfg.no_name_guard.enable then
    local grp = helpers.augroup((cfg.group_name or "autocmds_general") .. "_no_name_guard")
    Autocmd.create({ "BufDelete", "BufWipeout" }, function(event)
      helpers.no_name_guard_sweep({ [event.buf] = true })
    end, {
      group = grp,
      desc = "After a buffer is deleted, redirect any window left showing a spurious [No Name] buffer to a real one",
    })
    Autocmd.create("WinClosed", function()
      helpers.no_name_guard_sweep({})
    end, {
      group = grp,
      desc = "After a window closes, redirect any window left showing a spurious [No Name] buffer to a real one",
    })
  end
end

---@type AutoCmds.General
return M
