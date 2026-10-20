---@module 'bindings.usrcmds.native_repos'
---@brief `:MyNative {list|clone|pull|build} [name]` - the native apps next to the plugin checkouts.
---@description
--- Sister of `:MyPlugins` for the native apps (tasks-desktop, rules-desktop, loomAI, takt, docmap-desktop, appkit;
--- the list is `plugins.personal.core.natives`). They are no lazy specs, so `:MyPlugins` never sees them.
---
---  - `list`           per app: cloned or not, git state, and whether the build is current (artifact older than the
---                     newest commit of its sources = stale, same rule as `scripts/sync-machine.ps1`)
---  - `clone [name]`   clone what is missing (additive, never overwrites)
---  - `pull [name]`    fast-forward the clean ones (`--ff-only`; dirty or ahead is left alone and said so)
---  - `build [name]`   run the plain build command of an app (cargo / cmake); without a name, every STALE or missing
---                     build one after the other. Apps without a plain command only show their hint. Output goes to
---                     the quickfix list. Never installs or starts anything.

local notify = require("lib.nvim.notify").create("[usrcmds.native_repos]")
local composer = require("lib.nvim.bindings.usercmd.composer")
local ops = require("bindings.usrcmds.plugin_repos.ops")
local natives = require("plugins.personal.core.natives")

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

local building = false

---Which apps a build run covers. Without a name only the stale or missing ones; with a name that one.
---An app with a plain build command goes to `todo`, one that is built another way (its setup.exe) only
---to `hints` -- it is named, never started.
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

---@param only? string
function M.build(only)
  local base = base_dir()
  if not base then
    return
  end
  if building then
    notify.warn("A build is already running")
    return
  end
  -- `todo`: what has a plain build command; `hints`: stale or missing apps that are built another way (their
  -- setup.exe) -- they are named, never started
  local candidates, states = selected(only), {}
  for _, native in ipairs(candidates) do
    states[native.name] = state_of(native, base .. "/" .. native.name)
  end
  local todo, hints = M.plan_build(candidates, states, only ~= nil)
  if #todo == 0 then
    if #hints > 0 then
      notify.info("Nothing to build from here:\n" .. table.concat(hints, "\n"))
    else
      notify.info("All builds are current.")
    end
    return
  end

  local items, failed = {}, {}
  local index = 0
  local function finish()
    building = false
    vim.fn.setqflist({}, " ", { title = "MyNative build", items = items })
    if #failed == 0 then
      local names = vim.tbl_map(function(n)
        return n.name
      end, todo)
      local text = "Build done: " .. table.concat(names, ", ")
      if #hints > 0 then
        text = text .. "\nNot built from here:\n" .. table.concat(hints, "\n")
      end
      notify.info(text)
    else
      notify.error("Build FAILED: " .. table.concat(failed, ", ") .. " (quickfix has the output)")
      vim.cmd("botright copen")
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
    notify.info(("Build %d/%d: %s ..."):format(index, #todo, native.name))
    local started, err = pcall(vim.system, native.build, { text = true, cwd = dir }, function(res)
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
  building = true
  next_app()
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
      "Build the native apps whose build is stale or missing (cargo / cmake, output to the quickfix list); with a name, that app. Never installs or starts anything",
      M.build
    ),
  }
end

---Registers `:MyNative`.
function M.enable()
  composer.register_type("MYNATIVE_NAME", {
    desc = "Name of a native app (tasks-desktop, rules-desktop, loomAI, takt, ...)",
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
    desc = "Manage the native app checkouts (clone, pull, build state and build)",
    routes = M.routes(),
  })
end

return M
