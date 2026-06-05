-- =============================================================================
-- lua/custom/pdfport/renderers/terminal.lua
-- =============================================================================
---@module 'custom.pdfport.renderers.terminal'
---@brief Renders PDF pages as images in the terminal using ueberzug++, chafa,
---       kitty icat, or imgcat.
---@description
--- Each page of the PDF is first rasterized to a PNG via pdftoppm (poppler),
--- then displayed using the best available terminal image renderer.
--- Only the first page is shown by default; opts.pages controls which pages.

local term_mod = {}
local platform = require("custom.pdfport.platform")
local uv       = vim.uv or vim.loop

--- Rasterizes one PDF page to a temp PNG file.
---@param pdf_path string
---@param page integer  1-based page number
---@param dpi integer
---@param callback fun(png_path: string|nil, err: string|nil): nil
---@return nil
local function rasterize(pdf_path, page, dpi, callback)
  if not platform.has("pdftoppm") then
    callback(nil, "pdftoppm not found (install poppler-utils)")
    return
  end

  local tmp   = vim.fn.tempname()
  local args  = {
    "-png",
    "-r", tostring(dpi),
    "-f", tostring(page),
    "-l", tostring(page),
    "-singlefile",
    pdf_path,
    tmp,
  }

  local stderr_chunks = {}
  local stderr = uv.new_pipe(false)

  uv.spawn("pdftoppm", {
    args  = args,
    stdio = { nil, nil, stderr },
  }, function(code, _)
    if stderr and not stderr:is_closing() then stderr:close() end

    vim.schedule(function()
      local png = tmp .. ".png"
      if code ~= 0 or vim.fn.filereadable(png) ~= 1 then
        callback(nil, string.format(
          "pdftoppm exited %d: %s", code, table.concat(stderr_chunks)
        ))
        return
      end
      callback(png, nil)
    end)
  end)

  if not stderr then
    vim.notify("stderr is nil ", 4)
    return nil
  end


  stderr:read_start(function(_, data)
    if data then stderr_chunks[#stderr_chunks + 1] = data end
  end)
end

--- Displays a PNG file using the best available renderer.
---@param png_path string
---@param tool "ueberzug"|"chafa"|"kitty"|"imgcat"|nil
---@return nil
local function display_png(png_path, tool)
  tool = tool or platform.best_terminal_renderer()

  if not tool then
    vim.notify(
      "pdfport terminal: no image renderer found (install chafa or ueberzug++)",
      vim.log.levels.ERROR
    )
    vim.fn.delete(png_path)
    return
  end

  if tool == "chafa" then
    -- chafa: outputs ANSI art to stdout; display in a terminal buffer
    local width  = math.floor(vim.o.columns * 0.9)
    local height = math.floor(vim.o.lines   * 0.8)
    local cmd    = string.format(
      "chafa --size=%dx%d %s",
      width, height, vim.fn.shellescape(png_path)
    )
    -- Open a terminal buffer showing chafa output
    vim.cmd("split | terminal " .. cmd)
    vim.fn.delete(png_path)

  elseif tool == "kitty" then
    local exe = platform.has("kitten") and "kitten" or "kitty"
    vim.cmd("split | terminal " .. exe .. " icat " .. vim.fn.shellescape(png_path))
    vim.fn.delete(png_path)

  elseif tool == "imgcat" then
    vim.cmd("split | terminal imgcat " .. vim.fn.shellescape(png_path))
    vim.fn.delete(png_path)

  elseif tool == "ueberzug" then
    -- ueberzug++ requires a daemon; this sends a single draw command
    -- For a full integration, a persistent ueberzug layer is recommended.
    -- Here we fall back to chafa for simplicity.
    if platform.has("chafa") then
      local width  = math.floor(vim.o.columns * 0.9)
      local height = math.floor(vim.o.lines   * 0.8)
      local cmd    = string.format(
        "chafa --size=%dx%d %s",
        width, height, vim.fn.shellescape(png_path)
      )
      vim.cmd("split | terminal " .. cmd)
    else
      vim.notify(
        "pdfport terminal: ueberzug++ daemon mode not yet supported; install chafa as fallback",
        vim.log.levels.WARN
      )
    end
    vim.fn.delete(png_path)
  end
end

---@param _ PdfPort.Result  (text field contains path for terminal mode)
---@param opts PdfPort.RenderOpts
---@return nil
function term_mod.render(_, opts)
  local path = opts.path
  if not path or path == "" then
    vim.notify("pdfport terminal: no path provided", vim.log.levels.ERROR)
    return
  end

  local pages = (opts.pages and #opts.pages > 0) and opts.pages or { 1 }
  local tool  = opts.terminal_tool or platform.best_terminal_renderer()
  local dpi   = 150

  -- Render pages sequentially
  local function render_next(idx)
    if idx > #pages then return end

    rasterize(path, pages[idx], dpi, function(png, err)
      if not png then
        vim.notify("paramter argument png is nil", 4)
        return nil
      end
      if err then
        vim.notify("pdfport terminal: " .. err, vim.log.levels.ERROR)
        return
      end
      display_png(png, tool)
      -- Small delay between pages to avoid terminal flood
      vim.defer_fn(function()
        render_next(idx + 1)
      end, 500)
    end)
  end

  render_next(1)
end

return term_mod
