---@module 'bindings.mappings.telescope'
--- Centralized Telescope-related key mappings.
---
--- This module defines all Telescope and Telescope-extension mappings
--- in a single place to keep plugin specifications minimal and declarative.

local M = {}

--- Register Telescope-related key mappings.
--- Assumes a global keymap helper is available.
---@return nil
function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  -- Telescope's own picker-of-pickers meta UI: no pickers.nvim equivalent
  -- (nothing there lists "every picker"), stays a direct call.
  map("n", "<leader>ts", ":Telescope<CR>", { desc = "[Telescope] UI" })
  -- Grep with an own prompt first, then pickers.nvim's live grep in the cwd,
  -- seeded with what was typed (engine-agnostic: pickers.nvim picks telescope /
  -- fzf-lua / snacks). Telescope's grep_string only when pickers.nvim is absent.
  map("n", "<leader>tg", function()
    require("lib.nvim.ui.kit").input({
      title = "Grep > ",
      on_submit = function(query)
        local ok, command = pcall(require, "pickers.command")
        if ok then
          command.handle({ fargs = { "cwd", "grep" }, query = query })
          return
        end
        local ok_tb, tb = pcall(require, "telescope.builtin")
        if ok_tb then
          tb.grep_string({ search = query })
        end
      end,
    })
  end, { desc = "[Pickers] Grep (own prompt)" })

  -- Tabbed search (was search.nvim): Files / All Files / Grep / Buffers, cycled with
  -- <Tab>/<S-Tab> inside the picker, the typed query travelling along. Groups:
  -- pickers.nvim `tabs` in plugins/personal/specs/navigate.lua.
  map(
    "n",
    "<leader>s",
    "<cmd>Pickers tabs default<CR>",
    { desc = "[Pickers] Tabbed search (files/all/grep/buffers)" }
  )

  -- <leader>fa moved to pickers.nvim's own opt-in `keymaps.cwd_find_all`
  -- (plugins/personal/specs/navigate.lua): `:Pickers cwd files all` forces
  -- the same hidden+no_ignore+follow flags, engine-agnostic instead of
  -- telescope-only (2026-10-01, externe-plugins report §9.2).

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
