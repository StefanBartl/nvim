local M = {}

local nvlsp = require("nvchad.configs.lspconfig")
local lspconfig = require("lspconfig")
local lsp_servers = require("configs.lsp_servers")
local lua_ls_config = require("configs.lua_ls_config")


require("lazydev").setup({})
nvlsp.defaults()
lspconfig.lua_ls.setup(lua_ls_config)



vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

--lspconfig.lua_ls.setup({
--  capabilities = nvlsp.capabilities,
--  on_attach = function(client, bufnr)
--    require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
--    if nvlsp.on_attach then
--      nvlsp.on_attach(client, bufnr)
--    end
--  end,
--})

-- Custom on_attach kombiniert mit nvchad
local function on_attach(client, bufnr)
  require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
  -- Autoformat über conform
  if client.supports_method("textDocument/formatting") then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        require("conform").format({ bufnr = bufnr })
      end,
    })
  end

  --[[
  -- ESLint apply fixes
  if client.name == "eslint" then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        local range_params = vim.lsp.util.make_range_params(0, "utf-16")
        local params = {
          textDocument = range_params.textDocument,
          range = range_params.range,
          context = { only = { "source.fixAll.eslint" } },
        }
        local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
        if result then
          for _, res in pairs(result) do
            for _, action in pairs(res.result or {}) do
              if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, "utf-16")
              end
              if type(action.command) == "table" then
                vim.lsp.buf_request(bufnr, "workspace/executeCommand", action.command, function() end)
              end
            end
          end
        end
      end,
    })
  end
--]]

  -- NvChads Original on_attach aufrufen
  if nvlsp.on_attach then
    nvlsp.on_attach(client, bufnr)
  end
end

-- Alle Server aus custom/configs/lsp_servers.lua initialisieren
for server, config in pairs(lsp_servers) do
  lspconfig[server].setup(vim.tbl_extend("force", {
    on_attach = on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }, config))
end

-- Wenn nvim direkt mit einer Lua-Datei gestartet wird, attach manuell
vim.api.nvim_create_autocmd("BufReadPost", {
  once = true,
  callback = function(args)
    local bufnr = args.buf
    local ft = vim.bo[bufnr].filetype
    if ft == "lua" and #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then
      vim.lsp.start(lua_ls_config)
      vim.notify("🔧 Manually attached lua_ls to initial buffer", vim.log.levels.INFO)
    end
  end,
})


return M
