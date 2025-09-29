---@meta
---@module 'utils.tables.types'

---@class ResultOk<T>
---@field ok true
---@field value T

---@class ResultErr
---@field ok false
---@field error string

---@generic T
---@alias Result<T> ResultOk<T>|ResultErr

---@class TableSliceOptions
---@field from integer
---@field to integer

---@class PartitionResult<T>
---@field pass T[]
---@field fail T[]

---@class GroupedTable<K, V>
---@field [K] V[]

