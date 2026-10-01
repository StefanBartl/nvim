---@module 'config.lazy'
--- lazy.nvim's own bootstrap options -- `defaults.lazy = true`, plus a long
--- comment on why remote-managed personal plugins need special handling
--- (dir-mode plugins are excluded from lazy-lock.json, so nothing flags
--- them drifting behind origin/main).

local machine = require("machine")

--- How often lazy's checker fetches the third-party remotes.
local CHECK_EVERY = 3600 * 24 * 7

---Is the next check due? Read from lazy's own state file (its default path:
---this config does not set `state`).
---
---`checker.frequency` alone does not make the checker weekly. It only spaces
---out the *fetch*; an enabled checker still runs `git log` for every remote
---plugin at every start to refresh the update list (`checker.start()` ->
---`Manage.log({ check = true })`). Measured here: 92x `git log` + 9x
---`git show-ref`, 1.4 s of main thread spent on spawning alone, three
---seconds after startup. Nothing reads that list between two checks
---(`notify = false`, no statusline component), so the checker is switched on
---only for the session in which the fetch is due.
---
---lazy writes `last_check` when a check starts, not when it succeeds: a due
---session that is offline, or quit during the fetch, still uses up the week.
---`C` in `:Lazy` (or `:Lazy check`) refreshes by hand.
---@param frequency integer seconds
---@return boolean
local function check_due(frequency)
  -- No file, no key, not a number: all of them mean "never checked".
  local ok, last = pcall(function()
    local path = vim.fn.stdpath("state") .. "/lazy/state.json"
    local state = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
    return tonumber(state.checker.last_check)
  end)
  -- A `last_check` in the future (the clock was set ahead once) is NOT "due":
  -- lazy schedules from that value too, so enabling the checker for it would
  -- run the per-plugin `git log` pass at every start and still never fetch, or
  -- rewrite the value, until the clock catches up. Postponed is the cheap side.
  return os.time() - (ok and last or 0) >= frequency
end

return {
  defaults = { lazy = true },

  -- Checker disabled on the workstation: SOURCE="remote" there makes all
  -- ~25 personal plugins remote (~116 repos), and the corporate EDR scanning
  -- every git.exe spawn turned lazy's checker fetch into a 60-90s startup
  -- freeze. Everywhere else it runs once a week (see check_due above) --
  -- only third-party remotes get fetched. In the sessions in between `:Lazy`
  -- lists no pending updates until `C` (check) is pressed there; `:Lazy check`
  -- remains available manually. Full mechanic + measurements:
  -- wkdbook-Neovim/MyNotes/lazynvim-checker-git-fetch-storm.md
  checker = {
    enabled = not machine.is("workstation") and check_due(CHECK_EVERY),
    notify = false,
    frequency = CHECK_EVERY,
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
