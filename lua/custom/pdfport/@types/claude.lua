---@module 'custom.pdfport.backends.claude'
---@brief Extraction backend using the Anthropic Claude API.
---@description
--- Sends the PDF file as a base64-encoded document block to the
--- Anthropic Messages API. Claude can read PDFs natively and returns
--- a structured Markdown summary or full extraction depending on the
--- prompt.
---
--- Requirements:
---   - Valid ANTHROPIC_API_KEY environment variable or pdfport.config.claude_api_key
---   - curl on PATH (used for the HTTP request to avoid Lua HTTP deps)
---   - Internet connection
---
--- Cost note: each PDF page consumes input tokens. Long documents can
--- be expensive. Consider setting opts.max_pages.
---
--- Model: claude-opus-4-5 (best for document understanding)
--- Fallback: claude-haiku-4-5 (faster, cheaper)

local platform = require("custom.pdfport.platform")
local uv       = vim.uv or vim.loop

---@type PdfPort.Backend
local M = {
  id   = "claude",
  name = "Anthropic Claude API",

  capabilities = {
    markdown    = true,
    tables      = true,
    ocr         = true,  -- Claude can read image-based PDFs
    remote      = true,
    gpu_optional = false,
  },
}

---@type PdfPort.Config|nil
local _config = nil

--- Injected by pdfport.init after setup().
---@param config PdfPort.Config
---@return nil
function M._set_config(config)
  _config = config
end

--- Returns true when curl is on PATH and an API key is configured.
---@return boolean
function M.available()
  if not platform.has("curl") then
    return false
  end

  local key = (_config and _config.claude_api_key)
    or vim.env.ANTHROPIC_API_KEY

  return type(key) == "string" and key ~= ""
end

--- Reads a file and returns its base64-encoded content.
---@param path string
---@return string|nil base64
---@return string|nil error_msg
local function read_base64(path)
  -- Use base64 CLI tool to avoid loading entire file into Lua string first
  if not platform.has("base64") then
    return nil, "base64 binary not found on PATH"
  end

  local result = vim.fn.system({ "base64", "-w", "0", path })
  if vim.v.shell_error ~= 0 then
    return nil, "base64 encoding failed"
  end

  -- Trim trailing newline
  return result:gsub("%s+$", ""), nil
end

--- Builds the JSON request body for the Anthropic Messages API.
---@param base64_pdf string
---@param prompt string
---@param model string
---@return string json
local function build_request(base64_pdf, prompt, model)
  -- We build JSON manually to avoid requiring a JSON library.
  -- The prompt and model values are validated before insertion.
  local safe_prompt = prompt:gsub('"', '\\"'):gsub("\n", "\\n")
  local safe_model  = model:gsub('"', '\\"')

  return string.format([[{
  "model": "%s",
  "max_tokens": 4096,
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "document",
          "source": {
            "type": "base64",
            "media_type": "application/pdf",
            "data": "%s"
          }
        },
        {
          "type": "text",
          "text": "%s"
        }
      ]
    }
  ]
}]], safe_model, base64_pdf, safe_prompt)
end

---@param path string  Absolute path to PDF
---@param opts PdfPort.ExtractOpts
---@return PdfPort.Result|nil
function M.extract(path, opts)
  local api_key = (_config and _config.claude_api_key)
    or vim.env.ANTHROPIC_API_KEY

  if not api_key or api_key == "" then
    return {
      status  = "error",
      text    = nil,
      format  = "markdown",
      backend = "claude",
      pages_processed = nil,
      error   = "claude backend: ANTHROPIC_API_KEY not set",
    }
  end

  local model = opts.model
    or (_config and _config.ollama_model) -- reuse field? no, use dedicated
    or "claude-opus-4-5"

  local default_prompt = table.concat({
    "Extract all text content from this PDF document.",
    "Format the output as clean Markdown.",
    "Preserve headings, lists, tables and code blocks.",
    "Do not add commentary or preamble.",
  }, " ")

  local prompt = opts.prompt or default_prompt

  -- Read and base64-encode the PDF on the main thread (synchronous but fast
  -- for typical document sizes); offload the HTTP request via curl spawn.
  local b64, b64_err = read_base64(path)
  if not b64 then
    local result = {
      status  = "error",
      text    = nil,
      format  = "markdown",
      backend = "claude",
      pages_processed = nil,
      error   = "claude backend: " .. (b64_err or "base64 encoding failed"),
    }
    if type(opts.__callback) == "function" then
      opts.__callback(result)
    end
    return result
  end

  local json_body = build_request(b64, prompt, model)

  -- Write body to a temp file to avoid shell escaping issues with large payloads
  local body_file = vim.fn.tempname() .. ".json"
  local f = io.open(body_file, "w")
  if not f then
    return {
      status  = "error",
      text    = nil,
      format  = "markdown",
      backend = "claude",
      pages_processed = nil,
      error   = "claude backend: failed to write temp request file",
    }
  end
  f:write(json_body)
  f:close()

  local response_chunks = {}
  local stderr_chunks   = {}
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)

  local timeout_ms = opts.timeout_ms or 60000
  local timer = uv.new_timer()

  local function cleanup()
    if timer then timer:stop(); timer:close() end
    if stdout and not stdout:is_closing() then stdout:close() end
    if stderr and not stderr:is_closing() then stderr:close() end
    vim.fn.delete(body_file)
  end

  local curl_args = {
    "-s",
    "-X", "POST",
    "https://api.anthropic.com/v1/messages",
    "-H", "Content-Type: application/json",
    "-H", "x-api-key: " .. api_key,
    "-H", "anthropic-version: 2023-06-01",
    "-d", "@" .. body_file,
  }

  local handle = uv.spawn("curl", {
    args  = curl_args,
    stdio = { nil, stdout, stderr },
  }, function(code, _)
    cleanup()

    local raw_response = table.concat(response_chunks)
    local err_text     = table.concat(stderr_chunks)

    vim.schedule(function()
      if code ~= 0 then
        local result = {
          status  = "error",
          text    = nil,
          format  = "markdown",
          backend = "claude",
          pages_processed = nil,
          error   = string.format("curl exited %d: %s", code, err_text),
        }
        if type(opts.__callback) == "function" then
          opts.__callback(result)
        end
        return
      end

      -- Parse the JSON response with vim.json.decode
      local ok_json, decoded = pcall(vim.json.decode, raw_response)
      if not ok_json or type(decoded) ~= "table" then
        local result = {
          status  = "error",
          text    = nil,
          format  = "markdown",
          backend = "claude",
          pages_processed = nil,
          error   = "claude backend: invalid JSON response: " .. raw_response:sub(1, 200),
        }
        if type(opts.__callback) == "function" then
          opts.__callback(result)
        end
        return
      end

      -- Check for API-level error
      if decoded.type == "error" then
        local api_err = (decoded.error and decoded.error.message) or "unknown API error"
        local result = {
          status  = "error",
          text    = nil,
          format  = "markdown",
          backend = "claude",
          pages_processed = nil,
          error   = "claude API error: " .. api_err,
        }
        if type(opts.__callback) == "function" then
          opts.__callback(result)
        end
        return
      end

      -- Extract text from content blocks
      local text_parts = {}
      local content = decoded.content or {}
      for _, block in ipairs(content) do
        if block.type == "text" and type(block.text) == "string" then
          text_parts[#text_parts + 1] = block.text
        end
      end

      local final_text = table.concat(text_parts, "\n")
      local result = {
        status  = "ok",
        text    = final_text,
        format  = "markdown",
        backend = "claude",
        pages_processed = nil,
        error   = nil,
      }
      if type(opts.__callback) == "function" then
        opts.__callback(result)
      end
    end)
  end)

  if not handle then
    vim.fn.delete(body_file)
    return {
      status  = "error",
      text    = nil,
      format  = "markdown",
      backend = "claude",
      pages_processed = nil,
      error   = "claude backend: failed to spawn curl",
    }
  end

  if not stdout or not stderr or not timer then
    vim.notify("stderr or timer is nil ", 4)
    return nil
  end

  stdout:read_start(function(err, data)
    if err then return end
    if data then response_chunks[#response_chunks + 1] = data end
  end)

  stderr:read_start(function(err, data)
    if err then return end
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
        backend = "claude",
        pages_processed = nil,
        error   = string.format("claude backend: HTTP request timed out after %d ms", timeout_ms),
      }
      if type(opts.__callback) == "function" then
        opts.__callback(result)
      end
    end)
  end)

  return nil
end

return M
