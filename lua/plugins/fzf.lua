---@module 'plugins.fzf'
---fzf-lua plugin spec

local fzf_config = require("config.fzf")

---@type LazyPluginSpec[]
return {
  {
    "ibhagwan/fzf-lua",
    -- `lazy = true` with no trigger meant lazy.nvim never registered a stub
    -- `:FzfLua` command, so the eager `<leader>f*` keymaps in
    -- `bindings/mappings/fzf.lua` (registered at UIReady) hit
    -- `E492: Not an editor command: FzfLua` until something else pulled the
    -- plugin in. `cmd` makes lazy.nvim create the stub and load on first use.
    cmd = "FzfLua",
    -- opts = function()
    -- return fzf_config.get()
    -- end,
    config = function()
      -- config function instead of opts
      -- This ensures actions are properly registered
      require("fzf-lua").setup(fzf_config.get())
    end,
  },
}
