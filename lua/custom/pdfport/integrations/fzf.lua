-- =============================================================================
-- lua/custom/pdfport/integrations/fzf.lua
-- =============================================================================
---@module 'custom.pdfport.integrations.fzf'
---@brief fzf-lua previewer integration for pdfport.
---@description
--- Provides a custom preview function compatible with fzf-lua's
--- builtin previewer system.
---
--- Usage:
---   local pdfport_fzf = require("custom.pdfport.integrations.fzf")
---
---   require("fzf-lua").files({
---     preview = pdfport_fzf.preview_fn({ max_pages = 3 }),
---   })

local fzf_mod = {}

---@type table<string, string>
local _cache = {}

--- Returns an fzf-lua preview function for PDF files.
---@param opts? PdfPort.FzfPreviewOpts
---@return fun(filepath: string, bufnr: integer, opts: table): nil
function fzf_mod.preview_fn(opts)
  opts = opts or {}
  local pdfport = require("custom.pdfport")

  return function(filepath, bufnr, _)
    if not filepath or not filepath:lower():match("%.pdf$") then
      return
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then return end

    -- Serve from cache immediately
    if _cache[filepath] then
      local lines = vim.split(_cache[filepath], "\n", { plain = true })
      vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
      vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
      return
    end

    -- Show placeholder
    vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "pdfport: extracting..." })
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

    pdfport.extract({
      path       = filepath,
      backend_id = opts.backend_id,
      max_pages  = opts.max_pages or 5,
      __callback = function(result)
        if not vim.api.nvim_buf_is_valid(bufnr) then return end
        local text  = result.text or ("error: " .. (result.error or ""))
        _cache[filepath] = text
        local lines = vim.split(text, "\n", { plain = true })
        vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(bufnr, "filetype",
          result.format == "markdown" and "markdown" or "text"
        )
        vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
      end,
    })
  end
end

return fzf_mod
