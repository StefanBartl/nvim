---@module 'bindings.mappings.fzf'
--- fzf-lua pickers, mostly under `<leader>f*` (colorschemes, keymaps, git status,
--- quickfix, man pages) plus the `<leader>do`/`<leader>wo` diagnostics and
--- workspace-symbol entries.

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>fth", ":FzfLua colorschemes<CR>", { desc = "[FzfLua] Colorschemes" })
  -- Was <leader>ffk: collided as a prefix of <leader>ff (pickers.nvim's
  -- cwd-files), forcing Neovim to wait out timeoutlen (default 1000ms) on
  -- every <leader>ff press to see if a "k" was coming.
  map("n", "<leader>fK", ":FzfLua keymaps<CR>", { desc = "[FzfLua] Keymaps" })

  map("n", "<leader>fgs", ":FzfLua git_status<CR>", { desc = "[FzfLua] Git Status" })

  map("n", "<leader>dos", ":FzfLua lsp_document_symbols<CR>", { desc = "[FzfLua] LSP document symbols" })
  map("n", "<leader>wos", ":FzfLua lsp_live_workspace_symbols<CR>", { desc = "[FzfLua] LSP live workspace symbols" })

  map("n", "<leader>do", ":FzfLua diagnostics_document<CR>", { desc = "[FzfLua] Document Diagnostics" })
  map("n", "<leader>wo", ":FzfLua diagnostics_workspace<CR>", { desc = "[FzfLua] Workspace Diagnostics" })

  map("n", "<leader>fq", ":FzfLua quickfix<CR>", { desc = "[Quickfix] Quickfix" })
  map("n", "<leader>man", ":FzfLua man_pages<CR>", { desc = "[FzfLua] Man Pages" })

  map("n", "<leader>flg", ":FzfLua live_grep<CR>", { desc = "[FzfLua] Live Grep" })
  map("n", "<leader>fg", ":FzfLua grep<CR>", { desc = "[FzfLua] Grep" })
  -- <leader>fb moved to fB: pickers.nvim's keymaps.folder_files owns <leader>fb now.
  map("n", "<leader>fB", "<cmd>FzfLua grep_curbuf<CR>", { desc = "[FzfLua] Grep current buffer" })

  map("n", "<leader>fzf", ":FzfLua files<CR>", { desc = "[FzfLua] Files" })

  map("n", "<leader>ftf", ":FzfLua treesitter<CR>", { desc = "[FzfLua] Search Tree-sitter symbols" })

  map("n", "<leader>fws", function()
    require("fzf-lua").lsp_workspace_symbols()
  end, {
    desc = "[FzfLua] Search workspace symbols (LSP)",
  })
end

return M
