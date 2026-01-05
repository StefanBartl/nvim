---@module 'custom.recommender.autocmds'
---Autocommands used by recommender to react to external UI lifecycle events

local M = {}

local api = vim.api

---@type integer|nil
local autocmd_id = nil

---Register a temporary WinClosed autocmd that waits for Telescope Replace to finish
---@param state table
function M.register_replace_finish(state)
  if autocmd_id ~= nil then
    return
  end

  autocmd_id = api.nvim_create_autocmd("WinClosed", {
    callback = function(args)
      local pending = state._pending_insert
      if not pending then
        return
      end

      local winid = tonumber(args.match)
      if not winid then
        return
      end

      -- Window is already closed here, so win validity cannot be checked.
      -- We must inspect the buffer via args.
      local buf = tonumber(args.buf)
      if not buf or not api.nvim_buf_is_valid(buf) then
        return
      end

      if vim.bo[buf].filetype ~= "TelescopePrompt" then
        return
      end

      -- Restore target window and insert alias text
      if api.nvim_win_is_valid(pending.win) then
        api.nvim_set_current_win(pending.win)
        api.nvim_put({ pending.text }, "l", false, true)
      end

      state._pending_insert = nil
      M.unregister_replace_finish()
    end,
  })
end

---Remove the temporary WinClosed autocmd
function M.unregister_replace_finish()
  if autocmd_id ~= nil then
    api.nvim_del_autocmd(autocmd_id)
    autocmd_id = nil
  end
end

return M

