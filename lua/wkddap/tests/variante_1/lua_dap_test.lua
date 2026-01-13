---@module 'dap_test.lua'
--- Simple Lua program to test nvim-dap with runtime and logic errors.

-- =========================================
-- Intentional mistakes:
-- 1. Accessing a nil field
-- 2. Off-by-one error in loop
-- =========================================

---@class User
---@field name string
---@field age number

---@type User[]
local users = {
  { name = "Alice", age = 30 },
  { name = "Bob", age = 25 },
}

---@param list User[]
---@return number
local function average_age(list)
  local sum = 0

  -- Intentional off-by-one error: should be <= #list
  for i = 1, #list + 1 do
    -- Intentional nil access when i == #list + 1
    sum = sum + list[i].age
  end

  return sum / #list
end

local avg = average_age(users)

-- Intentional nil field access
print("Average age is: " .. avg.value)

