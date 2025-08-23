---@module 'plugins.misc'
--- Miscellaneous tools: UI enhancements, terminal, AI tools, copilot, denops.

---@type LazyPluginSpec[]
return {

  -- https://github.com/axieax/urlview.nvim
  -- !!! needs /usrcmd/urlview_integration to work TODO: integration file should not be in /usercmds
  { "axieax/urlview.nvim",
    lazy = true,
  },

 -- https://github.com/jghauser/mkdir.nvim
  {
    'jghauser/mkdir.nvim',
    lazy = true,
  },

-- WATCH:
{
    "NStefan002/screenkey.nvim",
    lazy = false,
    version = "*",
}

}

