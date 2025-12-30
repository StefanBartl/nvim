---@module 'lsp.servers.lua_ls.reload'
--- Manual library reload command for lua_ls
--- Use when @types are not detected automatically

local M = {}

--- Reload lua_ls workspace library for current buffer
---@return boolean success
function M.reload_library()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Find lua_ls client
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "lua_ls" })
  if #clients == 0 then
    vim.notify("lua_ls not attached to current buffer", vim.log.levels.WARN)
    return false
  end

  local client = clients[1]

  -- Get current root
  local root = client.config.root_dir
  if not root then
    vim.notify("Could not determine lua_ls root directory", vim.log.levels.ERROR)
    return false
  end

  -- Rebuild library
  local ok, build_library = pcall(require, "lsp.servers.lua_ls.build_library")
  if not ok then
    vim.notify("Could not load build_library module", vim.log.levels.ERROR)
    return false
  end

  local library = build_library(root)
  local count = 0
  for _ in pairs(library) do
    count = count + 1
  end

  -- Update client settings
  client.config.settings.Lua.workspace.library = library

  -- Notify client of configuration change
  client.notify("workspace/didChangeConfiguration", {
    settings = client.config.settings
  })

  vim.notify(
    string.format("Reloaded lua_ls workspace library: %d paths", count),
    vim.log.levels.INFO
  )

  return true
end

--- Setup user command
function M.setup()
  vim.api.nvim_create_user_command("LuaLsReloadLibrary", function()
    M.reload_library()
  end, {
    desc = "[lua_ls] Reload workspace library (useful when @types not detected)"
  })
end

return M
