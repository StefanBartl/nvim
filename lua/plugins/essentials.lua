---@module 'plugins.essentials'
--- Contains essential plugin dependencies

---@type LazyPluginSpec[]
return {

  -- Plenary: Shared Lua functions used by many plugins (fs, async, path, job, etc.)
  {
    "nvim-lua/plenary.nvim",
    lazy = false,
  },

  -- Mason: LSP server / DAP adapter / linter / formatter installer.
  -- lsp.integrations.mason.ensure_install (lsp.nvim) and :MasonInstallAll
  -- (bindings/usrcmds/init.lua) both `require("mason")`/`require(
  -- "mason-registry")` directly rather than going through one of Mason's own
  -- commands -- lazy-loading this on `cmd = { "Mason", ... }` the way
  -- NvChad's own spec did would leave those direct requires racing an
  -- unloaded plugin. `lazy = false` sidesteps that outright, same as every
  -- other piece of core tooling in this config.
  {
    "mason-org/mason.nvim",
    lazy = false,
    opts = {},
  },

  -- which-key: the <leader> popup and its group labels. Actively wired
  -- (harpoon, neotest, bindings/mappings/general.lua's :WhichKey and
  -- <leader>wK/<leader>w?) -- was previously installed only via NvChad's own
  -- bundle. Lazy on the keys that actually trigger it, matching NvChad's own
  -- spec: every call site that reaches for `require("which-key")` already
  -- checks `package.loaded["which-key"]` first (see harpoon.lua) rather than
  -- forcing a load, so keeping it lazy here doesn't strand anything the way
  -- a `cmd`-only trigger would for Mason above.
  {
    "folke/which-key.nvim",
    keys = { "<leader>", "<c-w>", '"', "'", "`", "c", "v", "g" },
    cmd = "WhichKey",
    opts = {},
  },
}
