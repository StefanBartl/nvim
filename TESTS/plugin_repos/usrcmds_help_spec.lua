-- TESTS/plugin_repos/usrcmds_help_spec.lua -- every flag and key=value pair of `:MyPlugins` has a
-- line in lib.nvim's option float.
--
-- The verb is assembled from this config's own routes (clone, fetch, sync, dashboard ...) and from
-- tasks.nvim's task routes. A new option without a `desc` shows up as a bare row in the cheatsheet,
-- so this fails until it is described.

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
  for _, m in ipairs(composer.help.undocumented("MyPlugins")) do
    missing[#missing + 1] = ("%s %s %s"):format(m.route, m.kind, m.name)
  end
  H.eq(#missing, 0, ":MyPlugins options without a help text: " .. table.concat(missing, ", "))
end
