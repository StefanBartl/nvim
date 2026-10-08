-- TESTS/clipboard/usrcmds_help_spec.lua -- every flag, key=value pair and positional argument of
-- `:Clipboard` has a line in lib.nvim's option float. The routes are directory and snippet words
-- without options today, so this pins that a route which grows one is described right away.

return function(H)
  local ok, composer = pcall(require, "lib.nvim.bindings.usercmd.composer")
  H.ok(ok, "the composer loads")

  -- A lib.nvim older than `help.undocumented` cannot answer the question; that is a missing
  -- feature of the dependency, not a defect of this config.
  if type(composer.help.undocumented) ~= "function" then
    return
  end

  require("bindings.usrcmds.clipboard").enable()
  H.ok(composer.registry().Clipboard ~= nil, ":Clipboard is registered through the composer")

  local missing = {}
  for _, m in ipairs(composer.help.undocumented("Clipboard", { args = true })) do
    missing[#missing + 1] = ("%s %s %s"):format(m.route, m.kind, m.name)
  end
  H.eq(#missing, 0, ":Clipboard options without a help text: " .. table.concat(missing, ", "))

  -- whatever argument texts exist have the shape of the others
  H.check_arg_texts("Clipboard")
end
