---@module 'sessions/autocmds'
---@brief Autocommands for portable sessions

local M = {}
local api = vim.api

---@return nil
function M.enable()
  local aug = api.nvim_create_augroup("PortableSessions", { clear = true })

  -- Autoload last session when starting without file args
  -- api.nvim_create_autocmd("VimEnter", {
  --   group = aug,
  --   callback = function()
  --     if vim.fn.argc(-1) == 0 then
  --       local ok, _ = require("sessions.core").load(nil)
  --       if ok then vim.notify("Session autoloaded") end
  --     end
  --   end,
  --   desc = "Portable sessions startup hook",
  --   once = true,
  -- })

  -- Autosave default session on exit
  api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      require("sessions.core").save(nil)
    end,
    desc = "Portable sessions shutdown hook",
  })
end

return M

