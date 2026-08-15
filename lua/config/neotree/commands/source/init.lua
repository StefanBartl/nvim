---@module 'config.neotree.commands.source'
--- `next_source`/`prev_source`: cycle neo-tree between its configured sources
--- (filesystem, git_status, ...) in either direction, wrapping around.

local M = {}

---@return nil
---@diagnostic disable-next-line: unused-local
function M.next_source(state)
  -- Speichere die aktuelle Window-ID
  local neotree_winid = vim.api.nvim_get_current_win()

  local sources = require("neo-tree").config.sources
  local current = vim.bo.filetype == "neo-tree" and vim.b.neo_tree_source or "filesystem"

  local current_index = 1
  for i, source in ipairs(sources) do
    if source == current then
      current_index = i
      break
    end
  end

  local next_index = current_index % #sources + 1
  local next_source = sources[next_index]

  require("neo-tree.command").execute({
    action = "show",
    source = next_source,
    position = "current", -- Wichtig: behalte die aktuelle Position
  })

  vim.schedule(function()
    -- Setze direkt zur gespeicherten Window-ID zurück
    if vim.api.nvim_win_is_valid(neotree_winid) then
      vim.api.nvim_set_current_win(neotree_winid)
    end
  end)
end

---@return nil
---@diagnostic disable-next-line: unused-local
function M.prev_source(state)
  local neotree_winid = vim.api.nvim_get_current_win()

  local sources = require("neo-tree").config.sources
  local current = vim.bo.filetype == "neo-tree" and vim.b.neo_tree_source or "filesystem"

  local current_index = 1
  for i, source in ipairs(sources) do
    if source == current then
      current_index = i
      break
    end
  end

  local prev_index = current_index - 1
  if prev_index < 1 then
    prev_index = #sources
  end
  local prev_source = sources[prev_index]

  require("neo-tree.command").execute({
    action = "show",
    source = prev_source,
    position = "current",
  })

  vim.schedule(function()
    if vim.api.nvim_win_is_valid(neotree_winid) then
      vim.api.nvim_set_current_win(neotree_winid)
    end
  end)
end

return M
