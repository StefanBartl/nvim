-- TESTS/sync/sync_status_spec.lua -- the statusline hint `sync:N` of `:MyPlugins sync`:
-- what it counts, that render() only reads a number, and that a saved result updates it.

return function(H)
  local eq, ok, has = H.eq, H.ok, H.has

  local status = require("bindings.usrcmds.plugin_repos.sync_status")
  local state = require("bindings.usrcmds.plugin_repos.sync_state")
  local path = H.tmpdir() .. "/status-state.json"

  ---@return MyPlugins.SyncRecord
  local function rec(name, st, skipped)
    return {
      name = name,
      path = "/r/" .. name,
      state = st,
      ahead = 0,
      behind = 0,
      dirty = false,
      changed = 0,
      skipped = skipped == true,
    }
  end

  status.reset()
  status.state_path = path -- the delayed first read must never see the real state file
  eq(status.count(), 0, "nothing read yet counts as zero")

  -- the first render only schedules the read: no file is touched inside a redraw
  eq(status.render(), "", "the first render is empty")
  eq(status.render(), "", "...and stays cheap")

  -- what is counted
  eq(
    status.unresolved({
      rec("a", "diverged"),
      rec("b", "dirty_blocked"),
      rec("c", "no_upstream", true), -- skipped: the user decided
      rec("d", "ahead"), -- a hint
      rec("e", "current"),
      rec("f", "pulled"),
    }),
    2,
    "unresolved problems only: skipped ones, hints and healthy repos do not count"
  )

  -- a saved result with two unresolved repos
  assert(state.save("/r", { rec("a", "diverged"), rec("b", "fetch_failed"), rec("c", "current") }, {
    path = path,
  }))
  status.refresh(path)
  eq(status.count(), 2, "refresh reads the saved result")
  local text = status.render()
  has(text, "sync:2", "the segment shows the count")
  has(text, "DiagnosticWarn", "in a highlight group that always exists")
  ok(text:sub(1, 1) == " " and text:sub(-1) == " ", "padded like the other segments")
  ok(not text:find("%%[^#]"), "no stray format item")

  -- a skip lowers it
  assert(state.save("/r", {
    rec("a", "diverged", true),
    rec("b", "fetch_failed"),
    rec("c", "current"),
  }, { path = path }))
  status.refresh(path)
  eq(status.count(), 1, "skipping one lowers the count")

  -- all clear: the segment disappears
  assert(state.save("/r", { rec("a", "current"), rec("b", "pulled") }, { path = path }))
  status.refresh(path)
  eq(status.count(), 0, "nothing unresolved")
  eq(status.render(), "", "the segment is empty")

  -- no saved result at all is no problem either
  status.refresh(H.tmpdir() .. "/never-written.json")
  eq(status.count(), 0, "no result yet: zero")
  eq(status.render(), "", "...and empty")

  -- a damaged file never raises into the statusline
  H.write(path, "{ not json")
  status.refresh(path)
  eq(status.count(), 0, "a damaged result counts as none")

  status.reset()
  status.state_path = nil
end
