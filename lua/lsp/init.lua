---@module 'lsp.init'
---@briefentry LSP entrypoint for a clean, defensive, and modular setup
local M = {}

---@return boolean ok
function M.setup()
  do
    local ok_h, handlers = pcall(require, "lsp.core.handlers")
    if ok_h and handlers and type(handlers.setup) == "function" then
      pcall(handlers.setup)
    end
  end

  local ok_diag, diagnostics = pcall(require, "lsp.core.diagnostics")
  if ok_diag and diagnostics and type(diagnostics.setup) == "function" then pcall(diagnostics.setup) end

  local ok_ts, treesitter = pcall(require, "lsp.core.treesitter")
  if ok_ts and treesitter and type(treesitter.setup) == "function" then pcall(treesitter.setup) end

  local caps = (function()
    local ok, mod = pcall(require, "lsp.core.capabilities")
    if ok and mod and type(mod.get) == "function" then return mod.get() end
    return vim.lsp.protocol.make_client_capabilities()
  end)()

  local attach_api = (function()
    local ok, mod = pcall(require, "lsp.core.attach")
    if ok and mod and type(mod.build) == "function" then
      return mod.build({ use_workspace_diagnostics = true, use_lazydev = true })
    end
    return { on_attach = function() end, on_init = function() return true end }
  end)()

  -- Build the formatter API with format_on_save = false (default OFF)
  local formatter = (function()
    local ok, mod = pcall(require, "lsp.formatter.init")
    if ok and mod and type(mod.build) == "function" then
      return mod.build({ format_on_save = false, timeout_ms = 1500 })
    end
    return {
      format = function(_) return false end,
      enable = function() return false end,
      disable = function() return true end,
      toggle = function() return false end,
      is_enabled = function() return false end,
    }
  end)()

  do
    local ok, conform_mod = pcall(require, "lsp.formatter.conform")
    if ok and conform_mod and type(conform_mod.setup) == "function" then pcall(conform_mod.setup) end
  end

  vim.g._formatter_api = formatter -- global reference: cache API for keymaps so they only build once

  -- Expose handy user-commands (no notify, no noise)
  do
    pcall(vim.api.nvim_create_user_command, "LspFormat", function(_)
      -- :LspFormat[!] formats current buffer once; bang is ignored (kept for muscle memory)
      formatter.format(0)
    end, { bang = true, desc = "LSP/Conform: format current buffer once (silent)" })

    pcall(vim.api.nvim_create_user_command, "LspFormatToggle", function()
      local _ = formatter.toggle()
      -- intentionally no vim.notify; fully silent toggle
    end, { desc = "LSP/Conform: toggle format-on-save (silent)" })

    pcall(vim.api.nvim_create_user_command, "LspFormatOn", function()
      formatter.enable()
    end, { desc = "LSP/Conform: enable format-on-save (silent)" })

    pcall(vim.api.nvim_create_user_command, "LspFormatOff", function()
      formatter.disable()
    end, { desc = "LSP/Conform: disable format-on-save (silent)" })

    pcall(vim.api.nvim_create_user_command, "LspFormatStatus", function()
      local state
      if formatter.is_enabled() then state = "true" else state = "false" end
      vim.notify("LSP/Conform state: " .. state, 2)
    end, { desc = "LSP/Conform: show state of formater" })
  end

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
  return registry.setup_all(shared)
end

return M
