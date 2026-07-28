---@module 'wkdnvchad.config.statusline.normal'
--- Default NvChad statusline (no customization), plus the replacer.nvim
--- progress component. NvChad's `nvchad.stl.utils.generate()` falls back to
--- its own built-in "default" theme order/modules whenever `order`/`modules`
--- are nil (see nvchad/stl/default.lua + nvchad/stl/utils.lua in the "ui"
--- plugin) — so this must spell out that same default order explicitly to
--- extend it, rather than leaving it nil like before.

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
    },
  },
}

return M
