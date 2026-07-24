---@module 'plugins.editing'
--- Editing tools: commenting, autotags, templates, quickfix enhancements, TODOs.

---@type LazyPluginSpec[]
return {

  -- Auto Template Strings for JS/TS
  {
    "chrisgrieser/nvim-puppeteer",
    lazy = false,
  },

  -- Treesitter-based HTML tag closing and renaming
  {
    "windwp/nvim-ts-autotag",
    opts = function()
      return {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
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
    lazy = false, -- or ft = { "lua", "vim", "c", "cpp", "python", "typescript", "javascript", "html", "tex" },
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
