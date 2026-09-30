---@module 'plugins.personal.specs.view'
--- View & render -- personal plugin specs (Statusline/theme, pictures, video, PDF and markdown rendering.)
---
--- Category names follow the plugin website's registry
--- (wkd/src/data/registry.json). Source control -- local vs. remote vs.
--- disabled -- is NOT decided here but in plugins.personal.core.source; this
--- file only declares the specs. Registered from plugins/personal/init.lua.

---@type LazyPluginSpec[]
return {
  {
    -- Statusline/tabline/theme -- needs neither NvChad nor base46 (see the
    -- plugin's own README). `config/ui_statusline.lua` wires this host's own
    -- statusline into it at UIReady.
    --
    -- No `opts`/`config` on purpose, same reason as my.nvim/lsp.nvim above:
    -- the actual setup() calls happen from a startup phase (UIReady) rather
    -- than a lazy hook.
    --
    -- `keymaps` below IS read, though -- by config/ui_statusline/init.lua, at
    -- that same UIReady phase, via `require("lazy.core.config")
    -- .plugins["ui.nvim"].keymaps` -- a plain custom field on this spec
    -- rather than lazy's own `opts`, since `opts` alone (even with no
    -- `config` function) makes lazy auto-run `require("ui").setup(opts)`
    -- immediately, at plugin-load time, well before UIReady. Passed through
    -- to `ui.setup({ keymaps = ... })` unchanged: `true` (or this field left
    -- out entirely) binds every shipped default with no opt-in needed --
    -- same "on unless you say otherwise" shape my.nvim's own `setup(opts)`
    -- uses -- `false` binds none of them, or a table
    -- (`{ next = "<C-Right>", close = false }`, see ui.nvim's
    -- docs/BINDINGS.md) remaps or drops individual actions, leaving the
    -- rest at their default. Set to `true` explicitly here anyway, so this
    -- line is the one place documenting that ui.nvim's keymaps are wanted
    -- at all -- not because the value itself differs from leaving it out.
    "StefanBartl/ui.nvim",
    lazy = false,
    priority = 900,
    dependencies = { "StefanBartl/lib.nvim" },
    keymaps = true,
  },

  {
    "StefanBartl/color_my_ascii.nvim",
    ft = "markdown",
    dependencies = { "StefanBartl/lib.nvim" }, -- optional, enables graceful keymap/notify integration
    -- Typing `opts` as ColorMyAscii.Config makes lua_ls offer value completion
    -- inside the config (e.g. `preset = "…"` suggests the fence-line presets).
    -- Requires the plugin's types on the LSP path (lazydev/neodev or workspace lib).
    opts = {
      -- Force the CommonMark-correct heuristic scanner for fence-block
      -- detection instead of treesitter: the installed markdown grammar
      -- version can differ machine-to-machine (no lockfile pinning), and
      -- some versions mis-parse a shorter fence nested inside a longer one
      -- as its own block, causing spurious fence-line highlights.
      treesitter = { block_detection = false },
    },
  },

  {
    "StefanBartl/images.nvim",
    -- Replaces snacks.image, which cannot work here in principle: it only
    -- sends Kitty APC, and WezTerm never draws that when Neovim is the
    -- sender. images.nvim uses OSC 1337 instead.
    --
    -- Both names are needed: `:Image` covers the command, the filetypes
    -- make sure <leader>im and the double-click are set in Markdown buffers
    -- even without a prior command call.
    cmd = { "Image" },
    ft = { "markdown", "vimwiki", "norg", "text" },
    dependencies = { "StefanBartl/lib.nvim" },
    -- cell_aspect: measured width/height ratio of this WezTerm setup (the 0.5
    -- default in images.scale leaves an empty strip below images).
    --
    -- terminal_padding is deliberately NOT set here: it lives in the stored
    -- calibration written by `:Image calibrate` (stdpath("data")/images.nvim),
    -- and an explicit option here would silently override it. draw_inset
    -- catches whatever sub-cell remainder is left after that.
    --
    -- ocr.lang: `:Image ocr` and `:Case ocr` read customer screenshots, and
    -- those are German or English depending on which system produced them --
    -- tesseract takes both at once in this form. Both language files are
    -- installed here; `:checkhealth images` checks each half separately and
    -- says so if one goes missing.
    opts = {
      display = { cell_aspect = 0.46 },
      ocr = { lang = "deu+eng" },
    },
  },

  {
    "StefanBartl/mdview.nvim",
    dependencies = { "StefanBartl/lib.nvim" },
    build = "npm ci && npm run build:go && npm run build",
    ft = { "markdown" },
    cmd = { "MDView" },
    config = function()
      -- Non-default choices only; the feedback log behind each (which
      -- experimental flags earned "make this the default") lives in
      -- mdview.nvim's own ROADMAP, not here.
      require("mdview").setup({
        browser = {
          -- shiki mis-highlights some fences; hljs until that is fixed upstream.
          highlighter = "hljs",
          focus = "nvim",
          cursor_marker = "caret",
        },
        -- Release build (from GitHub Releases, no toolchain needed). To test a
        -- locally built relay, uncomment and see mdview.nvim/docs/development.md
        -- (`npm run build:go` produces `mdview-server` without .exe on Windows):
        -- dev = {
        -- binary_path = vim.env.REPOS_DIR .. "/mdview.nvim/native/server/mdview-server",
        -- web_root = vim.env.REPOS_DIR .. "/mdview.nvim/dist/client",
        -- },
        -- standalone = {
        -- binary_path = vim.env.REPOS_DIR .. "/mdview.nvim/native/server/mdview-server",
        -- },
        experimental = {
          line_diff = true, -- send only changed lines to the browser
          click_navigate = true, -- relative link opens the file in nvim
          reverse_scroll = true, -- browser scroll moves the nvim cursor
        },
      })
    end,
  },

  {
    "StefanBartl/media.nvim",
    -- `VeryLazy` rather than `cmd = "Media"`: the four `<leader>M` keys have to
    -- exist before one is pressed, and a cmd trigger cannot bind them. The
    -- plugin file itself registers nothing at startup, so the cost is one
    -- require.
    --
    -- hover.nvim consumes this by name (`pcall(require, "media")`) for its
    -- video previews; it is listed as a dependency there rather than here, and
    -- neither plugin needs the other to load first.
    event = "VeryLazy",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- Every option media.nvim has, current value active and everything
      -- else commented out with its own default -- see docs/configuration.md
      -- for the full reasoning behind each one.

      -- Explicit binary paths, for when one is installed but not on PATH
      -- (the Windows winget/scoop shim-dir case). `core.bin` probes the
      -- usual locations itself; this is the escape hatch for what it misses.
      -- `:checkhealth media` says whether ffmpeg was found -- on this
      -- machine it is NOT installed yet:
      --   winget install Gyan.FFmpeg   (then restart the terminal for PATH)
      -- bin = { ffmpeg = nil, ffprobe = nil, mpv = nil },

      -- Hard ceiling on one ffmpeg/ffprobe run, in ms -- the backstop for a
      -- stalled network mount or a truncated download that would otherwise
      -- hang forever.
      -- timeout_ms = 15000,

      -- The poster frame (`media.frame` / `:Media frame`).
      frame = { at = "10%", width = 800 },
      -- frame = {
      --   at = "10%",   -- seconds, "10%" of duration, or an ffmpeg timestamp
      --   width = 800,  -- pixel width the still is scaled to
      -- },

      -- A run of stills at a fixed rate (`media.frames`) -- what hover.nvim's
      -- *inline* transport draws as moving picture.
      -- frames = {
      --   from = nil,     -- nil starts at the beginning
      --   fps = 12,       -- stills per second of source sampled
      --   count = 24,     -- stills per run -- two seconds at fps=12
      --   width = 320,    -- pixel width before sampling down to cells
      -- },

      -- The contact sheet (`media.sheet` / `:Media sheet`): one picture of
      -- the whole file.
      sheet = { rows = 3, cols = 4, width = 1200 },
      -- sheet = {
      --   rows = 3, cols = 4,
      --   width = 1200,     -- of the finished sheet, not one tile
      --   margin = 4,       -- gap between tiles, in pixels
      --   timeout_ms = 120000, -- a sheet is a full pass over the file, not a seek
      -- },

      -- Where rendered stills live, on disk, outliving the session (keyed by
      -- the source file's mtime, so a kept file is safe to serve forever).
      -- cache = {
      --   enabled = true,
      --   dir = nil, -- nil means stdpath("cache") .. "/media.nvim"
      -- },

      -- What `media.play` / `:Media play` launches -- also what hover.nvim's
      -- system-player fallback tier uses when there is no mpv (or
      -- `video.use_mpv = false`). nil hands the file to the system's default
      -- handler, which on Windows opens *behind* the terminal either way --
      -- Windows only grants foreground to the process owning it, which
      -- inside a terminal is the terminal host, not nvim.exe. Set to "mpv"
      -- (or { "mpv", "--loop-file=no" }) to override.
      player = nil,

      -- The windowed mpv player (`media.play_window` / `:Media window` /
      -- hover.nvim's `<CR>`). Always mpv, unlike `player` above -- a
      -- controllable window needs the same binary every time.
      -- window = {
      --   autofit = "80%x80%", -- mpv's --autofit-larger; "" leaves size to mpv
      --   ontop = true,        -- stay above the terminal regardless of focus
      --   args = {},           -- extra mpv flags, appended before the file
      -- },
      --
      -- NOTE: no static `window.args = { "--screen=1" }` here on purpose.
      -- hover.nvim's `<CR>` now detects which monitor the terminal is on and
      -- passes a per-call `screen` to `play_window` itself (2026-09-09) --
      -- a static `--screen=1` in `args` would be appended *after* that and
      -- win, silently overriding the dynamic detection and pinning the
      -- window back to one monitor regardless of where nvim actually is.
      -- Only add this back if the dynamic detection is ever turned off.

      keymaps = { preset = true },
      -- keymaps = {
      --   preset = true,       -- false binds nothing at all
      --   probe = "<leader>Mp",
      --   frame = "<leader>Mf",
      --   sheet = "<leader>Ms",
      --   play = "<leader>Mo",
      --   which_key = true,
      -- },
    },
  },

  {
    "StefanBartl/pdfport.nvim",
    -- Only ":PdfPort <sub>" is ever registered (composer.verb, see
    -- lua/pdfport/bindings/usrcmds.lua); the plugin has no separate
    -- PdfPortText/Float/System/Terminal/Health commands.
    cmd = "PdfPort",
    opts = {
      default_backend = "auto",
      fallback_chain = { "pdftotext", "pdfplumber", "marker", "docling", "ollama", "claude" },
      extract_opts = { max_pages = nil, timeout_ms = 30000 },
      render_opts = { mode = "buffer", split = "current", focus = true },
      claude_api_key = nil,
      -- OCR/AI backends run for minutes on a large PDF. Not cancellable from
      -- the indicator (see pdfport's docs), so a non-interactive style only.
      progress_style = "statusline",
      ollama_host = "http://localhost:11434",
      ollama_model = "qwen2.5-coder:7b",
      debug = false,
    },
  },
}
