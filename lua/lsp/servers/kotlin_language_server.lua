---@module 'lsp.servers.kotlin_language_server'
--- Kotlin Language Server for Android development.

local M = {}

---@param shared {capabilities?:table,on_attach?:fun(client,bufnr),on_init?:fun(client,init_result):boolean}|nil
---@param opts { enable?: boolean }|nil
---@return nil
function M.setup(shared, opts)
  shared = shared or {}
  opts = opts or {}

  if type(vim.lsp.config) ~= "table" then
    return
  end

  vim.lsp.config("kotlin_language_server", {
    cmd = { "kotlin-language-server" },
    filetypes = { "kotlin" },
    root_markers = {
      "settings.gradle",
      "settings.gradle.kts",
      "build.gradle",
      "build.gradle.kts",
      ".git",
    },
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
    settings = {
      kotlin = {
        compiler = {
          jvm = {
            target = "1.8",
          },
        },
      },
    },
  })

  if opts.enable ~= false then
    pcall(vim.lsp.enable, "kotlin_language_server")
  end
end

return M
