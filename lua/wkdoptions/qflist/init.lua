---@module 'wkdoptions.qflist'

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
