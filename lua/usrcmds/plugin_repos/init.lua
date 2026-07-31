---@module 'usrcmds.plugin_repos'
---@brief Clone or remove the personal Neovim plugin list in bulk.
---@description
--- Registers `:MyPluginsClone [dir]` and `:MyPluginsRemove [dir]`. Both operate
--- on the repos `plugins.personal` actually declares (see
--- `usrcmds.plugin_repos.list`) against `dir` (or `vim.env.REPOS_DIR` when
--- no argument is given) — never on every directory found by scanning `dir`,
--- unlike `:MyReposUpdate`, which fetches/pulls whatever git repos it finds
--- regardless of what they are. Cloning everything found and removing
--- everything found are not symmetric risks: an unrelated repo picked up by
--- a directory scan just gets an unwanted `git pull`, but the same repo
--- picked up by a scan-and-delete loses uncommitted work permanently.
--- Sticking to the named list is what makes `:MyPluginsRemove` safe to run at
--- all.
---
--- `:MyPluginsClone` never overwrites an existing clone (skips it) — cloning
--- is additive, no confirmation needed.
---
--- `:MyPluginsRemove` checks every present repo's `git status --porcelain
--- --branch` first: anything with uncommitted changes or commits ahead of
--- its upstream is reported and left alone, never deleted, no matter what.
--- The remaining clean repos are listed in a single confirmation prompt
--- naming exactly what will be deleted before `vim.fn.delete(path, "rf")`
--- runs on any of them.

local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos]")
local usercmd = require("lib.nvim.usercmd")
local plugin_list = require("usrcmds.plugin_repos.list")

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

---@param entry Usrcmds.PluginRepos.Entry
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
local function clone_all(path)
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
local function remove_all(path)
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

---Register :MyPluginsClone and :MyPluginsRemove.
function M.enable()
  usercmd.create("MyPluginsClone", function(args)
    local path = args.args ~= "" and args.args or nil
    clone_all(path)
  end, {
    desc = "[usrcmds.plugin_repos] Clone every plugin in the personal list that isn't already present",
    nargs = "?",
  })

  usercmd.create("MyPluginsRemove", function(args)
    local path = args.args ~= "" and args.args or nil
    remove_all(path)
  end, {
    desc = "[usrcmds.plugin_repos] Remove clean (no uncommitted/unpushed work) plugins from the personal list, after confirmation",
    nargs = "?",
  })
end

return M
