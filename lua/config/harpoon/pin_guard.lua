---@module 'config.harpoon.pin_guard'
--- Confirms before a persistent default pin drops out of the live Harpoon
--- list because the user edited it out of the quick menu (dd / blanking the
--- line). A non-pinned entry is never asked about -- removing it from the
--- live list IS the whole action, same as always.
---
--- Hooked into config.harpoon.hardening's ui.toggle_quick_menu wrap, right
--- before the close branch runs (which is where harpoon resolves the
--- buffer's current lines into the list and persists it).

local M = {}

local normkey = require("lib.nvim.fs.normkey")
local notify = require("lib.nvim.notify").create("[config.harpoon.pin_guard]")

---@param lines string[] the quick-menu buffer's current lines, about to be persisted
---@return string[] lines  same table; a declined removal is appended back
function M.confirm_before_close(lines)
  local ok_hp, harpoon = pcall(require, "harpoon")
  if not ok_hp then
    return lines
  end

  local list = harpoon.ui and harpoon.ui.active_list
  if type(list) ~= "table" or type(list.items) ~= "table" then
    return lines
  end

  local pinned = require("config.harpoon.persist_paths").pinned_set()
  if not next(pinned) then
    return lines
  end

  local still_present = {} ---@type table<string, boolean>
  for _, line in ipairs(lines) do
    local path = vim.trim(line)
    if path ~= "" then
      still_present[normkey(path, { realpath = true })] = true
    end
  end

  local length = list._length or #list.items
  for i = 1, length do
    local it = list.items[i]
    local v = (type(it) == "table") and it.value or it
    if type(v) == "string" and v ~= "" then
      local key = normkey(v, { realpath = true })
      if pinned[key] and not still_present[key] then
        local choice = vim.fn.confirm(
          ("Gepinnter Eintrag wird aus der Liste entfernt:\n%s"):format(v),
          "&Temporär (nur Liste)\n&Dauerhaft (auch entpinnen)\n&Abbrechen",
          1
        )
        if choice == 2 then
          -- `unpin` only removes machine-local `:HarpoonPin` entries -- it
          -- cannot touch a target_specs pin (git-tracked, hardcoded in
          -- misc.lua). For those, "dauerhaft" cannot actually be delivered
          -- here: say so, rather than let the user believe it worked.
          local unpinned = require("config.harpoon.persist_paths").unpin(v)
          if not unpinned then
            notify.warn(
              (
                "[harpoon] %s ist im Code fest gepinnt (target_specs) -- kann hier nicht entpinnt werden. "
                .. "Nur aus der Liste entfernt; kommt bei `:Harpoon defaults sync` zurück. "
                .. "Zum dauerhaften Entfernen aus lua/plugins/misc.lua streichen."
              ):format(v)
            )
          end
        elseif choice == 3 or choice == 0 then
          -- Keep it: put the line back so harpoon's own save sees it as
          -- still present, exactly as if the user had never deleted it.
          lines[#lines + 1] = v
          still_present[key] = true
        end
        -- choice == 1 ("Temporär"): line stays gone, pin file untouched --
        -- it comes back on the next `:Harpoon defaults sync` / first-run seed.
      end
    end
  end

  return lines
end

return M
