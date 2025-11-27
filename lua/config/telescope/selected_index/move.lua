---@module 'config.telescope.selected_files.move'
--- Small helper module that provides a single `wrap_move` helper.
--- The wrapper calls the original telescope action and then ensures a provided
--- update function is scheduled afterwards. This keeps movement-related logic
--- extracted while preserving the external call signature.
local M = {}

--- wrap_move
--- Creates a mapping that runs the given action and then triggers `update_fn`.
--- This function intentionally accepts the same basic parameters that the
--- original inline function used so callers can pass the same values.
--- @param map function mapping function supplied by telescope (map)
--- @param key string key to map
--- @param mode string mode string ("i" or "n")
--- @param action_fn function telescope action to invoke (e.g. actions.move_selection_next)
--- @param update_fn function function to call (no args) after action to refresh UI
function M.wrap_move(map, key, mode, action_fn, update_fn)
  -- The mapping created returns true to follow the original contract from attach_mappings.
  map(mode, key, function(prompt_bufnr_)
    -- invoke original action which may change selection; allow it to error internally
    pcall(action_fn, prompt_bufnr_)
    -- schedule the update so it runs after telescope applied the change
    if type(update_fn) == "function" then
      vim.schedule(function()
        pcall(update_fn)
      end)
    end
    return true
  end)
end

return M
