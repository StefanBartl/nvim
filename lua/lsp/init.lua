---@module 'lsp'
-- Native LSP bootstrap for Neovim ≥ 0.11.

local notify = require("lib.notify").create("[lsp]")

local M = {}

---@type boolean
M._initialized = false

---@param cfg LspMod.Init
---@return boolean ok
function M.setup(cfg)
  if M._initialized then
    return true
  end

  do
    local ok_h, handlers = pcall(require, "lsp.core.handlers")
    if ok_h and handlers and type(handlers.setup) == "function" then
      pcall(handlers.setup)
    end
  end
  do
    local ok_diag, diagnostics = pcall(require, "lsp.core.diagnostics")
    if ok_diag and diagnostics and type(diagnostics.setup) == "function" then
      pcall(diagnostics.setup)
    end
  end
  do
    local ok_ts, treesitter = pcall(require, "lsp.core.treesitter")
    if ok_ts and treesitter and type(treesitter.setup) == "function" then
      pcall(treesitter.setup)
    end
  end

  -- capabilities explizit holen und verifizieren
  local caps = (function()
    local ok, mod = pcall(require, "lsp.core.capabilities")
    if ok and mod and type(mod.get) == "function" then
      local result = mod.get()

      if result.textDocument and result.textDocument.completion then
        -- notify.info("Completion capabilities loaded")
      else
        notify.warn("⚠️  Completion capabilities missing!")
      end

      return result
    end
    notify.warn("⚠️  Using fallback capabilities (no cmp/blink)")
    return vim.lsp.protocol.make_client_capabilities()
  end)()

  -- attach api mit validation
  local attach_api = (function()
    local ok, mod = pcall(require, "lsp.core.attach")
    if ok and mod and type(mod.build) == "function" then
      return mod.build({ use_workspace_diagnostics = true, use_lazydev = true })
    end
    notify.warn("⚠️  Using minimal attach handlers")
    return {
      on_attach = function(client, bufnr)
        -- Minimal fallback: nur omnifunc setzen
        if
          client
          and client.server_capabilities
          and client.server_capabilities.completionProvider
        then
          vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
        end
      end,
      on_init = function()
        return true
      end,
    }
  end)()

  -- Formatter setup
  local formatter = (function()
    local ok, mod = pcall(require, "lsp.formatter.init")
    if ok and mod and type(mod.build) == "function" then
      return mod.build({ format_on_save = false, timeout_ms = 1500 })
    end
    return {
      format = function(_)
        return false
      end,
      enable = function()
        return false
      end,
      disable = function()
        return true
      end,
      toggle = function()
        return false
      end,
      is_enabled = function()
        return false
      end,
    }
  end)()

  do
    local ok, conform_mod = pcall(require, "lsp.formatter.conform")
    if ok and conform_mod and type(conform_mod.setup) == "function" then
      pcall(conform_mod.setup)
    end
  end

  -- global var for mappings.lsp
  vim.g._formatter_api = formatter

  -- usercommands formatter (conform)
  require("lsp.usercmds.formatter").attach(formatter)

  -- usercommands lps
  require("lsp.usercmds").attach()

  -- shared config mit validierung
  local shared = {
    capabilities = caps,
    on_attach = attach_api.on_attach,
    on_init = attach_api.on_init,
    formatter = formatter,
  }

  -- language-specific qol muss vor server-setup
  do
    local ok, langs = pcall(require, "lsp.languages")
    if ok and langs and type(langs.enable_all) == "function" then
      pcall(langs.enable_all)
    end
  end

  vim.filetype.add({
    extension = {
        astro = 'astro',
    },
})

  -- Registry setup
  local ok_reg, registry = pcall(require, "lsp.core.registry")
  if not ok_reg or not registry or type(registry.setup_all) ~= "function" then
    notify.warn("LSP registry missing; skipping server setup")
    return false
  end

  local names = registry.setup_all(shared)
  if type(names) == "table" and #names > 0 then
    for _, name in ipairs(names) do
      pcall(vim.lsp.enable, name)
    end
  else
    notify.warn("No LSP servers configured!")
  end

  -- LSP Server debugging
  -- if type(names) == "table" and #names > 0 then
    -- notify.info(string.format("Enabling %d LSP servers: %s", #names, table.concat(names, ", ")))

    -- for _, name in ipairs(names) do
        -- local ok, err = pcall(vim.lsp.enable, name)
        -- if not ok then
            -- notify.warn(string.format("Failed to enable '%s': %s", name, err))
        -- else
            -- notify.info(string.format("✓ Enabled '%s'", name))
        -- end
    -- end
-- else
    -- notify.warn("No LSP servers configured!")
-- end

  -- diagnostic config nach Server-Enable
  vim.diagnostic.config({
    update_in_insert = false,
    severity_sort = true,
    virtual_text = { spacing = 2, prefix = "●" },
    float = { border = "rounded", source = "if_many" },
  })

  -- Mason ensure_install (optional)
  if cfg.ensure_installing == true then
    require("config.mason.ensure_install").enable({
      lsp = true,
      dap = true,
      linters = true,
      formatters = true,
      overrides = {
        lsp = {
          ["java-language-server"] = false,
          ["csharp-language-server"] = false,
        },
        dap = {
          ["node-debug2-adapter"] = false,
        },
        linters = {
          ["eslint_d"] = true,
        },
        formatters = {
          ["prettier"] = true,
        },
      },
    })
  end

  --- ==== CUSTOM ENABLE LSP TOOLS ====
  require("lsp.lspdoctor").setup({
    use_notify = false,
    list_limit = 8,
    formatter_priority = { "eslint", "null-ls", "lua_ls" },
    semantic_tokens_timeout = 300,
    scratch_filetype = "markdown",
  })
  require("lsp.lspdoctor").setup({
    use_notify = false,
    auto_open_scratch = true,
    scratch_threshold = 20,
    formatter_priority = { "null-ls", "eslint", "lua_ls" },
  })
  require("lsp.lspdoctor").enable_usercmd()

  require("lsp.tools.eslint_prettier").setup({
    filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    enable_on_setup = true,
  })

  require("lsp.tools.lsp_signature").setup()
  require("lsp.tools.ts_type_lookup").setup()
  require("lsp.tools.deprecated_help").setup()
  require("lsp.diagnostics").setup()

  M._initialized = true
  -- notify.info("✅ LSP initialization complete")
  return true
end

return M
