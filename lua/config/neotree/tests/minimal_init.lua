-- Minimal init for tests
local root = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")

vim.opt.runtimepath:append(root)
vim.opt.packpath:append(root .. "/.tests/site")

-- Install plenary if needed
local plenary_path = root .. "/.tests/site/pack/vendor/start/plenary.nvim"
if not vim.loop.fs_stat(plenary_path) then
  vim.fn.system({
    "git",
    "clone",
    "https://github.com/nvim-lua/plenary.nvim",
    plenary_path,
  })
end

-- Load your config
require("config.neotree").setup({
  debug = true,
  restore_last_position = false,
})

