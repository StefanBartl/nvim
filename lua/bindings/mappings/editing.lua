---@module 'bindings.mappings.editing'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  -- Branch-aware redo/undo that survives auto-changes by plugins
  map("n", "<C-r>", "g+", { desc = "Redo (branch-aware)" })

  -- Insert blank lines
  map("n", "<leader><CR>", "o<Esc>k", { desc = "Insert blank line below" })
  map("n", "<CR>", "0i<CR><Esc>k", { desc = "Insert blank line" })

  -- Visual mode paste without overwriting the yank register
  map("x", "p", '"_dP', {
    noremap = true,
    silent = true,
    desc = "Paste over selection without yanking it",
  })

  -- Insert clipboard (+) literally, without triggering auto-indent doubling.
  -- NOTE: some terminals cannot encode <C-A-S-p>; if it never fires, the
  -- terminal/GUI is swallowing the chord, not this mapping.
  map("i", "<C-A-S-p>", "<C-r><C-o>+", {
    noremap = true,
    silent = true,
    desc = "Aus System-Zwischenablage im Insert-Modus einfügen",
  })

end

return M
