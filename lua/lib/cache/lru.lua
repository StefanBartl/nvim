---@module 'lib.cache.lru'
--- O(1) LRU cache using a hashmap + doubly linked list.

---@class LruNode
---@field key any
---@field value any
---@field prev LruNode|nil
---@field next LruNode|nil

---@class Lru
---@field cap integer
---@field size integer
---@field map table<any, LruNode>
---@field head LruNode|nil
---@field tail LruNode|nil
local Lru = {}
Lru.__index = Lru

--- Move a node to the front (most-recent).
---@param self Lru
---@param node LruNode
function Lru:_move_front(node)
  if self.head == node then
    return
  end
  -- unlink
  if node.prev then
    node.prev.next = node.next
  end
  if node.next then
    node.next.prev = node.prev
  end
  if self.tail == node then
    self.tail = node.prev
  end
  -- link at head
  node.prev = nil
  node.next = self.head
  if self.head then
    self.head.prev = node
  end
  self.head = node
  if not self.tail then
    self.tail = node
  end
end

--- Evict LRU (tail) node.
---@param self Lru
function Lru:_evict()
  local node = self.tail
  if not node then
    return
  end
  self.map[node.key] = nil
  if node.prev then
    node.prev.next = nil
  end
  self.tail = node.prev
  if self.head == node then
    self.head = nil
  end
  self.size = self.size - 1
end

--- Get a value by key; returns value or nil.
---@param self Lru
---@param key any
---@return any|nil
function Lru:get(key)
  local node = self.map[key]
  if not node then
    return nil
  end
  self:_move_front(node)
  return node.value
end

--- Put key/value; overwrites existing and moves to front.
---@param self Lru
---@param key any
---@param value any
function Lru:put(key, value)
  local node = self.map[key]
  if node then
    node.value = value
    self:_move_front(node)
    return
  end
  node = { key = key, value = value, prev = nil, next = nil }
  self.map[key] = node
  self.size = self.size + 1
  self:_move_front(node)
  if self.size > self.cap then
    self:_evict()
  end
end

--- New LRU with capacity >= 1.
---@param cap integer
---@return Lru
local function new_lru(cap)
  return setmetatable({ cap = math.max(1, cap), size = 0, map = {}, head = nil, tail = nil }, Lru)
end

return { new = new_lru }
