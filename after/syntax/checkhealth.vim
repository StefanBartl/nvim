" Neovim's own checkhealth syntax (`$VIMRUNTIME/syntax/checkhealth.vim`)
" defines exactly three keywords: ERROR, WARNING, OK. There is no INFO --
" core never writes one, since `vim.health.info()` emits no tag at all. The
" `ℹ️ INFO ` prefix some plugins' status lists (adapter/backend/engine) add
" by hand needs its own highlight the same way; DiagnosticInfo is a standard
" group every colorscheme already sets. See
" docs/ROADMAP/personal/All/FINISH/checkhealt_conventions.md.
syn keyword DiagnosticInfo INFO
