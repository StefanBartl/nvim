return {
  arduino_language_server = {},
  asm_lsp = {},
  awk_ls = {},
  bashls = {},
  clangd = {},
  cssls = {},
  docker_compose_language_service = {},
  dockerls = {},
  gopls = {
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
          shadow = true,
        },
        staticcheck = true,
        gofumpt = true,
      },
    },
  },
  html = {},
  -- java_language_server = {},
  jsonls = {},
  jsonnet_ls = {},
  lemminx = {},
  lua_ls = {},
  marksman = {},
  -- nginx_language_server = {}, max Python 3.11
  pyright = {},
  rust_analyzer = {},
  sqlls = {},
  svelte = {},
  tailwindcss = {},
  ts_ls = {},
  vimls = {},
  volar = {}, -- Vue 3 (vue-language-server)
  yamlls = {},
  zls = {},
}
