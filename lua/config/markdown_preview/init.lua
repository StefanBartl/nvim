-- init.lua (unter config/markdown_preview.lua)
local M = {}

M._preview_active = false

function M.setup()
  -- Die vim.g.* Variablen wurden in die init-Funktion der Plugin-Spec verschoben!

  -- Define wrapper commands to manage global flag
  vim.api.nvim_create_user_command("MarkdownPreviewWrapper", function()
    M._preview_active = true
    vim.cmd("silent! MarkdownPreview")
  end, { bang = true, nargs = 0 })

  vim.api.nvim_create_user_command("MarkdownPreviewStopWrapper", function()
    M._preview_active = false
    vim.cmd("silent! MarkdownPreviewStop")
  end, { bang = true, nargs = 0 })

  vim.api.nvim_create_user_command("MarkdownPreviewToggleWrapper", function()
    M._preview_active = not M._preview_active
    vim.cmd("silent! MarkdownPreviewToggle")
  end, { bang = true, nargs = 0 })

  -- Auto-refresh on buffer switch only if _preview_active is true
  local aug = vim.api.nvim_create_augroup("MkdpConditionalRefresh", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = aug,
    pattern = "*.md",
    callback = function()
      if M._preview_active and vim.fn.exists(":MarkdownPreview") == 2 then
        vim.cmd("silent! MarkdownPreview")
      end
    end,
  })
end

return M
