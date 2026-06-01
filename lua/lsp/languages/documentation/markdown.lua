---@module 'lsp.languages.scriipting.documentation.markdown'

local api = vim.api
local lsp = vim.lsp
local desc_tag = "[lsp] "

local M = {}

--- Set highlight for LSP reference groups (affects documentHighlight results).
---@return nil
function M.setup_reference_hl()
  -- Example: change foreground to a soft color and enable italic.
  -- Use colorscheme values or explicit hex values (here as placeholders).
  vim.api.nvim_set_hl(0, "LspReferenceText", { fg = "#FFFFFF", bg = "#2b2b2b", italic = true })
  vim.api.nvim_set_hl(0, "LspReferenceRead", { fg = "#FFFFFF", bg = "#2b2b2b" })
  vim.api.nvim_set_hl(0, "LspReferenceWrite", { fg = "#FFFFFF", bg = "#3a2b2b", bold = true })
end

---@return nil
function M.enable()
  local grp = api.nvim_create_augroup("LangMarkdownQoL", { clear = true })

  api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = { "markdown", "mdx" },
    callback = function(ev)
      if not (ev and ev.buf) then
        return
      end

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

      M.setup_reference_hl()

      pcall(vim.keymap.set, "n", "<leader>fm", function()
        local ok, conform = pcall(require, "conform")
        if ok and type(conform.format) == "function" then
          conform.format({ bufnr = ev.buf, timeout_ms = 2000, lsp_fallback = false })
        else
          lsp.buf.format({ bufnr = ev.buf, timeout_ms = 2000 })
        end
      end, { buffer = ev.buf, silent = true, desc = desc_tag .. "Format markdown buffer" })
    end,
    desc = desc_tag .. "Markdown QoL: UTF-8 (nur bei modifizierbar), Soft-Defaults, Format-Keymap",
  })

  pcall(api.nvim_create_user_command, "MdFormat", function()
    local ft = vim.bo.filetype
    local ok, conform = pcall(require, "conform")
    if not ok or type(conform.format) ~= "function" then
      lsp.buf.format({ timeout_ms = 2000 })
      return
    end
    local fmt = (ft == "markdown") and { "mdformat", "prettierd", "prettier" } or { "prettierd", "prettier" }
    conform.format({ formatters = fmt, timeout_ms = 2000, lsp_fallback = false })
  end, { desc = desc_tag .. "Format Markdown (prefer mdformat for .md)" })

  pcall(api.nvim_create_user_command, "MdFormatPrettier", function()
    local ok, conform = pcall(require, "conform")
    if ok and type(conform.format) == "function" then
      conform.format({ formatters = { "prettierd", "prettier" }, timeout_ms = 2000, lsp_fallback = false })
    else
      lsp.buf.format({ timeout_ms = 2000 })
    end
  end, { desc = desc_tag .. "Format via Prettier" })

  --- AUDIT:
  require("lsp.languages.documentation.markdown_words").setup()
end

---@type Lsp.Languages.ConfiguredLangs.Webdev.Markdown.Module
return M
