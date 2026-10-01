---@module 'bindings.mappings'
---@brief Entry point to register all keymaps grouped by topic.

local M = {}

---Setup all mapping modules
---@return nil
function M.setup()
  -- LSP/Trouble mappings moved into lsp.nvim's keymap catalogue
  -- (config/KEYMAPS.lua), so one module owns every LSP key instead of five.

  -- NOTE on load order: whoever maps a key last wins, silently -- the other
  -- mapping is simply gone, nothing said. Which side is last depends on the
  -- plugin's trigger:
  --   * `lazy = false`: the plugin mapped first, a key mapped here wins.
  --   * `event = "VeryLazy"`: the PLUGIN wins. UIReady is VimEnter +
  --     vim.schedule; lazy.nvim fires VeryLazy from UIEnter + vim.schedule,
  --     and UIEnter comes after VimEnter. Measured 2026-10-01 with a UI:
  --     this phase at ~505 ms, VeryLazy at ~550 ms. (This note used to claim
  --     the opposite. Headless there is no UIEnter and VeryLazy never fires,
  --     so nothing contradicted it.)
  --   * `keys`/`cmd`/`ft`: the plugin maps when it loads, i.e. later still.
  -- Check Keymaps-Collisions.md (WKDBooks wkdbook-myplugins/ALL/) whenever a
  -- key "does nothing", and before adding a key here a plugin might already
  -- own.

  require("bindings.mappings.buf_win_tab").setup()
  require("bindings.mappings.buffer_jump").setup()
  require("bindings.mappings.custom").setup()
  require("bindings.mappings.context_open").setup()
  require("bindings.mappings.editing").setup()
  require("bindings.mappings.general").setup()
  require("bindings.mappings.noice").setup()
  require("bindings.mappings.screen_line").setup()
  require("bindings.mappings.sessions").setup()
  require("bindings.mappings.smart_del_key").setup()
  require("bindings.mappings.surrounding").setup()
  require("bindings.mappings.telescope").setup()
  require("bindings.mappings.terminal").setup()
  require("bindings.mappings.toggle_comment").setup()
  -- `enable = false` here drops just the two keys; switching the plugin off
  -- in `plugins/treesitter.lua`'s `modes` table drops them too, and is the
  -- switch for "I do not want this at all".
  require("bindings.mappings.treesitter_structure").setup({ enable = true })
  require("bindings.mappings.window_orientation").setup()

  -- The `<leader>nt` group label. The keys under it are neotest's own (lazy
  -- stubs until the plugin loads, see plugins/neotest.lua), but the label
  -- has to be there before the first press and so cannot wait for the plugin.
  -- `add_group` never loads which-key: queued until it is there.
  require("config.neotest.whichkey").setup()
end

return M
