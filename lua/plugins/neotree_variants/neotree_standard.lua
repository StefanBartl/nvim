---Neo-tree plugin specification including key mappings for window toggling
---using different positions (current, float, left, right).

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",

    -- Neo-tree dependencies required for async operations, UI components,
    -- and optional file-type icons.
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },

    -- Neo-tree manages its own lazy-loading internally.
    lazy = false,

    -- Key mappings are declared directly in the plugin spec so that
    -- lazy.nvim can register them early and display proper descriptions.
    keys = {
      {
        "<M-c>",
        function()
          -- Toggle Neo-tree in the current window position.
          require("neo-tree.command").execute({
            toggle = true,
            position = "current",
          })
        end,
        desc = "[Neo-tree] Toggle window (current)",
      },
      {
        "<M-f>",
        function()
          -- Toggle Neo-tree as a floating window.
          -- Float windows are managed separately from split positions.
          require("neo-tree.command").execute({
            toggle = true,
            position = "float",
          })
        end,
        desc = "[Neo-tree] Toggle window (float)",
      },
      {
        "<M-l>",
        function()
          -- Toggle Neo-tree in a left-side vertical split.
          require("neo-tree.command").execute({
            toggle = true,
            position = "left",
          })
        end,
        desc = "[Neo-tree] Toggle window (left)",
      },
      {
        "<M-r>",
        function()
          -- Toggle Neo-tree in a right-side vertical split.
          require("neo-tree.command").execute({
            toggle = true,
            position = "right",
          })
        end,
        desc = "[Neo-tree] Toggle window (right)",
      },
    },
  },
}

