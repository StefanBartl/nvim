---@module 'bindings.usrcmds.plugin_repos.sync_routes'
---@brief The composer routes of `:MyPlugins sync`.
---@description
--- Grammar:
---  - `sync [dir] [--only=<name>] [--dry-run] [--no-fetch] [--jobs=<n>]`
---  - `sync issues`   reopen the triage list of the last run
---
--- `dir` and `--only=` use the argument types `init.lua` registers (`MYPLUGINS_DIR`,
--- `MYPLUGINS_NAME`, validated against the live `plugins.personal.core.list`). The handlers
--- live in `sync.lua` and are required on first use, so declaring the routes costs nothing
--- at startup. `init.lua` loads this file guarded: an older lib.nvim on the other machine then
--- loses only this route, not all of `:MyPlugins`.

local M = {}

---@return table[]
function M.routes()
  return {
    {
      path = { "sync" },
      args = { { name = "dir", type = "MYPLUGINS_DIR", optional = true } },
      flags = {
        { name = "only", type = "MYPLUGINS_NAME" },
        { name = "dry-run", bool = true },
        { name = "no-fetch", bool = true },
        { name = "jobs", type = "INT" },
      },
      desc = "Fetch ALL listed plugin repos first, then pull every one that is behind (fast-forward only); the ones that cannot be pulled (dirty, diverged, no upstream, unreachable ...) are collected into a triage list instead of stopping the run. --dry-run classifies without pulling, --no-fetch skips the fetch, --jobs=<n> sets the parallel fetches (default 2, max 6), --only=<name> syncs one repo",
      run = function(ctx)
        local jobs = tonumber(ctx.flags.jobs)
        require("bindings.usrcmds.plugin_repos.sync").run({
          dir = ctx.args.dir,
          only = ctx.flags.only,
          dry_run = ctx.flags["dry-run"] == true,
          no_fetch = ctx.flags["no-fetch"] == true,
          jobs = jobs,
        })
      end,
    },

    {
      path = { "sync", "issues" },
      desc = "Reopen the triage list (unresolved and skipped repos) of the last :MyPlugins sync, also after a restart",
      run = function()
        require("bindings.usrcmds.plugin_repos.sync").issues()
      end,
    },
  }
end

return M
