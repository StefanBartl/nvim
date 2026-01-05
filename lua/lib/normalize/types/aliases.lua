---@meta
---@module 'lib.normalize.aliases'

---@alias FnValidator fun(value:any):boolean        -- return true if value passes validation
---@alias FnMapper    fun(value:any):any            -- map value -> normalized value
---@alias FnApplier   fun(state:table, key:string, value:any):boolean  -- returns true if applied
---@alias Lib.Normalize.StringList  string[]                       -- list of strings
---@alias AnyList     any[]                          -- list of any
