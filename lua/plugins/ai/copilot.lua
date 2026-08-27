---@module 'plugins.ai.copilot'

-- local notify = require("lib.nvim.notify").create("[plugins.ai]")

---@type LazyPluginSpec[]
return {
  -- The cmp side of Copilot: hide the inline suggestion while cmp's menu is
  -- open, so the two do not draw over each other.
  --
  -- It lives here rather than with the LSP specs because it is about Copilot
  -- and cmp, not about LSP -- and it is a live fragment rather than a comment
  -- inside the disabled specs below so that it works the moment one of them is
  -- switched back on. Until then it is a no-op: it sets
  -- `vim.b.copilot_suggestion_hidden`, which nothing reads while no Copilot
  -- plugin is installed.
  --
  -- Note the `.setup()`. Until 2026-08-23 this read `require("config.copilot.cmp")`
  -- alone, which loads the module and returns its table without calling
  -- anything -- so the bridge had never actually run.
  {
    "hrsh7th/nvim-cmp",
    opts = function()
      require("config.copilot.cmp").setup()
    end,
  },

  -- required: Copilot LSP installed via Mason or system and on PATH
  -- {
  --   "copilotlsp-nvim/copilot-lsp",
  --   init = function()
  --     vim.g.copilot_nes_debounce = 500
  --     vim.lsp.enable("copilot_ls")
  --     vim.keymap.set("n", "<M-w>", function()
  --       local bufnr = vim.api.nvim_get_current_buf()
  --       local state = vim.b[bufnr].nes_state
  --       if state then
  --         -- Try to jump to the start of the suggestion edit.
  --         -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
  --         local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
  --           or (require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit())
  --         return nil
  --       else
  --         -- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
  --         return "<C-i>"
  --       end
  --     end, { desc = "Accept Copilot NES suggestion", expr = true })
  --   end,
  -- },

  -- {
  -- "zbirenbaum/copilot.lua",
  -- enabled = false,
  -- dependencies = {
  -- "copilotlsp-nvim/copilot-lsp", -- (optional) for NES functionality
  -- },
  -- cmd = "Copilot",
  -- event = "InsertEnter",
  -- config = function()
  -- local copilot = require("copilot")

  -- copilot.setup({
  -- panel = { enabled = true },
  -- suggestion = {
  -- enabled = true,
  -- auto_trigger = true,
  -- hide_during_completion = true,
  -- debounce = 75,
  -- trigger_on_accept = true,
  -- keymap = {
  -- accept = "<M-a>",
  -- accept_word = false,
  -- accept_line = false,
  -- next = "<M-]>",
  -- prev = "<M-[>",
  -- dismiss = "<M-d>",
  -- },
  -- },
  -- })

  -- -- Keymap to navigate suggestions
  -- vim.keymap.set(
  -- { "i", "n" },
  -- "<M-x>",
  -- [[<Cmd>lua require("copilot.suggestion").next()<CR>]],
  -- { noremap = true, silent = true }
  -- )

  -- -- Keymap to toggle Copilot enable/disable
  -- vim.keymap.set("n", "<leader>ct", function()
  -- if copilot.is_enabled() then
  -- copilot.disable()
  -- notify.info("Copilot disabled")
  -- else
  -- copilot.enable()
  -- notify.info("Copilot enabled")
  -- end
  -- end, { noremap = true, silent = true, desc = "Toggle Copilot" })
  -- end,
  -- },

  -- Copilot.vim legacy plugin
  -- {
  --   "github/copilot.vim",
  --   event = "InsertEnter",
  --   config = function()
  --     vim.api.nvim_set_var("copilot_no_tab_map", true)
  --   end,
  -- },
}
