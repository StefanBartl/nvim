---@module 'custom.pdfport.backends.pdfplumber'
---@brief Extraction backend using the Python pdfplumber library.
---@description
--- Invokes a small inline Python script via python3 that uses pdfplumber
--- to extract text with better table and layout awareness than pdftotext.
---
--- Install: pip install pdfplumber

local platform = require("custom.pdfport.platform")
local uv       = vim.uv or vim.loop

---@type PdfPort.Backend
local M = {
  id   = "pdfplumber",
  name = "pdfplumber (Python)",

  capabilities = {
    markdown    = false,
    tables      = true,
    ocr         = false,
    remote      = false,
    gpu_optional = false,
  },
}

--- Returns true when python3 and pdfplumber are available.
---@return boolean
function M.available()
  return platform.has("python3") and platform.has_python_module("pdfplumber")
end

---@param path string
---@param opts PdfPort.InternalExtractOpts
---@return PdfPort.Result|nil
function M.extract(path, opts)
  -- Inline Python script written to a temp file to avoid shell-escaping issues
  local max_pages = opts.max_pages or 0  -- 0 = all pages

  local script = string.format([[
import sys, pdfplumber

path      = %q
max_pages = %d

with pdfplumber.open(path) as pdf:
    pages = pdf.pages if max_pages == 0 else pdf.pages[:max_pages]
    parts = []
    for page in pages:
        text = page.extract_text()
        if text:
            parts.append(text)
    print("\n\n".join(parts))
]], path, max_pages)

  local script_file = vim.fn.tempname() .. ".py"
  local f = io.open(script_file, "w")
  if not f then
    return {
      status  = "error",
      text    = nil,
      format  = "plain",
      backend = "pdfplumber",
      pages_processed = nil,
      error   = "pdfplumber: failed to write temp script",
    }
  end
  f:write(script)
  f:close()

  local stdout_chunks = {}
  local stderr_chunks = {}
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)

  local timeout_ms = opts.timeout_ms or 30000
  local timer = uv.new_timer()

  local function cleanup()
    if timer then timer:stop(); timer:close() end
    if stdout and not stdout:is_closing() then stdout:close() end
    if stderr and not stderr:is_closing() then stderr:close() end
    vim.fn.delete(script_file)
  end

  local handle = uv.spawn("python3", {
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
        format          = "plain",
        backend         = "pdfplumber",
        pages_processed = max_pages > 0 and max_pages or nil,
        error           = nil,
      } or {
        status          = "error",
        text            = nil,
        format          = "plain",
        backend         = "pdfplumber",
        pages_processed = nil,
        error           = string.format("pdfplumber exited %d: %s", code, err_text),
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
      format  = "plain",
      backend = "pdfplumber",
      pages_processed = nil,
      error   = "pdfplumber: failed to spawn python3",
    }
  end

  if not stdout or not stderr or not timer then
    vim.notify("stdout, stderr or timer is nil", 4)
    return nil
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
        format  = "plain",
        backend = "pdfplumber",
        pages_processed = nil,
        error   = string.format("pdfplumber: timed out after %d ms", timeout_ms),
      }
      if type(opts.__callback) == "function" then
        opts.__callback(result)
      end
    end)
  end)

  return nil
end

return M
