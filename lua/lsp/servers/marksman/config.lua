---@module 'lsp.servers.marksman.config'
--- Marksman per-LSP configuration values.

local M = {
  suppress_missing_doc_links = true,
  missing_doc_links_pattern = "^Link to non%-existent document",
  root_dir_fallbacks = { ".marksman.toml", ".git", "mkdocs.yml" },
  filetypes = { "markdown", "markdown.mdx" },
}

return M
