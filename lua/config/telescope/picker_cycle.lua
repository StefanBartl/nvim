---@module 'config.telescope.picker_cycle'
--- Provide wrap-around navigation for Telescope cycle option.

local M = {}

-- Helper: Telescope wrap move function
-- Attempts to get the current picker and wrap selection if at bounds.
-- If picker API is not available, falls back to standard move actions.
local function telescope_wrap_move(prompt_bufnr, direction)
  -- direction: "next" or "previous"
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  -- default fallbacks: move selection normally
  local fallback_next = function() actions.move_selection_next(prompt_bufnr) end
  local fallback_prev = function() actions.move_selection_previous(prompt_bufnr) end

  local ok, picker = pcall(action_state.get_current_picker, prompt_bufnr)
  if not ok or not picker then
    if direction == "next" then return fallback_next() end
    return fallback_prev()
  end

  -- try to read number of results and current index in a safe manner
  local ok_count, total = pcall(function()
    -- many pickers expose a results/count length via picker.finder or picker.results
    -- attempt common properties in order
    if picker.manager and picker.manager.max_results then
      return picker.manager.max_results
    elseif picker.finder and type(picker.finder) == "table" and type(picker.finder._next) == "function" then
      -- unknown finder internals; can't reliably count -> fallback
      return nil
    elseif picker.results and type(picker.results) == "table" then
      return #picker.results
    end
    return nil
  end)
  if not ok_count or not total or total == 0 then
    -- cannot determine total; use fallback
    if direction == "next" then return fallback_next() end
    return fallback_prev()
  end

  local ok_row, row = pcall(function()
    -- attempt to get current selection row; different telescope versions provide:
    -- picker:get_selection_row(), picker:get_selection_index(), picker._selection_row
    if picker.get_selection_row then
      return picker:get_selection_row()
    elseif picker.get_selection_index then
      return picker:get_selection_index()
    elseif picker._selection_row then
      return picker._selection_row
    end
    return nil
  end)
  if not ok_row or not row then
    if direction == "next" then return fallback_next() end
    return fallback_prev()
  end

  -- row is zero-based in many implementations; clamp to 0..total-1
  local cur = tonumber(row) or 0
  local last_index = total - 1

  if direction == "next" then
    if cur >= last_index then
      -- wrap to first
      local ok_set = pcall(function()
        if picker.set_selection then
          picker:set_selection(0)
        elseif picker.set_selection_index then
          picker:set_selection_index(0)
        else
          error("no set_selection API")
        end
      end)
      if not ok_set then fallback_next() end
    else
      fallback_next()
    end
  else -- previous
    if cur <= 0 then
      -- wrap to last
      local ok_set = pcall(function()
        if picker.set_selection then
          picker:set_selection(last_index)
        elseif picker.set_selection_index then
          picker:set_selection_index(last_index)
        else
          error("no set_selection API")
        end
      end)
      if not ok_set then fallback_prev() end
    else
      fallback_prev()
    end
  end
end

-- Exported helper to be used in telescope.attach_mappings
function M.attach_telescope_wrap(prompt_bufnr, map)
  -- map is telescope prompt_bufnr-local map function; if not provided, use vim.api mappings
  -- Insert-mode mappings
  -- <Up> wrap
  map("i", "<Up>", function()
    telescope_wrap_move(prompt_bufnr, "previous")
  end)
  -- <Down> wrap
  map("i", "<Down>", function()
    telescope_wrap_move(prompt_bufnr, "next")
  end)
  -- Normal-mode mappings (inside telescope)
  map("n", "<Up>", function()
    telescope_wrap_move(prompt_bufnr, "previous")
  end)
  map("n", "<Down>", function()
    telescope_wrap_move(prompt_bufnr, "next")
  end)

  return true
end

-- Convenience function to return an attach_mappings function usable in telescope.setup
function M.telescope_attach_mappings()
  return function(prompt_bufnr, map)
    -- call helper to set mappings that preserve prompt buffer scope
    -- map signature is (mode, key, action)
    -- telescope expects attach_mappings to return true to keep default mappings
    M.attach_telescope_wrap(prompt_bufnr, map)
    return true
  end
end

return M
