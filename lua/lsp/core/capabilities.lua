---@module 'lsp.core.capabilities'
--- Build client capabilities from multiple completion stacks (cmp, blink, NvChad).
--- Low-level module: no UI side effects. Callers get `{ warnings, error }` back
--- and decide whether/how to notify.

local lsp = vim.lsp
local tbl_deep_extend = vim.tbl_deep_extend

local M = {}

---@alias Lsp.Capabilities.Warning { level: integer, msg: string }

--- Build merged LSP client capabilities.
---@return table caps
---@return Lsp.Capabilities.Warning[] warnings
function M.get()
  ---@type Lsp.Capabilities.Warning[]
  local warnings = {}

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
      if not (caps.textDocument and caps.textDocument.completion) then
        table.insert(warnings, {
          level = vim.log.levels.WARN,
          msg = "nvim-cmp loaded but no completion capabilities!",
        })
      end
    else
      table.insert(warnings, {
        level = vim.log.levels.WARN,
        msg = "nvim-cmp not found! Completion may not work.",
      })
    end
  end

  -- Blink capabilities optional, als fallback
  do
    local ok, blink = pcall(require, "blink.cmp")
    if ok and type(blink.get_lsp_capabilities) == "function" then
      caps = tbl_deep_extend("force", caps, blink.get_lsp_capabilities(caps))
    end
  end

  -- Explizit completion capabilities verifizieren
  if not caps.textDocument or not caps.textDocument.completion then
    table.insert(warnings, {
      level = vim.log.levels.ERROR,
      msg = "NO COMPLETION CAPABILITIES! Check if nvim-cmp or blink.cmp is installed!",
    })

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
    table.insert(warnings, {
      level = vim.log.levels.WARN,
      msg = "Using FALLBACK completion capabilities",
    })
  end

  return caps, warnings
end

---Apply capabilities globally to all LSP configs.
---@return boolean ok
---@return Lsp.Capabilities.Warning[] warnings
function M.apply_globally()
  -- Merge these caps into every named config as a base ("*")
  local caps, warnings = M.get()
  if type(lsp.config) ~= "table" then
    table.insert(warnings, {
      level = vim.log.levels.WARN,
      msg = "vim.lsp.config not available (Neovim < 0.10?)",
    })
    return false, warnings
  end

  lsp.config("*", { capabilities = caps })
  return true, warnings
end

return M
