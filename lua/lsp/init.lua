---@module 'lsp'
-- Native LSP bootstrap for Neovim ≥ 0.11.

local M = {}

local create_user_command = vim.api.nvim_create_user_command

---@type boolean
M._initialized = false

---@return boolean ok
function M.setup()
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
  vim.g._formatter_api = formatter

  pcall(create_user_command, "LspFormat", function(_)
    formatter.format(0)
  end, { bang = true, desc = "LSP/Conform: format current buffer once (silent)" })
  pcall(create_user_command, "LspFormatToggle", function()
    formatter.toggle()
  end, { desc = "LSP/Conform: toggle format-on-save (silent)" })
  pcall(create_user_command, "LspFormatOn", function()
    formatter.enable()
  end, { desc = "LSP/Conform: enable format-on-save (silent)" })
  pcall(create_user_command, "LspFormatOff", function()
    formatter.disable()
  end, { desc = "LSP/Conform: disable format-on-save (silent)" })
  pcall(create_user_command, "LspFormatStatus", function()
    local state = formatter.is_enabled() and "true" or "false"
    vim.notify("LSP/Conform state: " .. state, vim.log.levels.INFO)
  end, { desc = "LSP/Conform: show state of formater" })
  pcall(create_user_command, "LspFormatWhich", function()
    local ok, mod = pcall(require, "lsp.formatter.conform")
    if ok and type(mod.which) == "function" then
      mod.which(0)
    else
      vim.notify("Conform helper unavailable", vim.log.levels.WARN)
    end
  end, { desc = "Show formatter chain & availability for current buffer" })

  -- AUDIT: 'lspconfig'-builtin comands
	pcall(create_user_command, "LspInfo", ":checkhealth vim.lsp", { desc = "Alias to `:checkhealth vim.lsp`" })
  pcall(create_user_command, "LspLog", function()
    vim.cmd(string.format("tabnew %s", vim.lsp.log.get_filename()))
  end, {
    desc = "Opens the Nvim LSP client log.",
  })
  pcall(nvim_create_user_command, "LspStart", function(info)
    local server_name = string.len(info.args) > 0 and info.args or nil
    if server_name then
      local config = require("lspconfig.configs")[server_name]
      if config then
        config.launch()
        return
      end
    end

    local matching_configs = util.get_config_by_ft(vim.bo.filetype)
    for _, config in ipairs(matching_configs) do
      config.launch()
    end
  end, {
    desc = "Manually launches a language server",
    nargs = "?",
    complete = lsp_complete_configured_servers,
  })
  pcall(nvim_create_user_command, "LspRestart", function(info)
    local detach_clients = {}
    for _, client in ipairs(get_clients_from_cmd_args(info.args)) do
      -- Can remove diagnostic disabling when changing to client:stop() in nvim 0.11+
      --- @diagnostic disable: missing-parameter
      client.stop()
      if vim.tbl_count(client.attached_buffers) > 0 then
        detach_clients[client.name] = { client, lsp.get_buffers_by_client_id(client.id) }
      end
    end
    local timer = assert(vim.uv.new_timer())
    timer:start(
      500,
      100,
      vim.schedule_wrap(function()
        for client_name, tuple in pairs(detach_clients) do
          if require("lspconfig.configs")[client_name] then
            local client, attached_buffers = unpack(tuple)
            if client.is_stopped() then
              for _, buf in pairs(attached_buffers) do
                require("lspconfig.configs")[client_name].launch(buf)
              end
              detach_clients[client_name] = nil
            end
          end
        end

        if next(detach_clients) == nil and not timer:is_closing() then
          timer:close()
        end
      end)
    )
  end, {
    desc = "Manually restart the given language client(s)",
    nargs = "?",
    complete = lsp_get_active_clients,
  })
  pcall(nvim_create_user_command, "LspStop", function(info)
    ---@type string
    local args = info.args
    local force = false
    args = args:gsub("%+%+force", function()
      force = true
      return ""
    end)

    local clients = {}

    -- default to stopping all servers on current buffer
    if #args == 0 then
      clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
    else
      clients = get_clients_from_cmd_args(args)
    end

    for _, client in ipairs(clients) do
      -- Can remove diagnostic disabling when changing to client:stop(force) in nvim 0.11+
      --- @diagnostic disable: param-type-mismatch
      client.stop(force)
    end
  end, {
    desc = "Manually stops the given language client(s)",
    nargs = "?",
    complete = lsp_get_active_clients,
  })

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

  M._initialized = true
  return true
end

return M
