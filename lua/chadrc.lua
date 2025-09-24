---@module 'chadrc.lua'
---@brief NVChad UI configuration with defensive requires and modular statusline.

-- 1) Core if statusline fails --------------------------------------------------
local ok_util, utl = pcall(require, "ui.stl_modules.lsp_based")
if not ok_util then
  return {
    ui = {
      statusline = {
        theme = "vscode_colored",
        order = { "mode", "git", "%=", "breadcrumbs", "%=", "diagnostics", "lsp", "cursor", "cwd" },
        modules = {},
      },
    },
    base46 = { transparency = false, theme_toggle = { "tokyonight", "vim_default" }, theme = "tokyonight" },
  }
end

-- 2) Local state + API for cursor/progress mode --------------------------------
-- Available modes:
--   "classic"            → show "Ln %l, Col %v", no extra progress
--   "row_progress"       → classic cursor + row progress percentage+bar
--   "col_progress"       → classic cursor + column progress percentage+bar
--   "rows_cols_progress" → classic cursor + both row and column progress
--   "off"                → hide cursor+progress segment entirely
---@alias CursorProgressMode '"classic"'|'"row_progress"'|'"col_progress"'|'"rows_cols_progress"'|'"off"'

---@class CursorProgressCtl
---@field mode CursorProgressMode
local CursorCtl = { mode = "row_progress"  }

--- Set mode explicitly (no-op on invalid input).
--- @param m string
--- @return nil
function CursorCtl.set_mode(m)
  if m == "classic" or m == "row_progress" or m == "col_progress" or m == "rows_cols_progress" or m == "off" then
    CursorCtl.mode = m
  end
end

--- Cycle through modes in a stable order.
--- @return string new_mode
function CursorCtl.toggle_mode()
  local order = { "classic", "row_progress", "col_progress", "rows_cols_progress", "off" }
  local idx = 1
  for i, v in ipairs(order) do
    if v == CursorCtl.mode then idx = i break end
  end
  idx = (idx % #order) + 1
  CursorCtl.mode = order[idx]
  return CursorCtl.mode
end

--- Get current mode.
--- @return string
function CursorCtl.get_mode()
  return CursorCtl.mode
end

-- 3) Helpers: escaping and bar rendering --------------------------------------

--- Escape "%" for statusline so it is treated as a literal percent sign.
--- @param s string
--- @return string
local function esc_percent(s)
  local out = s:gsub("%%", "%%%%")
  return out
end

--- Compute an 8-level bar index from a 0..100 percentage.
--- @param pct integer
--- @return string
local function pct_bar(pct)
  if pct < 0 then pct = 0 elseif pct > 100 then pct = 100 end
  local bars = { "▁","▂","▃","▄","▅","▆","▇","█" }
  local step = 100 / #bars
  local idx  = math.floor(pct / step) + 1
  if idx < 1 then idx = 1 elseif idx > #bars then idx = #bars end
  return bars[idx]
end

-- 4) Progress calculators ------------------------------------------------------

--- Compute row percentage based on cursor line and total buffer lines.
--- @return integer|nil
local function compute_row_pct()
  local ok_cur, cursor = pcall(vim.api.nvim_win_get_cursor, 0)
  local ok_cnt, total  = pcall(vim.api.nvim_buf_line_count, 0)
  if not ok_cur or not ok_cnt or not cursor or not total or total < 1 then
    return nil
  end
  local line = cursor[1]
  if total == 1 then return 100 end
  local pct = math.floor(((line - 1) / (total - 1)) * 100 + 0.5)
  if pct < 0 then pct = 0 elseif pct > 100 then pct = 100 end
  return pct
end

-- Replace the previous compute_col_pct() with this virtcol-based version.
--- Compute column percentage using visual screen columns (virtcol).
--- This reflects what the user sees (tabs, wide chars) and avoids encoding APIs.
--- @return integer|nil
local function compute_col_pct()
  -- Safe cursor retrieval
  local ok_cur, _ = pcall(vim.api.nvim_win_get_cursor, 0)
  if not ok_cur then return nil end

  -- virtcol('.') is 1-based visual column at cursor; virtcol('$') is last visual col on the line
  local ok_curvc, cur_vc = pcall(vim.fn.virtcol, ".")
  local ok_endvc, end_vc = pcall(vim.fn.virtcol, "$")
  if not ok_curvc or not ok_endvc or type(cur_vc) ~= "number" or type(end_vc) ~= "number" then
    return nil
  end

  if end_vc <= 1 then
    -- Empty line or single visual cell: treat as 100% to avoid division by zero.
    return 100
  end

  -- Normalize to [0,100], using 0-based numerator (cur_vc - 1) vs (end_vc - 1)
  local pct = math.floor(((cur_vc - 1) / (end_vc - 1)) * 100 + 0.5)
  if pct < 0 then pct = 0 elseif pct > 100 then pct = 100 end
  return pct
end


-- 5) Renderers for progress text ----------------------------------------------

--- Build a compact progress token like "  37%▅ " (escaped for statusline).
--- @param pct integer|nil
--- @param prefix string  -- e.g. "R" or "C" or ""
--- @return string
local function render_pct_token(pct, prefix)
  if not pct then
    return esc_percent("  --%  ")
  end
  local bar = pct_bar(pct)
  local txt = string.format(" %s%3d%%%s ", (prefix and (prefix .. "") or ""), pct, bar)
  return esc_percent(txt)
end

--- Classic cursor string (no escaping; uses statusline placeholders).
--- @return string
local function render_cursor_classic()
  -- Keep placeholders so NVim fills line/col dynamically.
  return " Ln %l, Col %v "
end

-- 6) Controller/Logic (assembly of the statusline spec) -----------------------
local M = {}

M.ui = {
  statusline = {
    theme = "vscode_colored",

    -- Order: place cursor first, then (optional) progress, then cwd.
    order = { "mode", "git", "%=", "breadcrumbs", "%=", "diagnostics", "lsp", "cursor", "progress", "cwd" },

    modules = {
      --- Render LSP-aware breadcrumbs using the banded highlight utilities.
      --- @return string
      breadcrumbs = function()
        local ok, mod = pcall(require, "ui.stl_modules.lsp_based")
        if not ok or not mod then return "" end
        local band = mod.mode_band_group()
        return mod.hl_open(band) .. mod.render_breadcrumbs_inherit_lspfirst(band)
      end,

      --- Diagnostics as a pure segment; strip hl and rewrap with current band.
      --- @return string
      diagnostics = function()
        local okU, U = pcall(require, "nvchad.stl.utils")
        if not okU then return "" end
        local s = U.diagnostics()
        return utl.hl_wrap(utl.mode_band_group(), utl.stl_strip_hl(s))
      end,

      --- LSP client state, reusing the shared highlight band.
      --- @return string
      lsp = function()
        local okU, U = pcall(require, "nvchad.stl.utils")
        if not okU then return "" end
        local s = U.lsp()
        return utl.hl_wrap(utl.mode_band_group(), utl.stl_strip_hl(s))
      end,

      --- Cursor location + optional progress, based on the current mode.
      --- @return string
      cursor = function()
        local band = utl.mode_band_group()
        local mode = CursorCtl.get_mode()

        if mode == "off" then
          -- Entire cursor/progress block is hidden.
          return ""
        end

        -- Always start with classic cursor string.
        local pieces = { render_cursor_classic() }

        -- For modes that append progress directly after the cursor block,
        -- we add compact tokens here; the separate "progress" module can
        -- stay empty or add more details if desired.
        if mode == "row_progress" then
          pieces[#pieces + 1] = render_pct_token(compute_row_pct(), "R")
        elseif mode == "col_progress" then
          pieces[#pieces + 1] = render_pct_token(compute_col_pct(), "C")
        elseif mode == "rows_cols_progress" then
          pieces[#pieces + 1] = render_pct_token(compute_row_pct(), "R")
          pieces[#pieces + 1] = render_pct_token(compute_col_pct(), "C")
        end

        return utl.hl_wrap(band, table.concat(pieces, ""))
      end,

      --- Optional extra progress area (kept for compatibility).
      --- In this setup it returns empty, because we already append progress
      --- directly after the cursor module per mode.
      --- If preferred, one can move the progress tokens from 'cursor' to here.
      --- @return string
      progress = function()
        return "" -- no extra block needed; compact string lives in 'cursor'
      end,
    },
  },
}

M.base46 = {
  transparency = false,
  theme_toggle = { "tokyonight", "vim_default" },
  theme = "tokyonight",
}

-- 7) Public API exports for toggling (to be bound by the user elsewhere) -------
--- @param mode CursorProgressMode
--- @return nil
function M.set_cursor_progress_mode(mode)
  CursorCtl.set_mode(mode)
end

--- @return string new_mode
function M.toggle_cursor_progress_mode()
  return CursorCtl.toggle_mode()
end

--- @return string
function M.get_cursor_progress_mode()
  return CursorCtl.get_mode()
end

-- 8) Windows shell handling with strict guards --------------------------------
if vim and vim.g and vim.g.is_windows and vim.g.is_pwsh then
  vim.opt.shell = "pwsh"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

return M
