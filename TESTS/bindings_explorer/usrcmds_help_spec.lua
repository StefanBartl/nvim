-- TESTS/bindings_explorer/usrcmds_help_spec.lua -- every key=value pair of `:Bindings` has a line in
-- lib.nvim's option float (`plugin=`, `root=`, `out=`).
--
-- The text comes from the `desc` of each KvSpec in bindings/usrcmds/bindings_explorer/init.lua. A
-- new pair without one shows up as a bare row in the cheatsheet, so this fails until it is described.

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
  for _, m in ipairs(composer.help.undocumented("Bindings")) do
    missing[#missing + 1] = ("%s %s"):format(m.route, m.name)
  end
  H.eq(#missing, 0, ":Bindings options without a help text: " .. table.concat(missing, ", "))
end
