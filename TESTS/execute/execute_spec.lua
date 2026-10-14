-- TESTS/execute/execute_spec.lua -- `:Execute`: the text finders (inline code span, fenced block, selection),
-- the kind detection and the plan (Ex / Lua / shell, markers, comments, continuation lines, the risky flag),
-- running a plan (Ex, Lua, shell), and the flow of one invocation (command line first, bang, confirmation).

---@diagnostic disable: duplicate-set-field

return function(H)
  local ok, eq, has = H.ok, H.eq, H.has

  local source = require("bindings.usrcmds.execute.source")
  local kind = require("bindings.usrcmds.execute.kind")
  local sink = require("bindings.usrcmds.execute.sink")

  -- ── source: inline code span ────────────────────────────────────────────────
  local line = "run `:set wrap` now, or `!git status` instead"
  eq(source.backtick_at(line, 8), ":set wrap", "the cursor inside the first span")
  eq(source.backtick_at(line, 4), ":set wrap", "on the opening backtick")
  eq(source.backtick_at(line, 14), ":set wrap", "on the closing backtick")
  eq(source.backtick_at(line, 33), "!git status", "inside the second span")
  eq(source.backtick_at(line, 0), nil, "outside every span")
  eq(source.backtick_at(line, 20), nil, "between two spans")
  eq(source.backtick_at("a ``x`y`` b", 5), "x`y", "a double-backtick span holds a single backtick")
  eq(source.backtick_at("one ` alone", 6), nil, "a backtick without a partner is plain text")
  eq(source.backtick_at("`  `", 1), nil, "an empty span is nothing")
  eq(source.backtick_at("`  spaced  `", 3), "spaced", "the inner text is trimmed")

  -- ── source: fenced block ────────────────────────────────────────────────────
  local doc = {
    "text", -- 1
    "```bash", -- 2
    "git status", -- 3
    "git log", -- 4
    "```", -- 5
    "more text", -- 6
    "~~~Lua", -- 7
    "print(1)", -- 8
    "~~~", -- 9
    "````", -- 10
    "```", -- 11 (shorter: does not close)
    "inner", -- 12
    "````", -- 13
    "tail", -- 14
  }
  local body, lang = source.fence_at(doc, 3)
  eq(body, { "git status", "git log" }, "the body between the fences")
  eq(lang, "bash")
  eq(
    select(1, source.fence_at(doc, 2)),
    { "git status", "git log" },
    "the opening fence line counts as inside"
  )
  eq(select(1, source.fence_at(doc, 5)), { "git status", "git log" }, "and the closing one")
  eq(source.fence_at(doc, 1), nil, "text before a block")
  eq(source.fence_at(doc, 6), nil, "text between two blocks")
  local tbody, tlang = source.fence_at(doc, 8)
  eq(tbody, { "print(1)" })
  eq(tlang, "lua", "the language is lower-cased; a tilde fence works")
  eq(
    source.fence_at(doc, 12),
    { "```", "inner" },
    "a shorter fence inside a longer one does not close it"
  )
  eq(source.fence_at(doc, 14), nil, "text after the last block")
  local open_body = source.fence_at({ "x", "```", "a", "b" }, 4)
  eq(open_body, { "a", "b" }, "an unclosed fence runs to the end of the buffer")
  eq(
    source.fence_at({ "``` a`b", "x", "```" }, 2),
    nil,
    "a backtick in the info string makes it no fence"
  )

  -- ── source: reading the buffer ──────────────────────────────────────────────
  local function scratch(lines)
    vim.cmd("enew!")
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    return buf
  end
  local buf = scratch({ "alpha `one two` omega", "```sh", "echo hi", "```", "plain line" })

  vim.api.nvim_win_set_cursor(0, { 1, 9 })
  local src = assert(source.get({}))
  eq({ src.from, src.text }, { "backtick", "one two" }, "auto: the span under the cursor")

  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  src = assert(source.get({}))
  eq({ src.from, src.text, src.lang }, { "fence", "echo hi", "sh" }, "auto: then the fenced block")

  vim.api.nvim_win_set_cursor(0, { 5, 0 })
  src = assert(source.get({}))
  eq({ src.from, src.text }, { "line", "plain line" }, "auto: then the line")

  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  src = assert(source.get({ from = "line" }))
  eq(src.text, "alpha `one two` omega", "line: the line, whatever it holds")
  local none, err = source.get({ from = "fence" })
  ok(none == nil and (err or ""):find("fenced", 1, true), "fence outside a block says so")
  none, err = source.get({ from = "backtick" })
  ok(none == nil and (err or ""):find("inline code", 1, true), "backtick outside a span says so")
  none, err = source.get({ from = "selection" })
  ok(none == nil and (err or ""):find("no selection", 1, true), "selection without a range says so")

  -- a charwise selection is cut at its columns, a linewise one gives whole lines
  vim.fn.setpos("'<", { buf, 1, 8, 0 })
  vim.fn.setpos("'>", { buf, 1, 10, 0 })
  src = assert(source.get({ range = { range = 1, line1 = 1, line2 = 1, mode = "v" } }))
  eq(
    { src.from, src.text },
    { "selection", "one" },
    "charwise: the columns count, the last one included"
  )
  src = assert(source.get({ range = { range = 1, line1 = 1, line2 = 2, mode = "V" } }))
  eq(src.lines, { "alpha `one two` omega", "```sh" }, "linewise: whole lines")
  src = assert(source.get({ range = { range = 2, line1 = 3, line2 = 3, mode = "v" } }))
  eq(src.text, "echo hi", "stale marks on other lines are not used: the whole line")

  -- the clipboard
  local getreg = vim.fn.getreg
  vim.fn.getreg = function(reg)
    if reg == "+" then
      return "one\r\ntwo\r\n"
    end
    return ""
  end
  src = assert(source.get({ from = "clipboard" }))
  eq(
    { src.from, src.lines },
    { "clipboard", { "one", "two" } },
    "CRLF and the final newline are removed"
  )
  vim.fn.getreg = function()
    return ""
  end
  none, err = source.get({ from = "clipboard" })
  ok(none == nil and (err or ""):find("empty", 1, true), "an empty clipboard says so")
  vim.fn.getreg = getreg

  -- ── kind: detection and plan ────────────────────────────────────────────────
  eq(kind.detect({ "set wrap" }), "ex", "plain text is Ex")
  eq(kind.detect({ "!git status" }), "shell", "! is shell")
  eq(kind.detect({ "$ git status" }), "shell", "a $ prompt is shell")
  eq(kind.detect({ "", "  :set wrap" }), "ex", "the first line with text decides")
  eq(kind.detect({ "x" }, "bash"), "shell", "a bash fence")
  eq(kind.detect({ "x" }, "powershell"), "shell", "a powershell fence")
  eq(kind.detect({ "x" }, "lua"), "lua", "a lua fence")
  eq(kind.detect({ "!x" }, "vim"), "ex", "the fence language wins over the first character")

  local plan = assert(kind.build({ ":set wrap" }))
  eq(
    { plan.kind, plan.commands, plan.risky },
    { "ex", { "set wrap" }, false },
    "a leading : is a marker"
  )
  eq(plan.display, ":set wrap")

  plan = assert(kind.build({ "set wrap", "", '" a comment', "set list", "  \\ nu" }))
  eq(
    plan.commands,
    { "set wrap", "set listnu" },
    "blank lines and comments go, \\ continues the line before"
  )

  plan = assert(kind.build({ "!git status" }))
  eq(
    { plan.kind, plan.commands, plan.risky },
    { "shell", { "git status" }, true },
    "shell is always risky"
  )
  eq(plan.display, "!git status")

  plan = assert(kind.build({ "$ git log \\", "  --oneline", "# a comment", "", "$ ls" }, "shell"))
  eq(plan.commands, { "git log --oneline", "ls" }, "a trailing backslash continues, # comments go")
  plan = assert(kind.build({ "dir C:\\" }, "shell"))
  eq(plan.commands, { "dir C:\\" }, "a path ending in a backslash is no continuation")

  plan = assert(kind.build({ ":lua print(1)" }, "lua"))
  eq(plan.commands, { "print(1)" }, "a single-line chunk loses its lua prefix")
  eq(plan.risky, false)
  plan = assert(kind.build({ "local a = 1", "return a" }, "lua"))
  eq(plan.commands, { "local a = 1\nreturn a" }, "a Lua chunk stays one piece")
  eq(
    assert(kind.build({ "os.execute('x')" }, "lua")).risky,
    true,
    "a shell entry point in Lua is risky"
  )
  eq(assert(kind.build({ "vim.fn.system('x')" }, "lua")).risky, true)

  local nothing, nerr = kind.build({ "", '" only a comment' })
  ok(nothing == nil and (nerr or ""):find("nothing to run", 1, true), "only comments is nothing")
  nothing = kind.build({ "  " }, "lua")
  eq(nothing, nil, "an empty chunk is nothing")

  for _, cmd in ipairs({
    "!ls",
    "r !ls",
    "read !ls",
    "%!sort",
    "'<,'>!sort",
    "1,5!sort",
    "te",
    "terminal",
    "ter bash",
  }) do
    ok(kind.ex_is_risky(cmd), cmd .. " reaches the shell")
  end
  for _, cmd in ipairs({ "set wrap", "read file.txt", "echo '!'", "tabnew", "t.", "normal ihello" }) do
    ok(not kind.ex_is_risky(cmd), cmd .. " stays in the editor")
  end
  eq(assert(kind.build({ "set wrap", "r !ls" })).risky, true, "one risky line makes the plan risky")

  eq(kind.cmdline_text(assert(kind.build({ "set wrap" }))), "set wrap", "Ex goes as it is")
  eq(kind.cmdline_text(assert(kind.build({ "$ git status" }))), "!git status", "shell gets its !")
  eq(
    kind.cmdline_text(assert(kind.build({ "print(1)" }, "lua"))),
    "lua print(1)",
    "Lua gets its lua"
  )
  local text, terr = kind.cmdline_text(assert(kind.build({ "set wrap", "set list" })))
  ok(
    text == nil and (terr or ""):find("2 commands", 1, true),
    "several commands do not fit the command line"
  )
  text, terr = kind.cmdline_text(assert(kind.build({ "local a = 1", "return a" }, "lua")))
  ok(
    text == nil and (terr or ""):find("several lines", 1, true),
    "a multi-line chunk does not fit it either"
  )

  -- ── sink: running ───────────────────────────────────────────────────────────
  local function run(p)
    local got
    sink.run(p, function(res)
      got = res
    end)
    vim.wait(10000, function()
      return got ~= nil
    end, 10)
    return assert(got, "the run never finished")
  end

  local res = run(assert(kind.build({ 'echo "hello"' })))
  eq(res, { ok = true, lines = { "hello" } }, "an Ex command's output")
  res = run(assert(kind.build({ "set shiftwidth=3", "echo &shiftwidth" })))
  eq(res.lines, { "3" }, "commands run in order")
  res = run(assert(kind.build({ "echo 'a'", "nosuchcommand", "echo 'b'" })))
  ok(not res.ok and res.lines[#res.lines]:find("E492", 1, true), "the first error stops the run")
  ok(not vim.tbl_contains(res.lines, "b"), "and nothing runs after it")

  res = run(assert(kind.build({ "1 + 2" }, "lua")))
  eq(res, { ok = true, lines = { "3" } }, "Lua: an expression shows its value")
  res = run(assert(kind.build({ "local a = 'x'", "print(a .. 'y')" }, "lua")))
  eq(res, { ok = true, lines = { "xy" } }, "Lua: statements, print is captured")
  res = run(assert(kind.build({ "{ a = 1 }" }, "lua")))
  eq(res.lines, { "{", "  a = 1", "}" }, "Lua: a table is inspected")
  res = run(assert(kind.build({ "error('boom')" }, "lua")))
  ok(not res.ok and res.lines[1]:find("boom", 1, true), "Lua: an error is reported, not thrown")
  res = run(assert(kind.build({ "this is not lua" }, "lua")))
  ok(not res.ok, "Lua: a syntax error is reported")
  run(assert(kind.build({ "execute_spec_global = 7" }, "lua")))
  eq(rawget(_G, "execute_spec_global"), 7, "Lua: a global assignment reaches _G")
  _G.execute_spec_global = nil

  -- the shell the run uses is 'shell': a headless -u NONE run inside Git Bash keeps cmd.exe's flags with
  -- bash as 'shell'. Pin cmd.exe's own set on Windows so the spec says the same on every machine.
  local saved_shell = { vim.o.shell, vim.o.shellcmdflag, vim.o.shellquote, vim.o.shellxquote }
  if vim.fn.has("win32") == 1 then
    vim.o.shell, vim.o.shellcmdflag, vim.o.shellquote, vim.o.shellxquote =
      "cmd.exe", "/s /c", "", '"'
  end
  res = run(assert(kind.build({ "echo shell-ok" }, "shell")))
  eq(res, { ok = true, lines = { "shell-ok" } }, "shell: the output of a command")
  res = run(assert(kind.build({ "echo first", "echo second" }, "shell")))
  eq(
    res.lines,
    { "$ echo first", "first", "$ echo second", "second" },
    "shell: several commands show which printed what"
  )
  res = run(assert(kind.build({ "exit 3", "echo never" }, "shell")))
  ok(not res.ok and vim.tbl_contains(res.lines, "[exit 3]"), "shell: a non-zero exit is reported")
  ok(not vim.tbl_contains(res.lines, "never"), "shell: and stops the commands after it")

  -- ── the flow of one invocation ──────────────────────────────────────────────
  local execute = require("bindings.usrcmds.execute")
  execute.enable()

  local typed, copied, asked, shown = {}, {}, {}, {}
  local to_cmdline, copy_command, deliver = sink.to_cmdline, sink.copy_command, sink.deliver
  local confirm = execute.confirm
  sink.to_cmdline = function(t)
    typed[#typed + 1] = t
  end
  sink.copy_command = function(p)
    copied[#copied + 1] = p.display
    return true
  end
  sink.deliver = function(how, r, p)
    shown[#shown + 1] = { how = how, lines = r.lines, display = p.display }
  end
  local answer = true
  execute.confirm = function(p)
    asked[#asked + 1] = p.display
    return answer
  end
  local function reset()
    typed, copied, asked, shown = {}, {}, {}, {}
  end

  scratch({ "see `:set wrap` here", "see `!echo flow-ok` here", "plain: echo 'plain-ok'" })

  vim.api.nvim_win_set_cursor(0, { 1, 8 })
  execute.execute({})
  eq(typed, { "set wrap" }, "without a bang the command goes to the command line, not to the run")
  eq(shown, {}, "and nothing ran")
  eq(execute.default_how(false), "cmdline")
  eq(execute.default_how(true), "run")

  reset()
  execute.execute({ how = "clipboard" })
  eq(copied, { ":set wrap" }, "clipboard copies the command")
  eq(shown, {}, "and runs nothing")

  reset()
  execute.execute({ bang = true })
  eq(#shown, 1, "a bang runs it")
  eq(shown[1].how, "run", "with the output as a message")
  eq(asked, {}, "an Ex command that stays in the editor is not asked about")

  reset()
  vim.api.nvim_win_set_cursor(0, { 2, 8 })
  execute.execute({ bang = true })
  eq(asked, { "!echo flow-ok" }, "a shell command asks first")
  vim.wait(10000, function()
    return #shown > 0
  end, 10)
  eq(shown[1] and shown[1].lines, { "flow-ok" }, "and runs after a yes")

  reset()
  answer = false
  execute.execute({ bang = true })
  vim.wait(200, function()
    return false
  end, 10)
  eq(shown, {}, "a no runs nothing")

  reset()
  answer = true
  execute.execute({ bang = true, yes = true })
  vim.wait(10000, function()
    return #shown > 0
  end, 10)
  eq(asked, {}, "--yes skips the question")

  reset()
  execute.execute({ how = "cmdline" })
  eq(
    typed,
    { "!echo flow-ok" },
    "a shell command in the command line is only typed, never asked about"
  )
  eq(asked, {}, "the command line is the preview")

  reset()
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  execute.execute({ how = "split", as = "shell", from = "line" })
  eq(asked[1], "!plain: echo 'plain-ok'", "--as and --from are honoured")

  -- the registered command: completion and the route
  eq(vim.fn.getcompletion("Execute ", "cmdline")[1] ~= nil, true, "<Tab> offers something")
  local how_names = vim.fn.getcompletion("Execute ", "cmdline")
  for _, name in ipairs(sink.HOW) do
    ok(vim.tbl_contains(how_names, name), "how completes " .. name)
  end
  eq(vim.fn.getcompletion("Execute sp", "cmdline"), { "split" }, "and narrows by prefix")
  local from_names = vim.fn.getcompletion("Execute --from=", "cmdline")
  for _, name in ipairs(source.FROM) do
    ok(
      vim.tbl_contains(from_names, "--from=" .. name) or vim.tbl_contains(from_names, name),
      "--from= completes " .. name
    )
  end

  reset()
  vim.api.nvim_win_set_cursor(0, { 1, 8 })
  vim.cmd("Execute")
  eq(typed, { "set wrap" }, ":Execute types it")
  reset()
  vim.cmd("Execute!")
  eq(#shown, 1, ":Execute! runs it")
  reset()
  vim.cmd("Execute clipboard --from=line")
  eq(copied, { ":see `:set wrap` here" }, "how and --from reach the handler")
  reset()
  vim.cmd("1,1Execute --from=selection")
  eq(typed, { "see `:set wrap` here" }, "a range selects the text")

  sink.to_cmdline, sink.copy_command, sink.deliver = to_cmdline, copy_command, deliver
  execute.confirm = confirm
  has(execute.default_how(false), "cmdline")
  vim.o.shell, vim.o.shellcmdflag, vim.o.shellquote, vim.o.shellxquote = unpack(saved_shell)
  vim.cmd("enew!")
end
