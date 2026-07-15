---@module 'autocmds.general'
--- Centralized, toggleable autocmd suite with safe defaults and idempotent setup.
--- Each feature can be enabled/disabled via the `enable(cfg)` entry point.
--- Guards are included to avoid side effects in unsupported contexts.
local M = {}

local api = vim.api
local helpers = require("autocmds.general.helpers")
local DEFAULTS = require("autocmds.general.defaults").get_defaults()

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---@param cfg AutoCmds.General.Cfg|nil
---@return nil
function M.enable(cfg)
  cfg = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), cfg or {})

  -- 1) Kitty spacing tweaks on enter/leave (VimEnter, VimLeavePre)
  if cfg.kitty.enable then
    local grp = helpers.augroup((cfg.group_name or "autocmds_general") .. "_kitty_spacing")
    api.nvim_create_autocmd("VimEnter", {
      group = grp,
      callback = function()
        helpers.kitty_set_spacing(cfg.kitty.enter_padding, cfg.kitty.enter_margin)
      end,
      desc = "Kitty: reduce spacing for the current window on VimEnter",
    })
    api.nvim_create_autocmd("VimLeavePre", {
      group = grp,
      callback = function()
        helpers.kitty_set_spacing(cfg.kitty.leave_padding, cfg.kitty.leave_margin)
      end,
      desc = "Kitty: restore spacing for the current window on VimLeavePre",
    })
  end

  -- 2) Cursorline only in the active window
  if cfg.cursorline.enable then
    local grp_show = helpers.augroup((cfg.group_name or "autocmds_general") .. "_cursorline_show")
    api.nvim_create_autocmd(cfg.cursorline.show_events, {
      group = grp_show,
      callback = function(event)
        -- Only enable cursorline for "normal" buffers (empty buftype).
        if vim.bo[event.buf].buftype == "" then
          vim.opt_local.cursorline = true
        end
      end,
      desc = "Enable cursorline in the active window on relevant events",
    })

    local grp_hide = helpers.augroup((cfg.group_name or "autocmds_general") .. "_cursorline_hide")
    api.nvim_create_autocmd(cfg.cursorline.hide_events, {
      group = grp_hide,
      callback = function()
        vim.opt_local.cursorline = false
      end,
      desc = "Disable cursorline in inactive windows or insert mode",
    })
  end

  -- 3) Jump to last location when reopening a file (BufReadPost)
  if cfg.last_loc.enable then
    local grp = helpers.augroup((cfg.group_name or "autocmds_general") .. "_last_loc")
    api.nvim_create_autocmd("BufReadPost", {
      group = grp,
      callback = function(event)
        local buf = event.buf
        -- Skip specific filetypes (commit messages, rebase plans, etc.)
        if vim.tbl_contains(cfg.last_loc.exclude, vim.bo[buf].filetype) then
          return
        end
        -- Guard against running twice per buffer
        if vim.b[buf].__custom_last_loc_done then
          return
        end
        vim.b[buf].__custom_last_loc_done = true

        -- Retrieve the last-position mark (default: `"`).
        local mark = api.nvim_buf_get_mark(buf, cfg.last_loc.mark)
        local lcount = api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
          -- pcall to avoid throwing if the window is in a nonstandard state.
          pcall(api.nvim_win_set_cursor, 0, mark)
        end
      end,
      desc = "Jump to the last cursor position on file open",
    })
  end

  -- 4) Redirect spurious [No Name] buffers left behind by a close, to a real
  --    buffer if one exists (BufDelete/BufWipeout, WinClosed)
  if cfg.no_name_guard.enable then
    local grp = helpers.augroup((cfg.group_name or "autocmds_general") .. "_no_name_guard")
    api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
      group = grp,
      callback = function(event)
        helpers.no_name_guard_sweep({ [event.buf] = true })
      end,
      desc = "After a buffer is deleted, redirect any window left showing a spurious [No Name] buffer to a real one",
    })
    api.nvim_create_autocmd("WinClosed", {
      group = grp,
      callback = function()
        helpers.no_name_guard_sweep({})
      end,
      desc = "After a window closes, redirect any window left showing a spurious [No Name] buffer to a real one",
    })
  end

end

---@type AutoCmds.General
return M
