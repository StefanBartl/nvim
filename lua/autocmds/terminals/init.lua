---@module 'autocmds.terminals'
--- Terminal-focused autocommands with feature flags.
--- Provides per-feature augroups to (a) normalize terminal window options on open,
--- (b) optionally tweak Kitty padding/margin on startup/exit, and
--- (c) optionally enter Insert mode automatically in terminal buffers.
--- Enable with `require('autocmds.terminals').enable(cfg)`.

local M = {}

local api = vim.api
local nvim_create_autocmd = api.nvim_create_autocmd

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local lazy = require("lib.lua.lazy")
local augroup_lib = lazy.require("lib.nvim.autocmd.augroup")
local augroup = augroup_lib.create.clear
local autocmd_lib = lazy.require("lib.nvim.autocmd")
local norm_events = autocmd_lib.norm_events
local is_kitty = lazy.require("lib.nvim.terminal").is_kitty

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
    nvim_create_autocmd(norm_events(cfg.numbers.events, { "TermOpen" }), {
      group = augroup("numbers"),
      callback = function(ev)
        -- Use local options to avoid bleeding into non-terminal windows.
        api.nvim_buf_call(ev.buf, function()
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
        end)
      end,
      desc = "Terminal: disable absolute and relative line numbers (local)",
    })
  end

  -- 2) Kitty padding/margin tweaks -------------------------------------------
  -- Description: In Kitty terminals, set compact padding/margin on VimEnter and restore on VimLeavePre.
  if cfg.kitty.enable and is_kitty() then
    local function kitty_cmd(padding, margin)
      return string.format(":silent !kitty @ set-spacing padding=%d margin=%d", padding, margin)
    end
    nvim_create_autocmd("VimEnter", {
      group = augroup("kitty_enter"),
      command = kitty_cmd(cfg.kitty.enter_padding, cfg.kitty.enter_margin),
      desc = "Kitty: reduce padding/margin for a snug editor frame on startup",
    })
    nvim_create_autocmd("VimLeavePre", {
      group = augroup("kitty_leave"),
      command = kitty_cmd(cfg.kitty.leave_padding, cfg.kitty.leave_margin),
      desc = "Kitty: restore padding/margin when leaving Neovim",
    })
  end

  -- 3) Auto Insert in terminals ----------------------------------------------
  -- Description: Automatically switch to Insert mode on terminal open (and optionally on enter).
  if cfg.auto_insert.enable then
    nvim_create_autocmd(norm_events(cfg.auto_insert.events, { "TermOpen" }), {
      group = augroup("auto_insert"),
      callback = function()
        -- `startinsert` is safe here; schedule to avoid racing with other handlers.
        vim.schedule(function()
          if vim.bo.buftype == "terminal" then
            vim.cmd("startinsert")
          end
        end)
      end,
      desc = "Terminal: enter Insert mode automatically",
    })
  end
end


---@type AutoCmds.Terminals
return M
