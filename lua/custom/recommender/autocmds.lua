---@module 'custom.recommender.autocmds'
--- Autocmds for Recommender

local M = {}
local api = vim.api

---Register a temporary autocmd to run a callback after a Telescope Picker is closed
---@param target_win integer The window to insert into
---@param buf_snapshot string[] Lines of the buffer before replace
---@param alias_text string The alias to insert if Replace changed the buffer
function M.register_replace_finish(target_win, buf_snapshot, alias_text)
  local group = api.nvim_create_augroup("RecommenderReplaceInsert", { clear = true })
  api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(args)
      local winid = tonumber(args.match)
      if not winid then return end

      -- Prüfe, ob das geschlossene Fenster ein Telescope-Prompt war
      local buf_closed = nil
      if api.nvim_win_is_valid(winid) then
        buf_closed = api.nvim_win_get_buf(winid)
      end
      if not buf_closed or vim.bo[buf_closed].filetype ~= "TelescopePrompt" then
        return
      end

      -- Prüfe Target-Window Validität
      if not api.nvim_win_is_valid(target_win) then
        vim.api.nvim_del_augroup_by_id(group)
        return
      end

      local buf = api.nvim_win_get_buf(target_win)
      if not api.nvim_buf_is_valid(buf) then
        vim.api.nvim_del_augroup_by_id(group)
        return
      end

      -- Vergleiche alten Snapshot mit aktuellem Buffer
      local new_lines = api.nvim_buf_get_lines(buf, 0, -1, false)
      local changed = false
      for i = 1, math.min(#buf_snapshot, #new_lines) do
        if buf_snapshot[i] ~= new_lines[i] then
          changed = true
          break
        end
      end

      -- Führe Alias-Insert nur durch, wenn sich der Buffer geändert hat
      if changed and api.nvim_win_is_valid(target_win) then
        api.nvim_set_current_win(target_win)
        api.nvim_put({ alias_text }, "l", false, true)
      end

      -- Autocmd danach sofort löschen
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })
end

return M
