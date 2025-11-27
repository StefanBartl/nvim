---@module 'config.telescope.selected_index'
--- Lightweight helper to display the index of the currently selected Telescope entry
--- as an inline virtual text overlay in the results window.
--- This file now composes the smaller modules placed under config/selected_files/.
--- It keeps the external API identical (attach_mappings_with_selected_index).
local M = {}

--- attach_mappings_with_selected_index
--- Returns a function suitable for passing to Telescope's `attach_mappings`.
--- Implementation delegates compute/update/move logic to the extracted modules.
function M.attach_mappings_with_selected_index()
  return function(prompt_bufnr, map)
    local action_state = require("telescope.actions.state")
    local actions = require("telescope.actions")

    -- create a namespace for extmarks; reuse across pickers is fine
    local ns = vim.api.nvim_create_namespace("telescope_selected_index_ns")

    -- robust getter for the current picker instance (kept as inline helper)
    local function get_picker()
      local ok, p = pcall(action_state.get_current_picker, prompt_bufnr)
      if ok and p then
        return p
      end
      local ok2, p2 = pcall(action_state.get_current_picker)
      if ok2 and p2 then
        return p2
      end
      return nil
    end

    -- require extracted helpers
    local compute_mod = require("config.telescope.selected_index.compute")
    local move_mod = require("config.telescope.selected_index.move")
    local update_mod = require("config.telescope.selected_index.update")

    -- instantiate update function bound with dependencies (keeps same behaviour)
    local update_selected_index = update_mod.make_update_selected_index({
      action_state = action_state,
      ns = ns,
      get_picker = get_picker,
      compute_index = compute_mod.compute_index_from_picker,
    })

    -- Perform several deferred attempts to draw the index.
    vim.schedule(function()
      update_selected_index()
    end)
    vim.defer_fn(function() update_selected_index() end, 150)
    vim.defer_fn(function() update_selected_index() end, 500)

    -- Common movement keys in insert and normal modes
    -- Use extracted wrap_move helper which accepts the same basic parameters.
    move_mod.wrap_move(map, "<Down>", "i", actions.move_selection_next, update_selected_index)
    move_mod.wrap_move(map, "<Up>", "i", actions.move_selection_previous, update_selected_index)
    move_mod.wrap_move(map, "<C-n>", "i", actions.move_selection_next, update_selected_index)
    move_mod.wrap_move(map, "<C-p>", "i", actions.move_selection_previous, update_selected_index)
    move_mod.wrap_move(map, "j", "n", actions.move_selection_next, update_selected_index)
    move_mod.wrap_move(map, "k", "n", actions.move_selection_previous, update_selected_index)
    move_mod.wrap_move(map, "<Down>", "n", actions.move_selection_next, update_selected_index)
    move_mod.wrap_move(map, "<Up>", "n", actions.move_selection_previous, update_selected_index)

    -- Defensive autocmd: if results buffer cursor moves, refresh overlay.
    local ok, p = pcall(get_picker)
    if ok and p and p.results_bufnr and p.results_bufnr ~= 0 then
      local augname = "TelescopeSelectedIndexAUG_" .. tostring(p.results_bufnr)
      -- create/clear augroup to avoid duplicates for same buffer
      local aug = vim.api.nvim_create_augroup(augname, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorMoved" }, {
        group = aug,
        buffer = p.results_bufnr,
        callback = function()
          vim.schedule(function()
            update_selected_index()
          end)
        end,
      })
    end

    return true
  end
end

return M
