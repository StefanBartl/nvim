---@module 'plugins.neotree'

local KEYMAPS = require("config.neotree.keymaps")
local COMMANDS = require("config.neotree.commands")

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "MunifTanjim/nui.nvim",
      {
        "TimCreasman/neo-tree-tests-source.nvim",
        lazy = false, -- Changed from true
        dependencies = { "nvim-neotest/neotest" },
      },
      { "mrbjarksen/neo-tree-diagnostics.nvim" },
    },

    lazy = false,

    opts = function()
      local sources_config = require("config.neotree.init.sources").generate_config({
        icon_family = "nerd",
        icon_variant = "v1",
        name_length = "long",
        enable_diagnostics = true,
        enable_tests = true,
      })

      return vim.tbl_deep_extend("force", sources_config, {
        window = {
          width = 25,
          mappings = KEYMAPS,
        },
        close_if_last_window = false,
        popup_border_style = "rounded",
        sort_case_insensitive = true,
        event_handlers = require("config.neotree.event_handlers"),
        default_component_config = require("config.neotree.init.default_component_config"),
        filesystem = require("config.neotree.keymaps.filesystem"),
        commands = COMMANDS,
      })
    end,
    config = function(_, opts)
      require("config.neotree.actions.find_or_grep_menu").attach(opts)
      require("config.neotree.current_hl").attach(opts)
      require("neo-tree").setup(opts)
      require("config.neotree.components.marks").attach(opts)
      require("config.neotree").setup({
        debug = false,
        default_position = "left",
        restore_last_position = false,
        window_debug = false,
        window_open = false,
        reveal_current_file = false,
        only_lhs = true,
      })
    end,
  },
}
