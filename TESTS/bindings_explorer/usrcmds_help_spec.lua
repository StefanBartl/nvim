-- TESTS/bindings_explorer/usrcmds_help_spec.lua -- every key=value pair and positional argument of
-- `:Bindings` has a line in lib.nvim's option float (`plugin=`, `root=`, `out=`; the plugin, query,
-- scope and axis slots).
--
-- The text comes from the `desc` of each KvSpec / ArgSpec in bindings/usrcmds/bindings_explorer/init.lua
-- (a slot of the BINDINGS_PLUGIN type may rely on the text of the type, `plugin_scope.argtype`). A
-- new pair or slot without one shows up as a bare row in the cheatsheet, so this fails until it is
-- described.

return function(H)
  local ok, composer = pcall(require, "lib.nvim.bindings.usercmd.composer")
  H.ok(ok, "the composer loads")

  -- A lib.nvim older than `help.undocumented` cannot answer the question; that is a missing
  -- feature of the dependency, not a defect of this config.
  if type(composer.help.undocumented) ~= "function" then
    return
  end

  require("bindings.usrcmds.bindings_explorer").enable()
  H.ok(composer.registry().Bindings ~= nil, ":Bindings is registered through the composer")

  local missing = {}
  for _, m in ipairs(composer.help.undocumented("Bindings", { args = true })) do
    missing[#missing + 1] = ("%s %s %s"):format(m.route, m.kind, m.name)
  end
  H.eq(#missing, 0, ":Bindings options without a help text: " .. table.concat(missing, ", "))

  -- one line each, no closing full stop; and the check must not pass for the wrong reason
  local seen = H.check_arg_texts("Bindings")
  H.ok(seen >= 20, "the route tree carries the argument texts of all subcommands, saw " .. seen)
end
