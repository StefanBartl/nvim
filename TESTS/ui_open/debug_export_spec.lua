-- TESTS/ui_open/debug_export_spec.lua -- config/ui_open.lua keeps core's vim.ui.open
-- reachable for diagnosis, but not as a function-valued module field: runtime-analysis'
-- telemetry wraps every top-level function field of `config.*` modules, so such a field
-- read back as a telemetry wrapper and looked like a second setup(). The original sits
-- in the `_debug` table (not wrapped), and it is core's own function from vim/ui.lua --
-- also after a second setup() (config reload), which must not stack another wrapper.

return function(H)
  local eq, ok = H.eq, H.ok

  if vim.fn.has("win32") ~= 1 then
    -- setup() is a no-op off Windows; nothing is exported there.
    return
  end

  local core_open = vim.ui.open
  local done, err = pcall(function()
    package.loaded["config.ui_open"] = nil
    local M = require("config.ui_open")
    M.setup()

    ok(vim.ui.open ~= core_open, "setup() installs the wrapper")
    local wrapper = vim.ui.open

    -- The telemetry wraps every string-keyed function field, whatever its name, so
    -- the name check alone would let `M.orig_open = orig_open` through.
    for name, value in pairs(M) do
      if type(value) == "function" then
        ok(
          name:sub(1, 1) ~= "_",
          ("no underscore-prefixed function field is exported (found %s)"):format(name)
        )
        ok(
          value ~= core_open,
          ("core's vim.ui.open is not exported as a function field (found it in %s)"):format(name)
        )
      end
    end
    eq(M._orig_open, nil, "the original is not exported as M._orig_open")

    eq(type(M._debug), "table", "the debug handle is a table")
    ok(M._debug.orig_open == core_open, "_debug.orig_open is the vim.ui.open seen before setup()")
    local src = debug.getinfo(M._debug.orig_open, "S").short_src
    ok(
      src:match("vim[/\\]ui%.lua$") ~= nil,
      ("_debug.orig_open is defined in vim/ui.lua (got %s)"):format(src)
    )

    -- A config reload calls setup() again on the cached module.
    M.setup()
    ok(vim.ui.open == wrapper, "a second setup() keeps the installed wrapper (no double wrap)")
    ok(M._debug.orig_open == core_open, "after a second setup() _debug.orig_open is still core's")
  end)

  vim.ui.open = core_open
  package.loaded["config.ui_open"] = nil
  if not done then
    error(err, 0)
  end
end
