---@module 'plugins.treesitter'
---@brief Modern Treesitter setup (Neovim 0.12+, no deprecated install API)

return {
  ---------------------------------------------------------------------------
  -- Core Treesitter
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",

    lazy = false,

    build = ":TSUpdate",

    config = function()
      -----------------------------------------------------------------------
      -- Guard module
      -----------------------------------------------------------------------
      local guards = require("lib.nvim.treesitter.guard")

      -----------------------------------------------------------------------
      -- Highlight activation
      -----------------------------------------------------------------------
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          if guards.is_enabled(args.buf) then
            vim.treesitter.start(args.buf)
          end
        end,
      })

      -----------------------------------------------------------------------
      -- Folding
      -----------------------------------------------------------------------
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          if guards.is_enabled(args.buf) then
            vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
            vim.wo.foldmethod = "expr"
          end
        end,
      })

      -----------------------------------------------------------------------
      -- Indentation (experimental)
      -----------------------------------------------------------------------
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          if guards.is_enabled(args.buf) then
            vim.bo[args.buf].indentexpr =
              "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- Textobjects
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    lazy = false,
  },

  ---------------------------------------------------------------------------
  -- Context (sticky code context window)
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter-context",

    event = "BufReadPost",

    opts = {
      enable = true,
      max_lines = 3,
    },
  },
}
