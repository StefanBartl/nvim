---@module 'plugins.ai'

---@type LazyPluginSpec[]
return {
  {
    "robitx/gp.nvim",
    lazy = true,
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    config = function()
      local conf = require("config.gp_config.config")
      require("gp").setup(conf)
    end,
  },

  --- ==== COPILOT ===
  -- required: Copilot LSP installed via Mason or system and on PATH
  {
    "copilotlsp-nvim/copilot-lsp",
    init = function()
      vim.g.copilot_nes_debounce = 500
      vim.lsp.enable("copilot_ls")
      vim.keymap.set("n", "<Tab>", function()
        local bufnr = vim.api.nvim_get_current_buf()
        local state = vim.b[bufnr] and vim.b[bufnr].nes_state
        local nes_ok, nes = pcall(require, "copilot-lsp.nes")
        if nes_ok and state then
          -- Try to walk to start or apply and walk to end.
          local ok1 = nes.walk_cursor_start_edit()
          if not ok1 then
            if nes.apply_pending_nes() then
              nes.walk_cursor_end_edit()
            end
          end
          return nil
        else
          -- fallback: return normal <C-i> behaviour in Normal mode
          return "<C-i>"
        end
      end, { expr = true, desc = "Accept Copilot NES suggestion (safe)" })
    end,
  },

  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      "copilotlsp-nvim/copilot-lsp", -- (optional) for NES functionality
    },
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        panel = { enabled = true },
        suggestion = {
          enabled = true,
          auto_trigger = true,
          hide_during_completion = true,
          debounce = 75,
          trigger_on_accept = true,
          keymap = {
            accept = "<M-a>",
            accept_word = false,
            accept_line = false,
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<M-d>",
          },
        },
      })

      vim.keymap.set(
        { "i", "n" },
        "<M-x>", -- Alt+s
        [[<Cmd>lua require("copilot.suggestion").next()<CR>]],
        { noremap = true, silent = true }
      )
    end,
  },

  -- Copilot.vim legacy plugin
  -- {
  --   "github/copilot.vim",
  --   event = "InsertEnter",
  --   config = function()
  --     vim.api.nvim_set_var("copilot_no_tab_map", true)
  --   end,
  -- },
}
