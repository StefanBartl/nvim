---@module 'custom.pdfport.backends.ollama'
---@brief Extraction backend using a local ollama multimodal model.
---@description
--- Rasterizes each requested PDF page to a PNG via pdftoppm, then sends
--- each image to the ollama /api/generate endpoint as a base64-encoded
--- vision prompt. Results from all pages are concatenated.
---
--- Requires: ollama daemon running, pdftoppm (poppler-utils), curl

local platform = require("custom.pdfport.platform")
local uv       = vim.uv or vim.loop

---@type PdfPort.ConfigurableBackend
local M = {
  id   = "ollama",
  name = "Ollama (local multimodal)",

  capabilities = {
    markdown    = true,
    tables      = true,
    ocr         = true,
    remote      = false,
    gpu_optional = true,
  },
}

---@type PdfPort.Config|nil
local _config = nil

---@param config PdfPort.Config
---@return nil
function M._set_config(config)
  _config = config
end

---@return boolean
function M.available()
  return platform.has("ollama") and platform.has("pdftoppm") and platform.has("curl")
end

--- Rasterizes a single PDF page to a temp PNG synchronously.
--- Returns the PNG path or nil on failure.
---@param pdf_path string
---@param page integer  1-based
---@return string|nil png_path
local function rasterize_sync(pdf_path, page)
  local tmp  = vim.fn.tempname()
  local args = {
    "-png", "-r", "150",
    "-f", tostring(page), "-l", tostring(page),
    "-singlefile",
    pdf_path, tmp,
  }

  -- Synchronous spawn via vim.fn.system for simplicity in a sequential loop
  vim.fn.system(vim.list_extend({ "pdftoppm" }, args))

  local png = tmp .. ".png"
  if vim.fn.filereadable(png) == 1 then
    return png
  end
  return nil
end

--- Base64-encodes a file in pure Lua to avoid depending on an external
--- `base64` binary (not available by default on Windows).
---@param path string
---@return string|nil b64
---@return string|nil error_msg
local function b64_encode(path)
  local f = io.open(path, "rb")
  if not f then
    return nil, "b64_encode: cannot open file: " .. path
  end

  local data = f:read("*a")
  f:close()

  if not data then
    return nil, "b64_encode: failed to read file: " .. path
  end

  -- RFC 4648 base64 alphabet
  local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  local result   = {}
  local i        = 1
  local len      = #data

  while i <= len do
    local b1 = data:byte(i)     or 0
    local b2 = data:byte(i + 1) or 0
    local b3 = data:byte(i + 2) or 0

    local n = b1 * 65536 + b2 * 256 + b3

    result[#result + 1] = b64chars:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
    result[#result + 1] = b64chars:sub(math.floor(n / 4096)   % 64 + 1, math.floor(n / 4096)   % 64 + 1)
    result[#result + 1] = i + 1 <= len and b64chars:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1) or "="
    result[#result + 1] = i + 2 <= len and b64chars:sub(n % 64 + 1, n % 64 + 1) or "="

    i = i + 3
  end

  return table.concat(result), nil
end

--- Sends a prompt to ollama, optionally with a base64 image.
--- Vision models (llava, bakllava) require the image field.
--- Text-only models (qwen, mistral, llama) must NOT receive an images field.
---@param b64 string|nil  Base64 image, or nil for text-only models
---@param prompt string
---@param model string
---@param host string
---@param timeout_ms integer
---@param callback fun(text: string|nil, err: string|nil): nil
---@return nil
local function query_ollama(b64, prompt, model, host, timeout_ms, callback)
  local safe_prompt = prompt:gsub('"', '\\"'):gsub("\n", "\\n")
  local safe_model  = model:gsub('"', '\\"')

  local body
  if b64 then
    body = string.format(
      '{"model":"%s","prompt":"%s","images":["%s"],"stream":false}',
      safe_model, safe_prompt, b64
    )
  else
    body = string.format(
      '{"model":"%s","prompt":"%s","stream":false}',
      safe_model, safe_prompt
    )
  end

  local body_file = vim.fn.tempname() .. ".json"
  local f = io.open(body_file, "w")
  if not f then
    callback(nil, "ollama: failed to write temp request file")
    return
  end
  f:write(body)
  f:close()

  local response_chunks = {}
  local stderr_chunks   = {}
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)

  local timer = uv.new_timer()

  local function cleanup()
    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end
    if stdout and not stdout:is_closing() then stdout:close() end
    if stderr and not stderr:is_closing() then stderr:close() end
    -- vim.fn.delete must run on the main thread
    vim.schedule(function()
      vim.fn.delete(body_file)
    end)
  end

  local handle = uv.spawn("curl", {
    args = {
      "-s", "-X", "POST",
      host .. "/api/generate",
      "-H", "Content-Type: application/json",
      "-d", "@" .. body_file,
    },
    stdio = { nil, stdout, stderr },
  }, function(code, _)
    cleanup()

    local raw = table.concat(response_chunks)
    local err = table.concat(stderr_chunks)

    vim.schedule(function()
      if code ~= 0 then
        callback(nil, string.format("curl exited %d: %s", code, err))
        return
      end

      -- Check for ollama-level error before parsing response
      local first_line = vim.trim(vim.split(raw, "\n", { plain = true })[1] or "")
      if first_line ~= "" then
        local ok_err, err_obj = pcall(vim.json.decode, first_line)
        if ok_err and type(err_obj) == "table" and type(err_obj.error) == "string" then
          callback(nil, "ollama error: " .. err_obj.error
            .. "\n\nInstall the model with:  ollama pull " .. model)
          return
        end
      end
      -- stream:false. The final object has "done":true and contains the
      -- complete "response" field. Scan lines in reverse to find it.
      local lines = vim.split(raw, "\n", { plain = true })
      local text  = nil

      for i = #lines, 1, -1 do
        local line = vim.trim(lines[i])
        if line ~= "" then
          local ok_json, decoded = pcall(vim.json.decode, line)
          if ok_json and type(decoded) == "table" then
            if type(decoded.response) == "string" then
              text = decoded.response
              break
            end
          end
        end
      end

      if not text then
        -- Fallback: concatenate all response fields across all lines
        local parts = {}
        for _, line in ipairs(lines) do
          local line_t = vim.trim(line)
          if line_t ~= "" then
            local ok_json, decoded = pcall(vim.json.decode, line_t)
            if ok_json and type(decoded) == "table" and type(decoded.response) == "string" then
              parts[#parts + 1] = decoded.response
            end
          end
        end
        if #parts > 0 then
          text = table.concat(parts)
        end
      end

      if not text then
        callback(nil, "ollama: response field missing. Raw: " .. raw:sub(1, 300))
        return
      end

      callback(text, nil)
    end)
  end)

  if not handle then
    vim.fn.delete(body_file)
    callback(nil, "ollama: failed to spawn curl")
    return
  end

  if not stdout then
    vim.notify("stdout is nil", 4)
    return
  end

  stdout:read_start(function(_, data)
    if data then response_chunks[#response_chunks + 1] = data end
  end)

  if not stderr then
    vim.notify("stderr is nil", 4)
    return
  end

  stderr:read_start(function(_, data)
    if data then stderr_chunks[#stderr_chunks + 1] = data end
  end)

  if not timer then
    vim.notify("timer is nil", 4)
    return
  end

  timer:start(timeout_ms, 0, function()
    if handle and not handle:is_closing() then handle:kill(15) end
    cleanup()
    vim.schedule(function()
      callback(nil, string.format("ollama: request timed out after %d ms", timeout_ms))
    end)
  end)
end

---@param path string
---@param opts PdfPort.InternalExtractOpts
---@return PdfPort.Result|nil
function M.extract(path, opts)
  local host    = (_config and _config.ollama_host)  or "http://localhost:11434"
  local model   = opts.model or (_config and _config.ollama_model) or "llava"
  local prompt  = opts.prompt or
    "Extract all visible text from this image. Format the output as Markdown."
  local pages   = (opts.pages and #opts.pages > 0) and opts.pages
    or (opts.max_pages and (function()
         local t = {}
         for i = 1, opts.max_pages do t[i] = i end
         return t
       end)())
    or { 1 }

  local timeout_ms  = opts.timeout_ms or 60000
  local page_texts  = {}
  local page_idx    = 1

  -- Detect whether the model is a vision model by name convention.
  -- Known vision models contain "llava", "bakllava", "moondream", "vision".
  local is_vision_model = model:lower():match("llava")
    or model:lower():match("bakllava")
    or model:lower():match("moondream")
    or model:lower():match("vision")

  local function process_next()
    if page_idx > #pages then
      local final = table.concat(page_texts, "\n\n---\n\n")
      local result = {
        status          = "ok",
        text            = final,
        format          = "markdown",
        backend         = "ollama",
        pages_processed = #pages,
        error           = nil,
      }
      if type(opts.__callback) == "function" then
        opts.__callback(result)
      end
      return
    end

    local page     = pages[page_idx]
    page_idx       = page_idx + 1

    if is_vision_model then
      -- Vision path: rasterize page -> base64 -> send image to model
      local png = rasterize_sync(path, page)
      if not png then
        local result = {
          status  = "error",
          text    = nil,
          format  = "markdown",
          backend = "ollama",
          pages_processed = page_idx - 2,
          error   = string.format("ollama: failed to rasterize page %d", page),
        }
        if type(opts.__callback) == "function" then opts.__callback(result) end
        return
      end

      local b64, b64_err = b64_encode(png)
      vim.fn.delete(png)

      if not b64 then
        local result = {
          status  = "error",
          text    = nil,
          format  = "markdown",
          backend = "ollama",
          pages_processed = page_idx - 2,
          error   = string.format("ollama: %s", b64_err or "base64 encoding failed"),
        }
        if type(opts.__callback) == "function" then opts.__callback(result) end
        return
      end

      query_ollama(b64, prompt, model, host, timeout_ms, function(text, err)
        if err then
          local result = {
            status  = "error",
            text    = nil,
            format  = "markdown",
            backend = "ollama",
            pages_processed = page_idx - 2,
            error   = err,
          }
          if type(opts.__callback) == "function" then opts.__callback(result) end
          return
        end
        page_texts[#page_texts + 1] = string.format("<!-- page %d -->\n%s", page, text or "")
        process_next()
      end)

    else
      -- Text path: extract page text via pdftotext, send as plain prompt
      local raw_text = vim.fn.system({
        "pdftotext", "-f", tostring(page), "-l", tostring(page), path, "-"
      })

      local page_prompt = string.format(
        "%s\n\nPage %d content:\n%s", prompt, page, raw_text
      )

      query_ollama(nil, page_prompt, model, host, timeout_ms, function(text, err)
        if err then
          local result = {
            status  = "error",
            text    = nil,
            format  = "markdown",
            backend = "ollama",
            pages_processed = page_idx - 2,
            error   = err,
          }
          if type(opts.__callback) == "function" then opts.__callback(result) end
          return
        end
        page_texts[#page_texts + 1] = string.format("<!-- page %d -->\n%s", page, text or "")
        process_next()
      end)
    end
  end

  -- Kick off async page processing
  vim.schedule(process_next)
  return nil
end

return M
