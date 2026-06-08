---@module 'custom.pdfport.backends.docling'
---@brief Extraction backend using IBM docling.
---@description
--- Invokes docling via an inline Python script. Docling produces high-quality
--- Markdown with preserved tables, figures and document structure.
--- Optimised for scientific papers, reports and financial documents.
---
--- Install: pip install docling

local platform = require("custom.pdfport.platform")
local uv       = vim.uv or vim.loop

---@type PdfPort.Backend
local M = {
  id   = "docling",
  name = "docling (IBM, Python)",

  capabilities = {
    markdown    = true,
    tables      = true,
    ocr         = true,
    remote      = false,
    gpu_optional = true,
  },
}

---@return boolean
function M.available()
  return platform.has("python3") and platform.has_python_module("docling")
end

---@param path string
---@param opts PdfPort.InternalExtractOpts
---@return PdfPort.Result|nil
function M.extract(path, opts)
  local max_pages = opts.max_pages or 0

  -- docling's DocumentConverter returns a ConversionResult with an export_to_markdown method
  local script = string.format([[
import sys
from docling.document_converter import DocumentConverter

path      = %q
max_pages = %d

try:
    converter = DocumentConverter()
    result    = converter.convert(path)
    md        = result.document.export_to_markdown()
    print(md)
except Exception as e:
    print(f"docling error: {e}", file=sys.stderr)
    sys.exit(1)
]], path, max_pages)

  local script_file = vim.fn.tempname() .. ".py"
  local f = io.open(script_file, "w")
  if not f then
    return {
      status  = "error",
      text    = nil,
      format  = "markdown",
      backend = "docling",
      pages_processed = nil,
      error   = "docling: failed to write temp script",
    }
  end
  f:write(script)
  f:close()

  local stdout_chunks = {}
  local stderr_chunks = {}
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)

  -- docling can be slow on CPU; give it extra time
  local timeout_ms = opts.timeout_ms or 120000
  local timer = uv.new_timer()

  local function cleanup()
    if timer then timer:stop(); timer:close() end
    if stdout and not stdout:is_closing() then stdout:close() end
    if stderr and not stderr:is_closing() then stderr:close() end
    vim.fn.delete(script_file)
  end

  local handle = uv.spawn(py, {
    args  = { script_file },
    stdio = { nil, stdout, stderr },
  }, function(code, _)
    cleanup()

    local text     = table.concat(stdout_chunks)
    local err_text = table.concat(stderr_chunks)

    vim.schedule(function()
      local result = code == 0 and {
        status          = "ok",
        text            = text,
        format          = "markdown",
        backend         = "docling",
        pages_processed = max_pages > 0 and max_pages or nil,
        error           = nil,
      } or {
        status          = "error",
        text            = nil,
        format          = "markdown",
        backend         = "docling",
        pages_processed = nil,
        error           = string.format("docling exited %d: %s", code, err_text),
      }

      if type(opts.__callback) == "function" then
        opts.__callback(result)
      end
    end)
  end)

  if not handle then
    vim.fn.delete(script_file)
    return {
      status  = "error",
      text    = nil,
      format  = "markdown",
      backend = "docling",
      pages_processed = nil,
      error   = "docling: failed to spawn python3",
    }
  end

  stdout:read_start(function(_, data)
    if data then stdout_chunks[#stdout_chunks + 1] = data end
  end)

  stderr:read_start(function(_, data)
    if data then stderr_chunks[#stderr_chunks + 1] = data end
  end)

  timer:start(timeout_ms, 0, function()
    if handle and not handle:is_closing() then handle:kill(15) end
    cleanup()
    vim.schedule(function()
      local result = {
        status  = "error",
        text    = nil,
        format  = "markdown",
        backend = "docling",
        pages_processed = nil,
        error   = string.format("docling: timed out after %d ms", timeout_ms),
      }
      if type(opts.__callback) == "function" then
        opts.__callback(result)
      end
    end)
  end)

  return nil
end

return M
