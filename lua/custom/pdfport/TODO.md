1. pdftottext.lua:

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

   └╴  pdftotext.lua  1

     └╴  Undefined field `__callback`. Lua Diagnostics. (undefined-field) [186, 14]





---@class PdfPort.ExtractOpts

---@field pages? integer[]          -- Page numbers to extract (1-based), nil = all

---@field max_pages? integer        -- Hard limit on pages processed

---@field prompt? string            -- Custom prompt for AI backends

---@field model? string             -- Model override for AI backends (ollama/claude)

---@field timeout_ms? integer       -- Extraction timeout in milliseconds



muss hier der tyoa ngeoasst werden? gib das nue fiel doder eine andere lösung aus



das geliche auch in



1. marker.lua

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





1. terminal.lua zeile 123

2. ---@param _ PdfPort.Result  (text field contains path for terminal mode)

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



   └╴  terminal.lua  2

     ├╴  Undefined field `path`. Lua Diagnostics. (undefined-field) [134, 21]

     └╴  Undefined field `pages`. Lua Diagnostics. (undefined-field) [140, 59]



sollte RenderOpts die richtige klasse sein, dann ist hes hier sie:

---@class PdfPort.RenderOpts

---@field mode PdfPort.RendererMode

---@field backend_id? PdfPort.BackendId     -- Force specific backend; nil = auto-resolve

---@field split? "vsplit"|"split"|"tab"     -- For buffer mode

---@diagnostic  disable-next-line

---@field float_opts? vim.api.keyset.win_config  -- For float mode

---@field terminal_tool? "ueberzug"|"chafa"|"kitty"|"imgcat"  -- For terminal mode

---@field focus? boolean                    -- Focus opened window after render



1. pdfport/init.lua zeile 137:

2. function M.extract(opts)

  if not _initialized then

    M.setup()

  end

  assert(type(opts) == "table", "pdfport.extract: opts must be a table")

  assert(type(opts.path) == "string", "pdfport.extract: opts.path must be a string")

  assert(type(opts.__callback) == "function", "pdfport.extract: opts.__callback must be a function")

  require("custom.pdfport.core.dispatcher").dispatch(opts, opts.__callback)

end

  ---@class PdfPort.ExtractOpts

---@field pages? integer[]          -- Page numbers to extract (1-based), nil = all

---@field max_pages? integer        -- Hard limit on pages processed

---@field prompt? string            -- Custom prompt for AI backends

---@field model? string             -- Model override for AI backends (ollama/claude)

---@field timeout_ms? integer       -- Extraction timeout in milliseconds
