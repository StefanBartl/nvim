---@module 'bindings.mappings'
---@brief Entry point to register all keymaps grouped by topic.

local M = {}

---Setup all mapping modules
---@return nil
function M.setup()
  -- The LSP and Trouble mapping modules used to be registered here. They moved
  -- into lsp.nvim's keymap catalogue (config/KEYMAPS.lua) together with the
  -- four LSP lines from `fzf.lua` and inc-rename's `<leader>rn`, so that one
  -- module owns every LSP key instead of five. Same keys, one owner.

  require("bindings.mappings.buf_win_tab").setup()
  require("bindings.mappings.buffer_jump").setup()
  require("bindings.mappings.custom").setup()
  require("bindings.mappings.context_open").setup()
  -- ctrl_cycle is the ancestor cascade.nvim's cycle domain was ported from,
  -- and cascade now supersedes it: it covers all 24 of ctrl_cycle's active
  -- groups plus operator flips, ISO dates, single-letter stepping, counts,
  -- dot-repeat and a picker. Binding both was a silent regression -- this
  -- phase runs at UIReady, i.e. AFTER cascade's VeryLazy setup, so
  -- ctrl_cycle's <C-y>/<C-x> overwrote cascade's, and everything cascade
  -- adds beyond plain word groups fell through to a native <C-a>/<C-x> that
  -- does nothing on a letter, date or operator.
  require("bindings.mappings.editing").setup()
  require("bindings.mappings.fzf").setup()
  require("bindings.mappings.general").setup()
  require("bindings.mappings.git").setup()
  require("bindings.mappings.harpoon").setup()
  require("bindings.mappings.noice").setup()
  require("bindings.mappings.nvchad").setup()
  require("bindings.mappings.screen_line").setup()
  require("bindings.mappings.smart_del_key").setup({ set_cr = true })
  require("bindings.mappings.sourrounding").setup()
  require("bindings.mappings.telescope").setup()
  require("bindings.mappings.terminal").setup()
  require("bindings.mappings.toggle_comment").setup()
  require("bindings.mappings.window_orientation").setup()

  -- require("bindings.mappings.view_scroll").map_default_keys('<C-d>', '<C-u>')
end

return M
