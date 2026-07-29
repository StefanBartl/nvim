---@module 'wkdnvchad.config.statusline.normal'
--- Default NvChad statusline, plus three additions: the replacer.nvim progress
--- component, filetree.nvim's cwd-mode badge, and the cursor_ctl row/column
--- progress indicator. NvChad's `nvchad.stl.utils.generate()` falls back to
--- its own built-in "default" theme order/modules whenever `order`/`modules`
--- are nil (see nvchad/stl/default.lua + nvchad/stl/utils.lua in the "ui"
--- plugin) — so this must spell out that same default order explicitly to
--- extend it, rather than leaving it nil like before.

local lazy = require("lib.lua.lazy")
local render_module = lazy.require("wkdnvchad.ui.statusline.cursor_ctl.renderer")
local progr_calc_module = lazy.require("wkdnvchad.ui.statusline.cursor_ctl.progress_calculators")
local cursor_module = lazy.require("wkdnvchad.ui.statusline.cursor_ctl")

local M = {}

-- Mirrors nvchad.stl.utils' `orders.default`, with "replacer_progress" and
-- "filetree_cwd_mode" inserted before "cwd" (both are about *where you are*,
-- same neighbourhood as NvChad's own cwd module). If NvChad ever changes its
-- own default order, update this list to match (see nvchad/stl/utils.lua).
local order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "replacer_progress", "filetree_cwd_mode", "cwd", "cursor" }

M.ui = {
  statusline = {
    order = order,
    modules = {
      -- Only "replacer_progress" and "filetree_cwd_mode" are provided here;
      -- every other key in `order` above resolves to NvChad's own built-in
      -- "default" theme module (mode/file/git/lsp_msg/diagnostics/lsp/cwd/
      -- cursor), which `generate()` merges this table into rather than
      -- replaces.
      replacer_progress = require("wkdnvchad.ui.statusline.modules.replacer_progress"),
      filetree_cwd_mode = require("wkdnvchad.ui.statusline.modules.filetree_cwd_mode"),

      -- Overrides NvChad's built-in `cursor` (a fixed "%l/%v" string) with the
      -- cursor_ctl one, so the row/column progress indicator works in this
      -- variant too — it only ever lived in `custom.lua`, and was therefore
      -- lost when STATUSLINE_VARIANT switched to "normal". Uses the default
      -- theme's own separator/highlight groups (St_pos_*), not custom.lua's
      -- `get_separators()`, which is tied to `separator_style = "round"`.
      cursor = function()
        local mode = cursor_module.get_mode()
        if mode == "off" then
          return ""
        end

        -- Same left separator NvChad's own default `cursor` uses, resolved the
        -- same way (nvchad/stl/default.lua lines 5-8) so it tracks whatever
        -- `separator_style` is configured instead of hardcoding one glyph.
        local sep_style = require("nvconfig").ui.statusline.separator_style
        local sep_icons = require("nvchad.stl.utils").separators
        local separators = (type(sep_style) == "table" and sep_style) or sep_icons[sep_style]
        local sep_l = separators["left"]

        local pieces = { render_module.cursor_classic() }

        if mode == "row_progress" then
          pieces[#pieces + 1] = render_module.pct_token(progr_calc_module.compute_row_pct(), "R")
        elseif mode == "col_progress" then
          pieces[#pieces + 1] = render_module.pct_token(progr_calc_module.compute_col_pct(), "C")
        elseif mode == "rows_cols_progress" then
          pieces[#pieces + 1] = render_module.pct_token(progr_calc_module.compute_row_pct(), "R")
          pieces[#pieces + 1] = render_module.pct_token(progr_calc_module.compute_col_pct(), "C")
        end

        return "%#St_pos_sep#"
          .. sep_l
          .. "%#St_pos_icon# %#St_pos_text#"
          .. table.concat(pieces, "")
      end,
    },
  },
}

return M
