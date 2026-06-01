---@module 'lsp.languages.scripting.lua_hl'
---@brief Fixes für LuaLS Annotation-Highlights die NvChad/Colorscheme nicht setzt.
---
--- Hintergrund:
---   - Treesitter erkennt `---@module` als @comment.documentation  (korrekt)
---   - lua_ls schickt semantic tokens für Annotationen
---   - NvChad's Colorscheme mappt weder @comment.documentation noch
---     @lsp.type.comment.lua auf eine sichtbare Farbe → "cleared"
---   - Diese Funktion setzt die fehlenden Groups explizit.

local M = {}

---@return nil
function M.setup()
  -- Wird nach ColorScheme neu gesetzt, damit Theme-Wechsel sauber bleibt
  local grp = vim.api.nvim_create_augroup("LuaAnnotationHL", { clear = true })

  local function apply()
    -- -----------------------------------------------------------------------
    -- Treesitter: documentation comments  (---@param, ---@return, ---@module …)
    -- -----------------------------------------------------------------------
    vim.api.nvim_set_hl(0, "@comment.documentation",      { link = "Special" })
    vim.api.nvim_set_hl(0, "@comment.documentation.lua",  { link = "Special" })

    -- -----------------------------------------------------------------------
    -- LuaLS semantic tokens für Annotationen
    -- -----------------------------------------------------------------------
    vim.api.nvim_set_hl(0, "@lsp.type.comment.lua",       { link = "Special" })

    -- Optional: einzelne Annotation-Typen feiner steuern
    -- vim.api.nvim_set_hl(0, "@lsp.type.namespace.lua",  { link = "Type" })
    -- vim.api.nvim_set_hl(0, "@lsp.type.keyword.lua",    { link = "Keyword" })
  end

  -- Sofort anwenden
  apply()

  -- Nach jedem ColorScheme-Wechsel neu anwenden
  vim.api.nvim_create_autocmd("ColorScheme", {
    group    = grp,
    callback = apply,
    desc     = "[lua_hl] Reapply LuaLS annotation highlights after colorscheme change",
  })
end

return M
