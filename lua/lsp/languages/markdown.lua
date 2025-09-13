---@module 'lsp.languages.markdown'
---@class LangMdQoL

local M = {}

---@return nil
function M.enable()
  local api = vim.api
  local grp = api.nvim_create_augroup("LangMarkdownQoL", { clear = true })

  -- Always use UTF-8 (no BOM) for Markdown/MDX buffers + gentle text defaults.
  api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = { "markdown", "md" },
    callback = function(ev)
      if not (ev and ev.buf) then return end

      -- Encoding: avoid mojibake when formatters return UTF-8.
      vim.bo[ev.buf].fileencoding = "utf-8"
      vim.bo[ev.buf].bomb = false

      -- Soft text defaults (no hard reflow on save).
      vim.bo[ev.buf].textwidth = 0
      vim.bo[ev.buf].formatoptions = "jnql"

      -- <leader>fm -> format current buffer (prefer Conform, fallback to LSP).
      pcall(vim.keymap.set, "n", "<leader>fm", function()
        local ok, conform = pcall(require, "conform")
        if ok and type(conform.format) == "function" then
          conform.format({ bufnr = ev.buf, timeout_ms = 2000, lsp_fallback = false })
        else
          vim.lsp.buf.format({ bufnr = ev.buf, timeout_ms = 2000 })
        end
      end, { buffer = ev.buf, silent = true, desc = "Format markdown buffer" })
    end,
    desc = "Markdown QoL: UTF-8, soft-wrap, and safe formatting keymap",
  })

  -- :MdFormat -> prefer mdformat for .md, prettier for .mdx (same logic as your current setup).
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

  -- :MdFormatPrettier -> force prettier
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
