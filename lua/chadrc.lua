---@module 'chadrc.lua'
--- NVChad UI configuration with modular statusline.

local base_cfg = require("ui.base_config")

-- ==== Load Core statusline if custom fails --------------------------------------------------
local ok_util, utl = pcall(require, "ui.stl_modules.lsp_based")
local custom_stl = true

if not custom_stl then
  if not ok_util then
    vim.notify("Failed to load Custom NVChad statusline utilities; using default config.", vim.log.levels.WARN)
  end

  return base_cfg
end

-- =============================================
-- ==== Load and render Custom Stausline UI ====

local M = {}
local CursorCtl = require("ui.CursorCtl") -- Local state + API for cursor/progress mode
local pct = require("ui.CursorCtl.progress_calculators") -- Progress calculators
local renderer = require("ui.CursorCtl.renderer") -- Renderers for cursor/progress

-- Controller/Logic (assembly of the statusline spec) -----------------------

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
        if not ok or not mod then
          return ""
        end
        local band = mod.mode_band_group()
        return mod.hl_open(band) .. mod.render_breadcrumbs_inherit_lspfirst(band)
      end,

      --- Diagnostics as a pure segment; strip hl and rewrap with current band.
      --- @return string
      diagnostics = function()
        local okU, U = pcall(require, "nvchad.stl.utils")
        if not okU then
          return ""
        end
        local s = U.diagnostics()
        return utl.hl_wrap(utl.mode_band_group(), utl.stl_strip_hl(s))
      end,

      --- LSP client state, reusing the shared highlight band.
      --- @return string
      lsp = function()
        local okU, U = pcall(require, "nvchad.stl.utils")
        if not okU then
          return ""
        end
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
        local pieces = { renderer.cursor_classic() }

        -- For modes that append progress directly after the cursor block,
        -- we add compact tokens here; the separate "progress" module can
        -- stay empty or add more details if desired.
        if mode == "row_progress" then
          pieces[#pieces + 1] = renderer.pct_token(pct.compute_row_pct(), "R")
        elseif mode == "col_progress" then
          pieces[#pieces + 1] = renderer.pct_token(pct.compute_col_pct(), "C")
        elseif mode == "rows_cols_progress" then
          pieces[#pieces + 1] = renderer.pct_token(pct.compute_row_pct(), "R")
          pieces[#pieces + 1] = renderer.pct_token(pct.compute_col_pct(), "C")
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

M.ui = {
  tabufline = {
    bufwidth = 21,        -- normale Tabs
    bufwidth_cur = 27,    -- aktueller Tab (größer)
  },
}



-- ==========================
-- ==== Load UI Settings ====

--- ==== Base46 theme configuration =============
M.base46 = {
  transparency = true,
  theme_toggle = { "rosepine", "rosepine" },
   theme = "rosepine",
}

--- =============================
--- ====  Public API exports ====

---@param mode CursorProgressMode
---@return nil
function M.set_cursor_progress_mode(mode)
  CursorCtl.set_mode(mode)
end

---@return string new_mode
function M.toggle_cursor_progress_mode()
  return CursorCtl.toggle_mode()
end

---@return string mode
function M.get_cursor_progress_mode()
  return CursorCtl.get_mode()
end

return M
