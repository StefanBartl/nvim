---@module 'plugins.temp'
--- Plugins curently in test phase
-- TODO:

---@type LazyPluginSpec[]
return {


   {
		'AndrewRadev/linediff.vim',
		cmd = { 'Linediff', 'LinediffAdd' },
		keys = {
			{ '<leader>mdf', ':Linediff<CR>', mode = 'x', desc = 'Line diff' },
			{ '<leader>mda', ':LinediffAdd<CR>', mode = 'x', desc = 'Line diff add' },
			{ '<leader>mds', '<cmd>LinediffShow<CR>', desc = 'Line diff show' },
			{ '<leader>mdr', '<cmd>LinediffReset<CR>', desc = 'Line diff reset' },
		},
	},


	-- Use last-used colorscheme
	{
		'rafi/theme-loader.nvim',
		lazy = false,
		priority = 99,
		opts = { initial_colorscheme = 'neohybrid' },
	},
	{ 'rafi/neo-hybrid.vim', priority = 100, lazy = false },
	{ 'rafi/awesome-vim-colorschemes', lazy = false },


  --'dmmulroy/ts-error-translator.nvim' }, -- require("ts-error-translator").setup()
  -- { "MunifTanjim/nui.nvim" }, -- schon woanderrs implementiert? eventuell nutzbar?

  {
  "nvim-treesitter/nvim-treesitter-context",
  dependencies = {"nvim-treesitter/nvim-treesitter"},
  config = function()
    require("treesitter-context").setup()
  end
},

  { 'kosayoda/nvim-lightbulb' }, -- https://github.com/kosayoda/nvim-lightbulb

-- https://github.com/OXY2DEV/helpview.nvim
{
    "OXY2DEV/helpview.nvim",
    lazy = false
},

  -- https://github.com/tanvirtin/vgit.nvim
  -- require('vgit').setup()
  {
  'tanvirtin/vgit.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons' },
  -- Lazy loading on 'VimEnter' event is necessary.
  event = 'VimEnter',
  config = function() require("vgit").setup() end,
  },

  -- https://github.com/NeogitOrg/neogit
  -- require('neogit').setup {}
  {
  "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",         -- required
      "sindrets/diffview.nvim",        -- optional - Diff integration

      -- Only one of these is needed.
      "nvim-telescope/telescope.nvim", -- optional
      "ibhagwan/fzf-lua",              -- optional
      "echasnovski/mini.pick",         -- optional
      "folke/snacks.nvim",             -- optional
    },
  },

  -- https://github.com/andymass/vim-matchup
  {
    'andymass/vim-matchup',
     init = function()
    -- modify your configuration vars here
    vim.g.matchup_treesitter_stopline = 500

    -- or call the setup function provided as a helper. It defines the
    -- configuration vars for you
    require('match-up').setup({
      treesitter = {
        stopline = 500
      }
    })
  end,
  -- or use the `opts` mechanism built into `lazy.nvim`. It calls
  -- `require('match-up').setup` under the hood
  opts = {
    treesitter = {
      stopline = 500,
    }
  }
},

 -- https://github.com/danymat/neogen
{
    "danymat/neogen",
    config = true,
    -- Uncomment next line if you want to follow only stable versions
    -- version = "*"
},

-- https://github.com/axieax/urlview.nvim
 { "axieax/urlview.nvim" },

  -- https://github.com/jghauser/mkdir.nvim
  {
  'jghauser/mkdir.nvim'
  },

  { 'tamton-aquib/keys.nvim' },


}
