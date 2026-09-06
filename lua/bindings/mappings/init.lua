---@module 'bindings.mappings'
---@brief Entry point to register all keymaps grouped by topic.

local M = {}

---Setup all mapping modules
---@return nil
function M.setup()
  -- LSP/Trouble mappings moved into lsp.nvim's keymap catalogue
  -- (config/KEYMAPS.lua), so one module owns every LSP key instead of five.

  -- NOTE on load order: the mappings phase runs at UIReady, AFTER a plugin
  -- that sets its keys at VeryLazy. A key mapped here silently wins over a
  -- plugin's — the plugin's key is simply gone, nothing said. Check
  -- docs/NOTES/CrossPlugin/Keymaps-Collisions.md whenever a plugin key "does
  -- nothing", and before adding a key here a plugin might already own.

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
end

return M
