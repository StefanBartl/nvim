---@module 'configs.nvimtree'
---@brief on_attach function for nvim-tree with default mappings and custom file opener

--- Open the current node in Nautilus file manager
---@param node table|nil
local function open_in_nautilus(node)
  node = node or require("nvim-tree.lib").get_node_at_cursor()
  if not node or not node.absolute_path then
    vim.notify("Could not determine path", vim.log.levels.ERROR)
    return
  end

  local path = node.absolute_path
  if node.type == "file" then
    path = vim.fn.fnamemodify(path, ":h")
  end

  vim.fn.jobstart({ "nautilus", path }, { detach = true })
end

--- Custom on_attach callback for nvim-tree
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

  -- Default mappings
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
    if node and node.type == "file" then
      local open_cmd = vim.fn.has("mac") == 1 and "open"
          or vim.fn.has("unix") == 1 and "xdg-open"
          or nil
      if open_cmd then
        vim.fn.jobstart({ open_cmd, node.absolute_path }, { detach = true })
      else
        vim.notify("No suitable open command found", vim.log.levels.ERROR)
      end
    else
      vim.notify("Node is not a file", vim.log.levels.WARN)
    end
  end, opts("Open in system default app"))

  -- Open in Nautilus
  vim.keymap.set("n", "<leader>on", function()
    open_in_nautilus()
  end, opts("Open in Nautilus"))
end

-- Setup nvim-tree
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
