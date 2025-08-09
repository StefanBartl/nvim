local lspconfig = require("lspconfig")
local lua_ls_config = require("lsp.languageserver.lua_ls_config")

lspconfig.lua_ls.setup(lua_ls_config)

-- IF nvim directly starts with a Lua-File (like 'nvim some.lua'), attach manuell
vim.api.nvim_create_autocmd("BufReadPost", {
  once = true,
  callback = function(args)
    local bufnr = args.buf
    local ft = vim.bo[bufnr].filetype
    if ft == "lua" and #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then
      vim.lsp.start(lua_ls_config)
      vim.notify("Manually attached lua_ls to initial buffer", vim.log.levels.INFO)
    end
  end,
})
