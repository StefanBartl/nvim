--- @module nvim_tree_on_attach
--- @brief on_attach function for nvim-tree with default mappings and custom file opener
--- @param bufnr integer buffer number of the nvim-tree window



local function open_in_nautilus(node)
  -- Fallback, falls kein Node übergeben wurde (z. B. Root)
  node = node or require("nvim-tree.lib").get_node_at_cursor()
  if not node or not node.absolute_path then
    vim.notify("Pfad konnte nicht ermittelt werden", vim.log.levels.ERROR)
    return
  end

  -- Bestimme den Pfad: bei Dateien öffne den übergeordneten Ordner
  local path = node.absolute_path
  if node.type == "file" then
    path = vim.fn.fnamemodify(path, ":h")
  end

  -- Öffne Nautilus
  vim.fn.jobstart({ "nautilus", path }, { detach = true })
end






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

  --HACK:
  -- TODO:

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
  vim.keymap.set("n", "]o", function()
    print("huhu")
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


  vim.keymap.set("n", "<leader>on", function()
    local node = require("nvim-tree.lib").get_node_at_cursor()
    open_in_nautilus(node)
  end, opts("Open in Nautilus"))
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
    require_confirm = true
  },
})
