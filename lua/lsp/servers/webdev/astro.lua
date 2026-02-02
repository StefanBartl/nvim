---@module 'lsp.servers.webdev.astro'
--- Astro Language Server für .astro Komponenten

local notify = require("lib.notify").create("[lsp.servers.webdev.astro]")

local M = {}

---@param shared {capabilities?:table,on_attach?:fun(client,bufnr),on_init?:fun(client,init_result):boolean}|nil
---@param opts { enable?: boolean }|nil
---@return nil
function M.setup(shared, opts)
  shared = shared or {}
  opts = opts or {}

  if type(vim.lsp.config) ~= "table" then
    notify.warn("vim.lsp.config unavailable; skipping Astro LSP")
    return
  end

  vim.lsp.config("astro", {
    cmd = { "astro-ls", "--stdio" },
    filetypes = { "astro" },
    root_markers = { "package.json", "tsconfig.json", "astro.config.mjs", ".git" },
    capabilities = shared.capabilities,
    on_attach = function(client, bufnr)
      if type(shared.on_attach) == "function" then
        shared.on_attach(client, bufnr)
      end

      -- Astro-spezifische Keymaps
      pcall(vim.keymap.set, "n", "<leader>ac", function()
        vim.lsp.buf.code_action({
          context = { only = { "source.organizeImports.astro" } },
          apply = true,
        })
      end, { buffer = bufnr, desc = "Astro: Organize imports" })
    end,
    on_init = shared.on_init,
    settings = {
      astro = {
        typescript = {
          tsdk = vim.fn.stdpath("data") .. "/mason/packages/typescript-language-server/node_modules/typescript/lib",
        },
        css = {
          validate = true,
          lint = {
            unknownAtRules = "ignore",
          },
        },
      },
    },
  })

  if opts.enable ~= false then
    pcall(vim.lsp.enable, "astro")
  end
end

return M
