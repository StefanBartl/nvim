---@brief `scripts/strip_coauthor/inventory.lua` — read-only: what breaks when the trailer commits are rewritten.
---@description
--- Rewriting a commit gives it, and every commit above it, a new SHA. This lists everything that
--- names such a SHA and would point into the void afterwards:
---
---   * `repo@sha` references in tracked text files (task `done_in`/`refs`, docs, handovers),
---   * `engine.lock` pins (`commit`, `lib_commit`),
---   * tags that sit on a commit that changes,
---   * `Cargo.toml` git dependencies by `tag` (they move with the tag),
---   * remote branches that carry the trailer without a local counterpart (`ci-verified`, ...).
---
--- It changes nothing. The JSON it can write (`STRIP_INVENTORY_OUT`) is the work list for the
--- re-pinning step: every entry is a file, a line and the old SHA to translate.
---
---     nvim -n -i NONE --headless -u NONE -l scripts/strip_coauthor/inventory.lua
---     # optional: STRIP_INVENTORY_OUT=<file.json>   REPOS_DIR=<dir>

local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local gitx = dofile(script_dir .. "/git.lua")

local function out(text)
  io.stdout:write(text .. "\n")
end

---@param dir string
---@param args string[]
---@return string[] lines
local function git_lines(dir, args)
  local cmd = { "git", "-C", dir }
  vim.list_extend(cmd, args)
  local res = vim.system(cmd, { text = true }):wait()
  if res.code ~= 0 or (res.stdout or "") == "" then
    return {}
  end
  return vim.split((res.stdout:gsub("\n$", "")), "\n", { plain = true })
end

local base = gitx.resolve_base_dir(nil)
local repos = gitx.repos(base)

-- 1. The commits that change, per repository: the full SHA, indexed by its first 7 characters.
---@type table<string, table<string, string[]>>
local changed = {}
local changed_count = {}
for _, repo in ipairs(repos) do
  local plan = gitx.plan(repo.path)
  local index, n = {}, 0
  for _, sha in ipairs(plan and plan.commits or {}) do
    local key = sha:sub(1, 7)
    index[key] = index[key] or {}
    table.insert(index[key], sha)
    n = n + 1
  end
  changed[repo.name] = index
  changed_count[repo.name] = n
end

---Whether `sha` (7 to 40 hex digits) is a commit of `repo` that gets rewritten.
---@param repo string
---@param sha string
---@return boolean
local function is_changed(repo, sha)
  local candidates = changed[repo] and changed[repo][sha:sub(1, 7)]
  for _, full in ipairs(candidates or {}) do
    if vim.startswith(full, sha) then
      return true
    end
  end
  return false
end

-- 2. `repo@sha` references in tracked files, one `git grep` per repository.
local refs, broken = {}, {}
local per_target, per_source = {}, {}
for _, repo in ipairs(repos) do
  local pattern = "[A-Za-z0-9._-]+@[0-9a-f]{7,40}"
  local lines = git_lines(repo.path, { "grep", "-I", "-n", "-o", "-E", pattern, "--", "." })
  for _, line in ipairs(lines) do
    local file, lnum, match = line:match("^(.-):(%d+):(.+)$")
    local target, sha = (match or ""):match("^(.-)@(%x+)$")
    if target and changed[target] and #sha >= 7 then
      refs[#refs + 1] = true
      if is_changed(target, sha) then
        broken[#broken + 1] =
          { repo = repo.name, file = file, line = tonumber(lnum), target = target, sha = sha }
        per_target[target] = (per_target[target] or 0) + 1
        local key = repo.name .. "/" .. file
        per_source[key] = (per_source[key] or 0) + 1
      end
    end
  end
end

-- 3. `engine.lock` pins and appkit tags used by Cargo.toml.
local pins = {}
for _, repo in ipairs(repos) do
  local lock = repo.path .. "/engine.lock"
  if vim.uv.fs_stat(lock) then
    local own, lib
    for _, line in ipairs(vim.fn.readfile(lock)) do
      local key, value = line:match("^([%w_]+)%s*=%s*(.-)%s*$")
      if key == "repo" then
        own = value:match("([^/]+)$")
      elseif key == "lib_repo" then
        lib = value:match("([^/]+)$")
      elseif key == "commit" and own then
        pins[#pins + 1] =
          { repo = repo.name, target = own, sha = value, changed = is_changed(own, value) }
      elseif key == "lib_commit" and lib then
        pins[#pins + 1] =
          { repo = repo.name, target = lib, sha = value, changed = is_changed(lib, value) }
      end
    end
  end
end

-- 4. Tags on commits that change.
local tags = {}
for _, repo in ipairs(repos) do
  local fmt = "%(refname:short) %(objectname) %(*objectname)"
  for _, line in ipairs(git_lines(repo.path, { "for-each-ref", "--format=" .. fmt, "refs/tags" })) do
    local name, obj, peeled = line:match("^(%S+) (%x+) ?(%x*)$")
    local commit = (peeled ~= "" and peeled) or obj
    if name and is_changed(repo.name, commit) then
      tags[#tags + 1] = { repo = repo.name, tag = name }
    end
  end
end

-- 5. Cargo.toml git dependencies by tag.
local cargo = {}
for _, repo in ipairs(repos) do
  for _, line in
    ipairs(git_lines(repo.path, {
      "grep",
      "-I",
      "-n",
      "-E",
      'git *= *"[^"]+".*tag *= *"[^"]+"',
      "--",
      "Cargo.toml",
      "*/Cargo.toml",
    }))
  do
    local file, _, text = line:match("^(.-):(%d+):(.+)$")
    local url, tag = (text or ""):match('git *= *"([^"]+)".*tag *= *"([^"]+)"')
    if url then
      cargo[#cargo + 1] = { repo = repo.name, file = file, dep = url:match("([^/]+)$"), tag = tag }
    end
  end
end

-- Report
local total_changed = 0
for _, n in pairs(changed_count) do
  total_changed = total_changed + n
end
out(("%d Repo(s), %d Commit(s) werden umgeschrieben"):format(#repos, total_changed))
out(
  ("%d `repo@sha`-Verweise auf Repos mit Umschreibung, davon %d auf Commits, die sich ändern"):format(
    #refs,
    #broken
  )
)

local function sorted_pairs(t)
  local keys = vim.tbl_keys(t)
  table.sort(keys, function(a, b)
    return t[a] > t[b]
  end)
  return keys
end

out("\nBetroffene Verweise nach Ziel-Repo:")
for _, key in ipairs(sorted_pairs(per_target)) do
  out(("  %-24s %d"):format(key, per_target[key]))
end

out(
  "\nDateien mit den meisten betroffenen Verweisen (Top 12 von "
    .. vim.tbl_count(per_source)
    .. "):"
)
for i, key in ipairs(sorted_pairs(per_source)) do
  if i > 12 then
    break
  end
  out(("  %4d  %s"):format(per_source[key], key))
end

out("\nengine.lock:")
for _, pin in ipairs(pins) do
  out(
    ("  %-16s -> %-14s %s  %s"):format(
      pin.repo,
      pin.target,
      pin.sha:sub(1, 9),
      pin.changed and "WIRD UMGESCHRIEBEN" or "bleibt"
    )
  )
end

out("\nTags auf Commits, die sich ändern (" .. #tags .. "):")
for _, t in ipairs(tags) do
  out(("  %-16s %s"):format(t.repo, t.tag))
end

out("\nCargo-Abhängigkeiten per Tag:")
local seen = {}
for _, c in ipairs(cargo) do
  local key = c.repo .. " " .. c.dep .. " " .. c.tag
  if not seen[key] then
    seen[key] = true
    out(("  %-16s %-16s %s"):format(c.repo, c.dep, c.tag))
  end
end

local target = vim.env.STRIP_INVENTORY_OUT
if target and target ~= "" then
  local json = vim.json.encode({ refs = broken, pins = pins, tags = tags, cargo = cargo })
  vim.fn.writefile({ json }, target)
  out("\nJSON: " .. target)
end

io.stdout:flush()
os.exit(0)
