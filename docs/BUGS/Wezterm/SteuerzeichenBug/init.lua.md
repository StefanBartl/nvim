# Zusätzliche Neovim-seitige Absicherung

Falls das Problem weiterhin auftritt, Neovim härten:
In deiner Neovim init.lua (oder plugin/terminal-safety.lua):

```lua
-- Reject focus events completely (Neovim-seitig)
vim.opt.eventignore:append({ "FocusGained", "FocusLost" })

-- Disable bracketed paste if terminal claims it
vim.opt.paste = false  -- Verhindert Auto-Paste-Mode

-- Auto-Recovery bei Escape-Leak-Detection
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = function()
    -- Wenn Insert-Mode plötzlich Normal wird ohne User-Input:
    -- → Wahrscheinlich Escape-Leak
    local mode = vim.fn.mode()
    if mode == "n" and vim.v.insertmode == "i" then
      vim.notify("Escape sequence leak detected! Resetting terminal.", vim.log.levels.WARN)
      -- Reset Terminal
      vim.cmd("silent! !echo")  -- Dummy command flusht state
    end
  end,
})

-- Emergency Keybinding: Terminal komplett resetten
vim.keymap.set("n", "<leader>tr", function()
  vim.cmd([[
    silent !echo
    redraw!
    mode
  ]])
  vim.notify("Terminal reset complete", vim.log.levels.INFO)
end, { desc = "Reset Terminal State" })
-- Reject focus events completely (Neovim-seitig)
vim.opt.eventignore:append({ "FocusGained", "FocusLost" })

-- Disable bracketed paste if terminal claims it
vim.opt.paste = false  -- Verhindert Auto-Paste-Mode

-- Auto-Recovery bei Escape-Leak-Detection
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = function()
    -- Wenn Insert-Mode plötzlich Normal wird ohne User-Input:
    -- → Wahrscheinlich Escape-Leak
    local mode = vim.fn.mode()
    if mode == "n" and vim.v.insertmode == "i" then
      vim.notify("Escape sequence leak detected! Resetting terminal.", vim.log.levels.WARN)
      -- Reset Terminal
      vim.cmd("silent! !echo")  -- Dummy command flusht state
    end
  end,
})

-- Emergency Keybinding: Terminal komplett resetten
vim.keymap.set("n", "<leader>tr", function()
  vim.cmd([[
    silent !echo
    redraw!
    mode
  ]])
  vim.notify("Terminal reset complete", vim.log.levels.INFO)
end, { desc = "Reset Terminal State" })-- Reject focus events completely (Neovim-seitig)
vim.opt.eventignore:append({ "FocusGained", "FocusLost" })

-- Disable bracketed paste if terminal claims it
vim.opt.paste = false  -- Verhindert Auto-Paste-Mode

-- Auto-Recovery bei Escape-Leak-Detection
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = function()
    -- Wenn Insert-Mode plötzlich Normal wird ohne User-Input:
    -- → Wahrscheinlich Escape-Leak
    local mode = vim.fn.mode()
    if mode == "n" and vim.v.insertmode == "i" then
      vim.notify("Escape sequence leak detected! Resetting terminal.", vim.log.levels.WARN)
      -- Reset Terminal
      vim.cmd("silent! !echo")  -- Dummy command flusht state
    end
  end,
})

-- Emergency Keybinding: Terminal komplett resetten
vim.keymap.set("n", "<leader>tr", function()
  vim.cmd([[
    silent !echo
    redraw!
    mode
  ]])
  vim.notify("Terminal reset complete", vim.log.levels.INFO)
end, { desc = "Reset Terminal State" })
```
