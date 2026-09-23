---@module 'bindings.mappings.general'
--- Editor-wide keymaps that belong to no plugin: `<C-a>` select all, `<C-s>` save,
--- `jk` to leave insert mode, yank-free `x`/`dw`, plus (moved in from the
--- retired `bindings.mappings.nvchad` 2026-09-13 -- none of it was actually
--- NvChad-specific any more once its one real NvChad feature, the theme
--- picker, moved into `ui.nvim` itself as a configurable keymap) `<Esc>`
--- search-highlight clear, copy-whole-file, format-via-conform, which-key,
--- insert-mode cursor movement, and (moved in from the retired
--- `bindings.mappings.git` 2026-09-22, GS-08 -- the rest of that file's
--- keymaps moved into gitsuite.nvim itself) `<leader>dt`, native
--- `:diffthis`/`:diffoff` for every window in the tab.

local M = {}

---@return nil
function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  map("n", "<C-a>", "gg<S-v>G", { desc = "[General] Select all" })

  map({ "n", "v", "t" }, "<C-s>", function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd("write")

    -- Clamp: the file may be shorter after a save-time formatter ran.
    local last_line = vim.api.nvim_buf_line_count(0)
    if pos[1] > last_line then
      pos[1] = last_line
    end
    pcall(vim.api.nvim_win_set_cursor, 0, pos)
  end, { desc = "[General] Save file" })
  map("i", "<C-s>", function() -- explicit i-mode map so it beats vim.lsp.buf.signature_help()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd("write")

    local last_line = vim.api.nvim_buf_line_count(0)
    if pos[1] > last_line then
      pos[1] = last_line
    end
    pcall(vim.api.nvim_win_set_cursor, 0, pos)
  end, { desc = "[General] Save file", noremap = true })

  map({ "i", "v", "t" }, "jk", "<Esc>", { desc = "[General] Exit to normal mode" })
  map("n", "x", '"_x', { desc = "[Edit] Delete char without yanking" })
  map("n", "dw", 'vb"_d', { desc = "[Edit] Delete word backwards without yanking" })
  map(
    { "n", "i", "v", "t", "c" },
    "<F1>",
    "<Nop>",
    { desc = "[General] Disable F1", silent = true }
  )

  -- Insert today's date as dd.mm.yyyy. buffer-ctx.nvim's :Insert can also
  -- place timestamps, but this is the one-key shortcut for the common case.
  map("n", "<leader>date", function()
    vim.api.nvim_put({ tostring(os.date("%d.%m.%Y")) }, "c", false, true)
  end, { desc = "[General] Insert date" })

  map("n", "<Esc>", function()
    vim.cmd("noh")
  end, { desc = "[General] Clear search highlight" })
  map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "[General] Copy whole file" })

  -- Format via Conform (fallback handled in LSP attach)
  map({ "n", "x" }, "<leader>fm", function()
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.format({
        lsp_fallback = true,
        timeout_ms = 3000,
      })
    end
  end, { desc = "[General] Format file" })

  -- Which-key
  map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "[General] WhichKey (all)" })
  map("n", "<leader>wk", function()
    require("lib.nvim.ui.kit").input({
      title = "WhichKey: ",
      on_submit = function(query)
        -- The prompt's text goes in as an *argument*, not concatenated into
        -- an Ex string: in `vim.cmd("WhichKey " .. query)` a `|` in the query
        -- would start a second Ex command. which-key happens to declare its
        -- command without `-bar`, which swallows the `|` today -- but that is
        -- a third-party detail this config does not control, and the argument
        -- form delivers a byte-identical `cmd.args` either way.
        --
        -- `nvim_cmd` rejects an empty argument, so an empty prompt takes the
        -- same path as `<leader>wK`: show everything.
        if query == nil or query:match("^%s*$") then
          vim.cmd.WhichKey()
        else
          vim.cmd.WhichKey(query)
        end
      end,
    })
  end, { desc = "[General] WhichKey query" })

  -- Insert-mode cursor moves
  map("i", "<C-h>", "<Left>", { desc = "[Text] Left" })
  map("i", "<C-l>", "<Right>", { desc = "[Text] Right" })
  map("i", "<C-j>", "<Down>", { desc = "[Text] Down" })
  map("i", "<C-k>", "<Up>", { desc = "[Text] Up" })

  -- Native diff mode, all windows in the tab. Not a git.nvim/diff.nvim
  -- feature -- vim's own `:diffthis`/`:diffoff`, so it stayed here rather
  -- than moving into gitsuite.nvim with the rest of the old
  -- `bindings.mappings.git` (GS-08).
  map("n", "<leader>dt", function()
    vim.cmd("windo diff" .. (vim.wo.diff and "off" or "this"))
  end, { desc = "[General] Diff windows in tab" })
end

return M
