---@module 'lsp.languages.webdev.astro.autocmds'

local api = vim.api

local M = {}

---@return nil
function M.setup()
  local grp = api.nvim_create_augroup("AstroQoL", { clear = true })

  -- Auto-format on save
  api.nvim_create_autocmd("BufWritePre", {
    group = grp,
    pattern = "*.astro",
    callback = function(ev)
      local ok, conform = pcall(require, "conform")
      if ok then
        conform.format({ bufnr = ev.buf, timeout_ms = 2000 })
      else
        vim.lsp.buf.format({ bufnr = ev.buf, timeout_ms = 2000 })
      end
    end,
    desc = "Format Astro file on save",
  })

  -- Auto-organize imports on save
  api.nvim_create_autocmd("BufWritePre", {
    group = grp,
    pattern = "*.astro",
    callback = function(_)
      vim.lsp.buf.code_action({
        context = { only = { "source.organizeImports.astro" } },
        apply = true,
      })
    end,
    desc = "Organize imports on save",
  })

  -- Set local options
  api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "astro",
    callback = function(ev)
      vim.bo[ev.buf].shiftwidth = 2
      vim.bo[ev.buf].tabstop = 2
      vim.bo[ev.buf].expandtab = true
      vim.bo[ev.buf].commentstring = "{/* %s */}"
    end,
    desc = "Set Astro buffer options",
  })

  -- Highlight Astro sections differently
  api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "astro",
    callback = function()
      -- Custom highlight for frontmatter
      vim.cmd([[syntax region astroFrontmatter start=/^---$/ end=/^---$/]])
      vim.cmd([[highlight link astroFrontmatter Comment]])
    end,
    desc = "Custom Astro syntax highlighting",
  })

  -- Dev-server kill on exit and the missing-component-import check are not
  -- here: both live in project-insight.nvim (`devserver` / `unimported`),
  -- generalized past Astro and configured via its setup() spec.
end

return M
