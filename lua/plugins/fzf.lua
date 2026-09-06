---@module 'plugins.fzf'
---fzf-lua plugin spec

local fzf_config = require("config.fzf")

---@type LazyPluginSpec[]
return {
  {
    "ibhagwan/fzf-lua",
    -- `lazy = true` with no handler meant lazy.nvim never registered a stub
    -- `:FzfLua` command. The `<leader>f*` keymaps in bindings/mappings/fzf.lua
    -- are plain `:FzfLua <sub><CR>` and are set at UIReady, so pressing e.g.
    -- `<leader>fg` before anything else pulled fzf-lua in raised
    -- `E492: Not an editor command: FzfLua`. `cmd` makes lazy.nvim create the
    -- stub and load the plugin on first `:FzfLua`.
    cmd = "FzfLua",
    -- `config` instead of `opts`: this ensures actions are properly registered.
    config = function()
      require("fzf-lua").setup(fzf_config.get())
    end,
  },
}
