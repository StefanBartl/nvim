-- TESTS/sync/sync_dash_spec.lua -- the triage dashboard of `:MyPlugins sync`, end to end.
--
-- Real throwaway git repositories, the plain `vim.ui.select` backend (so the whole flow is
-- driven without a UI), `go_into` stubbed to do "what the user does in lazygit". Covers the
-- acceptance of the plan: solve a problem in the repo -> its row disappears without a restart;
-- skip -> the closing line names it; restart + `sync issues` -> the list is back.

return function(H)
  local eq, ok, has = H.eq, H.ok, H.has

  if vim.fn.executable("git") ~= 1 then
    return
  end

  local sync = require("bindings.usrcmds.plugin_repos.sync")
  local dash = require("bindings.usrcmds.plugin_repos.sync_dash")
  local classify = require("bindings.usrcmds.plugin_repos.sync_classify")
  local state = require("bindings.usrcmds.plugin_repos.sync_state")

  local fx = dofile(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)) .. "/fixture.lua")(H)
  local base, git, commit_file, make, incoming =
    fx.base, fx.git, fx.commit_file, fx.make, fx.incoming
  local state_path = H.tmpdir() .. "/sync-state.json"

  -- one problem of each kind the list is for
  local blocked = make("blocked") -- a local edit in the way of an incoming change
  H.write(blocked.repo .. "/b.txt", "b1\nlocal edit\n")
  incoming(blocked, "b.txt", "b-from-the-other-machine\n")
  local diverged = make("diverged")
  incoming(diverged, "theirs.txt", "theirs\n")
  commit_file(diverged.repo, "mine.txt", "mine\n", "unpushed")
  local feature = make("feature")
  git(feature.repo, "checkout", "-q", "-b", "wip") -- no upstream
  local fine = make("fine")
  commit_file(fine.repo, "mine.txt", "mine\n", "unpushed") -- ahead: only a hint
  local names = { "blocked", "diverged", "feature", "fine" }

  -- ── capture notifications and drive vim.ui.select ──────────────────────
  local orig_notify, orig_select, orig_go_into, orig_backend =
    vim.notify, vim.ui.select, dash.go_into, dash.backend
  local notes = {}
  vim.notify = function(msg, level)
    notes[#notes + 1] = { msg = msg, level = level or vim.log.levels.INFO }
  end
  dash.backend = "select"

  ---Each step picks the row `name` in the repo list, then the menu entry containing `menu`.
  ---An empty script cancels the list (which ends the sync).
  ---@type { name: string, menu: string }[]
  local script = {}
  local current = nil
  local list_prompts = {}
  vim.ui.select = function(items, opts, on_choice)
    local first = items[1]
    if first and first.name then -- the repo list
      list_prompts[#list_prompts + 1] = opts.prompt
      current = table.remove(script, 1)
      local picked
      for _, r in ipairs(items) do
        if current and r.name == current.name then
          picked = r
        end
      end
      vim.schedule(function()
        on_choice(picked)
      end)
      return
    end
    -- the action menu of one repo
    local chosen
    for _, m in ipairs(items) do
      if current and m.label:find(current.menu, 1, true) then
        chosen = m
      end
    end
    vim.schedule(function()
      on_choice(chosen)
    end)
  end

  local function restore()
    vim.notify, vim.ui.select, dash.go_into, dash.backend =
      orig_notify, orig_select, orig_go_into, orig_backend
  end

  local function last_note()
    return notes[#notes] and notes[#notes].msg or ""
  end

  local passed, err = pcall(function()
    -- whatever an earlier spec left on the loop is not this spec's message
    vim.wait(100, function()
      return false
    end)
    notes = {}
    local finished = false
    sync.run({
      dir = base,
      names = names,
      state_path = state_path,
      on_done = function()
        finished = true
      end,
    })
    -- `on_done` comes when the list is OPEN; the closing line comes when it is closed
    -- (the empty script answers its prompt with a cancel)
    ok(
      vim.wait(60000, function()
        return #notes > 0
      end, 20),
      "the list closed and the closing line was said"
    )
    ok(finished, "the run reported its records")

    -- a plain cancel of the list ends the sync with the one closing line, problems named
    local closing = last_note()
    has(closing, "3 unresolved", "diverged, blocked and the branch without upstream are unresolved")
    has(closing, "blocked", "blocked is named")
    has(closing, "diverged", "diverged is named")
    has(closing, "feature", "feature is named")
    ok(not closing:find("fine", 1, true), "the repo that is only ahead is not a problem")
    has(list_prompts[1], "3 unresolved", "the list was titled with the count")

    -- ── restart: `sync issues` brings the list back from the saved result ──
    notes, list_prompts = {}, {}
    script = {}
    sync.issues({ state_path = state_path })
    ok(
      vim.wait(30000, function()
        return #notes > 0
      end, 20),
      "issues showed the list again"
    )
    has(list_prompts[1] or "", "3 unresolved", "the saved result restored the list")

    -- ── solve a problem in the repo: the row disappears, nothing restarted ─
    notes, list_prompts = {}, {}
    local entered = {}
    dash.go_into = function(path, how, on_close)
      entered[#entered + 1] = { path = path, how = how }
      -- what the user does in lazygit: stash the edit that blocks the pull
      git(blocked.repo, "stash", "-q")
      vim.schedule(on_close)
    end
    local saved = assert(state.load({ path = state_path }))
    local session = {
      dir = saved.dir,
      records = saved.records,
      dry_run = false,
      opts = { state_path = state_path, ui = true },
    }
    script = { { name = "blocked", menu = "go into the repo" } }
    ok(dash.open(session), "the list opens for a session with problems")
    ok(
      vim.wait(60000, function()
        return #notes > 0
      end, 20),
      "the list closed after the second prompt"
    )
    eq(#entered, 1, "go_into was used once")
    eq(entered[1].how, "lazygit", "lazygit is the default way in")
    eq(vim.fs.normalize(entered[1].path), vim.fs.normalize(blocked.repo), "in the right repo")
    local after = {}
    for _, r in ipairs(session.records) do
      after[r.name] = r
    end
    eq(after["blocked"].state, "pulled", "the re-check after the window closed pulled it")
    eq(
      H.read(blocked.repo .. "/b.txt"),
      "b-from-the-other-machine\n",
      "the incoming change is in the working tree"
    )
    local after_line = last_note()
    has(after_line, "2 unresolved", "only diverged and the unpushed branch are left")
    ok(not after_line:find("blocked", 1, true), "blocked is gone from the unresolved list")

    -- ── skip: the closing line names it, and it is not 'unresolved' ────────
    notes, list_prompts = {}, {}
    script = {
      { name = "diverged", menu = "skip" },
      { name = "feature", menu = "skip" },
    }
    ok(dash.open(session), "the list opens again")
    ok(
      vim.wait(60000, function()
        return #notes > 0
      end, 20),
      "the list closed: the empty script cancels the prompt that is left (the skipped rows stay listed)"
    )
    local skipped_line = last_note()
    has(skipped_line, "2 skipped: ", "both skips are named")
    has(skipped_line, "diverged", "diverged is named as skipped")
    has(skipped_line, "feature", "feature is named as skipped")
    has(skipped_line, "0 unresolved", "nothing is unresolved")
    has(
      skipped_line,
      "all repositories are up to date except the skipped ones",
      "the assurance the run exists for"
    )
    local summary = classify.summarize(session.records)
    ok(summary.all_clear, "clear")
    local resaved = assert(state.load({ path = state_path }))
    local skipped_saved = 0
    for _, r in ipairs(resaved.records) do
      if r.skipped then
        skipped_saved = skipped_saved + 1
      end
    end
    eq(skipped_saved, 2, "the skips were saved")

    -- ── a skip never outlives the next full run ───────────────────────────
    notes, list_prompts = {}, {}
    script = {}
    local done_again = false
    sync.run({
      dir = base,
      names = names,
      state_path = state_path,
      on_done = function()
        done_again = true
      end,
    })
    ok(
      vim.wait(60000, function()
        return done_again
      end, 20),
      "the next full run finished"
    )
    local fresh = assert(state.load({ path = state_path }))
    for _, r in ipairs(fresh.records) do
      ok(not r.skipped, r.name .. ": the new run asks about it again")
    end

    -- ── the hints are off by default ────────────────────────────────────────
    local rows = classify.visible(fresh.records, false)
    for _, r in ipairs(rows) do
      ok(classify.is_problem(r.state), r.name .. " is a problem: only problems are listed")
    end
    local hinted = classify.visible(fresh.records, true)
    ok(#hinted > #rows, "with the hints on, the repo that is only ahead appears")

    -- ── the preview names what blocks a pull ─────────────────────────────
    git(blocked.repo, "checkout", "-q", "--", ".")
    H.write(blocked.repo .. "/b.txt", "again a local edit\n")
    incoming(blocked, "b.txt", "and again from elsewhere\n")
    local rec = classify.after_pull(
      classify.classify(
        "blocked",
        blocked.repo,
        classify.parse_status(table.concat({
          "# branch.oid x",
          "# branch.head main",
          "# branch.upstream origin/main",
          "# branch.ab +0 -1",
        }, "\0") .. "\0"),
        nil
      ),
      false,
      "error: local changes would be overwritten",
      classify.parse_status("1 .M N... 100644 100644 100644 a b b.txt\0"),
      { "b.txt" }
    )
    -- fetch what the other machine pushed so `@{u}` knows it
    git(blocked.repo, "fetch", "-q")
    local loaded = false
    dash.load_preview(rec, function()
      loaded = true
    end)
    ok(
      vim.wait(30000, function()
        return loaded
      end, 20),
      "the preview loaded"
    )
    local text = table.concat(rec.preview or {}, "\n")
    has(text, "Coming in", "preview: incoming commits")
    has(text, "incoming b.txt", "preview: the incoming commit")
    -- the BODY of the section, not just its header: b.txt is also in the commit line and in
    -- `git status -sb`, and the header is printed for any dirty_blocked record
    local blocking = "## Blocking the pull (changed here AND by the incoming commits)\nb.txt"
    ok(vim.endswith(text, blocking), "preview: the section names the file that blocks: " .. text)
    H.lacks(text, "could not be determined", "preview: the blocker was determined")

    ---@param name string
    ---@return string text
    local function preview_of_blocked(name)
      local r = {
        name = name,
        path = base .. "/" .. name,
        state = "dirty_blocked",
        branch = "main",
        upstream = "origin/main",
        skipped = false,
      }
      local done = false
      dash.load_preview(r, function()
        done = true
      end)
      ok(
        vim.wait(30000, function()
          return done
        end, 20),
        name .. ": the preview loaded"
      )
      return table.concat(r.preview or {}, "\n")
    end

    -- negative: the local edit and the incoming change touch different files
    local apart = make("apart")
    H.write(apart.repo .. "/a.txt", "a local edit\n")
    incoming(apart, "b.txt", "b from elsewhere\n")
    git(apart.repo, "fetch", "-q")
    local apart_text = preview_of_blocked("apart")
    has(apart_text, "## Blocking the pull", "negative: the section is there")
    has(apart_text, "(no overlap", "negative: it says there is no overlap")
    H.lacks(apart_text, "could not be determined", "negative: both calls succeeded")
    ok(not vim.endswith(apart_text, "\na.txt"), "negative: the local file is no blocker")
    ok(not vim.endswith(apart_text, "\nb.txt"), "negative: the incoming file is none either")

    -- an untracked DIRECTORY blocks: status collapses it to `d/`, the incoming file is `d/f`
    local untracked = make("untracked")
    vim.fn.mkdir(untracked.dev .. "/d", "p")
    incoming(untracked, "d/f", "theirs\n")
    H.write(untracked.repo .. "/d/f", "mine, untracked\n")
    git(untracked.repo, "fetch", "-q")
    local untracked_text = preview_of_blocked("untracked")
    ok(
      vim.endswith(
        untracked_text,
        "## Blocking the pull (changed here AND by the incoming commits)\nd/"
      ),
      "untracked dir: the directory is named as the blocker: " .. untracked_text
    )
    H.lacks(untracked_text, "could not be determined", "untracked dir: determined")
  end)

  restore()
  if not passed then
    error(err, 0)
  end
end
