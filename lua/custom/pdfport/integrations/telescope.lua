-- =============================================================================
-- lua/custom/pdfport/integrations/telescope.lua
-- =============================================================================
---@module 'custom.pdfport.integrations.telescope'
---@brief Telescope previewer integration for pdfport.
---@description
--- Provides a custom previewer that, when a .pdf entry is focused in any
--- Telescope picker, extracts its text asynchronously and renders it in
--- the preview pane.
---
--- Usage:
---   local pdfport_tel = require("custom.pdfport.integrations.telescope")
---
---   require("telescope.builtin").find_files({
---     previewer = pdfport_tel.previewer({ max_pages = 3 }),
---   })
---
--- Or attach globally:
---   require("telescope").setup({
---     defaults = {
---       preview = {
---         filetype_hook = pdfport_tel.filetype_hook,
---       },
---     },
---   })

local tel_mod = {}

--- Creates a Telescope previewer for PDF files.
---@param opts? PdfPort.TelescopePreviewOpts
---@return table  Telescope previewer definition
function tel_mod.previewer(opts)
  opts = opts or {}

  local previewers  = require("telescope.previewers")
  local pdfport     = require("custom.pdfport")

  -- Cache: path -> extracted text (avoids re-extraction on re-focus)
  ---@type table<string, string>
  local cache = {}

  return previewers.new_buffer_previewer({
    title = "PDF Preview (pdfport)",

    define_preview = function(self, entry, _)
      local path = entry.path or entry.filename or entry.value
      if not path or not path:lower():match("%.pdf$") then
        return
      end

      local bufnr = self.state.bufnr
      if not vim.api.nvim_buf_is_valid(bufnr) then return end

      -- Show cached result immediately if available
      if cache[path] then
        local lines = vim.split(cache[path], "\n", { plain = true })
        vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
        vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
        return
      end

      -- Show loading indicator
      vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        "-- pdfport: extracting text, please wait... --",
      })
      vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

      pdfport.extract({
        path       = path,
        backend_id = opts.backend_id,
        max_pages  = opts.max_pages or 5,
        __callback = function(result)
          if not vim.api.nvim_buf_is_valid(bufnr) then return end

          local text = result.text or ("-- pdfport error: " .. (result.error or "unknown") .. " --")
          cache[path] = text

          local lines = vim.split(text, "\n", { plain = true })
          vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
          vim.api.nvim_buf_set_option(bufnr, "filetype",
            result.format == "markdown" and "markdown" or "text"
          )
          vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
        end,
      })
    end,
  })
end

--- Filetype hook for use in telescope.defaults.preview.filetype_hook.
--- Activates the pdfport previewer automatically for .pdf files.
---@param filepath string
---@param bufnr integer
---@param _ table
---@return boolean  true = hook handled this file, false = use default
function tel_mod.filetype_hook(filepath, bufnr, _)
  if not filepath or not filepath:lower():match("%.pdf$") then
    return false
  end

  local pdfport = require("custom.pdfport")

  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "-- pdfport: loading... --" })
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  pdfport.extract({
    path      = filepath,
    max_pages = 5,
    __callback = function(result)
      if not vim.api.nvim_buf_is_valid(bufnr) then return end
      local text  = result.text or ""
      local lines = vim.split(text, "\n", { plain = true })
      vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
      vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
    end,
  })

  return true
end

return tel_mod
