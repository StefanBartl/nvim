---@module 'bindings.usrcmds.plugin_repos'
---@brief Clone, remove, list or switch the source mode of the personal plugin list.
---@description
--- Registers a single `:MyPlugins {clone|remove|mode|list} [args]` command via
--- `lib.nvim.usercmd.composer` (replaces the former flat `:MyPluginsClone` /
--- `:MyPluginsRemove`). `clone`/`remove`/`list` all operate on the repos
--- `plugins.personal` actually declares (see `plugins.personal.list`) against
--- `dir` (or `vim.env.REPOS_DIR` when no argument is given) — never on every
--- directory found by scanning `dir`, unlike `:MyReposUpdate` (or
--- `reposcope.nvim`'s `:Reposcope update`/`status`), which fetch/pull or
--- report on whatever git repos they find regardless of what they are. That
--- distinction matters here specifically because `$REPOS_DIR` is not a
--- plugin-only folder (Notes, WKDBooks, ... live there too) — cloning
--- everything found and removing everything found are not symmetric risks
--- either: an unrelated repo picked up by a directory scan just gets an
--- unwanted `git pull`, but the same repo picked up by a scan-and-delete
--- loses uncommitted work permanently. Sticking to the named list is what
--- makes `:MyPlugins remove` safe to run at all.
---
--- `:MyPlugins clone` never overwrites an existing clone (skips it) — cloning
--- is additive, no confirmation needed. `--only=<name>` narrows either
--- command to a single listed plugin (tab-completed from the live list).
---
--- `:MyPlugins remove` checks every present repo's `git status --porcelain
--- --branch` first: anything with uncommitted changes or commits ahead of
--- its upstream is reported and left alone, never deleted, no matter what.
--- The remaining clean repos are listed in a single confirmation prompt
--- naming exactly what will be deleted before `vim.fn.delete(path, "rf")`
--- runs on any of them.
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

local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos]")
local composer = require("lib.nvim.usercmd.composer")
local is_dir = require("lib.nvim.fs.is_dir")
local expand_path = require("lib.nvim.cross.fs.expand_path")
local plugin_list = require("plugins.personal.list")

local M = {}

local loop, fn, env = vim.uv or vim.loop, vim.fn, vim.env
local system, fnamemodify = vim.system, fn.fnamemodify

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

---@param override string|nil
---@return string|nil
local function resolve_base_dir(override)
  if override and override ~= "" then
    return fnamemodify(override, ":p")
  end
  if env.REPOS_DIR and env.REPOS_DIR ~= "" then
    return fnamemodify(env.REPOS_DIR, ":p")
  end
  return nil
end

---@param path string
---@return boolean
local function is_git_repo(path)
  local stat = loop.fs_stat(path .. "/.git")
  return stat ~= nil and stat.type == "directory"
end

-- =============================================================================
-- Clone
-- =============================================================================

---@param entry Plugins.Personal.Entry
---@param base_dir string
---@param on_done fun(status: "cloned"|"exists"|"failed", err: string|nil)
local function clone_one(entry, base_dir, on_done)
  local target = base_dir .. "/" .. entry.name
  if loop.fs_stat(target) then
    on_done("exists", nil)
    return
  end

  -- entry.repo is the full "owner/repo" exactly as declared in the spec
  -- (plugins.personal), not assembled from a hardcoded owner prefix — a repo
  -- under a different GitHub account would still clone correctly.
  local url = "https://github.com/" .. entry.repo .. ".git"
  system({ "git", "clone", url, target }, { text = true }, function(res)
    if res.code ~= 0 then
      on_done("failed", res.stderr or "git clone failed")
    else
      on_done("cloned", nil)
    end
  end)
end

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

---Reads `git status --porcelain --branch` and reports whether it's safe to
---delete: no uncommitted changes, and not ahead of its upstream (a repo with
---nothing pushed yet, or commits made since the last push, would lose real
---work — REPOS_DIR is where the work happens, not just a read-only mirror).
---@param path string
---@param on_done fun(safe: boolean, reason: string|nil)
local function check_removable(path, on_done)
  system({ "git", "status", "--porcelain", "--branch" }, { cwd = path, text = true }, function(res)
    if res.code ~= 0 then
      on_done(false, "git status failed")
      return
    end
    local lines = vim.split(res.stdout or "", "\n", { plain = true })
    local branch_line = lines[1] or ""
    if branch_line:match("%[ahead") then
      on_done(false, "ahead of upstream (unpushed commits)")
      return
    end
    -- Anything past the branch line is a dirty/untracked file.
    for i = 2, #lines do
      if lines[i] ~= "" then
        on_done(false, "uncommitted changes")
        return
      end
    end
    on_done(true, nil)
  end)
end

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
end

return M
