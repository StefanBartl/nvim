---@module 'custom.markdown.ui.autocmd'
---@description Lightweight FileType hook (extensible). Installs buffer-local keymaps and usercommands for Markdown filetypes.
---AUDIT: Format ist übel
local M = {}

---@type table
local api = vim.api
local cfg_mod = require("custom.markdown.config")

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

      local function is_md(ftname)
        if not ftname or ftname == "" then
          return false
        end
        if ftname == "md" or ftname == "mdx" then
          return true
        end
        if ftname == "markdown" then
          return true
        end
        if ftname:match("^markdown%.") then
          return true
        end -- e.g. markdown.pandoc, markdown.gfm
        return false
      end

      if not is_md(ft) then
        return
      end

      local ok, err = pcall(function()
        require("custom.markdown.setup.keymaps").apply(buf)
      end)
      if not ok then
        vim.notify(string.format("[Custom.Markdown] failed to attach keymaps for buffer %d (filetype='%s'): %s", buf, ft, tostring(err)), vim.log.levels.WARN)
      end
    end,
    desc = "[Custom.Markdown] Install buffer-local Markdown keymaps (robust matcher)",
  })

  local aug_uc = api.nvim_create_augroup("CustomMarkdownUserCommands", { clear = true })
  api.nvim_create_autocmd("FileType", {
    group = aug_uc,
    pattern = "*",
    callback = function(ev)
      local buf = ev.buf or api.nvim_get_current_buf()
      local ft = vim.bo[buf].filetype or ""
      if not (ft == "markdown" or ft == "md" or ft == "mdx" or ft:match("^markdown%.")) then
        return
      end

      local ok, err = pcall(function()
        require("custom.markdown.setup.usercommands").apply(ev)
      end)
      if not ok then
        vim.notify(
          string.format(
            "[Custom.Markdown] failed to attach usercommands for buffer %d (ft=%s): %s",
            buf,
            ft,
            tostring(err)
          ),
          vim.log.levels.WARN
        )
      end
    end,
    desc = "[Custom.Markdown] Install buffer-local usercommands for Markdown (robust matcher)",
  })
end

return M
