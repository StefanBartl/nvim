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
    callback = function(ev)
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

  -- Auto-close dev server on exit
  api.nvim_create_autocmd("VimLeavePre", {
    group = grp,
    pattern = "*.astro",
    callback = function()
      vim.fn.system("pkill -f 'astro dev'")
    end,
    desc = "Kill Astro dev server on exit",
  })

  -- Create missing component imports
  api.nvim_create_autocmd("BufWritePost", {
    group = grp,
    pattern = "*.astro",
    callback = function(ev)
      local lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)
      local used_components = {}

      -- Find all component usages
      for _, line in ipairs(lines) do
        for component in line:gmatch("<([A-Z][%w]*)") do
          used_components[component] = true
        end
      end

      -- Check if imports exist
      local missing = {}
      for component, _ in pairs(used_components) do
        local has_import = false
        for _, line in ipairs(lines) do
          if line:match("import " .. component) then
            has_import = true
            break
          end
        end
        if not has_import then
          table.insert(missing, component)
        end
      end

      if #missing > 0 then
        vim.notify("Missing imports: " .. table.concat(missing, ", "), vim.log.levels.WARN)
      end
    end,
    desc = "Check for missing component imports",
  })
end

return M
