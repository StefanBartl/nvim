---@module 'wkdoptions.qflist'
--- Diagnostic display config: virtual_text spacing/prefix, underline, signs,
--- severity-sorted -- the same `vim.diagnostic.config()` surface
--- `lsp.core.diagnostics` also touches, worth checking both stay in sync.

local QFLIST_MODULE = {}

vim.diagnostic.config({
  virtual_text = {
    spacing = 2,
    prefix = "●",
  },
  underline = true,
  signs = true,
  severity_sort = true,
})

return QFLIST_MODULE
