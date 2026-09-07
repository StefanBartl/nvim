---@module 'autocmds.markdown_folds'
--- Point `foldexpr` at markdown.nvim's own fold function, for markdown buffers
--- only.
---
--- Came out of `lua/options.lua` when that file moved into
--- StefanBartl/my.nvim. It did not go with it: my.nvim owns generic editor
--- options, and this is a markdown.nvim integration that happens to be
--- expressed as an option.
---
--- Not folded into markdown.nvim itself either, at least not yet: the plugin
--- is `ft`-lazy, so it would be registering a FileType handler for the
--- filetype that loads it. That is a real change to its load model, not a
--- move.
---
--- Local, via `opt_local`: the global `foldexpr` stays Treesitter's (see
--- my.declarative), and only markdown buffers get this one.

local M = {}

--- Register the FileType handler.
---@return nil
function M.setup()
  local autocmd = require("lib.nvim.bindings.autocmd")

  autocmd.create("FileType", function()
    local opt_local = vim.opt_local
    opt_local.foldmethod = "expr"
    opt_local.foldexpr = "v:lua.require'markdown.core.fold'.foldexpr(v:lnum)"
    opt_local.foldenable = true
    opt_local.foldlevel = 99
    opt_local.foldlevelstart = 99
  end, {
    group = autocmd.group("MarkdownLocalFolds", true),
    pattern = { "markdown" },
    desc = "Enable lightweight markdown-specific folding only for markdown buffers",
  })
end

return M
