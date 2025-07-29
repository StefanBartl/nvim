---@module 'plugins.personal'
--- Personal and local development plugins (myterm, mygrep, cmdlog, etc.)

---@type LazyPluginSpec[]
return {

  -- nvim-containers: Manage container engines from Neovim
  {
    dir = vim.fn.expand("E:\\MyGithub\\nvim-containers"),
    event = "VeryLazy",
    config = function()
      require("containers").setup({})
    end,
  },

  -- nvim-cmdlog: Command history management
  {
    "StefanBartl/nvim-cmdlog",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "ibhagwan/fzf-lua",
    },
    config = function()
      require("cmdlog").setup({
        picker = "telescope",
      })
    end,
  },
  -- Optional: local dev version of cmdlog
  -- {
  --   dir = vim.fn.expand("E:\\MyGithub\\nvim-cmdlog"),
  --   config = function()
  --     require("cmdlog").setup({
  --       picker = "telescope",
  --     })
  --   end,
  -- },

  -- reposcope.nvim: GitHub repo explorer
  {
    dir = vim.fn.expand("E:\\MyGithub\\reposcope.nvim"),
    name = "reposcope",
    event = "VeryLazy",
    config = function()
      require("reposcope.init").setup({})
    end,
  },

  -- myterm.local: Custom terminal interface with layout switching
  {
    name = "myterm.local",
    dir = vim.fn.stdpath("config") .. "\\lua\\custom\\myterm",
    lazy = false,
    config = function()
      require("custom.myterm")
    end,
  },

  -- mygrep.nvim: Grep interface with memory, history, favorites
  {
    dir = vim.fn.expand("E:\\MyGithub\\mygrep.nvim"),
    name = "mygrep",
    lazy = false,
    config = function()
      require("mygrep").setup({
        tool_picker_style = "ui",
      })
    end,
  },

  -- train.nvim: Daily training plugin (motions, treesitter, etc.)
  {
    dir = vim.fn.expand("E:\\MyGithub\\train.nvim"),
    name = "train.nvim",
    cmd = { "Train", "TrainToday" },
    config = function()
      require("nvim-train").setup()
    end,
  },

  -- markdown-toc-view.nvim: TOC viewer for Markdown files
  {
    dir = vim.fn.expand("E:\\MyGithub\\markdown-toc-view"),
    name = "markdown-toc-view.nvim",
    ft = { "markdown" },
    config = function()
      require("markdown_toc_view").setup()
    end,
  },


}

