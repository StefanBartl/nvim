---@module 'bindings.usrcmds.native_repos'
---@brief `:MyNative {list|clone|pull|deps|build|install|uninstall} [name]` - the native apps next to the plugin checkouts.
---@description
--- Sister of `:MyPlugins` for the native apps (tasks-desktop, rules-desktop, ai-desktop, takt, docmap-desktop, appkit;
--- the list is `plugins.personal.core.natives`). They are no lazy specs, so `:MyPlugins` never sees them.
---
---  - `list`           per app: cloned or not, git state, and whether the build is current (artifact older than the
---                     newest commit of its sources = stale, same rule as `scripts/sync-machine.ps1`)
---  - `clone [name]`   clone what is missing (additive, never overwrites)
---  - `pull [name]`    fast-forward the clean ones (`--ff-only`; dirty or ahead is left alone and said so)
---  - `deps [name]`    check the tools the apps build with (`toolchain.lua`) and install the missing ones that need
---                     no administrator (rustup, tauri-cli, the MSYS2 packages); the others are named
---  - `build [name]`   run the build command of an app (its scripts/build-install.ps1 -BuildOnly); without a name,
---                     every STALE or missing build one after the other. Apps without a command only show their
---                     hint, apps with a missing tool are skipped. Output goes to the quickfix list. Never installs
---                     or starts anything.
---  - `install [name]` `deps`, then build and install for the current user from the terminal, no downloaded
---                     setup.exe (which SmartScreen stops on a managed workstation); without a name, every cloned
---                     app. Output goes to the quickfix list.
---  - `uninstall [name]` scripts/uninstall.ps1 of the app; without a name, every cloned app.

local notify = require("lib.nvim.notify").create("[usrcmds.native_repos]")
local composer = require("lib.nvim.bindings.usercmd.composer")
local ops = require("bindings.usrcmds.plugin_repos.ops")
local natives = require("plugins.personal.core.natives")
local toolchain = require("bindings.usrcmds.native_repos.toolchain")

local M = {}

local uv = vim.uv or vim.loop

---Staleness rule: the artifact is stale when a source commit is newer than it.
---@param artifact_mtime integer|nil Seconds, nil when the artifact does not exist
---@param source_commit_time integer|nil Seconds of the newest commit touching the sources, nil when unknown
---@return "missing"|"stale"|"current"
function M.build_state(artifact_mtime, source_commit_time)
  if not artifact_mtime then
    return "missing"
  end
  if source_commit_time and source_commit_time > artifact_mtime then
    return "stale"
  end
  return "current"
end

---@param native Plugins.Personal.Native
---@param dir string
---@return string state "not cloned"|"no artifact"|"missing"|"stale"|"current"
local function state_of(native, dir)
  if not uv.fs_stat(dir) then
    return "not cloned"
  end
  if not native.artifact then
    return "no artifact"
  end
  local stat = uv.fs_stat(dir .. "/" .. native.artifact)
  local cmd = { "git", "-C", dir, "log", "-1", "--format=%ct", "--" }
  vim.list_extend(cmd, native.sources or { "." })
  local res = vim.system(cmd, { text = true }):wait()
  local commit_time = res.code == 0 and tonumber(vim.trim(res.stdout or "")) or nil
  return M.build_state(stat and stat.mtime.sec or nil, commit_time)
end

---@param dir string
---@return string
local function git_state(dir)
  local res = vim
    .system({ "git", "-C", dir, "status", "--porcelain", "--branch" }, { text = true })
    :wait()
  if res.code ~= 0 then
    return "no git"
  end
  local lines = vim.split(res.stdout or "", "\r?\n", { trimempty = true })
  local parts = {}
  local branch = lines[1] or ""
  local behind = branch:match("behind (%d+)")
  local ahead = branch:match("ahead (%d+)")
  if behind then
    parts[#parts + 1] = "behind " .. behind
  end
  if ahead then
    parts[#parts + 1] = "ahead " .. ahead
  end
  if #lines > 1 then
    parts[#parts + 1] = "dirty"
  end
  return #parts > 0 and table.concat(parts, ", ") or "clean"
end

---@return string|nil
local function base_dir()
  local base = ops.resolve_base_dir(nil)
  if not base then
    notify.error("REPOS_DIR is not set")
    return nil
  end
  return (base:gsub("[/\\]+$", ""))
end

---@param only? string
---@return Plugins.Personal.Native[]
local function selected(only)
  if not only then
    return natives.list
  end
  local one = natives.get(only)
  return one and { one } or {}
end

function M.list()
  local base = base_dir()
  if not base then
    return
  end
  local out, attention = {}, false
  for _, native in ipairs(natives.list) do
    local dir = base .. "/" .. native.name
    local build = state_of(native, dir)
    local git = build == "not cloned" and "-" or git_state(dir)
    out[#out + 1] = ("%-15s git: %-14s build: %s"):format(native.name, git, build)
    attention = attention or build == "not cloned" or build == "stale" or build == "missing"
  end
  local text = table.concat(out, "\n")
  if attention then
    notify.warn(text)
  else
    notify.info(text)
  end
end

---@param only? string
function M.clone(only)
  local base = base_dir()
  if not base then
    return
  end
  local todo = selected(only)
  ops.run_sequential(todo, function(native, on_done)
    ops.clone_one({ repo = native.repo, name = native.name }, base, function(status, err)
      on_done(status ~= "failed", err)
    end)
  end, function(native)
    return native.name
  end, function(ok_items, failed)
    local lines = { ("%d native repo(s) handled"):format(#ok_items) }
    for _, f in ipairs(failed) do
      lines[#lines + 1] = ("%s failed: %s"):format(f.item.name, f.err)
    end
    if #failed > 0 then
      notify.warn(table.concat(lines, "\n"))
    else
      notify.info(table.concat(lines, "\n"))
    end
  end)
end

---@param only? string
function M.pull(only)
  local base = base_dir()
  if not base then
    return
  end
  local notes = {}
  ops.run_sequential(selected(only), function(native, on_done)
    local dir = base .. "/" .. native.name
    if not uv.fs_stat(dir) then
      notes[#notes + 1] = native.name .. ": not cloned"
      on_done(true)
      return
    end
    ops.check_removable(dir, function(safe, reason)
      if not safe then
        notes[#notes + 1] = ("%s: left alone (%s)"):format(native.name, reason or "dirty or ahead")
        on_done(true)
        return
      end
      ops.pull_one(dir, function(ok, err, changed)
        if ok then
          notes[#notes + 1] = native.name .. (changed and ": pulled" or ": up to date")
        end
        on_done(ok, err)
      end)
    end)
  end, function(native)
    return native.name
  end, function(_, failed)
    for _, f in ipairs(failed) do
      notes[#notes + 1] = ("%s: pull failed: %s"):format(f.item.name, f.err)
    end
    local text = table.concat(notes, "\n")
    if #failed > 0 then
      notify.warn(text)
    else
      notify.info(text)
    end
  end)
end

local running = false

---Which apps a build run covers. Without a name only the stale or missing ones; with a name that one.
---An app with a build command goes to `todo`, one without only to `hints` -- it is named, never started.
---@param list Plugins.Personal.Native[]
---@param states table<string, string>  # app name -> state (see state_of)
---@param named boolean  # the run was asked for by name
---@return Plugins.Personal.Native[] todo, string[] hints
function M.plan_build(list, states, named)
  local todo, hints = {}, {}
  for _, native in ipairs(list) do
    local state = states[native.name]
    if named or state == "stale" or state == "missing" then
      if native.build then
        todo[#todo + 1] = native
      else
        hints[#hints + 1] = ("%s: %s"):format(native.name, native.hint)
      end
    end
  end
  return todo, hints
end

---Which apps an install (or uninstall) run covers. Without a name every cloned one with that command (an install
---is not stale or current: the artifact says nothing about what is installed); with a name that one.
---@param list Plugins.Personal.Native[]
---@param states table<string, string>  # app name -> state (see state_of)
---@param named boolean  # the run was asked for by name
---@param field? "install"|"uninstall"  # default "install"
---@return Plugins.Personal.Native[] todo, string[] hints
function M.plan_install(list, states, named, field)
  field = field or "install"
  local todo, hints = {}, {}
  for _, native in ipairs(list) do
    if named or states[native.name] ~= "not cloned" then
      if native[field] then
        todo[#todo + 1] = native
      elseif named or native.build then
        hints[#hints + 1] = ("%s: %s"):format(native.name, native.hint)
      end
    end
  end
  return todo, hints
end

local labels = { build = "Build", install = "Install", uninstall = "Uninstall" }

---Runs the build, install or uninstall command of the apps one after the other, output to the quickfix list.
---A build skips the apps whose tools are missing; an install first installs the tools it can (toolchain.ensure).
---@param kind "build"|"install"|"uninstall"
---@param only? string
local function run(kind, only)
  local base = base_dir()
  if not base then
    return
  end
  if running then
    notify.warn("A build or install is already running")
    return
  end
  local candidates, states = selected(only), {}
  for _, native in ipairs(candidates) do
    local dir = base .. "/" .. native.name
    -- only a build asks git for the staleness; install and uninstall need nothing but "cloned"
    if kind == "build" then
      states[native.name] = state_of(native, dir)
    else
      states[native.name] = uv.fs_stat(dir) and "cloned" or "not cloned"
    end
  end
  local todo, hints
  if kind == "build" then
    todo, hints = M.plan_build(candidates, states, only ~= nil)
  else
    todo, hints = M.plan_install(candidates, states, only ~= nil, kind)
  end
  if #todo == 0 then
    if #hints > 0 then
      notify.info("Nothing to " .. kind .. " from here:\n" .. table.concat(hints, "\n"))
    elseif kind == "build" then
      notify.info("All builds are current.")
    else
      notify.info(("Nothing to %s (no cloned app has that command)."):format(kind))
    end
    return
  end

  local label = labels[kind]
  local items, failed = {}, {}
  local index = 0
  local function finish()
    running = false
    vim.fn.setqflist({}, " ", { title = "MyNative " .. kind, items = items })
    if #failed > 0 then
      notify.error(
        label .. " FAILED: " .. table.concat(failed, ", ") .. " (quickfix has the output)"
      )
      vim.cmd("botright copen")
    elseif #todo == 0 then
      notify.warn(label .. ": nothing could run:\n" .. table.concat(hints, "\n"))
    else
      local names = vim.tbl_map(function(n)
        return n.name
      end, todo)
      local text = label .. " done: " .. table.concat(names, ", ")
      if #hints > 0 then
        text = text .. "\nNot handled from here:\n" .. table.concat(hints, "\n")
      end
      notify.info(text)
    end
  end
  local function next_app()
    index = index + 1
    local native = todo[index]
    if not native then
      finish()
      return
    end
    local dir = base .. "/" .. native.name
    if not uv.fs_stat(dir) then
      failed[#failed + 1] = native.name
      items[#items + 1] = { text = ("== %s: not cloned (:MyNative clone)"):format(native.name) }
      next_app()
      return
    end
    notify.info(("%s %d/%d: %s ..."):format(label, index, #todo, native.name))
    local argv = native[kind]
    local started, err = pcall(vim.system, argv, { text = true, cwd = dir }, function(res)
      vim.schedule(function()
        items[#items + 1] =
          { text = ("== %s: %s"):format(native.name, res.code == 0 and "ok" or "FAILED") }
        if res.code ~= 0 then
          failed[#failed + 1] = native.name
        end
        for _, line in
          ipairs(vim.split((res.stdout or "") .. (res.stderr or ""), "\r?\n", { trimempty = true }))
        do
          items[#items + 1] = { text = line }
        end
        next_app()
      end)
    end)
    if not started then
      failed[#failed + 1] = native.name
      items[#items + 1] = { text = ("== %s: cannot start: %s"):format(native.name, tostring(err)) }
      next_app()
    end
  end
  ---@param missing table<string, boolean>
  local function hold_back(missing)
    local held
    todo, held = toolchain.split(todo, missing)
    vim.list_extend(hints, held)
  end

  local function go()
    running = true
    -- a throw before the first command (a tool check) must not leave `running` set for the session
    local ok, err = pcall(function()
      if kind == "uninstall" then
        next_app()
      elseif kind == "build" then
        hold_back(toolchain.check(toolchain.needed(todo)))
        next_app()
      else
        notify.info("Install: checking the tools ...")
        toolchain.ensure(toolchain.needed(todo), items, function(missing, tool_hints)
          hold_back(missing)
          vim.list_extend(hints, tool_hints)
          next_app()
        end)
      end
    end)
    if not ok then
      running = false
      notify.error(label .. " stopped: " .. tostring(err))
    end
  end

  if kind == "uninstall" then
    local names = table.concat(
      vim.tbl_map(function(n)
        return n.name
      end, todo),
      ", "
    )
    -- asked through the shared dialog, so the work continues in the answer's callback
    require("bindings.usrcmds.plugin_repos.confirm").yesno(
      "Uninstall " .. names .. "?",
      "uninstall",
      function(yes)
        if not yes then
          notify.info("Uninstall cancelled.")
          return
        end
        go()
      end
    )
    return
  end
  go()
end

---@param only? string
function M.build(only)
  run("build", only)
end

---@param only? string
function M.install(only)
  run("install", only)
end

---@param only? string
function M.uninstall(only)
  run("uninstall", only)
end

---Checks the tools of the cloned apps (or of the named one) and installs the missing ones it can.
---@param only? string
function M.deps(only)
  local base = base_dir()
  if not base then
    return
  end
  if running then
    notify.warn("A build or install is already running")
    return
  end
  local apps = vim.tbl_filter(function(native)
    return only ~= nil or uv.fs_stat(base .. "/" .. native.name) ~= nil
  end, selected(only))
  local ids = toolchain.needed(apps)
  if #ids == 0 then
    notify.info("No tools to check.")
    return
  end
  local items = {}
  running = true
  notify.info("Checking the tools: " .. table.concat(ids, ", ") .. " ...")
  local ok, err = pcall(toolchain.ensure, ids, items, function(missing, hints)
    running = false
    local lines = {}
    for _, id in ipairs(ids) do
      lines[#lines + 1] = ("%-10s %s"):format(id, missing[id] and "MISSING" or "ok")
    end
    if #items > 0 then
      vim.fn.setqflist({}, " ", { title = "MyNative deps", items = items })
    end
    if #hints > 0 then
      notify.warn(table.concat(lines, "\n") .. "\n\nBy hand:\n" .. table.concat(hints, "\n"))
    else
      notify.info(table.concat(lines, "\n"))
    end
  end)
  if not ok then
    running = false
    notify.error("Deps stopped: " .. tostring(err))
  end
end

---@return table[]
function M.routes()
  local name_arg = { { name = "name", type = "MYNATIVE_NAME", optional = true } }
  local function route(path, desc, fn)
    local args
    if path ~= "list" then
      args = name_arg
    end
    return {
      path = { path },
      args = args,
      desc = desc,
      run = function(ctx)
        fn(ctx.args and ctx.args.name)
      end,
    }
  end
  return {
    route(
      "list",
      "Per native app: cloned, git state and whether the build is current, stale or missing",
      function()
        M.list()
      end
    ),
    route(
      "clone",
      "Clone the native app repos that are missing (additive, never overwrites)",
      M.clone
    ),
    route(
      "pull",
      "Fast-forward the clean native app repos (git pull --ff-only); dirty or ahead ones are left alone",
      M.pull
    ),
    route(
      "build",
      "Build the native apps whose build is stale or missing (output to the quickfix list); with a name, that app. Never installs or starts anything",
      M.build
    ),
    route(
      "install",
      "Install the missing tools, then build and install every cloned native app for the current user, without a downloaded setup.exe (output to the quickfix list); with a name, that app",
      M.install
    ),
    route(
      "uninstall",
      "Remove the installation of every cloned native app for the current user (scripts/uninstall.ps1); with a name, that app",
      M.uninstall
    ),
    route(
      "deps",
      "Check the tools the cloned native apps build with and install the missing ones that need no administrator (rustup, tauri-cli, MSYS2 packages)",
      M.deps
    ),
  }
end

---Registers `:MyNative`.
function M.enable()
  composer.register_type("MYNATIVE_NAME", {
    desc = "Name of a native app (tasks-desktop, rules-desktop, ai-desktop, takt, ...)",
    validate = function(raw)
      if natives.get(raw) then
        return true, raw, nil
      end
      return false, nil, ("'%s' is not in plugins.personal.core.natives"):format(raw)
    end,
    complete = function(arg_lead)
      return vim.tbl_filter(function(name)
        return arg_lead == "" or name:sub(1, #arg_lead) == arg_lead
      end, natives.names())
    end,
  })
  composer.verb("MyNative", {
    desc = "Manage the native app checkouts (clone, pull, build state, tools, build, install, uninstall)",
    routes = M.routes(),
  })
end

return M
