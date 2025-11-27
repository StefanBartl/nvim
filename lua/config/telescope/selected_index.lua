---@module 'config.telescope.selected_index'
--- Lightweight helper to display the index of the currently selected Telescope entry
--- as an inline virtual text overlay in the results window.
--- Improved initialization: multiple deferred attempts to draw the index so that
--- it reliably appears immediately when the picker opens (fixes "only after a move"
--- and "shows 2 first" race conditions).
local M = {}

--- compute_index_from_picker
--- Best-effort resolution of absolute index for a given picker and results-row.
--- @param picker table telescope picker instance
--- @param row number zero-based row in the results buffer
--- @return number index 1-based index (best-effort)
local function compute_index_from_picker(picker, row)
  -- Defensive checks: prefer picker.results, then manager.results, then fallback.
  local results = nil
  if picker == nil then
    return row + 1
  end

  if type(picker.results) == "table" and #picker.results > 0 then
    results = picker.results
  elseif picker.manager and type(picker.manager.results) == "table" and #picker.manager.results > 0 then
    results = picker.manager.results
  elseif picker._results and type(picker._results) == "table" and #picker._results > 0 then
    results = picker._results
  end

  if not results then
    -- fallback: assume contiguous rows -> row + 1
    return row + 1
  end

  -- Count non-nil entries up to the given row (pragmatic heuristic).
  local count = 0
  local upto = math.min(row + 1, #results)
  for i = 1, upto do
    if results[i] ~= nil then
      count = count + 1
    end
  end
  if count == 0 then
    return row + 1
  end
  return count
end

--- attach_mappings_with_selected_index
--- Returns a function suitable for passing to Telescope's `attach_mappings`.
--- It will:
---  * draw a small virtual text overlay at the selected result line showing "N. "
---  * update the overlay after movement keys and on initial open (with retries)
---  * clear the overlay when selection has no index
--- @return function
function M.attach_mappings_with_selected_index()
  return function(prompt_bufnr, map)
    local action_state = require("telescope.actions.state")
    local actions = require("telescope.actions")

    -- create a namespace for extmarks; reuse across pickers is fine
    local ns = vim.api.nvim_create_namespace("telescope_selected_index_ns")

    -- robust getter for the current picker instance
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

    -- draw/refresh the index overlay for the currently selected entry
    local function update_selected_index()
      -- get selected entry if available; it may be nil very early
      local ok_ent, entry = pcall(action_state.get_selected_entry)
      -- continue even if entry is nil — compute index from row fallback
      local p = get_picker()
      if not p then
        return
      end

      local results_bufnr = p.results_bufnr or (p.manager and p.manager.results_bufnr) or p._results_bufnr
      if not results_bufnr or results_bufnr == 0 then
        return
      end

      -- clear previous extmarks
      pcall(vim.api.nvim_buf_clear_namespace, results_bufnr, ns, 0, -1)

      -- get the current row in the results buffer
      local row = nil
      if type(p.get_selection_row) == "function" then
        local ok_row, r = pcall(p.get_selection_row, p)
        if ok_row and type(r) == "number" then
          row = r
        end
      end

      if not row then
        -- conservative fallback: get cursor position from results window
        local ok_win, win = pcall(function() return p.results_win end)
        if ok_win and win and win ~= 0 then
          local ok_cur, cur = pcall(vim.api.nvim_win_get_cursor, win)
          if ok_cur and type(cur) == "table" then
            row = cur[1] - 1
          end
        end
      end

      if not row then
        row = 0
      end

      -- compute index: prefer explicit entry.index if present; else fallback to computed
      local index = nil
      if ok_ent and type(entry) == "table" and type(entry.index) == "number" then
        index = entry.index
      else
        index = compute_index_from_picker(p, row)
      end

      if index and index > 0 then
        local virt_text = { { tostring(index) .. ". ", "TelescopeResultsFunction" } }
        pcall(vim.api.nvim_buf_set_extmark, results_bufnr, ns, row, 0, {
          virt_text = virt_text,
          virt_text_pos = "overlay",
          hl_mode = "combine",
        })
      end
    end

    -- Perform several deferred attempts to draw the index. This solves race
    -- where attach_mappings runs before picker has fully populated results or
    -- set internal selection; the retries are short and keep UI responsive.
    vim.schedule(function()
      update_selected_index()
    end)
    vim.defer_fn(function() update_selected_index() end, 40)
    vim.defer_fn(function() update_selected_index() end, 120)

    -- Wrapper to update after movement actions
    local function wrap_move(key, mode, action_fn)
      map(mode, key, function(prompt_bufnr_)
        -- call original action (may change selection)
        action_fn(prompt_bufnr_)
        -- schedule update so it runs after telescope applied the change
        vim.schedule(function()
          update_selected_index()
        end)
        return true
      end)
    end

    -- Common movement keys in insert and normal modes
    wrap_move("<Down>", "i", actions.move_selection_next)
    wrap_move("<Up>", "i", actions.move_selection_previous)
    wrap_move("<C-n>", "i", actions.move_selection_next)
    wrap_move("<C-p>", "i", actions.move_selection_previous)
    wrap_move("j", "n", actions.move_selection_next)
    wrap_move("k", "n", actions.move_selection_previous)
    wrap_move("<Down>", "n", actions.move_selection_next)
    wrap_move("<Up>", "n", actions.move_selection_previous)

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
