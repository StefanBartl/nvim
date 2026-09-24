---@module 'bindings.mappings.terminal'
--- Terminal-mode keymaps: `<Esc>`/`<C-c>` to leave terminal mode, `<C-h/j/k/l>`
--- so window navigation keeps working from inside a terminal buffer, and
--- `<A-l>` to clear the terminal job's screen.
---
--- `<C-l>` here is window-move-right only. A second `<C-l>` map that sent
--- `clear`/`cls` to the job was dropped — the shell's own `clear` does that.
--- `<A-l>` below is the replacement for that use case, terminal-mode only so
--- it can't collide with filetree.nvim's normal-mode `<A-l>` explorer toggle.

local M = {}

---@return nil
function M.setup()
  local map = require("lib.nvim.bindings.keymap")
  map("t", "<Esc>", "<C-\\><C-n>", { desc = "[Terminal] Exit terminal mode" })
  map("t", "<C-c>", "<C-\\><C-n>", { desc = "[Terminal] Exit terminal mode" })

  -- Window movement
  map("t", "<C-h>", "<C-\\><C-w>h", { desc = "[Terminal] Left" })
  map("t", "<C-l>", "<C-\\><C-w>l", { desc = "[Terminal] Right" })
  map("t", "<C-j>", "<C-\\><C-w>j", { desc = "[Terminal] Down" })
  map("t", "<C-k>", "<C-\\><C-w>k", { desc = "[Terminal] Up" })

  -- Clear the shell's screen without leaving insert/terminal mode.
  map("t", "<A-l>", function()
    local term_id = vim.b.terminal_job_id
    if term_id then
      local env = require("lib.nvim.system.env")
      local cmd = env.get().is_windows and "cls" or "clear"
      vim.fn.chansend(term_id, { cmd, "" })
    end
  end, { desc = "[Terminal] Clear screen" })

  map({ "n", "t" }, "<A-h>", function()
    -- Was nvchad.term.toggle({ pos = "float", ... }) -- NvChad is gone
    -- (ui.nvim roadmap step 7), snacks.nvim's own terminal module is this
    -- host's already-installed equivalent. `pcall(require, "snacks")` rather
    -- than the bare global, same as autocmds/explorer-singleton.lua's own
    -- Snacks.picker call sites.
    local ok, Snacks = pcall(require, "snacks")
    if ok and Snacks.terminal then
      -- snacks.nvim's own "terminal"/"float" window styles (snacks/
      -- terminal.lua, snacks/win.lua) set no border at all -- explicit here
      -- rather than relying on `vim.o.winborder`, so this float looks the
      -- same regardless of that global option.
      --
      -- `keys.term_normal = false` disables snacks' own buffer-local
      -- terminal-mode `<Esc>` (snacks/terminal.lua's default style key):
      -- that one only leaves terminal mode on a DOUBLE `<Esc>` within
      -- 200ms and, being buffer-local, wins over our global `<Esc>` map
      -- above -- a single `<Esc>` looked like it did nothing at all.
      -- Disabling it here lets our global map handle `<Esc>` normally, so
      -- one press reaches Terminal-Normal mode for cursor/selection use.
      Snacks.terminal.toggle(nil, {
        win = {
          position = "float",
          border = "rounded",
          keys = { term_normal = false },
        },
      })
    end
  end, { desc = "[Term] Toggle floating" })
end

return M
