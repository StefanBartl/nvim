---@module 'config.harpoon.utils.sanitize'
-- Sanitize and deduplicate without replacing the internal items table.

local M = {}

local normkey = require("lib.nvim.fs.normkey")
local dedup_indices = require("lib.lua.tables").dedup_indices

---@param list Cfg.Harpoon.List
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
      ---@cast it Cfg.Harpoon.ItemLegacy|Cfg.Harpoon.Item
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

---@param list Cfg.Harpoon.List
---@return integer removed_count
function M.dedup_in_place_safe(list)
  if type(list) ~= "table" or type(list.items) ~= "table" then
    return 0
  end

  -- Non-string values (shouldn't occur after sanitize_items_in_place, but
  -- kept defensive) key to themselves so they never collide with a real path.
  -- A nil hole has no identity to key on at all and would be an illegal table
  -- index, so each one gets its own fresh table as a key: never deduped away,
  -- never a crash.
  local to_remove = dedup_indices(list.items, function(it)
    local v = (type(it) == "table") and it.value or it
    if type(v) == "string" then
      return normkey(v)
    end
    return v ~= nil and v or {}
  end)

  if #to_remove == 0 then
    return 0
  end
  for idx = #to_remove, 1, -1 do
    local j = to_remove[idx]
    -- `remove_at`, not `remove`: `j` is an index, and harpoon's `remove`
    -- takes an ITEM which it hands to `config.equals` -- that indexes its
    -- argument, so an integer threw inside this pcall and nothing was ever
    -- removed, while the count below still claimed it had been.
    if type(list.remove_at) == "function" then
      pcall(function()
        list:remove_at(j)
      end)
    else
      table.remove(list.items, j)
    end
  end
  return #to_remove
end

return M
