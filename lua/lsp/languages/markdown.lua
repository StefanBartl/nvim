-- lsp/languages/markdown.lua
---@module 'lsp.languages.markdown'
---@class LangMdQoL

local M = {}

---@return nil
function M.enable()
  local api = vim.api
  local grp = api.nvim_create_augroup("LangMarkdownQoL", { clear = true })

  api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = { "markdown", "mdx" },
    callback = function(ev)
      if not (ev and ev.buf) then return end

      local bo = vim.bo[ev.buf]
      local bt = bo.buftype or ""

      local is_normal_file = (bt == "")
      local can_recode = is_normal_file and bo.modifiable

      if can_recode then
        bo.fileencoding = "utf-8"
        bo.bomb = false
      end

      bo.textwidth = 0
      bo.formatoptions = "jnql"

      pcall(vim.keymap.set, "n", "<leader>fm", function()
        local ok, conform = pcall(require, "conform")
        if ok and type(conform.format) == "function" then
          conform.format({ bufnr = ev.buf, timeout_ms = 2000, lsp_fallback = false })
        else
          vim.lsp.buf.format({ bufnr = ev.buf, timeout_ms = 2000 })
        end
      end, { buffer = ev.buf, silent = true, desc = "Format markdown buffer" })
    end,
    desc = "Markdown QoL: UTF-8 (nur bei modifizierbar), Soft-Defaults, Format-Keymap",
  })

  pcall(api.nvim_create_user_command, "MdFormat", function()
    local ft = vim.bo.filetype
    local ok, conform = pcall(require, "conform")
    if not ok or type(conform.format) ~= "function" then
      vim.lsp.buf.format({ timeout_ms = 2000 })
      return
    end
    local fmt = (ft == "markdown") and { "mdformat", "prettierd", "prettier" } or { "prettierd", "prettier" }
    conform.format({ formatters = fmt, timeout_ms = 2000, lsp_fallback = false })
  end, { desc = "Format Markdown (prefer mdformat for .md)" })

  pcall(api.nvim_create_user_command, "MdFormatPrettier", function()
    local ok, conform = pcall(require, "conform")
    if ok and type(conform.format) == "function" then
      conform.format({ formatters = { "prettierd", "prettier" }, timeout_ms = 2000, lsp_fallback = false })
    else
      vim.lsp.buf.format({ timeout_ms = 2000 })
    end
  end, { desc = "Format via Prettier" })
end

return M
