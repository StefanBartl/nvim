---@module 'config.telescope.attach_selected_index'
--- Small helper that automatically attaches the selected-index virtual-text
--- overlay to all Telescope builtin pickers by wrapping their functions.
--- Place this file in `lua/config/telescope/attach_selected_index.lua`
--- and require it from the plugin configuration (see usage below).
---
local M = {}

-- ensure we only wrap once per function
local wrapped_builtins = {}

-- Merge two attach_mappings functions into one.
-- If both exist, call the user one first, then the index one.
-- Each attach_mappings must return true to allow other mappings to register.
-- If user_attach returns false/nil, we still call index_attach to be defensive.
-- @param user_attach function|nil
-- @param index_attach function
-- @return function combined_attach
local function combine_attach_mappings(user_attach, index_attach)
  -- If no user attach is provided, just return the index attach.
  if type(user_attach) ~= "function" then
    return index_attach
  end

  return function(prompt_bufnr, map)
    -- call user-provided attach_mappings first to allow their mappings to exist
    local ok, res = pcall(user_attach, prompt_bufnr, map)
    -- always call the index attach afterwards; schedule it so it runs after telescope internal setup
    -- but keep it synchronous here for simplicity -- the index attach itself schedules internal updates as needed
    pcall(index_attach, prompt_bufnr, map)
    -- prefer the user's return value if it's boolean true; otherwise return true to keep other attachers happy
    if ok and res == true then
      return true
    end
    return true
  end
end

-- Wrap a builtin function so that when called it injects our attach_mappings
-- into opts (unless opts already contains an attach_mappings, in which case merge).
-- @param builtin_name string
-- @param builtin_fn function
-- @param index_attach function
local function wrap_builtin(builtin_name, builtin_fn, index_attach)
  if type(builtin_fn) ~= "function" or wrapped_builtins[builtin_name] then
    return
  end

  wrapped_builtins[builtin_name] = true
  -- store original under <name>_orig to preserve if needed
  local orig = builtin_fn

  local function wrapper(opts)
    -- ensure opts is a table
    opts = opts or {}
    -- combine any user attach_mappings with our index attach
    opts.attach_mappings = combine_attach_mappings(opts.attach_mappings, index_attach)
    -- forward call to original builtin
    return orig(opts)
  end

  return wrapper
end

-- Try to find a stable place where telescope exposes its builtins table.
-- Returns the builtins table or nil.
local function try_get_builtins()
  local ok, tb = pcall(require, "telescope.builtin")
  if ok and type(tb) == "table" then
    return tb
  end
  return nil
end

-- Main setup function: given the index-attach factory (from the other module),
-- wrap all functions found in telescope.builtin.
-- The function is idempotent.
-- @param index_attach_factory function a function that returns the attach_mappings function
function M.setup(index_attach_factory)
  if type(index_attach_factory) ~= "function" then
    error("attach_selected_index.setup expects a function that returns attach_mappings")
  end

  -- create the attach_mappings function once (it may itself create closures)
  local index_attach = index_attach_factory()

  -- attempt immediate wrapping
  local builtins = try_get_builtins()
  if builtins then
    for name, fn in pairs(builtins) do
      if type(fn) == "function" then
        local wrapped = wrap_builtin(name, fn, index_attach)
        if wrapped then
          builtins[name] = wrapped
        end
      end
    end
    return
  end

  -- fallback: telescope not loaded yet -> register a VimEnter autocmd to retry
  -- this ensures that when telescope plugin is loaded later (typical lazy setups),
  -- builtins are wrapped once.
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      local builtins_late = try_get_builtins()
      if not builtins_late then
        return
      end
      for name, fn in pairs(builtins_late) do
        if type(fn) == "function" then
          local wrapped = wrap_builtin(name, fn, index_attach)
          if wrapped then
            builtins_late[name] = wrapped
          end
        end
      end
    end,
    once = true,
  })
end

return M
