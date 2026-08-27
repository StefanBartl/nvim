---@module 'bindings.mappings.nvchad'
--- Keymaps against NvChad's own features — theme switcher, formatter, which-key
--- lookups — plus the `<Esc>`/`<C-c>` handler that clears Copilot NES overlays
--- before falling back to `nohl`.

local M = {}

function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  -- General
  map("n", "<Esc>", function()
    local ok, nes = pcall(require, "copilot-lsp.nes")
    if ok and nes and nes.clear then
      local cleared = nes.clear()
      if not cleared then
        vim.cmd("noh")
      end
    else
      vim.cmd("noh")
    end
  end, { desc = "Clear copilot NES overlays or nohl" })
  map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "[General] Copy whole file" })
  -- map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "[General] NvCheatsheet" })
  map("n", "<leader>nvt", function()
    require("nvchad.themes").open({
      icon = "", -- optional
      style = "compact", -- optional! compact/flat/bordered
      border = false,
    })
  end, { desc = "[nvchad] Themes switcher" })

  -- Format via Conform (fallback handled in LSP attach)
  map({ "n", "x" }, "<leader>fm", function()
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.format({
        lsp_fallback = true,
        timeout_ms = 3000,
      })
    end
  end, { desc = "[General] Format file" })

  -- Which-key
  map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "[General] WhichKey (all)" })
  map("n", "<leader>wk", function()
    require("lib.nvim.ui.kit").input({
      title = "WhichKey: ",
      on_submit = function(query) vim.cmd("WhichKey " .. query) end,
    })
  end, { desc = "[General] WhichKey query" })

  -- Insert-mode cursor moves
  map("i", "<C-h>", "<Left>", { desc = "[Text] Left" })
  map("i", "<C-l>", "<Right>", { desc = "[Text] Right" })
  map("i", "<C-j>", "<Down>", { desc = "[Text] Down" })
  map("i", "<C-k>", "<Up>", { desc = "[Text] Up" })
end

return M
