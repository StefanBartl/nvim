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

  --- One positional slot of a route, by the route's path (`"check"`) and the slot's name.
  ---@param route_path string
  ---@param arg_name string
  ---@return table|nil
  local function slot(route_path, arg_name)
    for _, route in ipairs(composer.registry().Bindings:spec().routes or {}) do
      if table.concat(route.path, " ") == route_path then
        for _, arg in ipairs(route.args or {}) do
          if arg.name == arg_name then
            return arg
          end
        end
      end
    end
  end

  -- `extern` swaps the whole corpus (third-party cheatsheets against the session, plus the live
  -- commands that are not ours); it is not "only the commands that have no cheatsheet"
  for _, route_path in ipairs({ "check", "report" }) do
    local axis = slot(route_path, "axis")
    H.ok(axis ~= nil and axis.enum_desc ~= nil, route_path .. ": the axis slot has value texts")
    local extern = axis and axis.enum_desc and axis.enum_desc.extern or ""
    H.has(extern, "cheatsheets", route_path .. " extern: names the cheatsheet side")
    H.lacks(extern, "only", route_path .. " extern: is not narrowed to the undocumented direction")
  end

  -- `path personal` copies a root that no longer exists (the sheets live in each plugin's
  -- docs/BINDINGS.md); the text calls it stale exactly as long as the directory is missing
  local scope = slot("path", "scope")
  H.ok(scope ~= nil and scope.enum_desc ~= nil, "path: the scope slot has value texts")
  local config = require("bindings.usrcmds.bindings_explorer.config")
  local personal_gone = vim.fn.isdirectory(config.roots()[1]) == 0
  local personal = scope and scope.enum_desc and scope.enum_desc.personal or ""
  H.eq(
    personal:find("stale", 1, true) ~= nil,
    personal_gone,
    "path personal: the text says 'stale' iff the personal root is gone"
  )
  if personal_gone then
    H.has(personal, "docs/BINDINGS.md", "path personal: points at where the sheets live now")
  end
end
