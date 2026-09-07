---@module 'bindings.usrcmds.bindings_explorer.ui'
--- Picker wiring for `:Bindings search` — `lib.nvim.ui.kit.select`, not
--- `pickers.nvim` (its `sources/*` are filesystem source objects, no trivial
--- "picker over this list" entry point; see docs/FEATURES.md). Same fallback
--- images.nvim and casedesk take in this situation.
---
--- Note: user-facing strings here are German, deliberately — every string of
--- `:Bindings` is (see status.lua).

local M = {}

---@return table lib.nvim notify handle
local function notify()
  return require("lib.nvim.notify").create("[bindings]")
end

--- Show an absolute path relative to `stdpath("config")`, so every picker row
--- isn't padded with the same long prefix.
---@param path string
---@return string
local function display_path(path)
  local cfg = vim.fn.stdpath("config")
  if path:sub(1, #cfg) == cfg then
    return path:sub(#cfg + 2)
  end
  return path
end

--- Show search results as a picker; `<CR>` opens the file at the hit.
---@param hits Bindings.Hit[]
---@return nil
function M.pick(hits)
  if #hits == 0 then
    notify().warn("Keine Treffer")
    return
  end

  require("lib.nvim.ui.kit.select").open({
    items = hits,
    title = ("%d Treffer"):format(#hits),
    format_item = function(hit)
      return ("%s:%d: %s"):format(display_path(hit.path), hit.line, hit.text)
    end,
    on_select = function(hit)
      vim.cmd("edit " .. vim.fn.fnameescape(hit.path))
      vim.api.nvim_win_set_cursor(0, { hit.line, 0 })
      vim.cmd("normal! zz")
    end,
  })
end

return M
