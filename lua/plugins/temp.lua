---@module 'plugins.temp'
--- Plugins curently in test phase
-- TODO:

---@type LazyPluginSpec[]
return {

  { 'rafi/neo-hybrid.vim',           priority = 100, lazy = false },
  { 'rafi/awesome-vim-colorschemes', lazy = false },

  --'dmmulroy/ts-error-translator.nvim' }, -- require("ts-error-translator").setup()

  -- https://github.com/OXY2DEV/helpview.nvim
  {
    "OXY2DEV/helpview.nvim",
    lazy = false
  },

  -- https://github.com/axieax/urlview.nvim
  { "axieax/urlview.nvim" },

  -- https://github.com/jghauser/mkdir.nvim
  {
    'jghauser/mkdir.nvim'
  },

  { 'tamton-aquib/keys.nvim' },


}
