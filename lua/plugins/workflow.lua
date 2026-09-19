---@module 'plugins.workflow'
--- Tools for organizing development workflow (annotations, reminders).

---@type LazyPluginSpec[]
return {

  -- folke/todo-comments.nvim replaced by insights.nvim's `todos` feature
  -- (2026-09-19): the keyword table and colours this spec fed it -- the
  -- former `config/todo_comments/` -- ship as insights' defaults now, the
  -- scan is `:Insights todos`, and the in-buffer highlight is insights'
  -- own. `<leader>sT` (picker) and `<leader>ST` (quickfix) are set on the
  -- insights spec in plugins/personal/init.lua. Along with the plugin went
  -- its `config/todo_comments/init.lua` monkey-patch of
  -- `todo-comments.highlight` for an upstream "Invalid 'end_col'" error.

  -- NStefan002/screenkey.nvim replaced by ui.nvim's own built-in feature
  -- (see lua/plugins/personal/init.lua's ui.nvim spec). Use :UI screenkey.

  -- translate.nvim replaced by the standalone language.nvim plugin
  -- (see lua/plugins/language.lua). Use :Translate.

  -- chrisbra/unicode.vim replaced by emojis.nvim's `:Emojis unicode`
  -- (see lua/plugins/personal/init.lua's emojis.nvim spec). Use
  -- :Emojis unicode name|search|table|digraphs, or the "uni" key.
}
