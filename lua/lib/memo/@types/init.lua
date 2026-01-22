---@meta
---@module 'lib.memo.@types'

---@class Lib.Memo.LruNode
---@field key any
---@field value any
---@field prev Lib.Memo.LruNode|nil
---@field next Lib.Memo.LruNode|nil

---@class Lib.Memo.LruState
---@field cap integer
---@field size integer
---@field map table<any, Lib.Memo.LruNode>
---@field head Lib.Memo.LruNode|nil
---@field tail Lib.Memo.LruNode|nil

---@class Lib.Memo.Lru : Lib.Memo.LruState
---@field get fun(self: Lib.Memo.Lru, key: any): any|nil
---@field put fun(self: Lib.Memo.Lru, key: any, value: any)
---@field _move_front fun(self: Lib.Memo.Lru, node: Lib.Memo.LruNode)
---@field _evict fun(self: Lib.Memo.Lru)

---@class Lib.Memo.Memo
---@field memoize fun(fn: fun(...): any, cap: integer|nil, keyer: fun(...): string|nil): fun(...): any

---@class Lib.Memo
---@field lru Lib.Memo.Lru # Exposed LRU cache constructor module.
---@field memo Lib.Memo.Memo # Exposed memoization helper module.

return {}
