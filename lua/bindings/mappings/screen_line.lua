---@module 'bindings.mappings.screen_line'
---@brief Move by screen line (through soft-wrapped text) instead of by
---logical line. `j`/`k` always jump a whole logical line even when it spans
---multiple wrapped rows; `gj`/`gk` move one screen row at a time. These
---keymaps expose that as a quick chord instead of remapping j/k outright.
---@description
--- NOTE: <C-S-k>/<C-S-j> require a terminal that distinguishes Ctrl+Shift
--- chords from plain Ctrl (e.g. via the Kitty keyboard protocol or a CSI-u
--- capable terminal). <C-k>/<C-j> are already bound to window-jump
--- (buf_win_tab.lua) — if the terminal collapses Ctrl+Shift into plain
--- Ctrl, this mapping simply never fires (the window-jump one wins, since
--- Neovim only ever sees the one keycode the terminal actually sent).
--- <M-k>/<M-j> (Alt) is free in normal buffers and is the more portable
--- fallback if that happens.

local M = {}

function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  map({ "n", "v" }, "<C-S-k>", "gk", { desc = "Move up by screen line (through wrapped text)" })
  map({ "n", "v" }, "<C-S-j>", "gj", { desc = "Move down by screen line (through wrapped text)" })
end

return M
