---@module 'bindings.mappings.telescope'
--- Centralized Telescope-related key mappings.
---
--- This module defines all Telescope and Telescope-extension mappings
--- in a single place to keep plugin specifications minimal and declarative.

local M = {}

--- Register Telescope-related key mappings.
--- Assumes a global keymap helper is available.
function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>ts", ":Telescope<CR>", { desc = "[Telescope] UI" })
  map("n", "<leader>tg", function()
    local ok, tb = pcall(require, "telescope.builtin")
    if not ok then
      return
    end

    tb.grep_string({ search = vim.fn.input("Grep > ") })
  end, { desc = "[Telescope] Grep" })
  -- map("n", "<leader><leader>", "<cmd>Telescope live_grep<CR>", { desc = "[Telescope] Live Grep" })
  -- map("n", "<leader>fk", "<cmd>Telescope keymaps<CR>", { desc = "[Telescope] Find keymaps" })
  -- map("n", "<leader>com", "<cmd>Telescope commands<CR>", { desc = "[Telescope] Commands" })
  -- map("n", "<leader>col", "<cmd>Telescope colorscheme<CR>", { desc = "[Telescope] Colorscheme" })
  -- map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "[Telescope] Find Files" })
  -- map("n", "<leader>help", "<cmd>Telescope help_tags<CR>", { desc = "[Telescope] Help" })
  -- map("n", "<leader>cb", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "[Telescope] In Buffer" })
  -- map("n", "<leader>bu", "<cmd>Telescope buffers<CR>", { desc = "[Telescope] Buffers" })
  -- map("n", "<leader>old", "<cmd>Telescope oldfiles<CR>", { desc = "[Telescope] Oldfiles" })

  map(
    "n",
    "<leader>fa",
    "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
    { desc = "[Telescope] Find All Files" }
  )

  ---==== Telescope file browser extension mappings =====---

  map("n", "<leader>,", function()
    local ok, telescope = pcall(require, "telescope")
    if not ok then
      return
    end

    pcall(telescope.load_extension, "file_browser")
    telescope.extensions.file_browser.file_browser()
  end, { desc = "[Telescope] File Browser (at current file)" })

  map("n", "<leader>.", function()
    local ok, telescope = pcall(require, "telescope")
    if not ok then
      return
    end

    pcall(telescope.load_extension, "file_browser")
    telescope.extensions.file_browser.file_browser({
      path = vim.loop.cwd(),
    })
  end, { desc = "[Telescope] File Browser (at CWD)" })
end

return M
