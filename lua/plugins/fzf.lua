---@module 'plugins.fzf'
---fzf-lua plugin spec

local fzf_config = require("config.fzf")

---@type LazyPluginSpec[]
return {
  {
    "ibhagwan/fzf-lua",
    lazy = true,
    opts = function()
      return fzf_config.get()
    end,
  },
}
