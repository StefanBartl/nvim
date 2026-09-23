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
---
--- Insert mode gets its own pair, <M-j>/<M-k> — not <C-j>/<C-k>, which are
--- already bound there (general.lua) to plain <Down>/<Up>. Neovim's insert
--- mode <Down>/<Up> move by logical (text) line, not screen line — verified
--- empirically, not assumed from Vim's normal-mode j/k semantics — so they
--- are not already a gj/gk equivalent and this is additive, not a
--- duplicate. <C-o> runs one normal-mode command without leaving insert
--- mode, which is the only way to reach gj/gk (a motion) from there.

local M = {}

---@return nil
function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  map({ "n", "v" }, "<C-S-k>", "gk", { desc = "Move up by screen line (through wrapped text)" })
  map({ "n", "v" }, "<C-S-j>", "gj", { desc = "Move down by screen line (through wrapped text)" })

  map("i", "<M-k>", "<C-o>gk", { desc = "Move up by screen line (through wrapped text)" })
  map("i", "<M-j>", "<C-o>gj", { desc = "Move down by screen line (through wrapped text)" })
end

return M
