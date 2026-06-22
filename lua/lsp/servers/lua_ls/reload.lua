---@module 'lsp.servers.lua_ls.reload'
--- Manual library reload command for lua_ls
--- Use when @types are not detected automatically

local notify = require("lib.nvim.notify").create("[lsp.servers.lua_ls.reload]")

local M = {}

--- Reload lua_ls workspace library for current buffer
---@return boolean success
function M.reload_library()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Find lua_ls client
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "lua_ls" })
  if #clients == 0 then
    notify.warn("lua_ls not attached to current buffer")
    return false
  end

  local client = clients[1]

  -- Get current root
  local root = client.config.root_dir
  if not root then
    notify.error("Could not determine lua_ls root directory")
    return false
  end

  -- Rebuild library
  local ok, build_library = pcall(require, "lsp.servers.lua_ls.build_library")
  if not ok then
    notify.error("Could not load build_library module")
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

  notify.info(string.format("Reloaded lua_ls workspace library: %d paths", count))

  return true
end

--- Setup user command
function M.setup()
  vim.api.nvim_create_user_command("LuaLsReloadLibrary", function()
    M.reload_library()
  end, {
    desc = "[lsp.lua_ls] Reload workspace library (useful when @types not detected)"
  })

  vim.api.nvim_create_user_command("LuaLsInspectLibrary", function()
    local debug = require("lsp.servers.lua_ls.debug")
    debug.print_debug_info(vim.api.nvim_get_current_buf())
  end, {
    desc = "[lsp.lua_ls] Inspect current workspace library configuration"
  })

    vim.api.nvim_create_user_command("LuaLsSetProfile", function(opts)
    local profile = opts.args
    if profile == "" then
      profile = "normal"
    end

    vim.env.LUA_LS_PROFILE = profile
    M.reload_library()

    notify.info(string.format("Switched to profile: %s - Reloading...", profile))
  end, {
    nargs = "?",
    complete = function()
      return { "minimal", "normal", "full" }
    end,
    desc = "[lsp.lua_ls] Set library profile (minimal/normal/full)"
  })
end

return M
