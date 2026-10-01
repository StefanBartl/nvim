---@module 'bindings.mappings.fzf'
--- Direct fzf-lua calls that have no pickers.nvim equivalent. Everything
--- that pickers.builtins DOES cover (colorschemes, keymaps, git_status,
--- quickfix, man, live_grep, files, treesitter, lsp_workspace_symbols) moved
--- to pickers.nvim's own declarative `mappings`/`keymaps` config
--- (plugins/personal/specs/navigate.lua) -- engine-agnostic there instead of
--- hardcoded to fzf-lua, and most of them already had an established
--- pickers.nvim lhs of their own, so the old `<leader>f*` keys here were
--- dropped rather than duplicated (2026-10-01, externe-plugins report §9.2).

local M = {}

---@return nil
function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  -- grep_curbuf: a live interactive regex grep scoped to the current buffer.
  -- No pickers.builtins match -- `lines`/`blines` is a fuzzy line-filter, a
  -- different mechanic, not this picker under another name.
  -- <leader>fb moved to fB: pickers.nvim's keymaps.folder_files owns <leader>fb now.
  map("n", "<leader>fB", "<cmd>FzfLua grep_curbuf<CR>", { desc = "[FzfLua] Grep current buffer" })
end

return M
