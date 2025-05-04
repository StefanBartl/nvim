--- @module nvim_tree_on_attach
--- @brief on_attach function for nvim-tree with default mappings and custom file opener
--- @param bufnr integer buffer number of the nvim-tree window

local function on_attach(bufnr)
  ---@type nvim-tree.api
  local api = require("nvim-tree.api")

  --- Helper function to build consistent keymap options
  ---@param desc string description of the keybinding
  ---@return table<string, any> keymap options
  local function opts(desc)
    return {
      desc = "nvim-tree: " .. desc,
      buffer = bufnr,
      noremap = true,
      silent = true,
      nowait = true,
    }
  end

  -- Load default nvim-tree mappings
  api.config.mappings.default_on_attach(bufnr)

  -- Keymap: Change root to node under cursor (directory or parent of file)
  vim.keymap.set("n", "<C-]>", function()
    local node = api.tree.get_node_under_cursor()
    if node then
      api.tree.change_root_to_node(node)
    end
  end, opts("Change root to node under cursor"))

  -- Keymap: Open file with system default application (Linux/macOS only)
  vim.keymap.set("n", "o", function()
    local node = api.tree.get_node_under_cursor()

    if node and node.type == "file" then
      -- Determine appropriate open command for current OS
      ---@type string|nil
      local open_cmd = vim.fn.has("mac") == 1 and "open"
          or vim.fn.has("unix") == 1 and "xdg-open"
          or nil

      if open_cmd then
        -- Run open command asynchronously and detached
        vim.fn.jobstart({ open_cmd, node.absolute_path }, { detach = true })
      else
        vim.notify("No supported open command found", vim.log.levels.ERROR)
      end
    else
      vim.notify("Not a valid file node", vim.log.levels.ERROR)
    end
  end, opts("Open file with system default application"))
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
})
