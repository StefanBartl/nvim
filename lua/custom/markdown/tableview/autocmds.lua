---@module 'custom.markdown.tableview.autocmds'
--- FileType autocmds to install TableView keymaps and usercommands buffer-locally.

local api = vim.api
local M = {}

local filetypes = { "markdown", "markdown.mdx", "mdx", "md" }

--- Setup autocmds (idempotent)
---@return nil
function M.setup()
  local aug = api.nvim_create_augroup("CustomCustom.Markdown.TableView", { clear = true })

  api.nvim_create_autocmd("FileType", {
    group = aug,
    pattern = filetypes,
    callback = function(ev)
      -- apply buffer-local keymaps and commands
      pcall(function()
        require("custom.markdown.tableview.mappings").apply(ev.buf)
        require("custom.markdown.tableview.commands").apply(ev)
      end)
    end,
    desc = "[Custom.Markdown.TableView] Install buffer-local maps & commands for markdown",
  })
end

return M
