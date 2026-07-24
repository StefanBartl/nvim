---@module 'plugins.fzf'
---fzf-lua plugin spec

local fzf_config = require("config.fzf")

---@type LazyPluginSpec[]
return {
  {
    "ibhagwan/fzf-lua",
    lazy = true,
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
