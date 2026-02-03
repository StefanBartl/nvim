---@module 'lsp.core.capabilities'
--- Build client capabilities from multiple completion stacks (cmp, blink, NvChad).

local lsp = vim.lsp
local tbl_deep_extend = vim.tbl_deep_extend

local M = {}

---@return table
function M.get()
  -- Start with base LSP capabilities
  local caps = lsp.protocol.make_client_capabilities()

  -- NvChad capabilities FIRST
  do
    local ok, nvlsp = pcall(require, "nvchad.config.lspconfig")
    if ok and type(nvlsp.capabilities) == "table" then
      caps = tbl_deep_extend("force", caps, nvlsp.capabilities)
    end
  end

  -- nvim-cmp capabilities (wichtig für completion)
  do
    local ok, cmp = pcall(require, "cmp_nvim_lsp")
    if ok and type(cmp.default_capabilities) == "function" then
      local cmp_caps = cmp.default_capabilities()
      caps = tbl_deep_extend("force", caps, cmp_caps)

      -- Verify completion capabilities wurden geladen
      if caps.textDocument and caps.textDocument.completion then
        -- vim.notify("[lsp.capabilities]  nvim-cmp completion capabilities loaded", vim.log.levels.INFO)
      else
        vim.notify("[lsp.capabilities] ⚠️  nvim-cmp loaded but no completion capabilities!", vim.log.levels.WARN)
      end
    else
      vim.notify("[lsp.capabilities] ⚠️  nvim-cmp not found! Completion may not work.", vim.log.levels.WARN)
    end
  end

  -- Blink capabilities optional, als fallback
  do
    local ok, blink = pcall(require, "blink.cmp")
    if ok and type(blink.get_lsp_capabilities) == "function" then
      caps = tbl_deep_extend("force", caps, blink.get_lsp_capabilities(caps))
      -- vim.notify("[lsp.capabilities] blink.cmp capabilities loaded", vim.log.levels.INFO)
    end
  end

  -- Explizit completion capabilities verifizieren
  if not caps.textDocument or not caps.textDocument.completion then
    vim.notify(
      "[lsp.capabilities] ⚠️  NO COMPLETION CAPABILITIES! Check if nvim-cmp or blink.cmp is installed!",
      vim.log.levels.ERROR
    )

    -- Fallback: Minimale completion capabilities manuell setzen
    caps.textDocument = caps.textDocument or {}
    caps.textDocument.completion = {
      dynamicRegistration = false,
      completionItem = {
        snippetSupport = true,
        commitCharactersSupport = true,
        deprecatedSupport = true,
        preselectSupport = true,
        tagSupport = {
          valueSet = { 1 } -- Deprecated
        },
        insertReplaceSupport = true,
        resolveSupport = {
          properties = { "documentation", "detail", "additionalTextEdits" }
        },
        insertTextModeSupport = {
          valueSet = { 1, 2 } -- AsIs = 1, AdjustIndentation = 2
        },
        labelDetailsSupport = true
      },
      contextSupport = true,
      insertTextMode = 1,
      completionList = {
        itemDefaults = {
          "commitCharacters",
          "editRange",
          "insertTextFormat",
          "insertTextMode",
          "data"
        }
      }
    }
    vim.notify("[lsp.capabilities] ⚠️  Using FALLBACK completion capabilities", vim.log.levels.WARN)
  end

  return caps
end

---Apply capabilities globally to all LSP configs
---@return nil
function M.apply_globally()
  -- Merge these caps into every named config as a base ("*")
  local caps = M.get()
  if type(lsp.config) == "table" then
    lsp.config("*", { capabilities = caps })
    -- vim.notify("[lsp.capabilities] Applied capabilities globally to all servers", vim.log.levels.INFO)
  else
    vim.notify("[lsp.capabilities] ⚠️  vim.lsp.config not available (Neovim < 0.10?)", vim.log.levels.WARN)
  end
end

return M

