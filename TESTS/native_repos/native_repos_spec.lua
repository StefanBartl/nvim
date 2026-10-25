-- TESTS/native_repos/native_repos_spec.lua -- :MyNative: the staleness rule and the registry.

return function(H)
  local eq, ok = H.eq, H.ok
  local native = require("bindings.usrcmds.native_repos")
  local natives = require("plugins.personal.core.natives")

  eq(native.build_state(nil, 100), "missing", "no artifact is missing")
  eq(native.build_state(100, 200), "stale", "a newer source commit makes it stale")
  eq(native.build_state(200, 100), "current", "an artifact newer than the sources is current")
  eq(native.build_state(100, nil), "current", "unknown source time is not stale")

  local seen = {}
  for _, entry in ipairs(natives.list) do
    ok(not seen[entry.name], "unique name " .. entry.name)
    seen[entry.name] = true
    ok(
      entry.repo:match("^[%w-]+/" .. vim.pesc(entry.name) .. "$"),
      "repo matches the name: " .. entry.name
    )
    ok(entry.hint and entry.hint ~= "", "hint for " .. entry.name)
    ok(not entry.build or entry.artifact, "a build command comes with an artifact: " .. entry.name)
    ok(not entry.artifact or entry.sources, "an artifact comes with sources: " .. entry.name)
    ok(
      not entry.install or entry.build,
      "an install command comes with a build command: " .. entry.name
    )
  end
  -- setup.ps1 configures build/ itself; a bare `cmake --build build` failed on a checkout without it
  local ai = natives.get("ai-desktop")
  eq(vim.tbl_contains(ai.build, "scripts/setup.ps1"), true, "ai-desktop builds with its setup.ps1")
  eq(vim.tbl_contains(ai.build, "-SkipInstall"), true, "and its build does not install")
  for _, name in ipairs({ "tasks-desktop", "rules-desktop", "docmap-desktop" }) do
    local entry = natives.get(name)
    eq(vim.tbl_contains(entry.build, "-BuildOnly"), true, name .. " builds without installing")
    eq(vim.tbl_contains(entry.install, "-BuildOnly"), false, name .. " installs")
  end
  eq(natives.get("nope"), nil, "unknown name")
  eq(vim.tbl_contains(natives.names(), "takt"), true, "takt is listed")

  -- what a build run covers: only apps with a plain build command are built, the others are named
  local with_build = { repo = "o/a", name = "a", build = { "x" }, hint = "ha" }
  local by_setup = { repo = "o/b", name = "b", hint = "built by its setup.exe" }
  local list = { with_build, by_setup }
  local todo, hints = native.plan_build(list, { a = "current", b = "stale" }, false)
  eq(#todo, 0, "a current build is not run")
  eq(hints, { "b: built by its setup.exe" }, "a stale one without a command is only named")
  todo, hints = native.plan_build(list, { a = "stale", b = "missing" }, false)
  eq(#todo, 1, "a stale build with a command is run")
  eq(todo[1].name, "a")
  eq(#hints, 1, "and the other one is named")
  todo, hints = native.plan_build({ with_build }, { a = "current" }, true)
  eq(#todo, 1, "by name it is run even when current")
  eq(#hints, 0)
  todo, hints = native.plan_build({ by_setup }, { b = "current" }, true)
  eq({ #todo, #hints }, { 0, 1 }, "by name without a command: only the hint")
  todo = native.plan_build({ with_build }, { a = "not cloned" }, false)
  eq(#todo, 0, "an app that is not cloned is not built unasked")

  -- what an install run covers: every cloned app with an install command, whatever its build state
  local installs = { repo = "o/c", name = "c", build = { "x" }, install = { "y" }, hint = "hc" }
  local builds_only = { repo = "o/d", name = "d", build = { "x" }, hint = "hd" }
  local lib = { repo = "o/e", name = "e", hint = "a library" }
  todo, hints = native.plan_install(
    { installs, builds_only, lib },
    { c = "current", d = "stale", e = "no artifact" },
    false
  )
  eq(
    vim.tbl_map(function(n)
      return n.name
    end, todo),
    { "c" },
    "a current build is installed as well"
  )
  eq(hints, { "d: hd" }, "an app with only a build is named, a library is left out")
  todo = native.plan_install({ installs }, { c = "not cloned" }, false)
  eq(#todo, 0, "an app that is not cloned is not installed unasked")
  todo, hints = native.plan_install({ lib }, { e = "no artifact" }, true)
  eq({ #todo, hints }, { 0, { "e: a library" } }, "by name without a command: only the hint")

  -- the routes: `list` takes no name, the others an optional one
  local by_path = {}
  for _, route in ipairs(native.routes()) do
    by_path[route.path[1]] = route
  end
  eq(by_path.list.args, nil, "list has no argument")
  eq(by_path.build.args[1].optional, true, "build takes an optional name")
  eq(by_path.install.args[1].optional, true, "install takes an optional name")
  eq(by_path.clone.args[1].type, "MYNATIVE_NAME", "clone completes the app names")
end
