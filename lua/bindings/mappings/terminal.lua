---@module 'bindings.mappings.terminal'
--- Terminal-mode keymaps: `<Esc>`/`<C-c>` to leave terminal mode, and `<C-h/j/k/l>`
--- so window navigation keeps working from inside a terminal buffer.
---
--- `<C-l>` here is window-move-right only. A second `<C-l>` map that sent
--- `clear`/`cls` to the job was dropped — the shell's own `clear` does that.

local M = {}

function M.setup()
  local map = require("lib.nvim.bindings.keymap")
  map("t", "<Esc>", "<C-\\><C-n>", { desc = "[Terminal] Exit terminal mode" })
  map("t", "<C-c>", "<C-\\><C-n>", { desc = "[Terminal] Exit terminal mode" })

  -- Window movement
  map("t", "<C-h>", "<C-\\><C-w>h", { desc = "[Terminal] Left" })
  map("t", "<C-l>", "<C-\\><C-w>l", { desc = "[Terminal] Right" })
  map("t", "<C-j>", "<C-\\><C-w>j", { desc = "[Terminal] Down" })
  map("t", "<C-k>", "<C-\\><C-w>k", { desc = "[Terminal] Up" })

  map({ "n", "t" }, "<A-h>", function()
    -- Was nvchad.term.toggle({ pos = "float", ... }) -- NvChad is gone
    -- (ui.nvim roadmap step 7), snacks.nvim's own terminal module is this
    -- host's already-installed equivalent. `pcall(require, "snacks")` rather
    -- than the bare global, same as autocmds/explorer-singleton.lua's own
    -- Snacks.picker call sites.
    local ok, Snacks = pcall(require, "snacks")
    if ok and Snacks.terminal then
      Snacks.terminal.toggle(nil, { win = { position = "float" } })
    end
  end, { desc = "[Term] Toggle floating" })
end

return M
