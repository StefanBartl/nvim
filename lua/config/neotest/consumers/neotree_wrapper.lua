---@module 'config.neotest.consumers.neotree_wrapper'
---@brief Deferred Neo-tree consumer wrapper to prevent race conditions

---@type function|nil
local _real_consumer = nil

--- Lazy consumer factory that defers execution until Neotest client is ready
---@param client NeoTest.Client
---@return table
local function create_consumer(client)
  -- Prevent double-initialization
  if _real_consumer then
    return _real_consumer(client)
  end

  -- Load real consumer lazily
  local ok, neotree_consumer = pcall(require, "neotest.consumers.neotree")
  if not ok then
    vim.notify(
      "[neotest.consumers.neotree_wrapper] Failed to load neo-tree consumer",
      vim.log.levels.ERROR
    )
    return {}
  end

  -- Cache consumer factory
  _real_consumer = neotree_consumer

  -- Call with client
  return neotree_consumer(client)
end

return create_consumer
