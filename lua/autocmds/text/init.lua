---@module 'autocmds.text'
--- Text-focused autocommands with feature flags and detailed options.
--- Provides safe trimming helpers (trailing whitespace, blank-line cleanup with cursor preservation)
--- and a “last cursor position” restore on file reopen. Each feature has its own augroup and can be
--- toggled independently via `require('autocmds.text').enable(cfg)`.

local M = {}
local api, cmd, bo = vim.api, vim.cmd, vim.bo
local tbl_contains = vim.tbl_contains

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local lazy = require("lib.lua.lazy")
local augroup_lib = lazy.require("lib.nvim.bindings.autocmd.augroup")
local augroup = augroup_lib.create.clear
local autocmd_lib = lazy.require("lib.nvim.bindings.autocmd")
local norm_pattern = autocmd_lib.norm_pattern
local Autocmd = lazy.require("lib.nvim.bindings.autocmd")

--- Check whether the current buffer should be processed given the config gates.
---@param buf integer
---@param ignore_filetypes string[]|nil
---@param ignore_buftypes string[]|nil
---@param only_modifiable boolean|nil
---@param only_normal_bufs boolean|nil
---@return boolean
local function should_process(
  buf,
  ignore_filetypes,
  ignore_buftypes,
  only_modifiable,
  only_normal_bufs
)
  local bt = bo[buf].buftype or ""
  local ft = bo[buf].filetype or ""
  if only_normal_bufs ~= false and bt ~= "" then
    return false
  end
  if only_modifiable ~= false and not bo[buf].modifiable then
    return false
  end
  if ignore_filetypes and tbl_contains(ignore_filetypes, ft) then
    return false
  end
  if ignore_buftypes and tbl_contains(ignore_buftypes, bt) then
    return false
  end
  return true
end

--------------------------------------------------------------------------------
-- Defaults --------------------------------------------------------------------
--------------------------------------------------------------------------------

---@type AutoCmds.Text.Cfg
local DEFAULTS = require("autocmds.text.defaults").get_defaults()

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Enable text-related autocommands per feature.
---@param cfg AutoCmds.Text.Cfg|nil
---@return nil
function M.enable(cfg)
  cfg = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), cfg or {})

  -- 1) Trim trailing whitespace on save --------------------------------------
  -- Description: On BufWritePre, remove trailing spaces at EOL in eligible buffers.
  if cfg.trim_trailing.enable then
    Autocmd.create("BufWritePre", function(ev)
      local buf = ev.buf
      if
        not should_process(
          buf,
          cfg.trim_trailing.ignore_filetypes,
          cfg.trim_trailing.ignore_buftypes,
          cfg.trim_trailing.only_modifiable,
          cfg.trim_trailing.only_normal_bufs
        )
      then
        return
      end
      -- Use a buffer-local :substitute that ignores errors (`e` flag) and is silent.
      -- The pattern `\s\+$` trims any whitespace at the end of lines.
      api.nvim_buf_call(buf, function()
        cmd([[silent! keepjumps keeppatterns %s/\s\+$//e]])
      end)
    end, {
      group = augroup("trim_trailing"),
      pattern = norm_pattern(cfg.trim_trailing.pattern),
      desc = "Trim trailing whitespace on save",
    })
  end

  -- 2) Trim whitespace-only lines (blank lines) while preserving cursor ------
  -- Description: On BufWritePre, collapse whitespace on fully empty lines; optionally preserve cursor.
  if cfg.trim_blank.enable then
    Autocmd.create("BufWritePre", function(ev)
      local buf = ev.buf
      if
        not should_process(
          buf,
          cfg.trim_blank.ignore_filetypes,
          cfg.trim_blank.ignore_buftypes,
          cfg.trim_blank.only_modifiable,
          cfg.trim_blank.only_normal_bufs
        )
      then
        return
      end
      local row, col
      if cfg.trim_blank.preserve_cursor ~= false then
        ---@diagnostic disable-next-line: deprecated
        row, col = unpack(api.nvim_win_get_cursor(0))
      end
      -- Substitute leading whitespace on empty lines with nothing.
      -- `^\s*$` matches lines entirely composed of whitespace.
      api.nvim_buf_call(buf, function()
        cmd([[silent! keepjumps keeppatterns %s/^\s*$//e]])
      end)
      if row and col then
        pcall(api.nvim_win_set_cursor, 0, { row, col })
      end
    end, {
      group = augroup("trim_blank"),
      pattern = norm_pattern(cfg.trim_blank.pattern),
      desc = "Trim whitespace on fully blank lines (preserve cursor)",
    })
  end

  -- 3) Restore last cursor position on reopen --------------------------------
  -- Description: On BufReadPost, jump to the last known cursor position, respecting exclusions.
  if cfg.last_loc.enable then
    Autocmd.create("BufReadPost", function(ev)
      local buf = ev.buf
      local ft = bo[buf].filetype or ""
      if cfg.last_loc.exclude and tbl_contains(cfg.last_loc.exclude, ft) then
        return
      end
      -- Get the mark `"` (last known cursor position in this file).
      local target_line = vim.fn.line([['"]])
      local last_line = api.nvim_buf_line_count(buf)
      local min_line = cfg.last_loc.min_line or 1
      if target_line >= min_line and target_line <= last_line then
        -- Use pcall to avoid errors in special windows.
        pcall(function()
          cmd([[normal! g`"]])
        end)
      end
    end, {
      group = augroup("last_loc"),
      pattern = norm_pattern(cfg.last_loc.pattern),
      desc = "Restore last cursor position after reading a buffer",
    })
  end
end

---@type AutoCmds.Text
return M
