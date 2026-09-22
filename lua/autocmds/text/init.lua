---@module 'autocmds.text'
--- Text-focused autocommands with feature flags. Safe trimming (trailing
--- whitespace, blank-line cleanup with cursor preservation) and a "last cursor
--- position" restore on reopen. Each feature has its own augroup and toggles
--- independently via `require('autocmds.text').enable(cfg)`.

local M = {}
local api, cmd, bo = vim.api, vim.cmd, vim.bo
local tbl_contains = vim.tbl_contains

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local lazy = require("lib.lua.lazy")
local augroup_lib = lazy.require("lib.nvim.bindings.autocmd.augroup")
local augroup = augroup_lib.create.clear
local Autocmd = lazy.require("lib.nvim.bindings.autocmd")
local norm_pattern = Autocmd.norm_pattern

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
      local row, col
      if cfg.trim_trailing.preserve_cursor ~= false then
        ---@diagnostic disable-next-line: deprecated
        row, col = unpack(api.nvim_win_get_cursor(0))
      end
      -- Use a buffer-local :substitute that ignores errors (`e` flag) and is silent.
      -- The pattern `\s\+$` trims any whitespace at the end of lines. Like any
      -- `:substitute`, this leaves the cursor on the last line it changed
      -- (`keepjumps` only skips the jumplist, not the cursor itself) -- e.g. a
      -- trailing-whitespace line far above where you were editing pulls the
      -- cursor back there once the write completes.
      api.nvim_buf_call(buf, function()
        cmd([[silent! keepjumps keeppatterns %s/\s\+$//e]])
      end)
      if row and col then
        -- The trimmed line may now be shorter than `col`; clamp instead of
        -- letting nvim_win_set_cursor error (and pcall silently swallow it,
        -- leaving the cursor wherever the substitute above put it).
        local target_line = api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
        if target_line then
          col = math.min(col, math.max(0, #target_line - 1))
        end
        pcall(api.nvim_win_set_cursor, 0, { row, col })
      end
    end, {
      group = augroup("trim_trailing"),
      pattern = norm_pattern(cfg.trim_trailing.pattern),
      desc = "Trim trailing whitespace on save",
    })
  end

  -- 2) Trim whitespace-only lines (blank lines) while preserving cursor ------
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
        -- Same clamp as trim_trailing: if the cursor's own line was blanked
        -- out, its length just dropped to 0 and the original `col` would
        -- make nvim_win_set_cursor error (silently, via pcall).
        local target_line = api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
        if target_line then
          col = math.min(col, math.max(0, #target_line - 1))
        end
        pcall(api.nvim_win_set_cursor, 0, { row, col })
      end
    end, {
      group = augroup("trim_blank"),
      pattern = norm_pattern(cfg.trim_blank.pattern),
      desc = "Trim whitespace on fully blank lines (preserve cursor)",
    })
  end

  -- 3) Restore last cursor position on reopen --------------------------------
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

  -- 4) Re-close folds a save's own edits reopened ----------------------------
  -- With `foldmethod=expr` (markdown.nvim's heading folds, Treesitter's, ...)
  -- the fold engine can recompute levels from scratch once *anything* in the
  -- buffer changes, dropping manually-closed state back to whatever
  -- 'foldlevel' says -- typically "all open". The BufWritePre hooks above (or
  -- a formatter, or any other plugin's own save hook) are exactly this kind
  -- of edit. Snapshot which ranges were closed before the write and re-close
  -- them after, per window, rather than chasing every possible source of the
  -- reopen.
  if cfg.preserve_folds.enable then
    -- Module-local, not `vim.b`: this only needs to survive from BufWritePre
    -- to the matching BufWritePost of the same write, in this same process --
    -- a plain table keyed by bufnr avoids round-tripping window handles
    -- through the buffer-var msgpack machinery for no benefit.
    ---@type table<integer, table<integer, [integer, integer][]>>
    local pending = {}

    -- Scans every line 1..last, so this costs O(buffer size) in the (common)
    -- case where nothing is closed. Only worth paying on `foldmethod=expr`
    -- windows -- markdown.nvim's heading folds, Treesitter's -- which is
    -- exactly the class of fold implementation that recomputes levels from
    -- scratch and is prone to losing manual close state; `manual`/`marker`/
    -- `syntax`/`indent`/`diff` (the vast majority of buffers, most of which
    -- have no folds at all) skip the scan entirely.
    ---@return [integer, integer][]
    local function closed_ranges()
      if vim.wo.foldmethod ~= "expr" then
        return {}
      end
      local ranges = {}
      local last = api.nvim_buf_line_count(0)
      local lnum = 1
      while lnum <= last do
        local closed_at = vim.fn.foldclosed(lnum)
        if closed_at == lnum then
          local endl = vim.fn.foldclosedend(lnum)
          ranges[#ranges + 1] = { lnum, endl }
          lnum = endl + 1
        else
          lnum = lnum + 1
        end
      end
      return ranges
    end

    Autocmd.create("BufWritePre", function(ev)
      local buf = ev.buf
      if
        not should_process(
          buf,
          cfg.preserve_folds.ignore_filetypes,
          cfg.preserve_folds.ignore_buftypes,
          false,
          cfg.preserve_folds.only_normal_bufs
        )
      then
        return
      end
      local per_win = {}
      for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        local ok, ranges = pcall(api.nvim_win_call, win, closed_ranges)
        if ok and ranges and #ranges > 0 then
          per_win[win] = ranges
        end
      end
      -- Always (re)assign, including to nil: a previous write that never
      -- reached BufWritePost (failed, or aborted by another plugin's own
      -- BufWritePre) would otherwise leave a stale entry here, which this
      -- write's BufWritePost would then apply on top of a state the user may
      -- have since changed on purpose (e.g. manually reopened that fold).
      pending[buf] = next(per_win) and per_win or nil
    end, {
      group = augroup("preserve_folds_pre"),
      pattern = norm_pattern(cfg.preserve_folds.pattern),
      desc = "Snapshot manually closed fold ranges before a save",
    })

    Autocmd.create("BufWritePost", function(ev)
      local buf = ev.buf
      local per_win = pending[buf]
      if not per_win then
        return
      end
      pending[buf] = nil
      for win, ranges in pairs(per_win) do
        if api.nvim_win_is_valid(win) then
          api.nvim_win_call(win, function()
            for _, r in ipairs(ranges) do
              -- Skip a range that is still closed: `:foldclose` on an
              -- already-closed fold behaves like a second `zc` and closes
              -- the *parent* fold instead (nothing left to close at this
              -- level) -- exactly the kind of unwanted extra fold-closing
              -- this feature exists to avoid. Only re-close what the save
              -- actually reopened.
              if vim.fn.foldclosed(r[1]) ~= r[1] then
                -- `vim.cmd` is a callable table, not a plain function, so
                -- `pcall(cmd, ...)` does not reliably invoke it -- the
                -- closure form does (see mdtable.lua's own note on this).
                pcall(function()
                  cmd(r[1] .. "," .. r[2] .. "foldclose")
                end)
              end
            end
          end)
        end
      end
    end, {
      group = augroup("preserve_folds_post"),
      pattern = norm_pattern(cfg.preserve_folds.pattern),
      desc = "Re-close whatever fold ranges were closed before the save",
    })
  end
end

---@type AutoCmds.Text
return M
