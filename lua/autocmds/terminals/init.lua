---@module 'autocmds.terminals'
--- Terminal-focused autocommands with feature flags.
--- Provides per-feature augroups to (a) normalize terminal window options on open,
--- (b) optionally tweak Kitty padding/margin on startup/exit, and
--- (c) optionally enter Insert mode automatically in terminal buffers.
--- Enable with `require('autocmds.terminals').enable(cfg)`.

---@class TermAutoCmds
local M = {}

-- Helpers ---------------------------------------------------------------------

--- Create/clear a namespaced augroup.
---@param name string
---@return integer
local function augroup(name)
  return vim.api.nvim_create_augroup("terminal_autocmds_" .. name, { clear = true })
end

--- Return true if the current terminal environment is Kitty (Linux/macOS).
--- Heuristics: KITTY_LISTEN_ON set OR TERM contains "kitty".
---@return boolean
local function is_kitty()
  local env = vim.env
  if env.KITTY_LISTEN_ON and env.KITTY_LISTEN_ON ~= "" then
    return true
  end
  local term = env.TERM or ""
  return term:find("kitty", 1, true) ~= nil
end

--- Normalize an event list.
---@param ev any
---@param fallback string[]
---@return string[]
local function norm_events(ev, fallback)
  if type(ev) == "table" and #ev > 0 then return ev end
  return fallback
end

-- Defaults --------------------------------------------------------------------

---@type TermAutoCmdsCfg
local Defaults = {
  numbers = {
    enable = true,
    events = { "TermOpen" },
  },
  kitty = {
    enable = true,
    enter_padding = 0,
    enter_margin = 0,
    leave_padding = 20,
    leave_margin = 10,
  },
  auto_insert = {
    enable = false,
    events = { "TermOpen" }, -- Alternative: add "TermEnter" if one prefers aggressive insert-on-focus.
  },
}

-- Public API ------------------------------------------------------------------

--- Enable terminal-related autocommands per feature.
---@param cfg TermAutoCmdsCfg|nil
---@return nil
function M.enable(cfg)
  cfg = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), cfg or {})

  -- 1) Terminal window numbers off -------------------------------------------
  -- Description: On terminal open (or configured events), disable absolute/relative numbers locally.
  if cfg.numbers.enable then
    vim.api.nvim_create_autocmd(norm_events(cfg.numbers.events, { "TermOpen" }), {
      group = augroup("numbers"),
      callback = function(ev)
        -- Use local options to avoid bleeding into non-terminal windows.
        vim.api.nvim_buf_call(ev.buf, function()
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
    vim.api.nvim_create_autocmd("VimEnter", {
      group = augroup("kitty_enter"),
      command = kitty_cmd(cfg.kitty.enter_padding, cfg.kitty.enter_margin),
      desc = "Kitty: reduce padding/margin for a snug editor frame on startup",
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = augroup("kitty_leave"),
      command = kitty_cmd(cfg.kitty.leave_padding, cfg.kitty.leave_margin),
      desc = "Kitty: restore padding/margin when leaving Neovim",
    })
  end

  -- 3) Auto Insert in terminals ----------------------------------------------
  -- Description: Automatically switch to Insert mode on terminal open (and optionally on enter).
  if cfg.auto_insert.enable then
    vim.api.nvim_create_autocmd(norm_events(cfg.auto_insert.events, { "TermOpen" }), {
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

return M
