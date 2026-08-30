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

  -- NOTE on load order, for everything in this list: the mappings phase runs
  -- at UIReady, which is AFTER a plugin that sets its keys at VeryLazy. A key
  -- mapped here therefore wins over a plugin's, silently -- the plugin's key
  -- is simply gone, with nothing said. Two of those have already been paid
  -- for; both are written up in
  -- docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/Collisions.md. Check that
  -- file first whenever a plugin key "does nothing", and before adding a key
  -- here that a plugin might already own.

  require("bindings.mappings.buf_win_tab").setup()
  require("bindings.mappings.buffer_jump").setup()
  require("bindings.mappings.custom").setup()
  require("bindings.mappings.context_open").setup()
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
  -- `enable = false` here drops just the two keys; switching the plugin off
  -- in `plugins/treesitter.lua`'s `modes` table drops them too, and is the
  -- switch for "I do not want this at all".
  require("bindings.mappings.treesitter_structure").setup({ enable = true })
  require("bindings.mappings.window_orientation").setup()

  -- require("bindings.mappings.view_scroll").map_default_keys('<C-d>', '<C-u>')
end

return M
