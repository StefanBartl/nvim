---@meta
---@module '@types.functional'

---@generic T
---@alias Predicate fun(value: T): boolean

---@generic T, U
---@alias Mapper fun(value: T): U

---@generic A, B
---@alias Comparator fun(a: A, b: B): boolean

---@generic T
---@alias Reducer fun(acc: T, value: T): T

---@generic T
---@class ResultOk<T>
---@field ok true
---@diagnostic disable-next-line
---@field value T

---@class ResultErr
---@field ok false
---@field error string

---@generic T
---@alias Result ResultOk<T>|ResultErr

---@class TableSliceOptions
---@field from integer
---@field to integer

return {}
