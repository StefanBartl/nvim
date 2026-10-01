---@module 'plugins.fzf'
---fzf-lua plugin spec

local fzf_config = require("config.fzf")

---@type LazyPluginSpec[]
return {
  {
    "ibhagwan/fzf-lua",
    -- `lazy = true` with no handler meant lazy.nvim never registered a stub
    -- `:FzfLua` command, raising `E492: Not an editor command: FzfLua` on a
    -- direct `:FzfLua <sub>` call before anything else had pulled fzf-lua in.
    -- `cmd` makes lazy.nvim create the stub and load the plugin on first
    -- `:FzfLua`. bindings/mappings/fzf.lua (the module this originally guarded
    -- against) was removed 2026-10-01 -- its one keymap went unused -- but
    -- fzf-lua stays available as a pickers.nvim engine option (`require()`
    -- lazy-loads it regardless of this trigger) and `replacer`/`cmdlog`/`lsp`
    -- still reach it directly.
    cmd = "FzfLua",
    -- `config` instead of `opts`: this ensures actions are properly registered.
    config = function()
      require("fzf-lua").setup(fzf_config.get())
    end,
  },
}
