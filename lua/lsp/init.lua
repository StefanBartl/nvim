---@module 'lsp'
-- Native LSP bootstrap for Neovim ≥ 0.11.

local M = {}

---@type boolean
M._initialized = false

---@param cfg MyLspInit
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

  local caps = (function()
    local ok, mod = pcall(require, "lsp.core.capabilities")
    if ok and mod and type(mod.get) == "function" then
      return mod.get()
    end
    return vim.lsp.protocol.make_client_capabilities()
  end)()

  local attach_api = (function()
    local ok, mod = pcall(require, "lsp.core.attach")
    if ok and mod and type(mod.build) == "function" then
      return mod.build({ use_workspace_diagnostics = true, use_lazydev = true })
    end
    return {
      on_attach = function() end,
      on_init = function()
        return true
      end,
    }
  end)()

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

  local shared = {
    capabilities = caps,
    on_attach = attach_api.on_attach,
    on_init = attach_api.on_init,
    formatter = formatter,
  }

  local ok_reg, registry = pcall(require, "lsp.core.registry")
  if not ok_reg or not registry or type(registry.setup_all) ~= "function" then
    vim.notify("LSP registry missing; skipping server setup", vim.log.levels.WARN)
    return false
  end

  do
    local ok, langs = pcall(require, "lsp.languages")
    if ok and langs and type(langs.enable_all) == "function" then
      pcall(langs.enable_all)
    end
  end

  local names = registry.setup_all(shared)
  if type(names) == "table" and #names > 0 then
    pcall(vim.lsp.enable, names)
  end

  vim.diagnostic.config({
    update_in_insert = false,
    severity_sort = true,
    virtual_text = { spacing = 2, prefix = "●" },
    float = { border = "rounded", source = "if_many" },
  })

  require("lsp.lspdoctor").setup({
    use_notify = false,
    list_limit = 8,
    formatter_priority = { "eslint", "null-ls", "lua_ls" },
    semantic_tokens_timeout = 300,
    scratch_filetype = "markdown",
  })
  require("lsp.lspdoctor").enable_usercmd()

  if cfg.ensure_installing == true then
    require("config.mason.ensure_install").enable({
      lsp = true,
      dap = true,
      linters = true,
      formatters = true,
      overrides = {
        lsp = {
          ["java-language-server"] = false, -- keep off unless 'mvn' is available
          ["csharp-language-server"] = false, -- prefer 'omnisharp' if dotnet exists
          -- ["omnisharp"]              = require('config.mason.ensure_install').has_dotnet and true or false, -- you can compute booleans beforehand
        },
        dap = {
          ["node-debug2-adapter"] = false, -- deprecated; use js-debug-adapter
        },
        linters = {
          ["eslint_d"] = true, -- ensure enabled
        },
        formatters = {
          ["prettier"] = true, -- ensure enabled
        },
      },
    })
  end

  --- ==== CUSTOM ENABLE  LSP TOOLS ====

  require("lsp.tools.eslint_prettier").setup({
    -- optional: provide custom binaries if Mason is not in the default location
    -- binaries = {
    --   eslint = "C:\\Users\\me\\AppData\\Local\\nvim-data\\mason\\bin\\eslint_d.cmd",
    --   prettier = "C:\\Users\\me\\AppData\\Local\\nvim-data\\mason\\bin\\prettier.cmd"
    -- },
    filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    enable_on_setup = true, -- initial autorun state
  })

  require("lsp.tools.ts_type_lookup").setup()
  require("lsp.tools.deprecated_help").setup()
  require("lsp.diagnostics").setup()

  M._initialized = true
  return true
end

return M
