---@module 'config.lazy_config'

return {
  defaults = { lazy = true },

  -- Without this, remote-managed plugins (personal plugins fall back to
  -- remote on machines without a local checkout, see plugins/personal/init.lua)
  -- can silently drift for months behind origin/main: they have no
  -- lazy-lock.json entry (dir-mode plugins are excluded from the lock), so
  -- nothing pins/flags their version, and ":Lazy" showing no pending action
  -- just means "never checked", not "up to date".
  checker = {
    enabled = true,
    notify = true,
  },

  ui = {
    icons = {
      ft = "",
      lazy = "󰂠 ",
      loaded = "",
      not_loaded = "",
    },
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "2html_plugin",
        "tohtml",
        "getscript",
        "getscriptPlugin",
        "gzip",
        "logipat",
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
        "matchit",
        "tar",
        "tarPlugin",
        "rrhelper",
        "spellfile_plugin",
        "vimball",
        "vimballPlugin",
        "zip",
        "zipPlugin",
        "tutor",
        "rplugin",
        "syntax",
        "synmenu",
        "optwin",
        "compiler",
        "bugreport",
        "ftplugin",
      },
    },
  },
}
