---@module 'config.harpoon.utils.sanitize'
-- Sanitize and deduplicate without replacing the internal items table.

local M = {}

local Norm = require("config.harpoon.utils.normkey")

---@param list HarpoonList
---@return nil
function M.sanitize_items_in_place(list)
  if type(list) ~= "table" or type(list.items) ~= "table" then
    return
  end

  for i = 1, #list.items do
    local it = list.items[i]

    -- Case 1: raw string entry -> upgrade to structured item
    if type(it) == "string" then
      list.items[i] = { value = it, context = { row = 1, col = 0 } }
    elseif type(it) == "table" then
      ---@cast it HarpoonItemLegacy|HarpoonItem
      -- Normalize 'value':
      --  - primary: 'value' if present
      --  - fallback: legacy 'path' (access via rawget to avoid undefined-field diagnostics)
      if it.value == nil then
        local maybe_path = rawget(it, "path")
        if type(maybe_path) == "string" then
          it.value = maybe_path
        end
      end

      -- Ensure 'context'
      if it.context == nil then
        it.context = { row = 1, col = 0 }
      end
    end
  end
end

---@param list HarpoonList
---@return integer removed_count
function M.dedup_in_place_safe(list)
  if type(list) ~= "table" or type(list.items) ~= "table" then
    return 0
  end
  local seen = {} ---@type table<string, boolean>
  local to_remove = {} ---@type integer[]

  for i = 1, #list.items do
    local it = list.items[i]
    local v = (type(it) == "table") and it.value or it
    if type(v) == "string" then
      local k = Norm.normkey(v)
      if seen[k] then
        to_remove[#to_remove + 1] = i
      else
        seen[k] = true
      end
    end
  end

  if #to_remove == 0 then
    return 0
  end
  for idx = #to_remove, 1, -1 do
    local j = to_remove[idx]
    if type(list.remove) == "function" then
      pcall(function()
        list:remove(j)
      end)
    else
      table.remove(list.items, j)
    end
  end
  return #to_remove
end

return M
