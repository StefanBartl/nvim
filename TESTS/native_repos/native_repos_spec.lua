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
  eq(natives.get("loomAI").build[1], "cmake", "loomAI builds with cmake")
  eq(natives.get("nope"), nil, "unknown name")
  eq(vim.tbl_contains(natives.names(), "takt"), true, "takt is listed")
end
