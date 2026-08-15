---@module 'config.lazy'

local machine = require("machine")

return {
  defaults = { lazy = true },

  -- Without this, remote-managed plugins (personal plugins fall back to
  -- remote on machines without a local checkout, see plugins/personal/init.lua)
  -- can silently drift for months behind origin/main: they have no
  -- lazy-lock.json entry (dir-mode plugins are excluded from the lock), so
  -- nothing pins/flags their version, and ":Lazy" showing no pending action
  -- just means "never checked", not "up to date".
  --
  -- BUT: lazy's checker starts on VeryLazy (interactive sessions only) and, on
  -- the first start after `frequency` has elapsed — i.e. practically every
  -- fresh daily launch — immediately `git fetch`es every non-local plugin.
  -- On the "workstation" SOURCE="remote" makes ALL ~25 personal plugins remote
  -- too (~116 git repos total), and the corporate EDR scans every git.exe
  -- spawn, so that fetch storm froze the UI for 60-90s on every startup.
  -- (Headless can't reproduce it: the checker is gated to non-headless.)
  --
  -- Fix: no automatic checker on the workstation — run `:Lazy check` manually
  -- when you actually want to see drift. Everywhere else the personal plugins
  -- are local dir-mode (skipped by the checker anyway), so only third-party
  -- remotes get fetched over a fast, EDR-free network — keep it enabled there.
  checker = {
    enabled = not machine.is("workstation"),
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
