local function on_attach(bufnr)
  local api = require("nvim-tree.api")

  -- Mapping für den Finder (nur im nvim-tree-Buffer)
  vim.keymap.set("n", "f", function()
    local node = api.tree.get_node_under_cursor()
    local path = node and node.absolute_path or vim.fn.getcwd()
    vim.fn.jobstart({ "open", path }, { detach = true })
  end, { buffer = bufnr, desc = "Open Finder in current directory" })

  -- Mapping zum Öffnen von Dateien mit Standardanwendung (nur im nvim-tree-Buffer)
  vim.keymap.set("n", "o", function()
    local node = api.tree.get_node_under_cursor()
    if node and node.type == "file" then
      vim.fn.jobstart({ "open", node.absolute_path }, { detach = true })
    else
      vim.notify("Not a valid file to open", vim.log.levels.ERROR)
    end
  end, { buffer = bufnr, desc = "Open file with default application" })
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
