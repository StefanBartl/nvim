---@module 'autocmds.text'
--- Text-focused autocommands with feature flags and detailed options.
--- Provides safe trimming helpers (trailing whitespace, blank-line cleanup with cursor preservation)
--- and a “last cursor position” restore on file reopen. Each feature has its own augroup and can be
--- toggled independently via `require('autocmds.text').enable(cfg)`.

---@class TextAutoCmds
local M = {}

-- Helpers ---------------------------------------------------------------------

--- Create/clear a namespaced augroup.
---@param name string
---@return integer
local function augroup(name)
  return vim.api.nvim_create_augroup("text_autocmds_" .. name, { clear = true })
end

--- Check whether the current buffer should be processed given the config gates.
---@param buf integer
---@param ignore_filetypes string[]|nil
---@param ignore_buftypes string[]|nil
---@param only_modifiable boolean|nil
---@param only_normal_bufs boolean|nil
---@return boolean
local function should_process(buf, ignore_filetypes, ignore_buftypes, only_modifiable, only_normal_bufs)
  local bt = vim.bo[buf].buftype or ""
  local ft = vim.bo[buf].filetype or ""
  if only_normal_bufs ~= false and bt ~= "" then
    return false
  end
  if only_modifiable ~= false and not vim.bo[buf].modifiable then
    return false
  end
  if ignore_filetypes and vim.tbl_contains(ignore_filetypes, ft) then
    return false
  end
  if ignore_buftypes and vim.tbl_contains(ignore_buftypes, bt) then
    return false
  end
  return true
end

--- Normalize an autocmd pattern field.
---@param pat any
---@return string|string[]
local function norm_pattern(pat)
  if pat == nil then
    return "*"
  end
  return pat
end

-- Defaults --------------------------------------------------------------------

---@type AutoCmds.Text.Cfg
local Defaults = {
  trim_trailing = {
    enable = true,
    pattern = "*",
    ignore_filetypes = { "diff" },
    ignore_buftypes = { "nofile", "prompt" },
    only_modifiable = true,
    only_normal_bufs = true,
  },
  trim_blank = {
    enable = true,
    pattern = "*",
    preserve_cursor = true,
    ignore_filetypes = { "diff" },
    ignore_buftypes = { "nofile", "prompt" },
    only_modifiable = true,
    only_normal_bufs = true,
  },
  last_loc = {
    enable = true,
    pattern = "*",
    exclude = { "commit", "gitrebase", "xxd" },
    min_line = 1,
  },
}

-- Public API ------------------------------------------------------------------

--- Enable text-related autocommands per feature.
---@param cfg AutoCmds.Text.Cfg|nil
---@return nil
function M.enable(cfg)
  cfg = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), cfg or {})

  -- 1) Trim trailing whitespace on save --------------------------------------
  -- Description: On BufWritePre, remove trailing spaces at EOL in eligible buffers.
  if cfg.trim_trailing.enable then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup("trim_trailing"),
      pattern = norm_pattern(cfg.trim_trailing.pattern),
      callback = function(ev)
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
        vim.api.nvim_buf_call(buf, function()
          vim.cmd([[silent! keepjumps keeppatterns %s/\s\+$//e]])
        end)
      end,
      desc = "Trim trailing whitespace on save",
    })
  end

  -- 2) Trim whitespace-only lines (blank lines) while preserving cursor ------
  -- Description: On BufWritePre, collapse whitespace on fully empty lines; optionally preserve cursor.
  if cfg.trim_blank.enable then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup("trim_blank"),
      pattern = norm_pattern(cfg.trim_blank.pattern),
      callback = function(ev)
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
          row, col = unpack(vim.api.nvim_win_get_cursor(0))
        end
        -- Substitute leading whitespace on empty lines with nothing.
        -- `^\s*$` matches lines entirely composed of whitespace.
        vim.api.nvim_buf_call(buf, function()
          vim.cmd([[silent! keepjumps keeppatterns %s/^\s*$//e]])
        end)
        if row and col then
          pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
        end
      end,
      desc = "Trim whitespace on fully blank lines (preserve cursor)",
    })
  end

  -- 3) Restore last cursor position on reopen --------------------------------
  -- Description: On BufReadPost, jump to the last known cursor position, respecting exclusions.
  if cfg.last_loc.enable then
    vim.api.nvim_create_autocmd("BufReadPost", {
      group = augroup("last_loc"),
      pattern = norm_pattern(cfg.last_loc.pattern),
      callback = function(ev)
        local buf = ev.buf
        local ft = vim.bo[buf].filetype or ""
        if cfg.last_loc.exclude and vim.tbl_contains(cfg.last_loc.exclude, ft) then
          return
        end
        -- Get the mark `"` (last known cursor position in this file).
        local target_line = vim.fn.line([['"]])
        local last_line = vim.api.nvim_buf_line_count(buf)
        local min_line = cfg.last_loc.min_line or 1
        if target_line >= min_line and target_line <= last_line then
          -- Use pcall to avoid errors in special windows.
          pcall(function()
            vim.cmd([[normal! g`"]])
          end)
        end
      end,
      desc = "Restore last cursor position after reading a buffer",
    })
  end
end

return M
