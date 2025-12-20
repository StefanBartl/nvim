---@module 'usrcmds.diff.diff_exit'
--- Context-aware mapping to exit Neovim diff mode.
--- The mapping only triggers :diffoff when the current window
--- is in diff mode; otherwise it does nothing.

local M = {}

---@return nil
function M.enable()
---FIX: Daduch verzögert sich das normale Esc sehr. Nur anwenden wenn ein weg gefunden wird, das nur im diff modus zu registrieren
  vim.keymap.set("n", "<Esc><Esc>", function()
    -- Diff mode is window-local
    if vim.wo.diff then
      -- Disable diff mode in all windows
      vim.cmd("diffoff!")
    end
  end, {
    silent = true,
    desc = "[usrcmds.diff] Exit diff mode when active",
  })
end

return M

