---@module 'ui.base_config'
--- Returns the base configuration for the UI module.

---@return table
return {
  ui = {
    statusline = {
      -- minimale Reihenfolge: immer noch theme-agnostisch
      order = { "mode", "git", "%=", "cwd", "%=", "diagnostics", "lsp", "cursor", "progress"},

      modules = {
        --- @return string
        cursor = function()
          local ok_r, renderer = pcall(require, "ui.CursorCtl.renderer")
          local ok_p, pct = pcall(require, "ui.CursorCtl.progress_calculators")

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

  base46 = {
    transparency = false,
    theme_toggle = { "vim_default", "tokyonight" },
    theme = "vim_default",
  },
}
