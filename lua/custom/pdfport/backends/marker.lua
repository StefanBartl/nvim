---@module 'custom.pdfport.backends.marker'
---@brief Extraction backend using the marker-pdf Python tool.
---@description
--- marker-pdf (https://github.com/VikParuchuri/marker) converts PDFs to
--- Markdown with high fidelity, preserving headings, tables and code blocks.
--- It uses a combination of Surya OCR and layout detection models.
---
--- marker can run on CPU only; GPU is optional but speeds up large documents.
---
--- Install: pip install marker-pdf
--- Usage:   marker_single <pdf> <output_dir> --output_format markdown
---
--- This backend invokes the `marker_single` CLI tool asynchronously and
--- reads back the generated .md file from the output directory.

local platform = require("custom.pdfport.platform")
local uv       = vim.uv or vim.loop

---@type PdfPort.Backend
local M = {
  id   = "marker",
  name = "marker-pdf (AI Markdown extraction)",

  capabilities = {
    markdown    = true,
    tables      = true,
    ocr         = true,
    remote      = false,
    gpu_optional = true,
  },
}

--- Returns true when marker_single is on PATH.
---@return boolean
function M.available()
  return platform.has("marker_single")
end

---@param path string  Absolute path to PDF
---@param opts PdfPort.ExtractOpts
---@return PdfPort.Result|nil
function M.extract(path, opts)
  -- marker writes output to a directory; we use a temp dir per extraction
  local tmp_dir = vim.fn.tempname()
  vim.fn.mkdir(tmp_dir, "p")

  local args = {
    path,
    tmp_dir,
    "--output_format", "markdown",
  }

  if opts.max_pages then
    args[#args + 1] = "--max_pages"
    args[#args + 1] = tostring(opts.max_pages)
  end

  local stderr_chunks = {}
  local stderr = uv.new_pipe(false)

  local timeout_ms = opts.timeout_ms or 120000 -- marker is slow on CPU; 2 min default
  local timer = uv.new_timer()

  local function cleanup()
    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end
    if stderr and not stderr:is_closing() then
      stderr:close()
    end
  end

  local handle

  handle = uv.spawn("marker_single", {
    args  = args,
    stdio = { nil, nil, stderr },
  }, function(code, _)
    cleanup()

    local err_text = table.concat(stderr_chunks)

    vim.schedule(function()
      if code ~= 0 then
        -- Clean up temp dir on error
        vim.fn.delete(tmp_dir, "rf")

        local result = {
          status  = "error",
          text    = nil,
          format  = "markdown",
          backend = "marker",
          pages_processed = nil,
          error   = string.format("marker_single exited %d: %s", code, err_text),
        }
        if type(opts.__callback) == "function" then
          opts.__callback(result)
        end
        return
      end

      -- Locate the generated .md file
      -- marker names it <stem>/<stem>.md inside tmp_dir
      local stem = vim.fn.fnamemodify(path, ":t:r")
      local md_path = tmp_dir .. "/" .. stem .. "/" .. stem .. ".md"

      -- Fallback: scan tmp_dir for any .md file
      if vim.fn.filereadable(md_path) ~= 1 then
        local found = vim.fn.glob(tmp_dir .. "/**/*.md", false, true)
        if #found > 0 then
          md_path = found[1]
        else
          vim.fn.delete(tmp_dir, "rf")
          local result = {
            status  = "error",
            text    = nil,
            format  = "markdown",
            backend = "marker",
            pages_processed = nil,
            error   = "marker_single: output .md file not found in " .. tmp_dir,
          }
          if type(opts.__callback) == "function" then
            opts.__callback(result)
          end
          return
        end
      end

      local lines = vim.fn.readfile(md_path)
      local text  = table.concat(lines, "\n")

      -- Clean up temp dir
      vim.fn.delete(tmp_dir, "rf")

      local result = {
        status  = "ok",
        text    = text,
        format  = "markdown",
        backend = "marker",
        pages_processed = opts.max_pages,
        error   = nil,
      }
      if type(opts.__callback) == "function" then
        opts.__callback(result)
      end
    end)
  end)

  if not handle then
    vim.fn.delete(tmp_dir, "rf")
    return {
      status  = "error",
      text    = nil,
      format  = "markdown",
      backend = "marker",
      pages_processed = nil,
      error   = "marker: failed to spawn marker_single process",
    }
  end

  if not stderr or not timer then
    vim.notify("stdout, stderr or timer is nil", 4)
    return nil
  end

  stderr:read_start(function(err, data)
    if err then return end
    if data then
      stderr_chunks[#stderr_chunks + 1] = data
    end
  end)

  timer:start(timeout_ms, 0, function()
    if handle and not handle:is_closing() then
      handle:kill(15)
    end
    cleanup()
    vim.schedule(function()
      vim.fn.delete(tmp_dir, "rf")
      local result = {
        status  = "error",
        text    = nil,
        format  = "markdown",
        backend = "marker",
        pages_processed = nil,
        error   = string.format("marker: timed out after %d ms", timeout_ms),
      }
      if type(opts.__callback) == "function" then
        opts.__callback(result)
      end
    end)
  end)

  return nil
end

return M
