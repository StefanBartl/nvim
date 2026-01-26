---@module 'wkdnvchad.config.statusline.custom'

local lazy = require("lib.lazy")
local render_module = lazy.require("wkdnvchad.ui.statusline.cursor_ctl.renderer")
local progr_calc_module = lazy.require("wkdnvchad.ui.statusline.cursor_ctl.progress_calculators")
local hl_module = lazy.require("wkdnvchad.ui.statusline.modules.highlighting")
local lsp_module = lazy.require("wkdnvchad.ui.statusline.modules.lsp")
local cursor_module = lazy.require("wkdnvchad.ui.statusline.cursor_ctl")

return {
  base46 = require("wkdnvchad.config.base46"),
  ui = {
    statusline = {
      theme = "vscode_colored",

      -- Order: place cursor first, then (optional) progress, then cwd.
      order = {
        "mode",
        "git",
        "%=",
        "breadcrumbs",
        "%=",
        "diagnostics",
        "lsp",
        "cursor",
        "progress",
        "cwd",
      },

      modules = {
        --- Render LSP-aware breadcrumbs using the banded highlight utilities.
        --- @return string
        breadcrumbs = function()
          local band = lsp_module.mode_band_group()
          return hl_module.hl_open(band) .. lsp_module.render_breadcrumbs_inherit_lspfirst(band)
        end,

        --- Diagnostics as a pure segment; strip hl and rewrap with current band.
        --- @return string
        diagnostics = function()
          local okU, U = pcall(require, "nvchad.stl.utils")
          if not okU then
            return ""
          end
          local s = U.diagnostics()
          return hl_module.hl_wrap(hl_module.mode_band_group(), hl_module.stl_strip_hl(s))
        end,

        --- LSP client state, reusing the shared highlight band.
        --- @return string
        lsp = function()
          local okU, U = pcall(require, "nvchad.stl.utils")
          if not okU then
            return ""
          end
          local s = U.lsp()
          return hl_module.hl_wrap(hl_module.mode_band_group(), hl_module.stl_strip_hl(s))
        end,

        --- Cursor location + optional progress, based on the current mode.
        --- @return string
        cursor = function()
          local band = hl_module.mode_band_group()
          local mode = cursor_module.get_mode()

          if mode == "off" then
            -- Entire cursor/progress block is hidden.
            return ""
          end

          -- Always start with classic cursor string.
          local pieces = { render_module.cursor_classic() }

          -- For modes that append progress directly after the cursor block,
          -- we add compact tokens here; the separate "progress" module can
          -- stay empty or add more details if desired.
          if mode == "row_progress" then
            pieces[#pieces + 1] = render_module.pct_token(progr_calc_module.compute_row_pct(), "R")
          elseif mode == "col_progress" then
            pieces[#pieces + 1] = render_module.pct_token(progr_calc_module.compute_col_pct(), "C")
          elseif mode == "rows_cols_progress" then
            pieces[#pieces + 1] = render_module.pct_token(progr_calc_module.compute_row_pct(), "R")
            pieces[#pieces + 1] = render_module.pct_token(progr_calc_module.compute_col_pct(), "C")
          end

          return hl_module.hl_wrap(band, table.concat(pieces, ""))
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
  },
}

