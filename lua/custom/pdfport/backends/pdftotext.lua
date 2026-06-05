---@module 'custom.pdfport.backends.pdftotext'
---@brief Extraction backend using the pdftotext CLI from poppler-utils.
---@description
--- Uses vim.uv.spawn to run pdftotext asynchronously. Stdout is collected
--- incrementally via the pipe handle and assembled into a single string.
--- The result is delivered via an internal callback stored in the
--- dispatcher's closure.
---
--- Limitations:
---   - No Markdown output (plain text only)
---   - Tables are often mangled
---   - Does not handle scanned (image-only) PDFs
---
--- Install: apt install poppler-utils  |  brew install poppler

local platform = require("custom.pdfport.platform")
local uv       = vim.uv or vim.loop

---@type PdfPort.Backend
local M = {
  id   = "pdftotext",
  name = "pdftotext (poppler-utils)",
  capabilities = {
    markdown    = false,
    tables      = false,
    ocr         = false,
    remote      = false,
    gpu_optional = false,
  },
}

--- Returns true when pdftotext is found on PATH.
---@return boolean
function M.available()
  return platform.has("pdftotext")
end

--- Extracts text from a PDF using pdftotext.
--- This function is async: it returns nil immediately and delivers the
--- PdfPort.Result via the callback stored in opts.__callback.
---
--- IMPORTANT: callers must pass a __callback field in opts when they need
--- async delivery. The dispatcher handles this transparently.
---
---@param path string  Absolute path to the PDF file
---@param opts PdfPort.ExtractOpts
---@return PdfPort.Result|nil  Synchronous result (nil = async, callback used)
function M.extract(path, opts)
  -- Build argument list
  -- -layout: preserves reading order / column layout
  -- -enc UTF-8: explicit UTF-8 output
  -- "-" at the end means: write to stdout instead of a file
  local args = { "-layout", "-enc", "UTF-8" }

  if opts.pages and #opts.pages > 0 then
    -- pdftotext only supports contiguous ranges; use first and last
    local first = opts.pages[1]
    local last  = opts.pages[#opts.pages]
    args[#args + 1] = "-f"
    args[#args + 1] = tostring(first)
    args[#args + 1] = "-l"
    args[#args + 1] = tostring(last)
  elseif opts.max_pages then
    args[#args + 1] = "-l"
    args[#args + 1] = tostring(opts.max_pages)
  end

  args[#args + 1] = path
  args[#args + 1] = "-"   -- output to stdout

  -- Collect stdout chunks
  local chunks  = {}
  local stderr_chunks = {}

  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)

  local handle

  local timeout_ms = opts.timeout_ms or 30000
  local timer = uv.new_timer()

  local function cleanup()
    if timer then
      timer:stop()
      timer:close()
    end
    if stdout and not stdout:is_closing() then
      stdout:close()
    end
    if stderr and not stderr:is_closing() then
      stderr:close()
    end
  end

  handle = uv.spawn("pdftotext", {
    args  = args,
    stdio = { nil, stdout, stderr },
  }, function(code, _)
    cleanup()

    local text = table.concat(chunks)
    local err_text = table.concat(stderr_chunks)

    vim.schedule(function()
      if code ~= 0 then
        -- Store result for dispatcher callback
        M._last_result = {
          status  = "error",
          text    = nil,
          format  = "plain",
          backend = "pdftotext",
          pages_processed = nil,
          error   = string.format(
            "pdftotext exited with code %d: %s", code, err_text
          ),
        }
      else
        M._last_result = {
          status  = "ok",
          text    = text,
          format  = "plain",
          backend = "pdftotext",
          pages_processed = opts.max_pages,
          error   = nil,
        }
      end

      -- Deliver via callback if dispatcher passed one
      if type(opts.__callback) == "function" then
        opts.__callback(M._last_result)
      end
    end)
  end)

  if not handle then
    return {
      status  = "error",
      text    = nil,
      format  = "plain",
      backend = "pdftotext",
      pages_processed = nil,
      error   = "pdftotext: failed to spawn process",
    }
  end

  if not stdout or not stderr or not timer then
    vim.notify("stdout stderr or timer is nil", 4)
    return nil
  end
  -- Read stdout incrementally
  stdout:read_start(function(err, data)
    if err then
      return
    end
    if data then
      chunks[#chunks + 1] = data
    end
  end)

  stderr:read_start(function(err, data)
    if err then
      return
    end
    if data then
      stderr_chunks[#stderr_chunks + 1] = data
    end
  end)

  -- Timeout guard
  timer:start(timeout_ms, 0, function()
    if handle and not handle:is_closing() then
      handle:kill(15) -- SIGTERM
    end
    cleanup()
    vim.schedule(function()
      local result = {
        status  = "error",
        text    = nil,
        format  = "plain",
        backend = "pdftotext",
        pages_processed = nil,
        error   = string.format("pdftotext: timed out after %d ms", timeout_ms),
      }
      if type(opts.__callback) == "function" then
        opts.__callback(result)
      end
    end)
  end)

  -- Async path: no synchronous return value
  return nil
end

return M
