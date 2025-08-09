---@module 'configs.nvimtree_config'
---@brief on_attach function for nvim-tree with default mappings and custom file opener

local function open_in_filemanager(node)
  node = node or require("nvim-tree.lib").get_node_at_cursor()
  if not node or not node.absolute_path then
    vim.notify("Could not determine path", vim.log.levels.ERROR)
    return
  end

  local path = node.absolute_path
  if node.type == "file" then
    path = vim.fn.fnamemodify(path, ":h")
  end

  local ok = require("utils.system_filemanager").open_dir(path)
  if not ok then
    vim.notify("Opening in file manager failed", vim.log.levels.ERROR)
  end
end

---@param bufnr integer
local function on_attach(bufnr)
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
    local api = require("nvim-tree.api")
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
    open_in_filemanager()
  end, opts("Open in file manager"))
end

require("nvim-tree").setup({
  on_attach = on_attach,
  view = {
    width = 30,
    side = "left",
    relativenumber = false,
  },
  renderer = {
    highlight_git = true,
    icons = {
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
      },
    },
  },
  filters = {
    dotfiles = false,
  },
  trash = {
    cmd = "trash",
    require_confirm = true,
  },
})
