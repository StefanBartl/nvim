---@module 'plugins.editing'
--- Editing tools: commenting, autotags, templates, quickfix enhancements, TODOs.

---@type LazyPluginSpec[]
return {

  -- Auto-close (), [], {}, quotes, etc. while typing. Already present in the
  -- lazy install dir from an earlier version of this config, but with no
  -- spec left declaring it -- lazy never loaded it, so it never ran.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
    config = function(_, opts)
      require("nvim-autopairs").setup(opts)
    end,
  },

  -- Auto Template Strings for JS/TS
  {
    "chrisgrieser/nvim-puppeteer",
    lazy = false,
  },

  -- Treesitter-based HTML tag closing and renaming
  {
    "windwp/nvim-ts-autotag",
    -- Its own trigger, and it needs one: closing and renaming tags is an
    -- insert-mode feature, so InsertEnter is early enough by definition.
    -- Until 2026-08-28 this spec had no trigger at all and the plugin was
    -- loaded only because lsp.nvim's Astro module required it during startup --
    -- an Astro detail keeping HTML/TSX tag closing alive by accident. That
    -- require is deferred to the first Astro buffer now, so without this the
    -- plugin would never load in a session that opens no .astro file.
    event = "InsertEnter",
    -- New setup layout (top-level enable_* flags are deprecated as of the
    -- plugin's own config/plugin.lua: a top-level enable_rename/enable_close/
    -- enable_close_on_slash now prints a one-time "legacy setup opts" warning
    -- and gets wrapped into `opts.opts` internally anyway -- nesting it here
    -- ourselves just skips that warning. `per_filetype` entries stay flat
    -- (not nested under their own `opts` key); only the top-level flags moved.
    opts = function()
      return {
        opts = {
          enable_close = true,
          enable_rename = true,
          enable_close_on_slash = false,
        },
        per_filetype = {
          html = { enable_close = false },
        },
      }
    end,
    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
    end,
  },

  {
    "andymass/vim-matchup",
    -- Extends `%` and highlights the matching word *inside a buffer*, so a
    -- buffer is the earliest thing it can act on -- `lazy = false` bought
    -- 15.6 ms of startup for a plugin with nothing to match yet. The `ft`
    -- list this line used to suggest is worse than the event: it would have
    -- to enumerate every language, and lazy.nvim puts `ft` plugins on the
    -- runtimepath early anyway (see plugins/webdev.lua's header).
    --
    -- Nothing here depends on nvim-treesitter's setup order: matchup ships
    -- its own `treesitter-matchup` module and this config never enables
    -- nvim-treesitter's `matchup` module, so there is no load-order coupling
    -- to lose. `init` still runs at startup, so the `matchup_*` globals below
    -- are set before the plugin body reads them.
    event = { "BufReadPost", "BufNewFile" },
    init = function()
      -- Disable parenthesis highlight only
      vim.g.matchup_matchparen_enabled = 1 -- no MatchParen highlight
      vim.g.matchup_matchparen_deferred = 1 -- no delayed flashes
      -- vim.g.matchup_matchparen_offscreen = {} -- no offscreen popup
      vim.g.matchup_matchparen_offscreen = { method = "status" } -- Show off-screen matches in a popup/status
    end,
    opts = {
      treesitter = {
        -- Limit how far match-up looks around the cursor with Tree-sitter.
        -- Larger values increase range but may be slower on huge files.
        stopline = 500,
      },
    },
  },
}
