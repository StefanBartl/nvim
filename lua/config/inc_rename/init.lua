--- @module 'config.inc_rename'
--- Incremental LSP rename with Noice cmdline UI and automatic save of edited buffers.
--- Press <leader>rn to start a workspace-aware rename pre-filled with <cword>.
--- On <CR>, the LSP applies a WorkspaceEdit; a post_hook then writes all touched buffers.

-- ============================================================================
-- Types
-- ============================================================================

--- LSP text edit
--- @class LspTextEdit
--- @field range table              -- LSP Range
--- @field newText string

--- TextDocument identifier with version
--- @class LspVersionedLspMod.TextDocumentIdentifier
--- @field uri string
--- @field version integer|nil

--- A change to a single text document
--- @class LspTextDocumentEdit
--- @field textDocument LspVersionedLspMod.TextDocumentIdentifier
--- @field edits LspTextEdit[]

--- File operations in WorkspaceEdit (rename/create/delete)
--- @class LspFileOp
--- @field kind "rename"|"create"|"delete"
--- @field oldUri string|nil
--- @field newUri string|nil
--- @field uri string|nil

--- Result table passed by inc-rename's post_hook (LSP WorkspaceEdit result)
--- @class IncRenameResult
--- @field changes? table<string, LspTextEdit[]>
--- @field documentChanges? (LspTextDocumentEdit|LspFileOp)[]

-- ============================================================================
-- Helpers
-- ============================================================================

--- Collect all URIs affected by a WorkspaceEdit-like result.
--- @param res IncRenameResult|nil
--- @return string[] uris
local function collect_uris(res)
  ---@type string[]
  local uris = {}
  if not res then
    return uris
  end
  local push = function(u)
    if not u then
      return
    end
    uris[#uris + 1] = u
  end

  -- From map-like "changes"
  if res.changes then
    for uri, edits in pairs(res.changes) do
      if type(edits) == "table" and #edits > 0 then
        push(uri)
      end
    end
  end

  -- From array-like "documentChanges" (may contain TextDocumentEdit or file ops)
  if res.documentChanges then
    for _, dc in ipairs(res.documentChanges) do
      ---@cast dc table
      if dc.textDocument and dc.edits then
        push(dc.textDocument.uri)
      elseif dc.kind == "rename" then
        push(dc.oldUri)
        push(dc.newUri)
      elseif dc.kind == "create" or dc.kind == "delete" then
        push(dc.uri)
      end
    end
  end
  return uris
end

--- True if the result contains at least one edit or file op.
--- @param res IncRenameResult|nil
--- @return boolean
local function has_edits(res)
  if not res then
    return false
  end
  if res.changes then
    for _, edits in pairs(res.changes) do
      if type(edits) == "table" and #edits > 0 then
        return true
      end
    end
  end
  if res.documentChanges and #res.documentChanges > 0 then
    return true
  end
  return false
end

--- Write only buffers that correspond to the given URIs (load hidden ones as needed).
--- Preserves window state and avoids writing unmodified or unmodifiable buffers.
--- @param uris string[]
local function write_uri_buffers(uris)
  local seen = {}
  for _, uri in ipairs(uris) do
    if not seen[uri] then
      seen[uri] = true
      local bufnr = vim.uri_to_bufnr(uri) -- loads buffer if not loaded yet
      if
        vim.api.nvim_buf_is_loaded(bufnr)
        and vim.bo[bufnr].modifiable
        and vim.bo[bufnr].buftype == ""
        and vim.bo[bufnr].modified
      then
        vim.api.nvim_buf_call(bufnr, function()
          -- keepalt: do not clobber alternate file; silent keeps cmdline clean
          vim.cmd("silent keepalt write")
        end)
      end
    end
  end
end

-- ============================================================================
-- Setup
-- ============================================================================

-- Optional: live preview of edits in a split while you type
-- This complements inc-rename’s preview nicely for multi-file renames.
vim.o.inccommand = "split"

require("inc_rename").setup({
  -- Keep UI defaults; Noice preset supplies the cmdline UI
  cmd_name = "IncRename",
  hl_group = "Substitute",
  show_message = true,
  save_in_cmdline_history = true,

  -- After the LSP rename applied its WorkspaceEdit, save all touched buffers.
  ---@param result IncRenameResult|nil
  post_hook = function(result)
    -- Ensure we run after Neovim finished applying edits
    vim.schedule(function()
      if not has_edits(result) then
        return
      end
      local uris = collect_uris(result)
      if #uris == 0 then
        -- Fallback: if the server returned no URIs, write all modified buffers.
        vim.cmd("silent wall")
        return
      end
      write_uri_buffers(uris)
    end)
  end,
})

-- If using Noice, enable the dedicated preset for inc-rename's cmdline integration.
-- This only changes the input UI; the rename scope remains LSP-driven (workspace edits).
-- require("noice").setup({ presets = { inc_rename = true } })

-- ============================================================================
-- Keymaps
-- ============================================================================

-- <leader>rn → Start incremental rename, pre-filled with the word under the cursor.
-- { expr = true } returns a command-line string to execute.
vim.keymap.set("n", "<leader>rn", function()
  return ":IncRename " .. vim.fn.expand("<cword>")
end, { expr = true, desc = "[LSP] Incremental rename (workspace, auto-save)" })
