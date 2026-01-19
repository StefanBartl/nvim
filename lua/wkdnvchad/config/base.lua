---@module 'wkdnvchad.config.base'
--- Returns the base configuration for the UI module.

---@return table
return {
  base46 = require("wkdnvchad.config.base46"),
  ui = {
    statusline = {
      order = { "mode", "git",  "%=", "cwd", "%=", "diagnostics", "lsp", "cursor", "progress" },

      modules = {
        --- @return string
        cursor = function()
          local ok_r, renderer = pcall(require, "wkdnvchad.ui.statusline.cursor_ctl.renderer")
          local ok_p, pct = pcall(require, "wkdnvchad.ui.statusline.cursor_ctl.progress_calculators")

          if not ok_r then
            return " Ln %l, Col %v "
          end

          local parts = { renderer.cursor_classic() }

          if ok_p then
            parts[#parts + 1] = renderer.pct_token(pct.compute_row_pct(), "R")
          end

          return table.concat(parts, "")
        end,

        --- @return string
        cwd = function()
          return vim.fn.getcwd()
        end,
        progress = function()
          return "" -- no extra block needed; compact string lives in 'cursor'
        end,
      },
    },
  },
}
