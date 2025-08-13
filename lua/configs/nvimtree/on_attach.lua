---@module 'configs.nvimtree.on_attach'

---@param bufnr integer
---@return nil
return function(bufnr)
  ---@type table
  local api = require("nvim-tree.api")

  --- Helper to standardize keymap options
  ---@param desc string
  local function opts(desc)
    return {
      desc = "nvim-tree: " .. desc,
      buffer = bufnr,
      noremap = true,
      silent = true,
      nowait = true,
    }
  end

  api.config.mappings.default_on_attach(bufnr)

  -- Change root
  vim.keymap.set("n", "<C-]>", function()
    local node = api.tree.get_node_under_cursor()
    if node then
      api.tree.change_root_to_node(node)
    end
  end, opts("Change root to node"))

  -- Open in system app
  vim.keymap.set("n", "]o", function()
    local node = api.tree.get_node_under_cursor()
    if not node or node.type ~= "file" then
      vim.notify("Node is not a file", vim.log.levels.WARN)
      return
    end

    if vim.fn.filereadable(node.absolute_path) ~= 1 then
      vim.notify("File not readable: " .. node.absolute_path, vim.log.levels.ERROR)
      return
    end

    local ok = require("lua.system.open").open(node.absolute_path)
    if not ok then
      vim.notify("Open command failed", vim.log.levels.ERROR)
    end
  end, opts("Open in system default app"))

    vim.keymap.set("n", "<leader>on", function()
      require("configs.nvimtree.open_in_fm").open_in_filemanager()
    end, { desc = "Open in file manager", buffer = bufnr, noremap = true, silent = true, nowait = true})
    api.config.mappings.default_on_attach(bufnr) -- context menu entry

end
