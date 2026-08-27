---@module 'bindings.mappings.harpoon'
--- Harpoon keymaps, declared as ONE which-key spec (`wk.add` shape) that is
--- both the source for the real keymaps and what which-key is handed.
---
--- Two rules hold by construction here:
---   1. Every mapping's rhs is a `:Harpoon …` call, so no keymap can exist
---      without a user-command equivalent — the command IS the mapping.
---   2. Nothing in this file force-loads which-key (it is lazy, triggered by
---      `<leader>`): the mappings are created right away with the plain map
---      helper, and the spec goes to `wk.add` only once which-key is loaded
---      anyway — which is all the "Harpoon" group label needs, since which-key
---      reads the `desc` of existing keymaps by itself.
---
--- Commands live in config.harpoon.usrcmds, their implementation in
--- config.harpoon.api.

local notify = require("lib.nvim.notify").create("[bindings.mappings.harpoon]")

local M = {}

--- which-key spec: `{ lhs, rhs, desc = … }` entries plus the group label.
--- Passed verbatim to `wk.add()`.
---@type table[]
M.spec = {
  { "<leader>h", group = "Harpoon" },

  { "<leader>ha", "<cmd>Harpoon add<cr>", desc = "[HARPOON] Add current file (end of list)" },
  {
    "<leader>hA",
    "<cmd>Harpoon add --front<cr>",
    desc = "[HARPOON] Add current file (top of list)",
  },
  {
    "<leader>hp",
    "<cmd>Harpoon add --front --permanent<cr>",
    desc = "[HARPOON] Add current file permanently (top, pinned default)",
  },
  { "<leader>hd", "<cmd>Harpoon remove<cr>", desc = "[HARPOON] Remove current file from the list" },

  { "<leader>hm", "<cmd>Harpoon menu<cr>", desc = "[HARPOON] Open quick menu" },
  { "<leader>ht", "<cmd>Harpoon menu telescope<cr>", desc = "[HARPOON] Open list in telescope" },
  { "<leader>hf", "<cmd>Harpoon menu fzf<cr>", desc = "[HARPOON] Open list in fzf" },

  { "<leader>hs", "<cmd>Harpoon defaults sync<cr>", desc = "[HARPOON] Sync missing default paths" },
  { "<leader>hD", "<cmd>Harpoon debug<cr>", desc = "[HARPOON] Dump the current list" },

  { "<C-e>", "<cmd>Harpoon menu<cr>", desc = "[HARPOON] Open quick menu" },
}

-- Alt+1 … Alt+9: full-screen preview of entry N ('q' closes).
for i = 1, 9 do
  M.spec[#M.spec + 1] = {
    ("<M-%d>"):format(i),
    ("<cmd>Harpoon preview %d<cr>"):format(i),
    desc = ("[HARPOON] Preview entry %d (full screen)"):format(i),
  }
end

---Hand the spec to which-key, but only if it happens to be loaded already.
---@return boolean ok  false when which-key is not loaded (or has no `add`)
local function add_to_which_key()
  -- Deliberately `package.loaded` and not `pcall(require, …)`: requiring would
  -- LOAD which-key here, which is exactly what this file must not do.
  if not package.loaded["which-key"] then
    return false
  end
  local wk = require("which-key")
  if type(wk.add) ~= "function" then
    return false
  end
  wk.add(M.spec)
  return true
end

---Create the mappings without which-key, from the same spec.
---@param map fun(mode: string, lhs: string, rhs: string, opts: table)
---@return nil
local function map_plain(map)
  for _, entry in ipairs(M.spec) do
    if not entry.group then
      map("n", entry[1], entry[2], { desc = entry.desc, silent = true })
    end
  end
end

---Hand the spec over as soon as which-key loads (it is lazy, triggered by
---`<leader>`). Without this the mappings still work and still show up —
---which-key reads any keymap's `desc` — but `<leader>h` would be an unnamed
---prefix instead of the "Harpoon" group.
---@return nil
local function register_which_key_when_loaded()
  -- `raw = true`: this callback signals "delete me" by returning true, and
  -- the defensive pcall wrapper would discard that return value -- turning
  -- "fires once, on the LazyLoad event that is which-key.nvim's" into "never
  -- self-deletes, keeps firing on every later LazyLoad too". `raw` skips the
  -- wrapper and still records the autocmd.
  local autocmd = require("lib.nvim.bindings.autocmd")
  autocmd.create("User", function(ev)
    if ev.data ~= "which-key.nvim" then
      return
    end
    add_to_which_key()
    return true -- one-shot: delete this autocmd
  end, {
    group = autocmd.group("HarpoonWhichKey", true),
    pattern = "LazyLoad",
    raw = true,
    desc = "Register the Harpoon which-key group once which-key loads",
  })
end

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

  -- The keymaps are always created here, never left to which-key: `wk.add`
  -- only files the spec into which-key's own tree (verified against the
  -- pinned version — no `vim.keymap.set` happens), so relying on it would
  -- leave the mappings nonexistent whenever which-key is absent or lazy.
  -- which-key then contributes the group label on top.
  map_plain(map)

  if not add_to_which_key() then
    register_which_key_when_loaded()
  end
end

return M
