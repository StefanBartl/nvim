---@module 'config.neotree.actions.save.node_buffer'
---Helper to force-save the buffer that corresponds to the neo-tree node under cursor
---Only saves if:
---  - the node is a file (not a directory)
---  - the file is already open in a normal, writable buffer

local buffer = require("config.neotree.utils.buffer")

---Returns the absolute file path of the neo-tree node under cursor
---or nil if the cursor is not on a file node
---@return string|nil
local function get_node_file_path()
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if not ok then
    return nil
  end

  local state = manager.get_state("filesystem")
  if not state or not state.tree then
    return nil
  end

  local node = state.tree:get_node()
  if not node then
    return nil
  end

  -- Skip directories explicitly
  if node.type ~= "file" then
    return nil
  end

  return node.path
end

---Force-save the buffer that matches the neo-tree node under cursor
---Does nothing if the file is not already open in a buffer
---@return nil
return function()
  local target_path = get_node_file_path()
  if not target_path then
    return
  end

  local buffers = vim.api.nvim_list_bufs()
  for i = 1, #buffers do
    local bufnr = buffers[i]

    -- ✅ Korrekt: Nutze buffer.is_valid_file_buffer für Validierung
    if buffer.is_valid_file_buffer(bufnr) then
      local buf_path = vim.api.nvim_buf_get_name(bufnr)

      -- Exact path match
      if buf_path == target_path then
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd("w!")
        end)
        return
      end
    end
  end

  -- No matching open buffer → do nothing silently
end
