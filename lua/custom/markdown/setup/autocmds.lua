---@module 'custom.markdown.setup.autocmds'
---@description Lightweight FileType hook (extensible). Installs buffer-local keymaps and usercommands for Markdown filetypes.

local notify = require("lib.notify").create("[custom.markdown.setup.autocmds]")
local M = {}

local api = vim.api
local cfg_mod = require("custom.markdown.config")

---@param ftname string|nil
---@return boolean
local function is_md(ftname)
  if not ftname or ftname == "" then
    return false
  end
  if ftname == "md" or ftname == "mdx" or ftname == "markdown" then
    return true
  end
  return ftname:match("^markdown%.") ~= nil -- e.g. markdown.pandoc, markdown.gfm
end

--- Catch up on buffers whose FileType event already fired before this
--- module's autocmds were registered (e.g. the file given on the cmdline).
---@param fn fun(buf: integer)
local function apply_to_already_loaded_md_buffers(fn)
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(buf) and is_md(vim.bo[buf].filetype) then
      pcall(fn, buf)
    end
  end
end

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
    pattern = "*",
    callback = function(ev)
      local buf = ev.buf or api.nvim_get_current_buf()
      local ft = vim.bo[buf].filetype or ""
      if not is_md(ft) then
        return
      end
      local ok, err = pcall(function()
        require("custom.markdown.setup.keymaps").apply(buf)
      end)
      if not ok then
        notify.warn(string.format("[Custom.Markdown] failed to attach keymaps for buffer %d (filetype='%s'): %s", buf, ft, tostring(err)))
      end
    end,
    desc = "[Custom.Markdown] Install buffer-local Markdown keymaps (robust matcher)",
  })
  apply_to_already_loaded_md_buffers(function(buf)
    require("custom.markdown.setup.keymaps").apply(buf)
  end)

  local aug_uc = api.nvim_create_augroup("CustomMarkdownUserCommands", { clear = true })
  api.nvim_create_autocmd("FileType", {
    group = aug_uc,
    pattern = "*",
    callback = function(ev)
      local buf = ev.buf or api.nvim_get_current_buf()
      local ft = vim.bo[buf].filetype or ""
      if not is_md(ft) then
        return
      end
      local ok, err = pcall(function()
        require("custom.markdown.setup.usercmds").apply(ev)
      end)
      if not ok then
        notify.warn(string.format("[Custom.Markdown] failed to attach usercommands for buffer %d (ft=%s): %s", buf, ft, tostring(err)))
      end
    end,
    desc = "[Custom.Markdown] Install buffer-local usercommands for Markdown (robust matcher)",
  })
  apply_to_already_loaded_md_buffers(function(buf)
    require("custom.markdown.setup.usercmds").apply({ buf = buf })
  end)
end

return M
