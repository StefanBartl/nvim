---@module 'bindings.usrcmds.plugin_repos'
---@brief Clone, remove, fetch, pull, update, reclone, list or switch the
---source mode of the personal plugin list — plus an interactive picker.
---@description
--- Registers a single `:MyPlugins {clone|remove|fetch|pull|update|reclone|
--- mode|list|picker} [args]` command via `lib.nvim.usercmd.composer`
--- (replaces the former flat `:MyPluginsClone` / `:MyPluginsRemove`).
--- `clone`/`remove`/`fetch`/`pull`/`update`/`reclone`/`list` all operate on
--- the repos `plugins.personal` actually declares (see
--- `plugins.personal.list`) against `dir` (or `vim.env.REPOS_DIR` when no
--- argument is given) — never on every directory found by scanning `dir`,
--- unlike `:MyReposUpdate` (or `reposcope.nvim`'s `:Reposcope update`/
--- `status`), which fetch/pull or report on whatever git repos they find
--- regardless of what they are. That distinction matters here specifically
--- because `$REPOS_DIR` is not a plugin-only folder (Notes, WKDBooks, ...
--- live there too) — cloning everything found and removing everything found
--- are not symmetric risks either: an unrelated repo picked up by a
--- directory scan just gets an unwanted `git pull`, but the same repo picked
--- up by a scan-and-delete loses uncommitted work permanently. Sticking to
--- the named list is what makes `:MyPlugins remove`/`reclone` safe to run at
--- all.
---
--- `:MyPlugins clone` never overwrites an existing clone (skips it) — cloning
--- is additive, no confirmation needed. `--only=<name>` narrows any of these
--- subcommands to a single listed plugin (tab-completed from the live list).
---
--- `:MyPlugins remove`/`reclone` check every present repo's `git status
--- --porcelain --branch` first: anything with uncommitted changes or commits
--- ahead of its upstream is reported and left alone, never deleted, no
--- matter what. The remaining clean repos are listed in a single
--- confirmation prompt naming exactly what will be deleted before
--- `vim.fn.delete(path, "rf")` runs on any of them; `reclone` then clones
--- each one fresh afterwards (and clones anything from the list that wasn't
--- present at all — no deletion needed there).
---
--- `:MyPlugins fetch`/`pull`/`update` run `git fetch --all --prune`, `git
--- pull --ff-only`, or both in sequence, on every *present* listed repo —
--- the tool for the two-machine `dir`-mode workflow: after pushing from one
--- machine, `:MyPlugins update` on the other brings its checkouts level
--- without touching the non-plugin repos `$REPOS_DIR` also holds (that's
--- `:MyReposUpdate`'s job, scoped the other way — see its own module).
---
--- `:MyPlugins mode [auto|dir|remote|disabled]` reads (bare) or persistently
--- rewrites (with an argument) the `OVERRIDE` line in
--- `lua/plugins/personal/source.lua` directly — a small, targeted text edit,
--- not a runtime setter, since that file is the actual single source of
--- truth for the setting and `require()` caches it anyway. A restart is
--- needed for a change to take effect (see `mode_cmd` below).
---
--- `:MyPlugins list [dir]` is read-only: prints every listed plugin plus
--- whether it's present in `dir`, for a quick overview before clone/remove.
---
--- `:MyPlugins picker [dir]` opens an interactive `Snacks.picker` (see
--- `picker.lua`): `<Tab>` cycles the highlighted plugin through
--- clone/update/pull/fetch/remove/reclone (only the actions that make sense
--- for its current presence), `<CR>` runs every assigned action in one
--- batch — clone/remove/fetch/pull/update via the same functions as their
--- flat subcommands above, so the same safety checks and confirmation
--- prompts apply.

local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos]")
local composer = require("lib.nvim.usercmd.composer")
local is_dir = require("lib.nvim.fs.is_dir")
local expand_path = require("lib.nvim.cross.fs.expand_path")
local plugin_list = require("plugins.personal.list")
local ops = require("bindings.usrcmds.plugin_repos.ops")

local M = {}

local loop, fn, env = vim.uv or vim.loop, vim.fn, vim.env
local system, fnamemodify = vim.system, fn.fnamemodify

-- git-operation primitives (clone/fetch/pull/update/check_removable/delete)
-- live in ops.lua, shared with picker.lua. Local aliases keep every call
-- site below unchanged.
local resolve_base_dir = ops.resolve_base_dir
local is_git_repo = ops.is_git_repo
local clone_one = ops.clone_one
local check_removable = ops.check_removable

-- "statusline" reports into the shared lib.nvim.progress registry, rendered
-- by the statusline's "plugin_progress" module — same convention as the
-- personal plugins (see lua/plugins/personal/init.lua).
local ok_progress, progress_mod = pcall(require, "lib.nvim.progress")
---@param title string
local function new_progress(title)
  if not ok_progress then
    return nil
  end
  return progress_mod.create({ title = title, style = "statusline" })
end

-- =============================================================================
-- Clone
-- =============================================================================

---@param path string|nil
---@param only_name string|nil Restrict to this one entry's name, if given
local function clone_all(path, only_name)
  local base_dir = resolve_base_dir(path)
  if not base_dir then
    notify.error("No repository directory provided and REPOS_DIR is not set")
    return
  end

  local stat = loop.fs_stat(base_dir)
  if not stat or stat.type ~= "directory" then
    notify.error("Repository directory is not accessible: " .. base_dir)
    return
  end

  local entries, err = plugin_list.read()
  if not entries then
    notify.error(tostring(err))
    return
  end

  if only_name then
    local filtered = {}
    for _, entry in ipairs(entries) do
      if entry.name == only_name then
        filtered[#filtered + 1] = entry
      end
    end
    entries = filtered
  end

  local prog = new_progress("[usrcmds.plugin_repos] clone")
  local cloned, existing, failed = {}, {}, {}
  local index = 1
  local total = #entries

  local function run_next()
    local entry = entries[index]
    if not entry then
      vim.schedule(function()
        if prog then
          prog:finish(("%d cloned, %d already present, %d failed"):format(#cloned, #existing, #failed))
        end
        local lines = { ("Cloned %d, skipped %d already present"):format(#cloned, #existing) }
        if #failed > 0 then
          lines[#lines + 1] = "Failed:\n" .. table.concat(failed, "\n")
          notify.warn(table.concat(lines, "\n\n"))
        else
          notify.info(table.concat(lines, "\n\n"))
        end
      end)
      return
    end

    if prog then
      prog:update({ text = entry.name, current = index, total = total })
    end

    clone_one(entry, base_dir, function(status, clone_err)
      if status == "cloned" then
        cloned[#cloned + 1] = entry.name
      elseif status == "exists" then
        existing[#existing + 1] = entry.name
      else
        failed[#failed + 1] = entry.name .. ": " .. tostring(clone_err)
      end
      index = index + 1
      run_next()
    end)
  end

  notify.info(("Cloning %d plugin(s) into %s..."):format(total, base_dir))
  run_next()
end

-- =============================================================================
-- Remove
-- =============================================================================

-- Forward-declared: remove_all calls it before its definition further down,
-- and both need to stay `local` rather than leaking a global into a config
-- shared with every other plugin's Lua.
local finish_check

---@param path string|nil
---@param only_name string|nil Restrict to this one entry's name, if given
local function remove_all(path, only_name)
  local base_dir = resolve_base_dir(path)
  if not base_dir then
    notify.error("No repository directory provided and REPOS_DIR is not set")
    return
  end

  local entries, err = plugin_list.read()
  if not entries then
    notify.error(tostring(err))
    return
  end

  if only_name then
    local filtered = {}
    for _, entry in ipairs(entries) do
      if entry.name == only_name then
        filtered[#filtered + 1] = entry
      end
    end
    entries = filtered
  end

  ---@type string[]
  local present = {}
  for _, entry in ipairs(entries) do
    local target = base_dir .. "/" .. entry.name
    if loop.fs_stat(target) then
      if is_git_repo(target) then
        present[#present + 1] = entry.name
      else
        notify.warn(("%s exists at %s but is not a git repository — left untouched"):format(entry.name, target))
      end
    end
  end

  if #present == 0 then
    notify.info("None of the listed plugins are present in " .. base_dir)
    return
  end

  local prog = new_progress("[usrcmds.plugin_repos] checking")
  ---@type string[]
  local safe, unsafe = {}, {}
  local index = 1
  local total = #present

  local function checked_next()
    local name = present[index]
    if not name then
      vim.schedule(function()
        if prog then
          prog:finish(("%d clean, %d left alone"):format(#safe, #unsafe))
        end
        finish_check(safe, unsafe, base_dir)
      end)
      return
    end
    if prog then
      prog:update({ text = name, current = index, total = total })
    end
    check_removable(base_dir .. "/" .. name, function(is_safe, reason)
      if is_safe then
        safe[#safe + 1] = name
      else
        unsafe[#unsafe + 1] = name .. " (" .. reason .. ")"
      end
      index = index + 1
      checked_next()
    end)
  end

  notify.info(("Checking %d present plugin(s) for uncommitted/unpushed work..."):format(total))
  checked_next()
end

---Reports what was left alone, confirms, then deletes the clean list.
---@param safe string[]
---@param unsafe string[]
---@param base_dir string
finish_check = function(safe, unsafe, base_dir)
  if #unsafe > 0 then
    notify.warn("Left alone (not clean, not deleted):\n" .. table.concat(unsafe, "\n"))
  end

  if #safe == 0 then
    notify.info("Nothing left to remove — every present plugin has uncommitted or unpushed work.")
    return
  end

  local msg = ("Permanently delete %d repositor%s from %s?\n\n%s"):format(
    #safe, #safe == 1 and "y" or "ies", base_dir, table.concat(safe, "\n"))
  local choice = fn.confirm(msg, "&Yes, delete\n&No", 2)
  if choice ~= 1 then
    notify.info("Cancelled — nothing deleted.")
    return
  end

  local removed, remove_failed = {}, {}
  for _, name in ipairs(safe) do
    local target = base_dir .. "/" .. name
    local ok = fn.delete(target, "rf")
    if ok == 0 then
      removed[#removed + 1] = name
    else
      remove_failed[#remove_failed + 1] = name
    end
  end

  if #remove_failed > 0 then
    notify.error(("Removed %d, failed to remove: %s"):format(#removed, table.concat(remove_failed, ", ")))
  else
    notify.info(("Removed %d repositor%s"):format(#removed, #removed == 1 and "y" or "ies"))
  end
end

-- =============================================================================
-- Fetch / Pull / Update (present listed repos only — the two-machine sync case)
-- =============================================================================

---Resolves `base_dir`, reads the live list (optionally narrowed by
---`only_name`) and returns just the names actually present on disk as a git
---repo — the common setup every one of fetch/pull/update shares. Anything
---present but not a git repo is reported and skipped, same as `remove_all`.
---@param path string|nil
---@param only_name string|nil
---@return string[]|nil names
---@return string|nil base_dir
local function present_listed_names(path, only_name)
  local base_dir = resolve_base_dir(path)
  if not base_dir then
    notify.error("No repository directory provided and REPOS_DIR is not set")
    return nil, nil
  end

  local entries, err = plugin_list.read()
  if not entries then
    notify.error(tostring(err))
    return nil, nil
  end

  if only_name then
    local filtered = {}
    for _, entry in ipairs(entries) do
      if entry.name == only_name then
        filtered[#filtered + 1] = entry
      end
    end
    entries = filtered
  end

  ---@type string[]
  local present = {}
  for _, entry in ipairs(entries) do
    local target = base_dir .. "/" .. entry.name
    if loop.fs_stat(target) then
      if is_git_repo(target) then
        present[#present + 1] = entry.name
      else
        notify.warn(("%s exists at %s but is not a git repository — skipped"):format(entry.name, target))
      end
    end
  end

  return present, base_dir
end

---Shared runner for `fetch`/`pull`/`update`: resolves the present listed
---repos, runs `op_fn` on each sequentially (via `ops.run_sequential`) and
---reports one combined summary. `gerund`/`past` only drive the notify text
---(e.g. "Fetching"/"fetched"), never the git call itself.
---@param gerund string
---@param past string
---@param op_fn fun(path: string, on_done: fun(ok: boolean, err: string|nil))
---@param path string|nil
---@param only_name string|nil
local function run_listed_op(gerund, past, op_fn, path, only_name)
  local present, base_dir = present_listed_names(path, only_name)
  if not present then
    return
  end
  if #present == 0 then
    notify.info("None of the listed plugins are present in " .. tostring(base_dir))
    return
  end

  local prog = new_progress(("[usrcmds.plugin_repos] %s"):format(gerund:lower()))
  notify.info(("%s %d plugin(s) in %s..."):format(gerund, #present, base_dir))

  ops.run_sequential(
    present,
    function(name, on_done) op_fn(base_dir .. "/" .. name, on_done) end,
    function(name) return name end,
    function(ok_items, failed)
      if prog then
        prog:finish(("%d %s, %d failed"):format(#ok_items, past, #failed))
      end
      if #failed > 0 then
        local lines = {}
        for _, f in ipairs(failed) do
          lines[#lines + 1] = f.item .. ": " .. f.err
        end
        notify.warn(("%d %s, failed:\n%s"):format(#ok_items, past, table.concat(lines, "\n")))
      else
        notify.info(("%d repositor%s %s"):format(#ok_items, #ok_items == 1 and "y" or "ies", past))
      end
    end,
    prog
  )
end

---@param path string|nil
---@param only_name string|nil
local function fetch_all(path, only_name)
  run_listed_op("Fetching", "fetched", ops.fetch_one, path, only_name)
end

---@param path string|nil
---@param only_name string|nil
local function pull_all(path, only_name)
  run_listed_op("Pulling", "pulled", ops.pull_one, path, only_name)
end

---Fetch + fast-forward pull, scoped to the named plugin list — the
---`:MyReposUpdate`-equivalent for just `plugins.personal.list`, so a second
---machine can bring its `dir`-mode checkouts level with commits pushed from
---the first without touching the unrelated repos `$REPOS_DIR` also holds.
---@param path string|nil
---@param only_name string|nil
local function update_all(path, only_name)
  run_listed_op("Updating", "updated", ops.update_one, path, only_name)
end

-- =============================================================================
-- Check (read-only git-status overview, scoped to the listed plugins)
-- =============================================================================

---Same job as `reposcope.nvim`'s `:Reposcope status $REPOS_DIR`, but scoped
---to `plugins.personal.list` like every other `:MyPlugins` subcommand —
---never a directory scan (see the module-level note on why that distinction
---matters for `$REPOS_DIR`). Runs `git status` on every present listed repo
---in parallel (read-only, so unlike fetch/pull/clone there's no shared
---network/disk budget worth serializing for) and shows the aligned overview
---in a `kit.viewer` popup.
---@param path string|nil
---@param only_name string|nil
local function check_all(path, only_name)
  local present, base_dir = present_listed_names(path, only_name)
  if not present then
    return
  end
  if #present == 0 then
    notify.info("None of the listed plugins are present in " .. tostring(base_dir))
    return
  end

  local prog = new_progress("[usrcmds.plugin_repos] checking status")
  notify.info(("Reading status of %d plugin(s) in %s..."):format(#present, base_dir))

  ---@type table<integer, PluginRepoStatusRecord>
  local indexed = {}
  ---@type string[]
  local errors = {}
  local total = #present
  local remaining = total

  local function finish()
    remaining = remaining - 1
    if prog then
      prog:update({ text = ("%d of %d read"):format(total - remaining, total), current = total - remaining, total = total })
    end
    if remaining > 0 then
      return
    end

    -- Every `status_one` callback fires straight out of its `vim.system`
    -- completion handler — a fast-event/libuv context where API calls like
    -- `nvim_create_buf`/`nvim_open_win` (which `kit.viewer` needs) aren't
    -- allowed. `vim.schedule` defers the rest of this onto the main loop,
    -- same as `run_sequential`'s own `on_finish` dispatch does for
    -- fetch/pull/update.
    vim.schedule(function()
      if prog then
        prog:finish(("read %d of %d repositories"):format(total - #errors, total))
      end

      ---@type PluginRepoStatusRecord[]
      local records = {}
      for i = 1, total do
        if indexed[i] then
          records[#records + 1] = indexed[i]
        end
      end

      if #records == 0 then
        notify.error("Failed to read status of every plugin:\n" .. table.concat(errors, "\n"))
        return
      end

      local lines = ops.render_status(records)
      if #errors > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "Failed:"
        vim.list_extend(lines, errors)
      end

      require("lib.nvim.ui.kit").viewer({ title = "MyPlugins check", lines = lines })
    end)
  end

  for i, name in ipairs(present) do
    ops.status_one(base_dir .. "/" .. name, name, function(record, err)
      if record then
        indexed[i] = record
      else
        errors[#errors + 1] = name .. ": " .. (err or "unknown error")
      end
      finish()
    end)
  end
end

-- =============================================================================
-- Reclone (delete-if-clean + fresh clone; clone outright if not present)
-- =============================================================================

-- Forward-declared: reclone_all calls it before its definition further down.
local finish_reclone

---@param path string|nil
---@param only_name string|nil
local function reclone_all(path, only_name)
  local base_dir = resolve_base_dir(path)
  if not base_dir then
    notify.error("No repository directory provided and REPOS_DIR is not set")
    return
  end

  local entries, err = plugin_list.read()
  if not entries then
    notify.error(tostring(err))
    return
  end

  if only_name then
    local filtered = {}
    for _, entry in ipairs(entries) do
      if entry.name == only_name then
        filtered[#filtered + 1] = entry
      end
    end
    entries = filtered
  end

  ---@type Plugins.Personal.Entry[]
  local present_entries, missing_entries = {}, {}
  for _, entry in ipairs(entries) do
    local target = base_dir .. "/" .. entry.name
    if loop.fs_stat(target) then
      if is_git_repo(target) then
        present_entries[#present_entries + 1] = entry
      else
        notify.warn(("%s exists at %s but is not a git repository — left untouched"):format(entry.name, target))
      end
    else
      missing_entries[#missing_entries + 1] = entry
    end
  end

  if #present_entries == 0 and #missing_entries == 0 then
    notify.info("None of the listed plugins matched")
    return
  end

  if #present_entries == 0 then
    finish_reclone({}, {}, missing_entries, base_dir)
    return
  end

  local prog = new_progress("[usrcmds.plugin_repos] reclone: checking")
  notify.info(("Checking %d present plugin(s) for uncommitted/unpushed work before reclone..."):format(#present_entries))

  ops.run_sequential(
    present_entries,
    function(entry, on_done)
      check_removable(base_dir .. "/" .. entry.name, function(is_safe, reason)
        on_done(is_safe, reason)
      end)
    end,
    function(entry) return entry.name end,
    function(safe, failed)
      if prog then
        prog:finish(("%d clean, %d left alone"):format(#safe, #failed))
      end
      local unsafe = {}
      for _, f in ipairs(failed) do
        unsafe[#unsafe + 1] = f.item.name .. " (" .. f.err .. ")"
      end
      finish_reclone(safe, unsafe, missing_entries, base_dir)
    end,
    prog
  )
end

---Reports what was left alone, confirms deletion of the clean present set,
---deletes it, then clones that set plus everything that was missing —
---mirrors `finish_check`'s confirm shape for the deletion half, and
---`clone_all`'s run loop for the clone half.
---@param safe Plugins.Personal.Entry[]
---@param unsafe string[]
---@param missing Plugins.Personal.Entry[]
---@param base_dir string
finish_reclone = function(safe, unsafe, missing, base_dir)
  if #unsafe > 0 then
    notify.warn("Left alone (not clean, not recloned):\n" .. table.concat(unsafe, "\n"))
  end

  if #safe == 0 and #missing == 0 then
    notify.info("Nothing to reclone — every present plugin has uncommitted or unpushed work.")
    return
  end

  if #safe > 0 then
    local names = {}
    for _, entry in ipairs(safe) do
      names[#names + 1] = entry.name
    end
    local msg = ("Delete and re-clone %d repositor%s from %s?\n\n%s"):format(
      #safe, #safe == 1 and "y" or "ies", base_dir, table.concat(names, "\n"))
    local choice = fn.confirm(msg, "&Yes, reclone\n&No", 2)
    if choice ~= 1 then
      notify.info(#missing > 0 and "Reclone of the clean set cancelled — cloning only the missing ones." or "Cancelled — nothing recloned.")
      safe = {}
    end
  end

  ---@type Plugins.Personal.Entry[]
  local to_clone = {}
  if #safe > 0 then
    local delete_failed = {}
    for _, entry in ipairs(safe) do
      if ops.delete_one(base_dir .. "/" .. entry.name) then
        to_clone[#to_clone + 1] = entry
      else
        delete_failed[#delete_failed + 1] = entry.name
      end
    end
    if #delete_failed > 0 then
      notify.error("Failed to remove before reclone: " .. table.concat(delete_failed, ", "))
    end
  end
  vim.list_extend(to_clone, missing)

  if #to_clone == 0 then
    notify.info("Nothing left to clone.")
    return
  end

  local prog = new_progress("[usrcmds.plugin_repos] reclone: cloning")
  notify.info(("Cloning %d plugin(s) fresh..."):format(#to_clone))

  ops.run_sequential(
    to_clone,
    function(entry, on_done)
      clone_one(entry, base_dir, function(status, clone_err)
        on_done(status ~= "failed", clone_err)
      end)
    end,
    function(entry) return entry.name end,
    function(cloned, failed)
      if prog then
        prog:finish(("%d cloned fresh, %d failed"):format(#cloned, #failed))
      end
      if #failed > 0 then
        local lines = {}
        for _, f in ipairs(failed) do
          lines[#lines + 1] = f.item.name .. ": " .. f.err
        end
        notify.warn(("%d cloned, failed:\n%s"):format(#cloned, table.concat(lines, "\n")))
      else
        notify.info(("%d repositor%s cloned fresh"):format(#cloned, #cloned == 1 and "y" or "ies"))
      end
    end,
    prog
  )
end

-- =============================================================================
-- List (read-only overview)
-- =============================================================================

---Prints every listed plugin plus whether it's present in `base_dir` — a
---read-only companion to `clone`/`remove` for "what would this even touch".
---@param path string|nil
local function list_all(path)
  local entries, err = plugin_list.read()
  if not entries then
    notify.error(tostring(err))
    return
  end

  local base_dir = resolve_base_dir(path)
  local lines = {}
  for _, entry in ipairs(entries) do
    local marker = "?"
    if base_dir then
      marker = loop.fs_stat(base_dir .. "/" .. entry.name) and "+" or "-"
    end
    lines[#lines + 1] = ("%s  %-24s  %s"):format(marker, entry.name, entry.repo)
  end

  local header = base_dir
      and ("%d plugin(s) — '+' present / '-' missing in %s"):format(#entries, base_dir)
    or ("%d plugin(s) — presence unknown (no directory resolved; set $REPOS_DIR or pass one)"):format(#entries)
  notify.info(header .. "\n\n" .. table.concat(lines, "\n"))
end

-- =============================================================================
-- Mode (persistent dir/remote/auto/disabled switch)
-- =============================================================================

---@return string
local function source_file_path()
  return vim.fs.joinpath(fn.stdpath("config"), "lua", "plugins", "personal", "source.lua")
end

---Reads the live `OVERRIDE` value straight out of source.lua — that file is
---the actual single source of truth, so this never risks drifting from a
---separately-tracked runtime copy.
---@return string|nil override
---@return string|nil err
local function read_override()
  local path = source_file_path()
  local ok, lines = pcall(fn.readfile, path)
  if not ok then
    return nil, "cannot read " .. path
  end
  for _, line in ipairs(lines) do
    local value = line:match('^local%s+OVERRIDE%s*=%s*"([%a]+)"')
    if value then
      return value, nil
    end
  end
  return nil, "OVERRIDE line not found in " .. path
end

---Rewrites just the `OVERRIDE` line's quoted value in source.lua, leaving
---indentation, the surrounding comment block and everything else untouched.
---@param new_mode string
---@return boolean ok
---@return string|nil err
local function write_override(new_mode)
  local path = source_file_path()
  local ok, lines = pcall(fn.readfile, path)
  if not ok then
    return false, "cannot read " .. path
  end
  for i, line in ipairs(lines) do
    local prefix, suffix = line:match('^(local%s+OVERRIDE%s*=%s*)"[%a]+"(.*)$')
    if prefix then
      lines[i] = prefix .. '"' .. new_mode .. '"' .. suffix
      fn.writefile(lines, path)
      return true, nil
    end
  end
  return false, "OVERRIDE line not found in " .. path
end

---Bare `:MyPlugins mode` reports the current value; `:MyPlugins mode <x>`
---persists it. `require()` caches `plugins.personal.source`, and the spec
---list it produces is already baked into what lazy loaded at startup, so a
---change here only takes effect after a full restart — `:Lazy reload` does
---not re-evaluate this file.
---@param new_mode string|nil
local function mode_cmd(new_mode)
  local current, err = read_override()
  if not current then
    notify.error(tostring(err))
    return
  end

  if not new_mode then
    notify.info(("Current OVERRIDE: %q (restart Neovim after changing it for the change to take effect)"):format(current))
    return
  end

  if new_mode == current then
    notify.info(("OVERRIDE is already %q — nothing changed"):format(current))
    return
  end

  local ok, werr = write_override(new_mode)
  if not ok then
    notify.error(tostring(werr))
    return
  end
  notify.warn(
    ("OVERRIDE changed %q -> %q. Restart Neovim for plugins.personal.source to re-resolve — :Lazy reload will NOT pick this up (require() is cached).")
      :format(current, new_mode)
  )
end

-- =============================================================================
-- Command registration
-- =============================================================================

---Register `:MyPlugins {clone|remove|mode|list} [args]` via
---lib.nvim.usercmd.composer — replaces the former flat `:MyPluginsClone` /
---`:MyPluginsRemove`.
function M.enable()
  -- Directory arg: real directory completion plus `$REPOS_DIR` offered up
  -- front when resolvable, mirroring reposcope.nvim's own
  -- `REPOSCOPE_STATUS_DIR` type. Validation is otherwise the built-in DIR
  -- semantics (must expand to an existing directory).
  composer.register_type("MYPLUGINS_DIR", {
    validate = function(raw)
      local expanded = expand_path(raw)
      if not is_dir(fnamemodify(expanded, ":p")) then
        return false, nil, ("'%s' is not a directory"):format(raw)
      end
      return true, expanded, nil
    end,
    complete = function(arg_lead)
      local candidates = {}
      if env.REPOS_DIR and env.REPOS_DIR ~= "" and ("$REPOS_DIR"):sub(1, #arg_lead) == arg_lead then
        candidates[#candidates + 1] = "$REPOS_DIR"
      end
      vim.list_extend(candidates, fn.getcompletion(arg_lead, "dir"))
      return candidates
    end,
  })

  -- `--only=<name>` for clone/remove: validated and completed against the
  -- *live* plugins.personal.list on every request (not a snapshot taken once
  -- at registration time), same principle reposcope.nvim's own per-request
  -- completers use — the list only changes on a config edit anyway, but
  -- there is no reason to risk a stale copy for a lookup this cheap.
  composer.register_type("MYPLUGINS_NAME", {
    validate = function(raw)
      local entries = plugin_list.read()
      for _, entry in ipairs(entries or {}) do
        if entry.name == raw then
          return true, raw, nil
        end
      end
      return false, nil, ("'%s' is not in plugins.personal.list"):format(raw)
    end,
    complete = function(arg_lead)
      local entries = plugin_list.read() or {}
      local out = {}
      for _, entry in ipairs(entries) do
        if arg_lead == "" or entry.name:sub(1, #arg_lead) == arg_lead then
          out[#out + 1] = entry.name
        end
      end
      return out
    end,
  })

  composer.verb("MyPlugins", {
    desc = "Manage the personal plugin checkouts and their source mode",
    routes = {
      { path = { "clone" },
        args = { { name = "dir", type = "MYPLUGINS_DIR", optional = true } },
        flags = { { name = "only", type = "MYPLUGINS_NAME" } },
        desc = "Clone every listed plugin not yet present (or just --only=<name>) into dir/$REPOS_DIR",
        run = function(ctx) clone_all(ctx.args.dir, ctx.flags.only) end },

      { path = { "remove" },
        args = { { name = "dir", type = "MYPLUGINS_DIR", optional = true } },
        flags = { { name = "only", type = "MYPLUGINS_NAME" } },
        desc = "Remove clean (no uncommitted/unpushed work) listed plugins (or just --only=<name>), after confirmation",
        run = function(ctx) remove_all(ctx.args.dir, ctx.flags.only) end },

      { path = { "fetch" },
        args = { { name = "dir", type = "MYPLUGINS_DIR", optional = true } },
        flags = { { name = "only", type = "MYPLUGINS_NAME" } },
        desc = "git fetch --all --prune on every present listed plugin (or just --only=<name>)",
        run = function(ctx) fetch_all(ctx.args.dir, ctx.flags.only) end },

      { path = { "pull" },
        args = { { name = "dir", type = "MYPLUGINS_DIR", optional = true } },
        flags = { { name = "only", type = "MYPLUGINS_NAME" } },
        desc = "git pull --ff-only on every present listed plugin (or just --only=<name>)",
        run = function(ctx) pull_all(ctx.args.dir, ctx.flags.only) end },

      { path = { "update" },
        args = { { name = "dir", type = "MYPLUGINS_DIR", optional = true } },
        flags = { { name = "only", type = "MYPLUGINS_NAME" } },
        desc = "Fetch + fast-forward pull every present listed plugin (or just --only=<name>) — brings this machine level with another machine's pushed commits",
        run = function(ctx) update_all(ctx.args.dir, ctx.flags.only) end },

      { path = { "check" },
        args = { { name = "dir", type = "MYPLUGINS_DIR", optional = true } },
        flags = { { name = "only", type = "MYPLUGINS_NAME" } },
        desc = "Show a read-only git-status overview (branch, ahead/behind, dirty) of every present listed plugin (or just --only=<name>) — same idea as reposcope.nvim's :Reposcope status, scoped to the listed plugins",
        run = function(ctx) check_all(ctx.args.dir, ctx.flags.only) end },

      { path = { "reclone" },
        args = { { name = "dir", type = "MYPLUGINS_DIR", optional = true } },
        flags = { { name = "only", type = "MYPLUGINS_NAME" } },
        desc = "Delete (if clean) and re-clone present listed plugins, or clone missing ones fresh, after confirmation",
        run = function(ctx) reclone_all(ctx.args.dir, ctx.flags.only) end },

      { path = { "picker" },
        args = { { name = "dir", type = "MYPLUGINS_DIR", optional = true } },
        desc = "Interactive multi-select: assign clone/update/pull/fetch/remove/reclone per plugin, then run them all at once",
        run = function(ctx) require("bindings.usrcmds.plugin_repos.picker").open(ctx.args.dir) end },

      { path = { "mode" },
        args = { { name = "mode", type = "STRING", enum = { "auto", "dir", "remote", "disabled" }, optional = true } },
        desc = "Show, or persistently switch, plugins.personal.source's OVERRIDE (restart required to apply)",
        run = function(ctx) mode_cmd(ctx.args.mode) end },

      { path = { "list" },
        args = { { name = "dir", type = "MYPLUGINS_DIR", optional = true } },
        desc = "List every plugin in plugins.personal.list and whether it's present in dir/$REPOS_DIR",
        run = function(ctx) list_all(ctx.args.dir) end },
    },
  })

  -- Flat shorthand for the subcommand used often enough to want a single
  -- word: `:MyPluginsCheck [dir]` is exactly `:MyPlugins check [dir]`, same
  -- as `:Reposcope status $REPOS_DIR` but scoped to the listed plugins.
  vim.api.nvim_create_user_command("MyPluginsCheck", function(cmd_opts)
    check_all(cmd_opts.args ~= "" and expand_path(cmd_opts.args) or nil, nil)
  end, {
    nargs = "?",
    complete = function(arg_lead)
      local candidates = {}
      if env.REPOS_DIR and env.REPOS_DIR ~= "" and ("$REPOS_DIR"):sub(1, #arg_lead) == arg_lead then
        candidates[#candidates + 1] = "$REPOS_DIR"
      end
      vim.list_extend(candidates, fn.getcompletion(arg_lead, "dir"))
      return candidates
    end,
    desc = "Shorthand for :MyPlugins check [dir] — git-status overview of the listed plugins",
  })
end

return M
