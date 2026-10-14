---@module 'bindings.mappings.execute'
---@brief Keymaps for `:Execute` (`bindings.usrcmds.execute`).
---@description
--- `<leader>x`  `:Execute`   -- type the text under the cursor / in the selection into the command line
--- `<leader>X`  `:Execute!`  -- run it at once
---
--- Both work in Normal and Visual mode. In Visual mode the keys type `:Execute` themselves, so the range
--- (`:'<,'>`) is part of the command and the command knows what was selected.
---
--- Note: `<leader>x` is also the prefix of the Trouble keys (`<leader>xx`, `<leader>xt`, ...). Neovim
--- therefore waits for 'timeoutlen' after `<leader>x` before it runs `:Execute`; the longer Trouble keys
--- still work.

local M = {}

---@return nil
function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  map(
    "n",
    "<leader>x",
    "<Cmd>Execute<CR>",
    { desc = "[Execute] Put the `code` / line under the cursor on the command line" }
  )
  map(
    "n",
    "<leader>X",
    "<Cmd>Execute!<CR>",
    { desc = "[Execute] Run the `code` / line under the cursor" }
  )
  -- Visual: a typed ":" makes the range part of the command line; <Cmd> would leave the marks stale.
  map(
    "x",
    "<leader>x",
    ":Execute<CR>",
    { desc = "[Execute] Put the selection on the command line" }
  )
  map("x", "<leader>X", ":Execute!<CR>", { desc = "[Execute] Run the selection" })
end

return M
