local M = {}

local blacklist_patterns = {
  "%.cache/lua%-language%-server/meta/",
  "utf8%.lua$",
  "bit32%.lua$",
}

---@private
local function is_blacklisted_uri(uri)
  for _, pattern in ipairs(blacklist_patterns) do
    if uri:find(pattern) then
      return true
    end
  end
  return false
end

---@private
local function is_blacklisted_diag(diagnostic)
  -- In LSP-Diagnostiken ist `source` oder `uri` oft nicht direkt vorhanden, daher auf `diagnostic.source` und `diagnostic.filename` prüfen
  return diagnostic.filename and is_blacklisted_uri(diagnostic.filename)
end

M.virtual_text = vim.tbl_extend("force", vim.diagnostic.handlers.virtual_text, {
  show = function(namespace, bufnr, diagnostics, opts)
    local filtered = vim.tbl_filter(function(d)
      return not is_blacklisted_uri(d.uri or (d.user_data and d.user_data.lsp and d.user_data.lsp.uri) or "")
    end, diagnostics)
    vim.diagnostic.handlers.virtual_text.show(namespace, bufnr, filtered, opts)
  end,
})

M.underline = vim.tbl_extend("force", vim.diagnostic.handlers.underline, {
  show = function(namespace, bufnr, diagnostics, opts)
    local filtered = vim.tbl_filter(function(d)
      return not is_blacklisted_uri(d.uri or (d.user_data and d.user_data.lsp and d.user_data.lsp.uri) or "")
    end, diagnostics)
    vim.diagnostic.handlers.underline.show(namespace, bufnr, filtered, opts)
  end,
})

M.signs = vim.tbl_extend("force", vim.diagnostic.handlers.signs, {
  show = function(namespace, bufnr, diagnostics, opts)
    local filtered = vim.tbl_filter(function(d)
      return not is_blacklisted_uri(d.uri or (d.user_data and d.user_data.lsp and d.user_data.lsp.uri) or "")
    end, diagnostics)
    vim.diagnostic.handlers.signs.show(namespace, bufnr, filtered, opts)
  end,
})

return M
