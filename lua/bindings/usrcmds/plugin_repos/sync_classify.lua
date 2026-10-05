---@module 'bindings.usrcmds.plugin_repos.sync_classify'
---@brief The pure core of `:MyPlugins sync`: status parser, state classification, ordering and summary.
---@description
--- No process, no UI, no notify: plain tables in, plain tables out, so every row of the
--- state table is specified without a git repository (`TESTS/sync/sync_classify_spec.lua`).
---
--- Nothing here reads a git message text. Messages are localizable, and the structural
--- data is enough: the state comes from `git status --porcelain=v2 --branch` (head,
--- upstream, ahead/behind, changed entries), and the reason a pull failed is derived from a
--- second status taken after the failure, never from `stderr`.
---
--- ### States
---
---   ok          `current`  nothing to do          `pulled`   fast-forwarded this run
---   pending     `behind`   something to pull (only visible in a `--dry-run`)
---   hint        `ahead`    unpushed commits       `dirty`    local changes, nothing incoming
---               `not_git`  folder, no repo        `missing`  not cloned (`:MyPlugins clone`)
---   problem     `fetch_failed` `status_failed` `no_upstream` `detached` `diverged`
---               `dirty_blocked` `pull_failed`
---
--- Only problems count against "everything is up to date"; a hint never does (the repo
--- has everything the remote has), and a problem the user skipped does not either, but is
--- named in the summary.

local M = {}

---@alias MyPlugins.SyncState
---| "current"
---| "pulled"
---| "behind"
---| "ahead"
---| "dirty"
---| "not_git"
---| "missing"
---| "fetch_failed"
---| "status_failed"
---| "no_upstream"
---| "detached"
---| "diverged"
---| "dirty_blocked"
---| "pull_failed"

---@class MyPlugins.SyncStatus
---@field branch string|nil     Branch name; nil when detached.
---@field detached boolean
---@field initial boolean       No commit yet.
---@field upstream string|nil   `origin/main`; nil when none is configured.
---@field has_ab boolean        git reported ahead/behind (an upstream that exists).
---@field ahead integer
---@field behind integer
---@field changed integer       Tracked entries with a change (incl. renames and conflicts).
---@field untracked integer
---@field conflicted integer
---@field files string[]        Paths of the changed and untracked entries.

---@class MyPlugins.SyncRecord
---@field name string
---@field path string
---@field state MyPlugins.SyncState
---@field detail string|nil     One line: why (an error line, `ahead 2 / behind 3`, ...).
---@field branch string|nil
---@field upstream string|nil
---@field ahead integer
---@field behind integer
---@field dirty boolean
---@field changed integer
---@field skipped boolean
---@field pulled integer|nil    Commits a successful pull brought in.
---@field preview string[]|nil  Triage preview lines (filled by the dashboard, never persisted).

--- Order of the problem states in the dashboard (most blocking first).
---@type MyPlugins.SyncState[]
M.PROBLEM_STATES = {
  "diverged",
  "dirty_blocked",
  "pull_failed",
  "fetch_failed",
  "status_failed",
  "no_upstream",
  "detached",
}

---@type table<string, true>
local PROBLEM = {}
for _, s in ipairs(M.PROBLEM_STATES) do
  PROBLEM[s] = true
end

---@type table<string, true>
local HINT = { ahead = true, dirty = true, not_git = true, missing = true }

---Is the state a problem (it keeps the repo from being up to date)?
---@param state string
---@return boolean
function M.is_problem(state)
  return PROBLEM[state] == true
end

---Is the state only a hint (hidden by default in the dashboard)?
---@param state string
---@return boolean
function M.is_hint(state)
  return HINT[state] == true
end

-- ── Status parser ─────────────────────────────────────────────────────────────

---Parse `git status --porcelain=v2 --branch -z`. NUL-separated: header lines
---(`# branch.head main`), then one entry per change (`1 XY ...`, `2 XY ... path NUL orig`,
---`u XY ...`, `? path`). The paths come out raw, never C-quoted.
---@param raw string|nil
---@return MyPlugins.SyncStatus
function M.parse_status(raw)
  ---@type MyPlugins.SyncStatus
  local st = {
    detached = false,
    initial = false,
    has_ab = false,
    ahead = 0,
    behind = 0,
    changed = 0,
    untracked = 0,
    conflicted = 0,
    files = {},
  }
  if type(raw) ~= "string" or raw == "" then
    return st
  end
  local fields = vim.split(raw, "\0", { plain = true })
  local i, n = 1, #fields
  while i <= n do
    local f = fields[i]
    i = i + 1
    local c = f:sub(1, 1)
    if c == "#" then
      local key, value = f:match("^# (%S+) ?(.*)$")
      if key == "branch.head" then
        if value == "(detached)" then
          st.detached = true
        else
          st.branch = value
        end
      elseif key == "branch.oid" then
        st.initial = value == "(initial)"
      elseif key == "branch.upstream" then
        st.upstream = value ~= "" and value or nil
      elseif key == "branch.ab" then
        local a, b = value:match("^%+(%d+) %-(%d+)$")
        if a and b then
          st.has_ab = true
          st.ahead, st.behind = tonumber(a) or 0, tonumber(b) or 0
        end
      end
    elseif c == "1" then
      -- 1 XY sub mH mI mW hH hI path   (8 fixed fields, the path is the rest)
      local path = f:match("^1 %S+ %S+ %S+ %S+ %S+ %S+ %S+ (.*)$")
      st.changed = st.changed + 1
      if path then
        st.files[#st.files + 1] = path
      end
    elseif c == "2" then
      -- 2 XY sub mH mI mW hH hI Xscore path NUL origPath
      local path = f:match("^2 %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ (.*)$")
      i = i + 1 -- the original path is its own field
      st.changed = st.changed + 1
      if path then
        st.files[#st.files + 1] = path
      end
    elseif c == "u" then
      -- u XY sub m1 m2 m3 mW h1 h2 h3 path
      local path = f:match("^u %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ (.*)$")
      st.changed = st.changed + 1
      st.conflicted = st.conflicted + 1
      if path then
        st.files[#st.files + 1] = path
      end
    elseif c == "?" then
      st.untracked = st.untracked + 1
      local path = f:match("^%? (.*)$")
      if path then
        st.files[#st.files + 1] = path
      end
    end
    -- "!" (ignored) and anything unknown: not interesting here.
  end
  return st
end

---@param st MyPlugins.SyncStatus
---@return boolean
local function is_dirty(st)
  return st.changed + st.untracked > 0
end

-- ── Classification ────────────────────────────────────────────────────────────

---@param name string
---@param path string
---@param st MyPlugins.SyncStatus|nil
---@return MyPlugins.SyncRecord
local function base_record(name, path, st)
  return {
    name = name,
    path = path,
    state = "current",
    branch = st and st.branch or nil,
    upstream = st and st.upstream or nil,
    ahead = st and st.ahead or 0,
    behind = st and st.behind or 0,
    dirty = st and is_dirty(st) or false,
    changed = st and (st.changed + st.untracked) or 0,
    skipped = false,
  }
end

---`ahead 2 / behind 3` style one-liner.
---@param st MyPlugins.SyncStatus
---@return string
local function ab_detail(st)
  return ("ahead %d / behind %d"):format(st.ahead, st.behind)
end

---The state of a repo after fetch and status, before any pull.
---
--- `fetch_err` set: the fetch failed (network, auth, timeout), the repo is left alone.
--- `st` nil: git could not give a status at all.
---@param name string
---@param path string
---@param st MyPlugins.SyncStatus|nil
---@param fetch_err string|nil
---@return MyPlugins.SyncRecord
function M.classify(name, path, st, fetch_err)
  local rec = base_record(name, path, st)
  if fetch_err then
    rec.state, rec.detail = "fetch_failed", fetch_err
    return rec
  end
  if not st then
    rec.state, rec.detail = "status_failed", "git status failed"
    return rec
  end
  if st.detached then
    rec.state, rec.detail = "detached", "HEAD is detached"
    return rec
  end
  if not st.upstream then
    rec.state = "no_upstream"
    rec.detail = (st.initial and "no commit yet" or "no upstream configured")
      .. (st.branch and (" on " .. st.branch) or "")
    return rec
  end
  if not st.has_ab then
    -- An upstream is configured but git has no ahead/behind for it: the remote branch is gone.
    rec.state, rec.detail = "no_upstream", ("upstream %s no longer exists"):format(st.upstream)
    return rec
  end
  if st.ahead > 0 and st.behind > 0 then
    rec.state, rec.detail = "diverged", ab_detail(st)
    return rec
  end
  if st.behind > 0 then
    -- Pulled (or tried) afterwards even with a dirty tree: git decides whether the local
    -- changes are in the way, we do not.
    rec.state, rec.detail = "behind", ("behind %d"):format(st.behind)
    return rec
  end
  if st.ahead > 0 then
    rec.state, rec.detail = "ahead", ("%d unpushed commit(s)"):format(st.ahead)
    return rec
  end
  if rec.dirty then
    rec.state, rec.detail = "dirty", ("%d changed file(s)"):format(rec.changed)
    if st.conflicted > 0 then
      -- still only a hint (nothing is behind), but the user must know there are conflict markers
      rec.detail = rec.detail .. (", %d in conflict"):format(st.conflicted)
    end
    return rec
  end
  rec.state = "current"
  return rec
end

---The state of a `behind` repo after its pull.
---
--- Success: `pulled`. Failure: a second status decides structurally -- a dirty tree is
--- `dirty_blocked` (git refused because of the local changes), anything else
--- `pull_failed` with the error line as detail.
---@param rec MyPlugins.SyncRecord       The record `classify` returned (state `behind`).
---@param ok boolean                     The pull's result.
---@param err string|nil                 Its error text (shown, never parsed).
---@param after MyPlugins.SyncStatus|nil Status taken after a failed pull.
---@return MyPlugins.SyncRecord
function M.after_pull(rec, ok, err, after)
  local out = vim.deepcopy(rec)
  if ok then
    out.state, out.pulled, out.detail =
      "pulled", rec.behind, ("pulled %d commit(s)"):format(rec.behind)
    out.behind = 0
    return out
  end
  local first = err and vim.trim((err:match("^[^\r\n]*") or "")) or ""
  if after and is_dirty(after) then
    out.state = "dirty_blocked"
    out.dirty = true
    out.changed = after.changed + after.untracked
    out.detail = ("%d changed file(s) in the way%s"):format(
      out.changed,
      first ~= "" and (": " .. first) or ""
    )
  else
    out.state = "pull_failed"
    out.detail = first ~= "" and first or "git pull --ff-only failed"
  end
  return out
end

---A listed repo that cannot be synced because there is nothing (usable) to sync.
---@param name string
---@param path string
---@param state "missing"|"not_git"
---@return MyPlugins.SyncRecord
function M.absent(name, path, state)
  local rec = base_record(name, path, nil)
  rec.state = state
  rec.detail = state == "missing" and "not cloned (:MyPlugins clone)"
    or "the folder is not a git repository"
  return rec
end

---`fresh` records replace the ones of the same name in `old`; the rest of `old` stays. Used by
---a `--only` run, which must not wipe the saved result of the repos it did not look at.
---@param old MyPlugins.SyncRecord[]
---@param fresh MyPlugins.SyncRecord[]
---@return MyPlugins.SyncRecord[]
function M.merge(old, fresh)
  local by_name = {}
  for _, r in ipairs(fresh) do
    by_name[r.name] = r
  end
  local out, seen = {}, {}
  for _, r in ipairs(old) do
    out[#out + 1] = by_name[r.name] or r
    seen[r.name] = true
  end
  for _, r in ipairs(fresh) do
    if not seen[r.name] then
      out[#out + 1] = r
    end
  end
  return out
end

-- ── Assist actions ────────────────────────────────────────────────────────────

---@alias MyPlugins.SyncAssist "rebase"|"merge"|"stash_pull"

---@class MyPlugins.SyncAssistInfo
---@field label string       Menu entry.
---@field commands string[]  The exact commands, in order (shown in the confirmation).
---@field safety string      What happens when it goes wrong.

---What the optional assist actions do. Standard stays lazygit (the user decides); these are
---shortcuts for the two situations that are almost always solved the same way. Never
---`reset --hard`, never `clean`.
---@type table<MyPlugins.SyncAssist, MyPlugins.SyncAssistInfo>
M.ASSISTS = {
  rebase = {
    label = "rebase onto the upstream",
    commands = { "git rebase @{u}" },
    safety = "a conflict aborts the rebase (git rebase --abort); nothing is lost",
  },
  merge = {
    label = "merge the upstream",
    commands = { "git merge --no-edit @{u}" },
    safety = "a conflict aborts the merge (git merge --abort); nothing is lost",
  },
  stash_pull = {
    label = "stash, pull, stash pop",
    commands = { "git stash push --include-untracked", "git pull --ff-only", "git stash pop" },
    safety = "the stash is popped again even when the pull fails; a pop that conflicts leaves the changes in the stash",
  },
}

---The assist actions that make sense for a record, in the order they are offered.
---@param rec MyPlugins.SyncRecord
---@return MyPlugins.SyncAssist[]
function M.assists_for(rec)
  if rec.state == "diverged" then
    return { "rebase", "merge" }
  end
  if rec.state == "dirty_blocked" then
    return { "stash_pull" }
  end
  return {}
end

---The question of the confirmation: names the repo and the exact commands.
---@param rec MyPlugins.SyncRecord
---@param id MyPlugins.SyncAssist
---@return string
function M.assist_prompt(rec, id)
  local info = M.ASSISTS[id]
  return ("%s in %s?\n\n  %s\n\n%s."):format(
    info.label,
    rec.name,
    table.concat(info.commands, "\n  "),
    info.safety:sub(1, 1):upper() .. info.safety:sub(2)
  )
end

-- ── Order, filter, summary ────────────────────────────────────────────────────

---@type table<string, integer>
local RANK = {}
do
  local r = 0
  for _, s in ipairs(M.PROBLEM_STATES) do
    r = r + 1
    RANK[s] = r
  end
  for _, s in ipairs({ "behind", "ahead", "dirty", "missing", "not_git", "pulled", "current" }) do
    r = r + 1
    RANK[s] = r
  end
end

---Dashboard order: open problems, skipped ones, hints, then the rest; by name within a group.
---A new list, the argument is left alone.
---@param records MyPlugins.SyncRecord[]
---@return MyPlugins.SyncRecord[]
function M.sort(records)
  ---@param r MyPlugins.SyncRecord
  ---@return integer
  local function group(r)
    if M.is_problem(r.state) then
      return r.skipped and 2 or 1
    end
    return M.is_hint(r.state) and 3 or 4
  end
  local out = vim.list_slice(records, 1, #records)
  table.sort(out, function(a, b)
    local ga, gb = group(a), group(b)
    if ga ~= gb then
      return ga < gb
    end
    local ra, rb = RANK[a.state] or 99, RANK[b.state] or 99
    if ra ~= rb then
      return ra < rb
    end
    return a.name < b.name
  end)
  return out
end

---The records the triage list shows: open problems and skipped problems, plus the hints
---when `show_hints`. Order as `sort`.
---@param records MyPlugins.SyncRecord[]
---@param show_hints boolean
---@return MyPlugins.SyncRecord[]
function M.visible(records, show_hints)
  local out = {}
  for _, r in ipairs(M.sort(records)) do
    if M.is_problem(r.state) or (show_hints and M.is_hint(r.state)) then
      out[#out + 1] = r
    end
  end
  return out
end

---@class MyPlugins.SyncSummary
---@field total integer
---@field current integer      Up to date without a pull (`current`, plus hints: nothing to fetch in).
---@field pulled integer
---@field pending integer      `behind` (a dry run).
---@field hints integer
---@field unresolved MyPlugins.SyncRecord[]  Problems nobody skipped.
---@field skipped MyPlugins.SyncRecord[]     Problems the user skipped.
---@field all_clear boolean    No unresolved problem (skips allowed) and nothing pending.

---Count a run. A hint counts as up to date: the repo has everything the remote has.
---@param records MyPlugins.SyncRecord[]
---@return MyPlugins.SyncSummary
function M.summarize(records)
  ---@type MyPlugins.SyncSummary
  local s = {
    total = #records,
    current = 0,
    pulled = 0,
    pending = 0,
    hints = 0,
    unresolved = {},
    skipped = {},
    all_clear = true,
  }
  for _, r in ipairs(M.sort(records)) do
    if r.state == "pulled" then
      s.pulled = s.pulled + 1
    elseif r.state == "behind" then
      s.pending = s.pending + 1
    elseif M.is_problem(r.state) then
      if r.skipped then
        s.skipped[#s.skipped + 1] = r
      else
        s.unresolved[#s.unresolved + 1] = r
      end
    else
      s.current = s.current + 1
      if M.is_hint(r.state) then
        s.hints = s.hints + 1
      end
    end
  end
  s.all_clear = #s.unresolved == 0 and s.pending == 0
  return s
end

---@param list MyPlugins.SyncRecord[]
---@return string
local function names(list)
  local out = {}
  for _, r in ipairs(list) do
    out[#out + 1] = r.name
  end
  return table.concat(out, ", ")
end

---The one closing line, e.g.
---`Sync: 41 up to date (7 pulled), 2 skipped: cmdlog.nvim, ai.nvim, 0 unresolved`.
---With nothing unresolved it says so in words (the assurance the run exists for).
---@param records MyPlugins.SyncRecord[]
---@param dry_run? boolean
---@return string text
---@return "info"|"warn" level
function M.summary_line(records, dry_run)
  local s = M.summarize(records)
  local parts = {}
  parts[#parts + 1] = ("%d up to date"):format(s.current + s.pulled)
  if s.pulled > 0 then
    parts[#parts] = parts[#parts] .. (" (%d pulled)"):format(s.pulled)
  end
  if dry_run and s.pending > 0 then
    parts[#parts + 1] = ("%d would be pulled"):format(s.pending)
  end
  if #s.skipped > 0 then
    parts[#parts + 1] = ("%d skipped: %s"):format(#s.skipped, names(s.skipped))
  end
  parts[#parts + 1] = ("%d unresolved%s"):format(
    #s.unresolved,
    #s.unresolved > 0 and (": " .. names(s.unresolved)) or ""
  )
  local text = (dry_run and "Sync (dry run): " or "Sync: ") .. table.concat(parts, ", ")
  if s.all_clear and not dry_run then
    text = text
      .. (
        #s.skipped > 0 and " -- all repositories are up to date except the skipped ones"
        or " -- all repositories are up to date"
      )
  end
  return text, (#s.unresolved > 0) and "warn" or "info"
end

---Right-pad `s` with blanks to `width` display cells (never cuts).
---@param s string
---@param width integer
---@return string
local function pad(s, width)
  local missing = width - vim.fn.strdisplaywidth(s)
  return missing > 0 and (s .. string.rep(" ", missing)) or s
end

---One dashboard row (plain text; the picker adds highlights).
---@param r MyPlugins.SyncRecord
---@param widths? { state: integer, name: integer, branch: integer }
---@return string
function M.format_line(r, widths)
  widths = widths or { state = 13, name = 20, branch = 12 }
  local mark = "-"
  if r.skipped then
    mark = ">>"
  elseif M.is_problem(r.state) then
    mark = "x"
  elseif r.state == "pulled" or r.state == "current" then
    mark = "+"
  end
  local ab = ""
  if r.ahead > 0 or r.behind > 0 then
    ab = (" +%d -%d"):format(r.ahead, r.behind)
  end
  return table.concat({
    pad(mark, 2),
    " ",
    pad(r.skipped and "skipped" or r.state, widths.state),
    " ",
    pad(r.name, widths.name),
    " ",
    pad(r.branch or "", widths.branch),
    ab,
    "  ",
    r.detail or "",
  })
end

return M
