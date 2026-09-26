---@module 'config.neotest.whichkey'
--- which-key group label for the Neotest prefix.
---
--- The actual `<leader>nt*` keymaps are set by `config.neotest.keymaps` via
--- the plain `vim.keymap.set` wrapper (no which-key group support there); this
--- module's only job is the `<leader>nt` group header. It used to also
--- re-register all nine individual mappings through `wk.add()` -- redundant
--- with `config.neotest.keymaps`, and `pcall(require, "which-key")` forced
--- which-key to load right here (from the menu prewarm loading neotest),
--- which is the load trigger under a lazy manager for a popup nobody had
--- opened yet. `add_group` never requires it: applied at once if it is
--- already loaded, queued until it loads otherwise.

local M = {}

---@return nil
function M.setup()
  require("lib.nvim.bindings.keymap.which_key").add_group({ prefix = "<leader>nt", group = "Tests" })
end

return M
