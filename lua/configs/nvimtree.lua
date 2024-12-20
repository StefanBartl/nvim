local function on_attach(bufnr)
  local api = require("nvim-tree.api")

  -- Standard Keymaps (kann erweitert werden)
  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  -- Finder öffnen (Mapping "f")
  vim.keymap.set("n", "f", function()
    local node = require("nvim-tree.api").tree.get_node_under_cursor()
    local path = node and node.absolute_path or vim.fn.getcwd()
    vim.fn.jobstart({ "open", path }, { detach = true })
  end, opts("Open Finder in current directory"))

  -- Datei mit Standardanwendung öffnen (Mapping "o")
  vim.keymap.set("n", "o", function()
    local node = api.tree.get_node_under_cursor()
    if node and node.type == "file" then
      vim.fn.jobstart({ "open", node.absolute_path }, { detach = true })
    else
      vim.notify("Not a valid file to open", vim.log.levels.ERROR)
    end
  end, opts("Open file with default application"))
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
