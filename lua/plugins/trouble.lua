---@module 'plugins.trouble'
---@brief trouble.nvim plugin specification.

local numbering = require("config.trouble.numbering")

return {
  {
    "folke/trouble.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },

    version = "*",
    lazy = false,

    config = function()
      require("trouble").setup({
        preview = {
          type = "split",
          relative = "win",
          position = "right",
          size = 0.30,
        },

        modes = {
          -- Standard LSP diagnostics
          diagnostics = {
            mode = "diagnostics",

            preview = {
              type = "split",
              relative = "win",
              position = "right",
              size = 0.30,
            },

            formatters = {
              index = numbering.index_prefix(),
              main = "message",
            },
          },

          -- Quickfix list
          qflist = {
            mode = "qflist",

            preview = {
              type = "split",
              relative = "win",
              position = "right",
              size = 0.30,
            },

            formatters = {
              index = numbering.index_prefix(),
              main = "message",
            },
          },

          -- Location list
          loclist = {
            mode = "loclist",

            preview = {
              type = "split",
              relative = "win",
              position = "right",
              size = 0.30,
            },

            formatters = {
              index = numbering.index_prefix(),
              main = "message",
            },
          },
        },
      })


      -- AUDIT:

      -- Patch: trouble.view.treesitter calls TSHighlighter._on_win / _on_line
      -- which are private methods removed or renamed in Neovim 0.12+.
      -- We defer the patch so trouble's own setup() has already run and
      -- registered its decoration provider before we intercept it.
      vim.schedule(function()
        local ok, ts_view = pcall(require, "trouble.view.treesitter")
        if not ok or type(ts_view) ~= "table" then return end

        local TSHighlighter = vim.treesitter.highlighter
        if type(TSHighlighter) ~= "table" then return end

        -- Detect which internal method names actually exist.
        -- Neovim < 0.12 uses _on_win / _on_line directly on the module table.
        -- Neovim >= 0.12 moved them; the highlighter instance carries them
        -- as methods or they were dropped in favour of the decoration API.
        local function resolve_method(primary, fallbacks)
          if type(TSHighlighter[primary]) == "function" then
            return TSHighlighter[primary]
          end
          for _, alt in ipairs(fallbacks) do
            if type(TSHighlighter[alt]) == "function" then
              return TSHighlighter[alt]
            end
          end
          -- Return a no-op so the decoration provider does not crash.
          return function() end
        end

        -- Remap the missing private methods to whatever exists in this
        -- Neovim version, or to a safe no-op.
        TSHighlighter._on_win  = resolve_method("_on_win",  { "on_win",  "_win_start" })
        TSHighlighter._on_line = resolve_method("_on_line", { "on_line", "_on_buf"    })
      end)


      -- END

      -- Spell/grammar checking moved out of the config into the standalone
      -- language.nvim plugin (see lua/plugins/language.lua). Use :Spellcheck.
    end,
  },
}
