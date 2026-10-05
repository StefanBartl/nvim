-- TESTS/sync/sync_routes_spec.lua -- the grammar of `:MyPlugins sync`: dispatch, flags, the
-- `issues` sub-route. Driven through the real composer (the verb is registered here as
-- :SyncT with the very routes `:MyPlugins` gets); the handlers are stubbed.

return function(H)
  local eq, ok = H.eq, H.ok

  local composer = require("lib.nvim.bindings.usercmd.composer")
  local routes = require("bindings.usrcmds.plugin_repos.sync_routes")
  local sync = require("bindings.usrcmds.plugin_repos.sync")

  -- the two argument types init.lua registers for every `:MyPlugins` route
  composer.register_type("MYPLUGINS_DIR", {
    validate = function(raw)
      return true, raw, nil
    end,
  })
  composer.register_type("MYPLUGINS_NAME", {
    validate = function(raw)
      if raw == "alpha" or raw == "beta" then
        return true, raw, nil
      end
      return false, nil, ("'%s' is not in the list"):format(raw)
    end,
    complete = function()
      return { "alpha", "beta" }
    end,
  })
  composer.verb("SyncT", { routes = routes.routes() })

  local orig_run, orig_issues, orig_notify = sync.run, sync.issues, vim.notify
  local ran, issued, errors = nil, 0, {}
  sync.run = function(opts)
    ran = opts
  end
  sync.issues = function()
    issued = issued + 1
  end
  vim.notify = function(msg, level)
    if level == vim.log.levels.ERROR or level == vim.log.levels.WARN then
      errors[#errors + 1] = msg
    end
  end
  local function restore()
    sync.run, sync.issues, vim.notify = orig_run, orig_issues, orig_notify
  end
  local function reset()
    ran, issued, errors = nil, 0, {}
  end

  local passed, err = pcall(function()
    vim.cmd("SyncT sync")
    ok(ran ~= nil, "a bare `sync` runs")
    eq(ran.dry_run, false, "no --dry-run by default")
    eq(ran.no_fetch, false, "no --no-fetch by default")
    eq(ran.only, nil, "no --only by default")
    eq(ran.jobs, nil, "the job count is left to the module default")
    eq(issued, 0, "issues is not triggered")

    reset()
    vim.cmd("SyncT sync --dry-run --no-fetch --jobs=4 --only=alpha")
    eq(ran.dry_run, true, "--dry-run")
    eq(ran.no_fetch, true, "--no-fetch")
    eq(ran.jobs, 4, "--jobs=4 arrives as a number")
    eq(ran.only, "alpha", "--only=alpha")

    reset()
    vim.cmd("SyncT sync D:/some/dir")
    eq(ran.dir, "D:/some/dir", "an optional dir argument")

    reset()
    vim.cmd("SyncT sync issues")
    eq(issued, 1, "`sync issues` opens the saved list")
    eq(ran, nil, "...and does not start a run")

    reset()
    vim.cmd("silent! SyncT sync --only=gamma")
    eq(ran, nil, "an unknown --only name is refused before anything runs")

    reset()
    vim.cmd("silent! SyncT sync --jobs=many")
    eq(ran, nil, "a non-numeric --jobs is refused")

    -- completion offers the sub-route, and the flags once `--` is typed
    local sub = table.concat(vim.fn.getcompletion("SyncT sync ", "cmdline"), " ")
    ok(sub:find("issues", 1, true), "completion knows `issues`: " .. sub)
    local flags = table.concat(vim.fn.getcompletion("SyncT sync --", "cmdline"), " ")
    ok(flags:find("--dry-run", 1, true), "completion knows --dry-run: " .. flags)
    ok(flags:find("--no-fetch", 1, true), "completion knows --no-fetch: " .. flags)
    ok(flags:find("--jobs", 1, true), "completion knows --jobs: " .. flags)
    ok(flags:find("--only", 1, true), "completion knows --only: " .. flags)
    local only = table.concat(vim.fn.getcompletion("SyncT sync --only=", "cmdline"), " ")
    ok(only:find("alpha", 1, true), "--only= completes the names: " .. only)
  end)

  -- the composer reports its refusals on the next loop turn: let them land while the stub is in
  vim.wait(100, function()
    return false
  end)
  restore()
  pcall(vim.api.nvim_del_user_command, "SyncT")
  if not passed then
    error(err, 0)
  end
end
