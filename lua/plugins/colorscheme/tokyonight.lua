---@module 'plugins.colorscheme.tokyonight'
--- tokyonight.nvim's lazy.nvim spec: loads eagerly (`lazy = false`,
--- `priority = 1000`) in the storm style, non-transparent, with terminal
--- colors on.
---@type LazyPluginSpec[]

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "storm", -- "storm", "night", "moon", "day"
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
      },
      on_colors = function(colors)
        -- Kräftigere Farben
        colors.blue = "#7aa2f7"
        colors.cyan = "#7dcfff"
        colors.green = "#9ece6a"
        colors.orange = "#ff9e64"
        colors.purple = "#bb9af7"
        colors.red = "#f7768e"
        colors.yellow = "#e0af68"
        colors.magenta = "#bb9af7"
        colors.teal = "#1abc9c"
      end,
      on_highlights = function(hl, colors)
        -- TODO-Comments mit kräftigen Farben
        hl.TodoBgFIX = { bg = colors.red, fg = colors.black, bold = true }
        hl.TodoFgFIX = { fg = colors.red, bold = true }
        hl.TodoSignFIX = { fg = colors.red, bold = true }

        hl.TodoBgTODO = { bg = colors.blue, fg = colors.black, bold = true }
        hl.TodoFgTODO = { fg = colors.blue, bold = true }
        hl.TodoSignTODO = { fg = colors.blue, bold = true }

        hl.TodoBgWARN = { bg = colors.orange, fg = colors.black, bold = true }
        hl.TodoFgWARN = { fg = colors.orange, bold = true }
        hl.TodoSignWARN = { fg = colors.orange, bold = true }

        hl.TodoBgNOTE = { bg = colors.green, fg = colors.black, bold = true }
        hl.TodoFgNOTE = { fg = colors.green, bold = true }
        hl.TodoSignNOTE = { fg = colors.green, bold = true }

        hl.TodoBgHACK = { bg = colors.purple, fg = colors.black, bold = true }
        hl.TodoFgHACK = { fg = colors.purple, bold = true }
        hl.TodoSignHACK = { fg = colors.purple, bold = true }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight-storm")
    end,
  },
}
