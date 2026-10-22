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
  -- `b`: the script's Command goes to the clipboard with a folder change in front. The Hint is
  -- prose for a person ("run its setup.exe") and is never copied as a command.
  local function commanded(over)
    return vim.tbl_extend(
      "force",
      { Repo = "r", Path = [[E:\repos\mdview.nvim]], Hint = "", Command = "" },
      over
    )
  end
  eq(
    machine.build_command(commanded({ Command = "node scripts/build-go.mjs" })),
    [[Set-Location -LiteralPath 'E:\repos\mdview.nvim'; node scripts/build-go.mjs]],
    "cd first, then the Command"
  )
  eq(
    machine.build_command(commanded({ Command = "make (all)" })),
    [[Set-Location -LiteralPath 'E:\repos\mdview.nvim'; make (all)]],
    "the Command is taken as it is"
  )
  eq(
    machine.build_command(commanded({ Path = [[E:\it's\repo]], Command = "cmake --build build" })),
    [[Set-Location -LiteralPath 'E:\it''s\repo'; cmake --build build]],
    "a quote in the path is doubled for PowerShell"
  )
  eq(
    machine.build_command(commanded({ Hint = "run its setup.exe" })),
    nil,
    "prose in the Hint, no Command -> nil"
  )
  eq(
    machine.build_command(commanded({ Hint = "cargo build", Command = vim.NIL })),
    nil,
    "a null Command is no command, even when the Hint looks like one"
  )
  eq(machine.build_command(nil), nil, "no item -> nil")
  eq(
    machine.build_command(commanded({ Path = "", Command = "cargo build" })),
    "cargo build",
    "no path: the command alone"
  )

  -- B: the build in a float terminal (terminal.nvim), in the repo's folder. The items are the
  -- script's own (scripts/sync-machine.ps1, $natives): a Command next to the Hint, empty for the
  -- desktop apps.
  local mdview = item({
    Repo = "mdview.nvim",
    Hint = "sh scripts/rebuild-changed.sh HEAD~1 HEAD   (or: node scripts/build-go.mjs; npm run build)",
    Command = "node scripts/build-go.mjs",
  })
  local desktop = item({ Repo = "tasks-desktop", Hint = "run its setup.exe", Command = "" })
  local function wrapped(cmd)
    return ("$ErrorActionPreference = 'Stop'; %s; exit $LASTEXITCODE"):format(cmd)
  end
  eq(
    machine.build_argv(mdview, "pwsh"),
    { "pwsh", "-NoProfile", "-Command", wrapped("node scripts/build-go.mjs") },
    "the Command, as one PowerShell command passing the tool's exit code on"
  )
  local no_argv, why = machine.build_argv(desktop, "pwsh")
  eq(no_argv, nil, "a desktop app (setup.exe) has no command to run")
  eq(why, "tasks-desktop: no build command - run its setup.exe", "...and says what to do instead")
  eq(machine.build_command(desktop), nil, "b copies nothing for it either")
  eq(
    (machine.build_argv(item({ Hint = "make (all)" }), "pwsh")),
    nil,
    "no Command field at all: nothing to run, whatever the Hint says"
  )

  local repo = H.tmpdir()
  local runs, done = {}, {}
  local fake_terminal = {
    run = function(argv, opts)
      runs[#runs + 1] = { argv = argv, opts = opts }
      return true, nil, { bufnr = 1 }
    end,
  }
  ok(
    machine.build_in_terminal(vim.tbl_extend("force", mdview, { Path = repo }), {
      terminal = fake_terminal,
      shell = "pwsh",
      on_done = function(code, winid)
        done[#done + 1] = { code, winid }
      end,
    }),
    "a build with a folder and a command starts"
  )
  local o = runs[1].opts
  eq(o.direct, true, "the build is the terminal's job, no shell typed into")
  eq(o.cwd, repo, "in the repo's folder")
  eq(o.layout, "float")
  eq(o.close, "never", "the output stays readable after the build")
  eq(o.session, false, "a saved session does not start it again")
  eq(o.name, "build:mdview.nvim", "a named terminal, listed by :Terminal list")
  eq(runs[1].argv[4], wrapped("node scripts/build-go.mjs"))
  eq(
    machine.build_in_terminal(
      vim.tbl_extend("force", mdview, { Path = repo }),
      { terminal = fake_terminal }
    ),
    false,
    "a second B on the same folder while the first build runs starts nothing"
  )

  -- q closes the float in normal mode: on_open maps it on the terminal buffer.
  local term_buf = vim.api.nvim_create_buf(false, true)
  o.on_open({ bufnr = term_buf })
  eq(
    vim.api.nvim_buf_call(term_buf, function()
      return vim.fn.maparg("q", "n", false, true).buffer
    end),
    1,
    "q is mapped buffer-locally"
  )
  o.on_exit(0)
  eq(done, { { 0, nil } }, "the exit code reaches on_done (no window shows the buffer)")
  vim.api.nvim_buf_delete(term_buf, { force = true })

  eq(
    machine.build_in_terminal(
      vim.tbl_extend("force", mdview, { Path = repo .. "/gone" }),
      { terminal = fake_terminal }
    ),
    false,
    "a folder that is not there starts nothing"
  )
  eq(
    machine.build_in_terminal(
      vim.tbl_extend("force", desktop, { Path = repo }),
      { terminal = fake_terminal }
    ),
    false
  )
  eq(machine.build_in_terminal(nil, { terminal = fake_terminal }), false, "a line without a repo")
  eq(#runs, 1, "terminal.run was asked for none of these, nor for the guarded second B")
  eq(
    machine.build_in_terminal(vim.tbl_extend("force", mdview, { Path = repo }), {
      terminal = {
        run = function()
          return false, "E36"
        end,
      },
    }),
    false,
    "a terminal that could not start is reported as not started"
  )
  ok(
    machine.build_in_terminal(
      vim.tbl_extend("force", mdview, { Path = repo }),
      { terminal = fake_terminal }
    ),
    "and that failure did not leave the folder marked as building"
  )
  -- end that build, so no folder stays locked for the cases below
  runs[#runs].opts.on_exit(1)

  -- The default on_done: a successful build re-checks only once the float is closed.
  local reran = 0
  local real_run = machine.run
  machine.run = function()
    reran = reran + 1
  end
  local float_buf = vim.api.nvim_create_buf(false, true)
  local float = vim.api.nvim_open_win(
    float_buf,
    false,
    { relative = "editor", row = 1, col = 1, width = 10, height = 3 }
  )
  local captured
  machine.build_in_terminal(vim.tbl_extend("force", mdview, { Path = H.tmpdir() }), {
    terminal = {
      run = function(_, opts)
        captured = opts
        return true, nil, { bufnr = float_buf }
      end,
    },
  })
  captured.on_open({ bufnr = float_buf })
  captured.on_exit(0)
  eq(reran, 0, "not while the float is still open")
  vim.api.nvim_win_close(float, true)
  vim.wait(200, function()
    return reran > 0
  end)
  eq(reran, 1, "once it is closed")

  -- A second B on the folder while the finished build's float is open: terminal.nvim replaces
  -- the terminal of that name and closes the old float -- that close must not re-check.
  reran = 0
  local again = H.tmpdir()
  local float2_buf = vim.api.nvim_create_buf(false, true)
  local float2 = vim.api.nvim_open_win(
    float2_buf,
    false,
    { relative = "editor", row = 1, col = 1, width = 10, height = 3 }
  )
  local first
  machine.build_in_terminal(vim.tbl_extend("force", mdview, { Path = again }), {
    terminal = {
      run = function(_, opts)
        first = opts
        return true, nil, { bufnr = float2_buf, backend = "native" }
      end,
    },
  })
  first.on_open({ bufnr = float2_buf })
  first.on_exit(0)
  local second
  machine.build_in_terminal(vim.tbl_extend("force", mdview, { Path = again }), {
    terminal = {
      run = function(_, run_opts)
        -- what terminal.nvim does for a name it already has: close the old one first
        vim.api.nvim_win_close(float2, true)
        second = run_opts
        return true, nil, { bufnr = 999, backend = "native" }
      end,
    },
  })
  vim.wait(200, function()
    return reran > 0
  end)
  eq(reran, 0, "the replaced float of the first build did not re-check under the second")
  second.on_exit(1) -- end it: no folder stays locked for the cases below
  machine.run = real_run

  -- A multiplexer pane never reports its end: no lock left that nothing would release.
  local pane_dir = H.tmpdir()
  local pane_terminal = {
    run = function()
      return true, nil, { backend = "tmux" }
    end,
  }
  ok(
    machine.build_in_terminal(
      vim.tbl_extend("force", mdview, { Path = pane_dir }),
      { terminal = pane_terminal }
    )
  )
  ok(
    machine.build_in_terminal(
      vim.tbl_extend("force", mdview, { Path = pane_dir }),
      { terminal = pane_terminal }
    ),
    "a second B is possible: the pane's end is unknown, so the folder is not kept locked"
  )

  -- why_not promises b / B only where there is a command.
  H.lacks(
    machine.why_not(item({ Build = "stale", Hint = "run its setup.exe", Command = "" })),
    "B runs it",
    "no promise for a desktop app"
  )
  H.has(machine.why_not(vim.tbl_extend("force", mdview, { Build = "stale" })), "B runs it")
  H.has(
    machine.why_not(vim.tbl_extend("force", mdview, { Build = "stale" })),
    "node scripts/build-go.mjs",
    "it names the command B runs"
  )
  H.lacks(
    machine.why_not(vim.tbl_extend("force", mdview, { Build = "stale" })),
    "rebuild-changed",
    "and not the prose hint"
  )

  -- ── the focus, once more: when the check may run ─────────────────────────
  local checks = 0
  local saved_run = machine.run
  machine.run = function()
    checks = checks + 1
  end
  local function float_for()
    local b = vim.api.nvim_create_buf(false, true)
    local w = vim.api.nvim_open_win(
      b,
      false,
      { relative = "editor", row = 1, col = 1, width = 10, height = 3 }
    )
    return b, w
  end
  local function start(path, bufnr)
    local opts_of
    machine.build_in_terminal(vim.tbl_extend("force", mdview, { Path = path }), {
      terminal = {
        run = function(_, run_opts)
          opts_of = run_opts
          return true, nil, { bufnr = bufnr, backend = "native" }
        end,
      },
    })
    opts_of.on_open({ bufnr = bufnr })
    return opts_of
  end

  -- the float closed before the build ended: no check that would take the focus anywhere
  local gone_buf, gone_win = float_for()
  local early = start(H.tmpdir(), gone_buf)
  vim.api.nvim_win_close(gone_win, true)
  early.on_exit(0)
  vim.wait(100)
  eq(checks, 0, "no automatic check once the float is gone (R re-checks)")

  -- two builds: Q finishes and its float closes while P still runs -> no check yet
  local p_buf, p_win = float_for()
  local q_buf, q_win = float_for()
  local p = start(H.tmpdir(), p_buf)
  local q = start(H.tmpdir(), q_buf)
  q.on_exit(0)
  vim.api.nvim_win_close(q_win, true)
  vim.wait(100)
  eq(checks, 0, "not while P still runs under its float")
  p.on_exit(0)
  vim.api.nvim_win_close(p_win, true)
  vim.wait(200, function()
    return checks > 0
  end)
  eq(checks, 1, "once the last float is closed, one check")

  -- the float, not a split that shows the same buffer, is the window whose closing counts
  checks = 0
  local s_buf = vim.api.nvim_create_buf(false, true)
  vim.cmd("split")
  local split_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(split_win, s_buf)
  vim.cmd("wincmd p")
  local f_win = vim.api.nvim_open_win(
    s_buf,
    true,
    { relative = "editor", row = 1, col = 1, width = 10, height = 3 }
  )
  local s = start(H.tmpdir(), s_buf) -- on_open runs with the float current
  vim.cmd("wincmd p")
  s.on_exit(0)
  vim.api.nvim_win_close(f_win, true)
  vim.wait(200, function()
    return checks > 0
  end)
  eq(checks, 1, "closing the float re-checks, though a split shows the buffer too")
  pcall(vim.api.nvim_win_close, split_win, true)
  machine.run = saved_run

  -- a terminal.nvim that throws does not leave the folder locked
  local thrown = H.tmpdir()
  eq(
    machine.build_in_terminal(vim.tbl_extend("force", mdview, { Path = thrown }), {
      terminal = {
        run = function()
          error("lazy load failed")
        end,
      },
    }),
    false
  )
  ok(
    machine.build_in_terminal(
      vim.tbl_extend("force", mdview, { Path = thrown }),
      { terminal = fake_terminal }
    ),
    "the next B on that folder starts"
  )
  runs[#runs].opts.on_exit(1)

  H.has(table.concat(machine.help_lines(), "\n"), " B ", "the cheat sheet names B")
end
