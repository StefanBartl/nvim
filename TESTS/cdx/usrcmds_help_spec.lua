-- TESTS/cdx/usrcmds_help_spec.lua -- every option and positional argument of `:Cdx` has a line in
-- lib.nvim's option float (today: the `sha` of `prompt ultra_sha`).
--
-- The text comes from the `desc` of each ArgSpec in bindings/usrcmds/cdx/init.lua. A new argument
-- without one shows up as a bare row in the cheatsheet, so this fails until it is described.

return function(H)
  local ok, composer = pcall(require, "lib.nvim.bindings.usercmd.composer")
  H.ok(ok, "the composer loads")

  -- A lib.nvim older than `help.undocumented` cannot answer the question; that is a missing
  -- feature of the dependency, not a defect of this config.
  if type(composer.help.undocumented) ~= "function" then
    return
  end

  require("bindings.usrcmds.cdx").enable()
  H.ok(composer.registry().Cdx ~= nil, ":Cdx is registered through the composer")

  local missing = {}
  for _, m in ipairs(composer.help.undocumented("Cdx", { args = true })) do
    missing[#missing + 1] = ("%s %s %s"):format(m.route, m.kind, m.name)
  end
  H.eq(#missing, 0, ":Cdx options without a help text: " .. table.concat(missing, ", "))

  -- one line, no closing full stop; and the check must not pass for the wrong reason
  local seen = H.check_arg_texts("Cdx")
  H.ok(seen >= 1, "the route tree carries the argument text of prompt ultra_sha, saw " .. seen)
end
