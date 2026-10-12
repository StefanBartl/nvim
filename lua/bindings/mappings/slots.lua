---@module 'bindings.mappings.slots'
--- The `_` toggle for ui.nvim's numbered slots (`ui.slots`).
---
--- The slots themselves are switched on, and their own keys
--- (`<leader>_1`..`<leader>_9` apply, `<leader>_a` add, `<leader>_p` panel)
--- are mapped, by `ui.setup({ slots = ... })` in config/ui_statusline/init.lua.
--- Only the bare `_` lives here: it is this config's key, not the plugin's,
--- and it shares no prefix with the `<leader>_` family.
---
--- `_` is also Vim's "first non-blank, count - 1 lines down" motion. Mapped in
--- normal mode only, so `d_`/`y_`/`c_` (operator-pending) are untouched; a
--- counted `3_` still does the built-in motion, only the bare `_` toggles.

local M = {}

---@return nil
function M.setup()
  local map = require("lib.nvim.bindings.keymap")
  map.set("n", "_", function()
    local count = vim.v.count
    if count > 0 then
      vim.cmd.normal({ args = { count .. "_" }, bang = true })
      return
    end
    vim.cmd("UI slots toggle")
  end, { desc = "[Slots] Toggle slot bar (counted: built-in _ motion)" })
end

return M
