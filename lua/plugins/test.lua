---@module 'plugins.test'
--- Plugins curently in test phase

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


  -- https://github.com/jghauser/mkdir.nvim
  {
    'jghauser/mkdir.nvim'
  },

  { 'tamton-aquib/keys.nvim' },




-- KLingons check, capla!

-- C:/Users/bartl/AppData/Local/nvim/lua/plugins/test.lua
-- {
--   dir = vim.fs.normalize(vim.fn.stdpath("config") .. "/lua/plugins/test/klingons"),
--   name = "klingon_notify",
--   dev = true,
--   event = "VeryLazy",
--   config = function()
--     require("klingon_notify").setup({
--       hooks = {
--         notify_wrap = {
--       enabled = true,
--       forward_original = false,
--       prefix_mode = "always",
--       prefix_from_level = false,
--       fixed_prefix = "Qapla'!",
--         },
--       },
--   })
--   end,
-- }
--

-- require("klingon_notify").setup({
--   hooks = {
--     notify_wrap = {
--       enabled = true,
--       forward_original = false,

--       prefix_mode = "always",
--       prefix_from_level = false,
--       fixed_prefix = "Qapla'!",
--     },
--   },
-- })

-- require("klingon_notify").setup({
--   hooks = {
--     notify_wrap = {
--       enabled = true,
--       prefix_mode = "burst",
--       burst_window_ms = 1500,
--       prefix_from_level = true,
--     },
--   },
-- })


}
