-- File: lua/my/mod.lua
-- Purpose: cover module table functions, method syntax, table literals, member access.

-- Erwartete Kontexte (Default-Separator „⟩“, container_join „.“)
--
-- • bei function M.run() → my/mod.lua ⟩ M.run()
-- • bei function M:method → my/mod.lua ⟩ M.method()
-- • bei util.twice (Funktionsfeld) → my/mod.lua ⟩ util.twice()
-- • bei obj.name / obj.nested.value → my/mod.lua ⟩ obj bzw. my/mod.lua ⟩ obj.nested (lang_extra/fallback_object)
-- • bei Data.build = function() → my/mod.lua ⟩ Data.build()

---@module 'my.mod'

-- Module table with methods and nested tables
local M = {
  --- simple value
  version = "1.0.0", -- CURSOR: on 'version' (fallback object/word in field context)
  nested = {
    inner = { flag = true }, -- CURSOR: on 'inner' or 'flag' (owner chain from table assignment)
  },
}

--- Module function
--- CURSOR: on 'run' (expect: my/mod.lua ⟩ M.run())
function M.run()
  return "ok"
end

--- Method-style function (uses ':' and implicit self)
--- CURSOR: on 'method' (expect: my/mod.lua ⟩ M.method())
function M:method(x)
  return (self.version or "0") .. ":" .. tostring(x)
end

-- Local util table with function fields
local util = {}                   -- CURSOR: on 'util' (lang_extra owner name)
util.twice = function(a) return a * 2 end -- CURSOR: on 'twice' (owner 'util' inferred)

-- Member access / dot-index expression examples
local obj = { name = "alice", nested = { value = 42 } } -- CURSOR: on 'obj' (owner fallback)
print(obj.name)            -- CURSOR: on 'obj.name' (owner 'obj')
print(obj.nested.value)    -- CURSOR: on 'obj.nested.value' (owner chain 'obj.nested')

-- Anonymous function in a table field (owner comes from left-hand assignment)
local Data = {
  --- field with function value; owner inferred as 'Data'
  build = function() return { ok = true } end, -- CURSOR: on 'build'
}

return M
