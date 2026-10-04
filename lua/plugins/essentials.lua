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
  -- (neotest, bindings/mappings/general.lua's :WhichKey and
  -- <leader>wK/<leader>w?) -- was previously installed only via NvChad's own
  -- bundle. Loaded on `VeryLazy` (right after the first frame), with the keys
  -- and `:WhichKey` kept as fallback triggers: lazy loads on whichever comes
  -- first. Keys alone left a gap -- when `<Space>` was the first stub key of
  -- the session, which-key's own (scheduled) load never ran while the mapping
  -- still waited for its continuation, so a slow first press showed no popup.
  -- Every call site that reaches for `require("which-key")` already checks
  -- `package.loaded["which-key"]` first rather than forcing a load, so
  -- loading it later than the startup path strands nothing the way a
  -- `cmd`-only trigger would for Mason above.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = { "<leader>", "<c-w>", '"', "'", "`", "c", "v", "g" },
    cmd = "WhichKey",
    opts = {},
  },
}
