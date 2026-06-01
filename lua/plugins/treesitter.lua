---@module 'plugins.treesitter'
---@brief Treesitter plugin spec – extends NvChad's base config via opts-merge.
--- No `config` override: NvChad owns the configs.setup() call.
--- This spec only adds parsers, textobjects and context on top.

return {
  -- =========================================================================
  -- Core: extend NvChad's treesitter spec via opts merge
  -- opts = function(_, opts) receives NvChad's already-merged opts as second
  -- argument, so we never stomp on what NvChad configured.
  -- =========================================================================
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/nvim-treesitter-context",
    },
    opts = function(_, opts)
      -- -----------------------------------------------------------------------
      -- Parser list: merge our list into NvChad's ensure_installed
      -- -----------------------------------------------------------------------
      local ok_parser, parser_list = pcall(require, "config.treesitter.parser")

      opts.ensure_installed = opts.ensure_installed or {}
      if ok_parser and type(parser_list) == "table" then
        vim.list_extend(opts.ensure_installed, parser_list)
      end

      -- -----------------------------------------------------------------------
      -- Highlight (NvChad sets this already; only override if you must)
      -- -----------------------------------------------------------------------
      opts.highlight = opts.highlight or {}
      opts.highlight.enable                            = true
      opts.highlight.additional_vim_regex_highlighting = false

      -- -----------------------------------------------------------------------
      -- Indent
      -- -----------------------------------------------------------------------
      opts.indent = { enable = true }

      -- -----------------------------------------------------------------------
      -- Textobjects
      -- -----------------------------------------------------------------------
      opts.textobjects = {
        select = {
          enable    = true,
          lookahead = true,
          keymaps   = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
          },
        },
      }

      return opts
    end,
    -- No `config` key here – NvChad's config function runs configs.setup(opts)
  },

  -- =========================================================================
  -- Context: separate spec so it never interferes with the core setup
  -- =========================================================================
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts  = {
      enable    = true,
      max_lines = 3,
    },
  },
}
