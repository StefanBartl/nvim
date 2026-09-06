---@module 'wkdoptions.qflist'
--- Diagnostic display config: virtual_text spacing/prefix, underline, signs,
--- severity-sorted -- the same `vim.diagnostic.config()` surface
--- `lsp.core.diagnostics` also touches, worth checking both stay in sync.

--- CDX: `wkdoptions/init.lua`'s `set_diagnostic_signs()` runs right after this
--- module is required in `M.setup()` and calls `vim.diagnostic.config()` again
--- with an overlapping-but-richer surface (adds a real `signs` table + icons,
--- `update_in_insert`), so most of what this module sets here is immediately
--- superseded within the same setup pass. Intentional layering or leftover
--- from before `set_diagnostic_signs()` existed? Decision open.
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
