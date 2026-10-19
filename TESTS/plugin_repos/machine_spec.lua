-- TESTS/plugin_repos/machine_spec.lua -- :MyPlugins machine: the argv that runs scripts/sync-machine.ps1.
--
-- The command is read-only unless --pull is given, so the one thing that must hold is that
-- -Pull appears in the argv exactly when asked for, and that the script it points at exists.

return function(H)
  local eq, ok = H.eq, H.ok
  local machine = require("bindings.usrcmds.plugin_repos.machine")

  local base = machine.build_cmd({ shell = "pwsh", script = "S.ps1" })
  eq(base, { "pwsh", "-NoProfile", "-File", "S.ps1" }, "report-only argv has no -Pull")

  local pull = machine.build_cmd({ shell = "pwsh", script = "S.ps1", pull = true })
  eq(pull[#pull], "-Pull", "--pull adds -Pull")

  local only = machine.build_cmd({ shell = "pwsh", script = "S.ps1", only = "a,b" })
  eq({ only[#only - 1], only[#only] }, { "-Only", "a,b" }, "--only passes the list as ONE argument")

  eq(
    #machine.build_cmd({ shell = "pwsh", script = "S.ps1", only = "" }),
    4,
    "empty --only adds nothing"
  )

  ok((vim.uv or vim.loop).fs_stat(machine.script_path()), "the script exists in this config")

  eq(
    machine.build_cmd({ shell = "pwsh", script = "S.ps1", json = true })[5],
    "-Json",
    "json mode adds -Json"
  )

  -- The report: what the script prints is parsed, rendered and mapped back to its repos.
  local function item(over)
    return vim.tbl_extend("force", {
      Repo = "r",
      Path = "P",
      State = "ok",
      Note = "",
      Behind = 0,
      Ahead = 0,
      Dirty = 0,
      Pullable = false,
      Build = "",
      Hint = "",
    }, over or {})
  end
  local behind = item({ Repo = "a.nvim", State = "BEHIND", Behind = 2, Pullable = true })
  local dirty = item({ Repo = "b.nvim", State = "BEHIND", Behind = 1, Dirty = 3 })
  local diverged = item({ Repo = "c.nvim", State = "DIVERGED", Behind = 1, Ahead = 1 })
  local other = item({ Repo = "d.nvim", State = "BEHIND", Behind = 1 })
  local current = item({ Repo = "e.nvim" })
  local json = "noise\n" .. vim.json.encode({ behind, dirty, diverged, other, current })

  local items = assert(machine.parse(json))
  eq(#items, 5, "the array is found behind leading noise")
  local none, err = machine.parse("no json at all")
  eq(none, nil, "no JSON -> nil")
  ok(err, "...with a reason")

  -- Order: pullable, then the dangerous ones (unpushed / diverged), then the rest; current is hidden.
  local lines, by_line, hls = machine.render(items)
  eq(by_line[3].Repo, "a.nvim", "pullable first")
  eq(by_line[4].Repo, "c.nvim", "diverged (unpushed work) before the merely dirty ones")
  eq(by_line[5].Repo, "b.nvim", "then the rest in script order")
  eq(by_line[6].Repo, "d.nvim", "...")
  eq(by_line[7], nil, "a current repo is hidden")
  eq(lines[3]:sub(1, 1), "v", "a pullable repo is marked")
  eq(lines[4]:sub(1, 1), " ", "a diverged repo is not")
  eq(hls[3], "DiagnosticOk", "pullable is green")
  eq(hls[4], "DiagnosticError", "unpushed work is red")
  eq(hls[5], "DiagnosticWarn", "dirty is yellow")
  local _, all_by_line = machine.render(items, true)
  eq(all_by_line[7].Repo, "e.nvim", "a shows the current repo, last")

  eq(machine.rank(behind), 1, "rank pullable")
  eq(machine.rank(diverged), 2, "rank severe")
  eq(machine.rank(dirty), 3, "rank attention")
  eq(machine.rank(current), 4, "rank current")
  eq(machine.rank(item({ Build = "stale" })), 3, "a stale build alone needs attention")
  eq(
    machine.summary(items),
    "1 pullable | 1 unpushed | 1 dirty | 0 build | 1 current",
    "window bar totals"
  )
  ok(#machine.help_lines() > 8, "the cheat sheet has content")

  eq(
    vim.tbl_map(function(i)
      return i.Repo
    end, machine.pullable(items)),
    { "a.nvim" },
    "P pulls only the repo the script marked pullable"
  )
  eq(machine.why_not(behind), nil, "pullable: no reason")
  ok(machine.why_not(dirty):find("uncommitted"), "dirty names the files")
  ok(machine.why_not(diverged):find("unpushed"), "diverged names the unpushed commits")
  ok(machine.why_not(other):find("main"), "off main names the branch")
  eq(machine.why_not(current), "nothing to pull", "current: nothing to pull")

  local routes = machine.routes()
  eq(routes[1].path, { "machine" }, "route path")
end
