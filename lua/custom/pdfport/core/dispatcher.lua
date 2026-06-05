---@module 'custom.pdfport.core.dispatcher'
---@brief Central async dispatch logic for pdfport.
---@description
--- The dispatcher is the single point of coordination between callers
--- (integrations, user commands) and the backend/renderer pair.
---
--- Flow:
---   1. Validate input path
---   2. Resolve backend via resolver
---   3. Run extraction asynchronously in a libuv thread pool via vim.uv.new_work
---   4. On completion, call the renderer on the main thread via vim.schedule
---
--- Callers always get a non-blocking response; the callback receives a
--- PdfPort.Result on success or a result with status="error" on failure.

local uv = vim.uv or vim.loop
local resolver = require("custom.pdfport.core.resolver")
local registry = require("custom.pdfport.core.registry")

local M = {}

-- #############################################################################
-- Internal helpers
-- #############################################################################

---@type PdfPort.Config|nil
local _config = nil

--- Called by pdfport.init after setup().
---@param config PdfPort.Config
---@return nil
function M._set_config(config)
  _config = config
end

--- Constructs an error result table.
---@param msg string
---@param backend_id? PdfPort.BackendId
---@return PdfPort.Result
local function err_result(msg, backend_id)
  return {
    status = "error",
    text = nil,
    format = "plain",
    backend = backend_id or "none",
    pages_processed = nil,
    error = msg,
  }
end

--- Validates that the path exists and is a readable file.
---@param path string
---@return boolean ok
---@return string|nil error_msg
local function validate_path(path)
  if type(path) ~= "string" or path == "" then
    return false, "pdfport: path must be a non-empty string"
  end

  local stat = uv.fs_stat(path)
  if not stat then
    return false, string.format("pdfport: file not found: %s", path)
  end

  if stat.type ~= "file" then
    return false, string.format("pdfport: not a regular file: %s", path)
  end

  local ext = path:match("%.([^%.]+)$")
  if ext and ext:lower() ~= "pdf" then
    -- Warn but do not block — some PDFs may lack the extension
    if _config and _config.debug then
      vim.notify(
        string.format("pdfport: file does not have .pdf extension: %s", path),
        vim.log.levels.WARN
      )
    end
  end

  return true, nil
end

-- #############################################################################
-- Public API
-- #############################################################################

--- Extracts text from a PDF and delivers the result to a callback.
--- The extraction runs off the main thread; the callback is always
--- invoked on the main thread via vim.schedule.
---
---@param opts PdfPort.OpenOpts
---@param callback fun(result: PdfPort.Result): nil  Called with extraction result
---@return nil
function M.dispatch(opts, callback)
  assert(type(opts) == "table", "opts must be a table")
  assert(type(opts.path) == "string", "opts.path must be a string")
  assert(type(callback) == "function", "callback must be a function")

  -- Path validation happens on the main thread (uv.fs_stat is fast)
  local ok, err = validate_path(opts.path)
  if not ok then
    if err then
      vim.schedule(function()
        callback(err_result(err))
      end)
    end
    return
  end

  -- Handle system-open mode directly without extraction
  if opts.mode == "system" then
    local sys_renderer = registry.get_renderer("system")
    if not sys_renderer then
      vim.schedule(function()
        callback(err_result("pdfport: system renderer not registered"))
      end)
      return
    end

    vim.schedule(function()
      -- System-open does not need text; pass a minimal result
      sys_renderer({
        status = "ok",
        text = nil,
        format = "plain",
        backend = "system",
        pages_processed = nil,
        error = nil,
      }, opts)
    end)
    return
  end

  -- Handle terminal-preview mode (renders pages as images, no text extraction)
  if opts.mode == "terminal" then
    local term_renderer = registry.get_renderer("terminal")
    if not term_renderer then
      vim.schedule(function()
        callback(err_result("pdfport: terminal renderer not registered"))
      end)
      return
    end

    vim.schedule(function()
      term_renderer({
        status = "ok",
        text = opts.path, -- path used by renderer directly
        format = "plain",
        backend = "terminal",
        pages_processed = nil,
        error = nil,
      }, opts)
    end)
    return
  end

  -- Resolve extraction backend
  local backend, resolve_err = resolver.resolve(opts.backend_id)
  if not backend then
    vim.schedule(function()
      callback(err_result(resolve_err or "pdfport: no backend resolved"))
    end)
    return
  end

  -- Merge global extract opts with per-call opts
  local cfg_extract = (_config and _config.extract_opts) or {}
  ---@type PdfPort.ExtractOpts
  local extract_opts = vim.tbl_deep_extend("force", cfg_extract, {
    pages = opts.pages,
    max_pages = opts.max_pages,
    prompt = opts.prompt,
    model = opts.model,
    timeout_ms = opts.timeout_ms,
  })

  local path = opts.path
  local backend_id = backend.id
  local extract_fn = backend.extract

  -- Run extraction in libuv work queue (non-blocking)
  -- NOTE: extract_fn must be safe to call from a non-main thread context.
  -- Backends that call vim.fn or vim.api must wrap their work in vim.schedule.
  -- For backends that spawn external processes (pdftotext, marker, ...),
  -- the spawning itself happens on the main thread inside the backend, with
  -- stdout collected asynchronously, so they schedule their own callbacks.
  -- We therefore invoke extract_fn on the main thread and let it own async.
  vim.schedule(function()
    local ok_extract, result = pcall(extract_fn, path, extract_opts)

    if not ok_extract then
      -- extract_fn threw a Lua error (not a process failure)
      callback(
        err_result(
          string.format("pdfport: backend '%s' threw: %s", backend_id, tostring(result)),
          backend_id
        )
      )
      return
    end

    -- result may arrive synchronously (error case) or via an inner callback
    -- For backends that are truly async (claude, ollama), they call callback
    -- themselves and return nil here.
    if result ~= nil then
      callback(result)
    end
  end)
end

--- Convenience wrapper: extract and immediately render.
---@param opts PdfPort.OpenOpts
---@return nil
function M.open(opts)
  assert(type(opts) == "table", "opts must be a table")
  assert(type(opts.path) == "string", "opts.path must be a string")

  local mode = opts.mode
    or ((_config and _config.render_opts and _config.render_opts.mode) or "buffer")
  opts.mode = mode

  M.dispatch(opts, function(result)
    if result.status == "error" then
      vim.notify(result.error or "pdfport: unknown extraction error", vim.log.levels.ERROR)
      return
    end

    local renderer = registry.get_renderer(mode)
    if not renderer then
      vim.notify(string.format("pdfport: renderer '%s' not registered", mode), vim.log.levels.ERROR)
      return
    end

    -- Merge global render opts
    local cfg_render = (_config and _config.render_opts) or {}
    local render_opts = vim.tbl_deep_extend("force", cfg_render, opts)

    renderer(result, render_opts)
  end)
end

return M
