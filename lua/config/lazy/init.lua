---@module 'config.lazy'
--- lazy.nvim's own bootstrap options -- `defaults.lazy = true`, plus a long
--- comment on why remote-managed personal plugins need special handling
--- (dir-mode plugins are excluded from lazy-lock.json, so nothing flags
--- them drifting behind origin/main).

local machine = require("machine")

return {
  defaults = { lazy = true },

  -- Checker disabled on the workstation: SOURCE="remote" there makes all
  -- ~25 personal plugins remote (~116 repos), and the corporate EDR scanning
  -- every git.exe spawn turned lazy's checker fetch into a 60-90s startup
  -- freeze. Everywhere else it stays on (weekly, not lazy's 3600s default) --
  -- only third-party remotes get fetched. `:Lazy check` remains available
  -- manually. Full mechanic + measurements: wkdbook-Neovim/MyNotes/
  -- lazynvim-checker-git-fetch-storm.md
  checker = {
    enabled = not machine.is("workstation"),
    notify = false,
    frequency = 3600 * 24 * 7,
  },

  -- Nothing here reloads specs at runtime -- a config edit means a restart
  -- anyway. Off, so lazy stops stat'ing every spec file on the main loop.
  change_detection = {
    enabled = false,
    notify = false,
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
