---@module 'config.telescope.selected_files.update'
--- Module exposing `make_update_selected_index` which returns a function that
--- performs the same index-overlay update logic as in the original single-file
--- implementation. The factory accepts dependencies so callers can keep
--- constructing/getting `action_state`, `get_picker` closures, and `compute_index`
--- functions externally; this satisfies the requirement not to change external
--- dependency wiring.
local M = {}

--- make_update_selected_index
--- Factory that returns an `update_selected_index()` function bound to the
--- provided dependencies.
--- @param deps table {
---   action_state = table, -- telescope.actions.state (module)
---   ns = number,          -- namespace id returned by vim.api.nvim_create_namespace
---   get_picker = function -- function() -> picker | nil
---   compute_index = function -- function(picker, row) -> number
--- }
--- @return function update_selected_index
function M.make_update_selected_index(deps)
  -- Basic validation to avoid runtime errors if caller forgets to pass something.
  local action_state = deps.action_state
  local ns = deps.ns
  local get_picker = deps.get_picker
  local compute_index = deps.compute_index

  -- Returned function performs the overlay update. It intentionally mirrors the
  -- original implementation so external call-sites do not need to change.
  return function()
    -- get selected entry if available; it may be nil very early
    local ok_ent, entry = pcall(function()
      return action_state.get_selected_entry()
    end)
    -- continue even if entry is nil — compute index from row fallback
    local p = nil
    local ok_p, ptemp = pcall(get_picker)
    if ok_p and ptemp then
      p = ptemp
    end
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
      local ok_win, win = pcall(function()
        return p.results_win
      end)
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
      index = compute_index and compute_index(p, row) or (row + 1)
    end

    if index and index > 0 then
      require("config.telescope.selected_index.display.virt_text")(results_bufnr, ns, row, index, "right_align")
      -- require("config.telescope.selected_index.display.virt_lines")(results_bufnr, ns, row, index, false)
    end
  end
end

return M
