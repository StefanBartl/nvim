-- TESTS/plugin_repos/usrcmds_help_spec.lua -- every flag, key=value pair and positional argument of
-- `:MyPlugins` has a line in lib.nvim's option float.
--
-- The verb is assembled from this config's own routes (clone, fetch, sync, dashboard ...) and from
-- tasks.nvim's task routes. A new option or argument without a `desc` (or, for an argument, a text
-- of its type) shows up as a bare row in the cheatsheet, so this fails until it is described.
-- The task routes are only there when tasks.nvim is on the runtimepath; its own spec covers them.

return function(H)
  local ok, composer = pcall(require, "lib.nvim.bindings.usercmd.composer")
  H.ok(ok, "the composer loads")

  -- A lib.nvim older than `help.undocumented` cannot answer the question; that is a missing
  -- feature of the dependency, not a defect of this config.
  if type(composer.help.undocumented) ~= "function" then
    return
  end

  require("bindings.usrcmds.plugin_repos").enable()
  H.ok(composer.registry().MyPlugins ~= nil, ":MyPlugins is registered through the composer")

  local missing = {}
  for _, m in ipairs(composer.help.undocumented("MyPlugins", { args = true })) do
    missing[#missing + 1] = ("%s %s %s"):format(m.route, m.kind, m.name)
  end
  H.eq(#missing, 0, ":MyPlugins options without a help text: " .. table.concat(missing, ", "))

  -- one line each, no closing full stop; and the check must not pass for the wrong reason
  local seen = H.check_arg_texts("MyPlugins")
  H.ok(seen >= 10, "the route tree carries the argument texts of all subcommands, saw " .. seen)

  -- `mode dir|remote` force one source for the personal plugins, but a repo set to "disabled" in
  -- plugins/personal/core/source.lua stays off (its `resolve` lets the repo's own disable win),
  -- so "all" alone would promise too much
  local mode_arg
  for _, route in ipairs(composer.registry().MyPlugins:spec().routes or {}) do
    if table.concat(route.path, " ") == "mode" then
      mode_arg = (route.args or {})[1]
    end
  end
  H.ok(mode_arg ~= nil and mode_arg.enum_desc ~= nil, "mode: the slot has value texts")
  for _, value in ipairs({ "dir", "remote" }) do
    local text = mode_arg and mode_arg.enum_desc and mode_arg.enum_desc[value] or ""
    H.has(text, "disabled", "mode " .. value .. ": names the repos that stay off")
  end
end
