---@module 'plugins.test'
--- Plugins curently in test phase

---@type LazyPluginSpec[]
return {


  {
    'andymass/vim-matchup',
    init = function()
    require('match-up').setup({
      treesitter = {
        stopline = 500
      }
    })
  end,
  }







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
