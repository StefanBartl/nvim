-- MINIMAL TEST CONFIG - Speichere als test-minimal.lua
-- Start mit: nvim -u test-minimal.lua test.lua

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- NUR nvim-cmp + lua_ls
require("lazy").setup({
  -- nvim-cmp mit dependencies
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = {
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item() else fallback() end
          end, { "i", "s" }),
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        },
      })

      -- Debug output
      vim.defer_fn(function()
        print("=== MINIMAL TEST ===")
        local config = cmp.get_config()
        if config and config.sources then
          print("✅ Sources:")
          for i, src in ipairs(config.sources) do
            print("  " .. i .. ". " .. src.name)
          end
        else
          print("❌ NO SOURCES!")
        end
      end, 1000)
    end,
  },
})

-- lua_ls manuell starten
vim.defer_fn(function()
  -- Get capabilities from cmp
  local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  local caps = vim.lsp.protocol.make_client_capabilities()
  if ok then
    caps = cmp_lsp.default_capabilities(caps)
  end

  -- Start lua_ls
  vim.lsp.start({
    name = "lua_ls",
    cmd = { "lua-language-server" },
    root_dir = vim.fn.getcwd(),
    capabilities = caps,
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false,
        },
        telemetry = { enable = false },
      },
    },
  })

  print("✅ lua_ls started with completion caps")
end, 2000)
