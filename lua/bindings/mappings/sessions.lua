---@module 'bindings.mappings.sessions'
--- sessions.nvim's marks keymaps, deferred to UIReady like every other
--- module `bindings.mappings.setup()` pulls in -- rather than the eager
--- `opts`/`config` sessions.nvim's own lazy.nvim spec runs at
--- (plugins/personal/specs/navigate.lua), which is on the synchronous startup path
--- this config otherwise keeps keymap registration off of (see init.lua's
--- UIReady phases). That spec sets `keymaps = false` to skip sessions.nvim's
--- own (also eager) auto-attach; this module calls the same attach function
--- itself, from here, replacing harpoon's old bindings/mappings/harpoon.lua
--- (external-plugins report, 7.4).
---
--- `<C-e>` (quick menu) and `<M-1>`..`<M-9>` (full-screen preview) are
--- harpoon's old bindings for the same actions -- bound directly rather
--- than through `keymaps`/`marks.preview_key`, since mixing them into that
--- table would give sessions.nvim's which-key group-prefix detection a set
--- of lhs with no common prefix (`<leader>h*` alongside `<C-e>` and
--- `<M-%d>`), losing the "Session" group label on `<leader>h` entirely, not
--- just for those two keys.

local M = {}

---@return nil
function M.setup()
  require("sessions.bindings.keymaps").attach({
    marks_menu = "<leader>hm",
    -- Capitalized, not `<leader>he`: that would be a strict prefix of the
    -- already-bound `<leader>help` (plugins/personal/specs/navigate.lua pickers `mappings`),
    -- forcing a `timeoutlen` wait on every press before Neovim can tell the
    -- two apart. Same bug class as the `<leader>ffk`/`<leader>ff` collision
    -- fixed in bindings/mappings/fzf.lua -- same fix, capitalize to break it.
    marks_edit = "<leader>hE",
    marks_add = "<leader>ha",
    marks_add_front = "<leader>hA",
    marks_pin = "<leader>hp",
    marks_remove = "<leader>hd",
    marks_sync = "<leader>hs",
    marks_debug = "<leader>hD",
  }, true)

  local map = require("lib.nvim.bindings.keymap")
  map.set("n", "<C-e>", "<cmd>Session marks<cr>", { desc = "[Session] Open marks menu" })
  -- Bound directly, same reasoning as <C-e>/<M-%d> above: this shares no
  -- prefix with the marks table's <leader>h*, and mixing it into that
  -- attach() call would lose the "Session" which-key group label for ALL
  -- of them, not just this one.
  --
  -- NOT <leader>sc: found live (adversarial review) that it is a strict
  -- prefix of the already-bound <leader>s (plugins/telescope.lua, search.nvim's
  -- tabbed UI) -- forcing a full timeoutlen wait on every plain <leader>s
  -- press before Neovim could tell the two apart. Same bug class as the
  -- <leader>ffk/<leader>ff and <leader>hE/<leader>help fixes elsewhere in
  -- this config. <M-s> ("session") shares no prefix with anything and is
  -- already deliberately kept a no-op inside neo-tree's own buffer-local
  -- keymaps (lua/config/neotree/keymaps/*.lua) -- this buffer-local noop
  -- still wins over this global mapping while focus is inside a neo-tree
  -- window, so the toggle is a no-op there specifically, same tradeoff
  -- <C-e>/<M-%d> above already accept for their own hardcoded keys.
  map.set(
    "n",
    "<M-s>",
    "<cmd>Session chip-toggle<cr>",
    { desc = "[Session] Toggle chip visibility" }
  )
  for i = 1, 9 do
    map.set(
      "n",
      ("<M-%d>"):format(i),
      ("<cmd>Session marks preview %d<cr>"):format(i),
      { desc = ("[Session] Preview mark %d (full screen)"):format(i) }
    )
  end
end

return M
