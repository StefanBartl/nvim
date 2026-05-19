return {
  -- 1. nvim-treesitter (Das Haupt-Plugin)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    -- Wir laden die Erweiterungen als direkte Abhängigkeiten
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/nvim-treesitter-context",
    },
    opts = function()
      -- Sicherer Import der Parser-Liste
      local ok_parser, parser_list = pcall(require, "config.treesitter.parser")

      return {
        ensure_installed = ok_parser and parser_list or { "c_sharp", "lua", "vim", "vimdoc", "rust", "go" },
        highlight = {
          enable = true,
          use_languagetree = true,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
        -- Textobjects Konfiguration direkt hier rein
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
        },
      }
    end,
    config = function(_, opts)

-- Wir nutzen pcall, damit Neovim nicht hart crasht,
      -- falls das Plugin im ersten Moment noch nicht "da" ist.
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if ok then
        configs.setup(opts)
      else
        -- Falls es fehlschlägt, geben wir eine Warnung aus,
        -- aber lassen Neovim weiterlaufen.
        vim.notify("Treesitter konnte noch nicht geladen werden. Starte Neovim ggf. neu.", vim.log.levels.WARN)
      end


      -- Treesitter Context hier drin initialisieren, um Sicherzugehen
      local ok_context, context = pcall(require, "treesitter-context")
      if ok_context then
        context.setup({
          enable = true,
          max_lines = 3, -- optional: begrenzt die Anzeige oben
        })
      end
    end,
  },
}