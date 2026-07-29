---@module 'bindings.mappings.harpoon'
--- Harpoon keymaps. Every mapping is a thin wrapper around config.harpoon.api,
--- i.e. the exact same entry point `:Harpoon <sub>` dispatches to — each
--- mapping's `desc` names its command equivalent, so the two never drift.

local notify = require("lib.nvim.notify").create("[bindings.mappings.harpoon]")

local M = {}

function M.setup()
  local map = vim.g.__map_helper
  local ok_hp, harpoon = pcall(require, "harpoon")
  if not ok_hp or not harpoon then
    notify.warn("[harpoon] not installed")
    return
  end
  -- ONE global harpoon list, shared across every project/cwd. Harpoon2 keys
  -- its lists by `settings.key()`, defaulting to the raw `vim.loop.cwd()` — so
  -- out of the box every directory gets its own list and the quick menu looks
  -- empty whenever the cwd differs from where marks were added. We pin the key
  -- to a single constant (config.harpoon.persist_paths.PINS_KEY, =
  -- stdpath("config")), which is also the bucket the persistent default paths
  -- are seeded into, so `<C-e>` always shows the same list everywhere and the
  -- pins are always present.
  local PINS_KEY = require("config.harpoon.persist_paths").PINS_KEY
  local settings = {
    save_on_change = true,
    save_on_toggle = true,
    key = function()
      return PINS_KEY
    end,
  }
  -- Safe setup: enable immediate persistence on every change.
  -- In Harpoon v2, this writes to storage on add/remove/toggle operations.
  pcall(function()
    -- Both method-style and function-style setup are supported in the wild.
    if type(harpoon.setup) == "function" then
      local info = debug.getinfo(harpoon.setup, "u")
      if info and info.nparams and info.nparams >= 2 then
        harpoon:setup({ settings = settings })
      else
        harpoon.setup({ settings = settings })
      end
    end
  end)

  local api = require("config.harpoon.api")

  map("n", "<leader>h", function()
    api.add(nil)
  end, { desc = "[HARPOON] Add current file at the end (:Harpoon add)" })

  map("n", "<leader>H", function()
    api.add(nil, { front = true })
  end, { desc = "[HARPOON] Add current file at the top (:Harpoon add --front)" })

  map("n", "<C-e>", function()
    api.menu("default")
  end, { desc = "[HARPOON] Open harpoon window (:Harpoon menu)" })

  map("n", "<leader>ht", function()
    api.menu("telescope")
  end, { desc = "[HARPOON] Open harpoon window with telescope (:Harpoon menu telescope)" })

  map("n", "<leader>hf", function()
    api.menu("fzf")
  end, { desc = "[HARPOON] Open harpoon window with fzf (:Harpoon menu fzf)" })
end

return M
