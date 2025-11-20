---@module 'lib.tables.types.aliases'
--- Central alias definitions for shared typing across modules.

---@diagnostic disable

---@generic T
---@alias Array<T> T[]

---@alias DictStringAny table<string, any>
---@alias DictAnyAny table<any, any>

---@generic T
---@alias Predicate<T> fun(value:T):boolean

---@generic T,U
---@alias Mapper<T,U> fun(value:T):U

---@generic A,B
---@alias Comparator<A,B> fun(a:A, b:B):boolean

---@generic T
---@alias Reducer<T> fun(acc:T, value:T):T

---@generic A,R
---@alias Folder<A,R> fun(acc:R, value:A, index:integer):R

---@alias PathKind "file"|"directory"|""  -- empty string for non-existent
