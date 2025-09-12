---@module 'lsp.languages.markdown'
---@class LangMdQoL

local M = {}

---@return nil
function M.enable()
  local grp = vim.api.nvim_create_augroup("LangMarkdownQoL", { clear = true })

  -- Buffer-Local Tweaks für Markdown und MDX
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = { "markdown", "markdown.mdx" },
    callback = function(ev)
      if not (ev and ev.buf) then return end
      -- sanfte Defaults: Softwrap, Spell optional, sauberes Textobjekt-Verhalten
      vim.bo[ev.buf].textwidth = 0
      -- vim.bo[ev.buf].spell = true  -- falls du immer Spell willst, ent-kommentieren
      vim.bo[ev.buf].formatoptions = "jnql" -- kein hartes Reflow auf Save

      -- Keymap: <leader>fm -> Format (nimmt Conform-Setup)
      pcall(vim.keymap.set, "n", "<leader>fm", function()
        local ok, conform = pcall(require, "conform")
        if ok and conform and type(conform.format) == "function" then
          conform.format({ bufnr = ev.buf, timeout_ms = 2000, lsp_fallback = false })
        else
          vim.lsp.buf.format({ bufnr = ev.buf, timeout_ms = 2000 })
        end
      end, { buffer = ev.buf, silent = true, desc = "Format markdown buffer" })
    end,
    desc = "QoL defaults for Markdown/MDX",
  })

  -- Command: :MdFormat bevorzugt mdformat (für .md)
  pcall(vim.api.nvim_create_user_command, "MdFormat", function()
    local ft = vim.bo.filetype
    local ok, conform = pcall(require, "conform")
    if not ok or type(conform.format) ~= "function" then
      vim.lsp.buf.format({ timeout_ms = 2000 })
      return
    end
    local fmt = (ft == "markdown") and { "mdformat", "prettierd", "prettier" } or { "prettierd", "prettier" }
    conform.format({ formatters = fmt, timeout_ms = 2000, lsp_fallback = false })
  end, { desc = "Format Markdown/MDX (mdformat bevorzugt für .md)" })

  -- Command: :MdFormatPrettier erzwingt prettier (nützlich bei frontmatter/mdx)
  pcall(vim.api.nvim_create_user_command, "MdFormatPrettier", function()
    local ok, conform = pcall(require, "conform")
    if ok and type(conform.format) == "function" then
      conform.format({ formatters = { "prettierd", "prettier" }, timeout_ms = 2000, lsp_fallback = false })
    else
      vim.lsp.buf.format({ timeout_ms = 2000 })
    end
  end, { desc = "Format via Prettier (Fallback für MD/MDX)" })
end

return M
