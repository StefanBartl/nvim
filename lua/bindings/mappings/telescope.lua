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

  -- <leader>ts (":Telescope<CR>", the picker-of-pickers meta UI) left on
  -- 2026-10-01: never used (externe-plugins report §9.2 follow-up).

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

  -- <leader>, (telescope-file-browser.nvim "at CWD") left on 2026-10-01:
  -- never used, same pass as <leader>ts above. <leader>. (pickers.nvim's own
  -- engine-agnostic "explorer" builtin, "at current file") was already the
  -- replacement and is unaffected.
end

return M
