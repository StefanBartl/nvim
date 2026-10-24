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
  end
  eq(natives.get("ai-desktop").build[1], "cmake", "ai-desktop builds with cmake")
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

  -- the routes: `list` takes no name, the others an optional one
  local by_path = {}
  for _, route in ipairs(native.routes()) do
    by_path[route.path[1]] = route
  end
  eq(by_path.list.args, nil, "list has no argument")
  eq(by_path.build.args[1].optional, true, "build takes an optional name")
  eq(by_path.clone.args[1].type, "MYNATIVE_NAME", "clone completes the app names")
end
