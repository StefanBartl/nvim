---@module 'bindings.mappings.telescope'
--- Centralized Telescope-related key mappings.
---
--- This module defines all Telescope and Telescope-extension mappings
--- in a single place to keep plugin specifications minimal and declarative.

local M = {}

--- Register Telescope-related key mappings.
--- Assumes a global keymap helper is available.
function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  map("n", "<leader>ts", ":Telescope<CR>", { desc = "[Telescope] UI" })
  map("n", "<leader>tg", function()
    local ok, tb = pcall(require, "telescope.builtin")
    if not ok then
      return
    end

    require("lib.nvim.ui.kit").input({
      title = "Grep > ",
      on_submit = function(query)
        tb.grep_string({ search = query })
      end,
    })
  end, { desc = "[Telescope] Grep" })

  map(
    "n",
    "<leader>fa",
    "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
    { desc = "[Telescope] Find All Files" }
  )

  ---==== Telescope file browser extension mappings =====---
  -- <leader>. now belongs to pickers.nvim's own "explorer" builtin
  -- (engine-agnostic, same "at current file" behavior this used to have on
  -- <leader>,). Keeping only the CWD variant here since pickers.builtins
  -- doesn't take a path override with a stable cross-engine opts shape.

  map("n", "<leader>,", function()
    local ok, telescope = pcall(require, "telescope")
    if not ok then
      return
    end

    pcall(telescope.load_extension, "file_browser")
    telescope.extensions.file_browser.file_browser({
      path = vim.uv.cwd(),
    })
  end, { desc = "[Telescope] File Browser (at CWD)" })
end

return M
