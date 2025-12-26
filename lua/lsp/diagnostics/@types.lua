---@meta
---@module 'lsp.diagnostics.@types'

---@class Lsp.Diagnostics.QfOpts
---@field open? boolean            # open quickfix/loclist window immediately.
---@field severity? integer|string # umeric severity (vim.diagnostic.severity.*) or string ("error","warn","info","hint","all")
---@field bufnr? integer           # target buffer; nil = all buffers (workspace) for quickfix, or current buffer for loclist.
---@field namespace? integer       # namespace filter; nil = all namespaces.
---@field win_id? integer          # window id for loclist; defaults to 0 (current window).
