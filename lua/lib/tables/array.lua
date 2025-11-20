---@module 'lib.tables.array'
--- High-performance helpers for Array<T> (contiguous 1..n lists).
--- All functions avoid reallocation when possible and pre-size outputs.

---@diagnostic disable

---@class TablesArray
local M = {}

--- Return length using # (assumes dense array).
---@class Array<T>: { [integer]: T }
---@param xs Array<T>
---@return integer
function M.len(xs)
  return #xs
end

--- Create a shallow copy of a dense array.
---@class Array<T>: { [integer]: T }
---@param xs Array<T>
---@return Array<T>
function M.clone(xs)
  local n = #xs
  ---@type Array<T>
  local out = { [n] = xs[n] } -- pre-size; value will be overwritten below
  for i = 1, n do
    out[i] = xs[i]
  end
  return out
end

--- Map over a dense array with preallocation.
---@class Array<T>: { [integer]: T }
---@param xs Array<T>
---@param f fun(v: T, i: integer, xs: Array<T>): R
---@return R[]
function M.map(xs, f)
  local n = #xs
  ---@type R[]
  local out = { [n] = false }
  for i = 1, n do
    out[i] = f(xs[i], i, xs)
  end
  return out
end

--- Filter a dense array. Prealloc then compact in one pass.
---@class Array<T>: { [integer]: T }
---@param xs Array<T>
---@param pred fun(v: T, i: integer, xs: Array<T>): boolean
---@return Array<T>
function M.filter(xs, pred)
  local n = #xs
  ---@type Array<T>
  local out = { [n] = xs[n] }
  local m = 0
  for i = 1, n do
    local v = xs[i]
    if pred(v, i, xs) then
      m = m + 1
      out[m] = v
    end
  end
  for j = m + 1, n do
    out[j] = nil
  end
  return out
end

--- Reduce with explicit initial accumulator.
---@class Array<T>: { [integer]: T }
---@param xs Array<T>
---@param f fun(acc: A, v: T, i: integer): A
---@param init A
---@return A
function M.reduce(xs, f, init)
  local acc = init
  for i = 1, #xs do
    acc = f(acc, xs[i], i)
  end
  return acc
end

--- Partition into {pass, fail} according to predicate.
---@class Array<T>: { [integer]: T }
---@param xs Array<T>
---@param pred fun(v: T, i: integer, xs: Array<T>): boolean
---@return Array<T> pass, Array<T> fail
function M.partition(xs, pred)
  local n = #xs
  ---@type Array<T>
  local pass = { [n] = xs[n] }
  ---@type Array<T>
  local fail = { [n] = xs[n] }
  local p, q = 0, 0
  for i = 1, n do
    local v = xs[i]
    if pred(v, i, xs) then
      p = p + 1
      pass[p] = v
    else
      q = q + 1
      fail[q] = v
    end
  end
  for i = p + 1, n do
    pass[i] = nil
  end
  for i = q + 1, n do
    fail[i] = nil
  end
  return pass, fail
end

--- Flatten one level of nested arrays.
---@class Array<T>: { [integer]: T }
---@param xss Array<T>[]
---@return Array<T>
function M.flatten(xss)
  local total = 0
  for i = 1, #xss do
    total = total + #xss[i]
  end
  ---@type Array<T>
  local out = { [total] = false }
  local k = 0
  for i = 1, #xss do
    local xs = xss[i]
    for j = 1, #xs do
      k = k + 1
      out[k] = xs[j]
    end
  end
  return out
end

--- Unique by equality (O(n) with set if primitives).
---@class Array<T>: { [integer]: T }
---@param xs Array<T>
---@return Array<T>
function M.unique(xs)
  local seen = {}
  local n = #xs
  ---@type Array<T>
  local out = { [n] = xs[n] }
  local k = 0
  for i = 1, n do
    local v = xs[i]
    if not seen[v] then
      seen[v] = true
      k = k + 1
      out[k] = v
    end
  end
  for j = k + 1, n do
    out[j] = nil
  end
  return out
end

--- Pluck a field from array of tables, skipping nils.
---@param xs table[]
---@param key string
---@return any[]
function M.pluck(xs, key)
  local n = #xs
  ---@type any[]
  local out = { [n] = false }
  local k = 0
  for i = 1, n do
    local v = xs[i][key]
    if v ~= nil then
      k = k + 1
      out[k] = v
    end
  end
  for j = k + 1, n do
    out[j] = nil
  end
  return out
end

--- Sort copy (stable-ish for small arrays); does not mutate input.
---@class Array<T>: { [integer]: T }
---@param xs Array<T>
---@param cmp fun(a: T, b: T): boolean
---@return Array<T>
function M.sorted(xs, cmp)
  local out = M.clone(xs)
  table.sort(out, cmp)
  return out
end

return M
