---@module 'config.fzf.keymaps'
---Keymaps for fzf-lua (fzf prompt).
---Preview-page-down/up (<PageDown>/<PageUp>) are owned by pickers.nvim
---(lua/pickers/keys/), patched globally into fzf-lua's keymap.builtin — do
---not rebind them here, see pickers.nvim's docs/KEYMAPS.md.

local M = {}

---@return table
function M.get()
  return {
    fzf = {
      ["ctrl-n"] = "next-history",
      ["ctrl-p"] = "prev-history",
    },
  }
end

return M
