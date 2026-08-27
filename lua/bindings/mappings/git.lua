---@module 'bindings.mappings.git'
--- Diffview keymaps: `<leader>dv`/`dc` open and close it, `<leader>dh` file
--- history, `<leader>dt` diffs the windows in the current tab.

local notify = require("lib.nvim.notify").create("[bindings.mappings.git]")
local usercmd = require("lib.nvim.bindings.usercmd")

local M = {}

--- ==== ToggleInlineDiff =====

---@type table
local defaults = {
  -- keybind for toggle (normal mode)
  key = "<leader>di",
  -- user command name
  cmd = "ToggleInlineDiff",
  -- notify level to use for messages
  notify_level = vim.log.levels.INFO,
  -- brief message shown after toggling
  msg = "Inline-diff toggled: word_diff & linehl inverted; preview current hunk",
}

---Safely require gitsigns, return nil and notify if unavailable.
local function require_gs()
  local ok, gitsigns = pcall(require, "gitsigns")
  if not ok or not gitsigns then
    notify.notify("gitsigns not found", defaults.notify_level)
    return nil
  end
  return gitsigns
end

---Perform the unified toggle action:
---1) toggle_word_diff()
---2) toggle_linehl()
---3) preview_hunk_inline() for the hunk under cursor (if available)
---@param bufnr integer|nil buffer number, defaults to current buffer
function M.toggle_inline_diff(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local gs = require_gs()
  if not gs then
    return
  end

  -- call the two toggle APIs (they invert their internal state)
  pcall(function()
    if type(gs.toggle_word_diff) == "function" then
      gs.toggle_word_diff()
    end
  end)
  pcall(function()
    if type(gs.toggle_linehl) == "function" then
      gs.toggle_linehl()
    end
  end)

  -- Preferred: preview current hunk inline (temporary).
  -- preview_hunk_inline may not exist in older gitsigns; guard it.
  if type(gs.preview_hunk_inline) == "function" then
    pcall(gs.preview_hunk_inline)
  else
    -- If preview_hunk_inline not available, fall back to preview_hunk (popup).
    if type(gs.preview_hunk) == "function" then
      pcall(gs.preview_hunk)
      notify.notify(
        "preview_hunk_inline not available; used preview_hunk popup",
        defaults.notify_level
      )
    end
  end

  notify.notify(defaults.msg, defaults.notify_level)
end

local function ToggleInlineDiffSetup()
  local map = require("lib.nvim.bindings.keymap")
  map("n", defaults.key, M.toggle_inline_diff, { desc = "Toggle inline diff (gitsigns)" })

  usercmd.create(defaults.cmd, function()
    M.toggle_inline_diff()
  end, { desc = "Toggle inline diff: invert word_diff & linehl, preview current hunk inline" })
end

function M.setup()
  ToggleInlineDiffSetup()

  local map = require("lib.nvim.bindings.keymap")

  map("n", "<leader>dv", ":DiffviewOpen<CR>", { desc = "[Diffview] Open" })
  map("n", "<leader>dc", ":DiffviewClose<CR>", { desc = "[Diffview] Close" })
  map("n", "<leader>dh", ":DiffviewFileHistory<CR>", { desc = "[Diffview] File History" })
  map("n", "<Leader>dt", function()
    vim.cmd("windo diff" .. (vim.wo.diff and "off" or "this"))
  end, { desc = "Diff Windows in Tab" })
end

return M
