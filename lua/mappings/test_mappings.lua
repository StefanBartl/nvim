---@module 'mappings.test_mappings'

local map = vim.keymap.set

-- === FORMATTING ===
--  silent toggles for format-on-save and one-shot format
--  No notifications, no echo messages; descriptions for which-key/help

map("n", "<leader>tf", function()
  local ok, f = pcall(function() return require("lsp.formatter.init").build end)
  -- If the module returns a builder, we need the built API;
  -- Prefer using the instance exposed via lsp.init (shared.formatter) if you have it globally.
  -- For simplicity, query a cached API if you store it globally, e.g., vim.g._formatter_api
  if vim.g._formatter_api and type(vim.g._formatter_api.toggle) == "function" then
    vim.g._formatter_api.toggle()
    return
  end
  -- Fallback: build a temporary API and toggle (stateless across sessions)
  if type(ok) == "boolean" and f then
    local api = f({ format_on_save = false, timeout_ms = 1500 })
    api.toggle()
  end
end, { desc = "[LSP] Toggle format-on-save (silent)", silent = true })

map("n", "<leader>ff", function()
  if vim.g._formatter_api and type(vim.g._formatter_api.format) == "function" then
    vim.g._formatter_api.format(0)
    return
  end
  local ok, build = pcall(require, "lsp.formatter.init")
  if ok and build and type(build.build) == "function" then
    build.build({ format_on_save = false, timeout_ms = 1500 }).format(0)
  end
end, { desc = "[LSP] Format current buffer once (silent)", silent = true })


-- === REPLACE BUFFER WITH CLIPBOARD CONTENT ===

-- Function to clear the current buffer and paste from system clipboard
local function replace_with_clipboard()
  -- Get text from the + register (system clipboard)
  local clip = vim.fn.getreg("+")
  -- Split into lines (Neovim expects a list of lines for buffer API)
  local lines = vim.split(clip, "\n", { plain = true })

  -- Replace the whole buffer content
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

vim.keymap.set("n", "<leader>rp", replace_with_clipboard, {
  desc = "[Edit] Replace buffer with clipboard content",
  noremap = true,
  silent = true,
})
vim.api.nvim_create_user_command("ReplaceWithClipboard", replace_with_clipboard, {
  desc = "Replace current buffer with system clipboard content",
})


-- Duplicate lines without affecting PRIMARY and CLIPBOARD selections.
map('n', '<Leader>dd', 'm`""Y""P``', { desc = 'Duplicate line' })
map('x', '<Leader>dd', '""Y""Pgv', { desc = 'Duplicate selection' })

-- Toggle diff on all windows in current tab
map('n', '<Leader>bf', function()
  vim.cmd('windo diff' .. (vim.wo.diff and 'off' or 'this'))
end, { desc = 'Diff Windows in Tab' })

-- Switch (tab) to the directory of the current opened buffer
map('n', '<Leader>cd', function()
  local bufdir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p:h')
  if bufdir ~= nil and vim.uv.fs_stat(bufdir) then
    vim.cmd.tcd(bufdir)
    vim.notify(bufdir)
  end
end, { desc = 'Change Tab Directory' })
