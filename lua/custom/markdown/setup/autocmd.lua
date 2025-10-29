---@module 'custom.markdown.ui.autocmd'
---@description Lightweight FileType hook (extensible). Installs buffer-local keymaps and usercommands for Markdown filetypes.

local M = {}

---@type table
local api = vim.api

---@type string[]
local filetypes = { "markdown", "markdown.mdx", "mdx", "md" }

local cfg_mod = require("custom.markdown.config")
local keymaps = require("custom.markdown.setup.keymaps")
local usercommands = require("custom.markdown.setup.usercommands")

--- Setup FileType autocmds that install buffer-local keymaps and usercommands.
---@return nil
function M.setup()
  local cfg = cfg_mod.get()
  if not cfg.enable_keymaps then
    return
  end

  local aug_km = api.nvim_create_augroup("CustomMarkdownKeymaps", { clear = true })
  api.nvim_create_autocmd("FileType", {
    group = aug_km,
    pattern = filetypes,
    callback = function(ev)
      pcall(function() keymaps.apply(ev.buf) end)
    end,
    desc = "[Custom.Markdown] Install buffer-local Markdown keymaps",
  })

  local aug_uc = api.nvim_create_augroup("CustomMarkdownUserCommands", { clear = true })
  api.nvim_create_autocmd("FileType", {
    group = aug_uc,
    pattern = filetypes,
    callback = function(ev)
      pcall(function() usercommands.apply(ev) end)
    end,
    desc = "[Custom.Markdown] Install buffer-local usercommands for Markdown",
  })
end

return M
