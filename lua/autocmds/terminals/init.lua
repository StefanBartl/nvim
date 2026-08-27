---@module 'autocmds.terminals'
--- Terminal-focused autocommands with feature flags.
--- Provides per-feature augroups to (a) normalize terminal window options on open,
--- (b) optionally tweak Kitty padding/margin on startup/exit, and
--- (c) optionally enter Insert mode automatically in terminal buffers.
--- Enable with `require('autocmds.terminals').enable(cfg)`.

local M = {}

local api = vim.api

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local lazy = require("lib.lua.lazy")
local autocmd_lib = lazy.require("lib.nvim.bindings.autocmd")
local norm_events = autocmd_lib.norm_events
local is_kitty = lazy.require("lib.nvim.terminal").is_kitty
local Autocmd = lazy.require("lib.nvim.bindings.autocmd")

--- Clear and return a feature's augroup.
---
--- Through `Autocmd.group`, not `augroup.create.clear`: clearing this way also
--- drops the feature's previous *records*, so calling `enable()` twice replaces
--- its rows in the generated bindings table instead of doubling them.
---@param name string
---@return integer
local function augroup(name)
  return Autocmd.group(name, true)
end

--------------------------------------------------------------------------------
-- Defaults --------------------------------------------------------------------
--------------------------------------------------------------------------------

---@type AutoCmds.Term.Cfg
local DEFAULTS = require("autocmds.terminals.defaults").get_defaults()

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Enable terminal-related autocommands per feature.
---@param cfg AutoCmds.Term.Cfg|nil
---@return nil
function M.enable(cfg)
  cfg = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), cfg or {})

  -- 1) Terminal window numbers off -------------------------------------------
  -- Description: On terminal open (or configured events), disable absolute/relative numbers locally.
  if cfg.numbers.enable then
    Autocmd.create(norm_events(cfg.numbers.events, { "TermOpen" }), function(ev)
      -- Use local options to avoid bleeding into non-terminal windows.
      api.nvim_buf_call(ev.buf, function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
      end)
    end, {
      group = augroup("numbers"),
      desc = "Terminal: disable absolute and relative line numbers (local)",
    })
  end

  -- 2) Kitty padding/margin tweaks -------------------------------------------
  -- Description: In Kitty terminals, set compact padding/margin on VimEnter and restore on VimLeavePre.
  if cfg.kitty.enable and is_kitty() then
    local function kitty_cmd(padding, margin)
      return string.format(":silent !kitty @ set-spacing padding=%d margin=%d", padding, margin)
    end
    -- `Autocmd.create` takes a callback, not a `command` string, so the two
    -- `:silent !kitty @ …` invocations run through `vim.cmd` instead.
    local enter_cmd = kitty_cmd(cfg.kitty.enter_padding, cfg.kitty.enter_margin)
    local leave_cmd = kitty_cmd(cfg.kitty.leave_padding, cfg.kitty.leave_margin)
    Autocmd.create("VimEnter", function()
      vim.cmd(enter_cmd)
    end, {
      group = augroup("kitty_enter"),
      desc = "Kitty: reduce padding/margin for a snug editor frame on startup",
    })
    Autocmd.create("VimLeavePre", function()
      vim.cmd(leave_cmd)
    end, {
      group = augroup("kitty_leave"),
      desc = "Kitty: restore padding/margin when leaving Neovim",
    })
  end

  -- 3) Auto Insert in terminals ----------------------------------------------
  -- Description: Automatically switch to Insert mode on terminal open (and optionally on enter).
  if cfg.auto_insert.enable then
    Autocmd.create(norm_events(cfg.auto_insert.events, { "TermOpen" }), function(args)
      local buf = args.buf
      -- `startinsert` is safe here; schedule to avoid racing with other handlers.
      -- Re-check the terminal buffer is still current: another handler may have
      -- switched windows/buffers during the scheduled gap.
      vim.schedule(function()
        if
          vim.api.nvim_buf_is_valid(buf)
          and vim.bo[buf].buftype == "terminal"
          and vim.api.nvim_get_current_buf() == buf
        then
          vim.cmd("startinsert")
        end
      end)
    end, {
      group = augroup("auto_insert"),
      desc = "Terminal: enter Insert mode automatically",
    })
  end
end

---@type AutoCmds.Terminals
return M
