vim.g.start_time = vim.uv.hrtime()

-- Enable vim.loader for faster module loading
local loader_ok = pcall(function()
  vim.loader.enable()
end)

if not loader_ok then
  vim.notify("Using standard Neovim loader (vim.loader failed)", vim.log.levels.INFO)
end

-- Bootstrap lazy.nvim
vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"
vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({ "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Bootstrap lib.nvim
-- lib.nvim is a foundational dependency: plugin specs in lua/plugins/*.lua
-- require config modules that use lib.* already during the spec-import phase of
-- lazy.setup(). It must therefore be on the runtimepath BEFORE the specs are
-- imported, so we bootstrap it the same way as lazy.nvim itself. The lazy spec
-- in plugins/personal.lua keeps it updatable; this only guarantees early
-- availability.
--
-- Must resolve to the same dir plugins/personal/init.lua's apply_source() will
-- later assign to the "StefanBartl/lib.nvim" spec (local repos checkout when
-- present, else lazy's managed dir). Otherwise lazy sees the plugin's `dir`
-- change after it's already on the runtimepath and errors ("changed dir ...
-- already partially loaded") on every startup.
local libpath = require("plugins.personal.utils").local_dev("lib.nvim") or (vim.fn.stdpath("data") .. "/lazy/lib.nvim")
if not vim.uv.fs_stat(libpath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/StefanBartl/lib.nvim.git",
    libpath,
  })
end
vim.opt.rtp:prepend(libpath)
-- lazy.nvim installs its own module loader that does not search runtimepath
-- entries we add here, so during the plugin spec-import phase `require("lib.*")`
-- would still fail. Register lib.nvim on package.path as well — the C require
-- searcher is the universal fallback that lazy does not replace.
package.path = table.concat({
  libpath .. "/lua/?.lua",
  libpath .. "/lua/?/init.lua",
  package.path,
}, ";")

-- Setup lazy.nvim with plugins
local lazy_config = require("config.lazy")
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
  },
  -- Pin lib.nvim's `dir` as the very first spec fragment lazy.nvim sees for
  -- this plugin. Some imported files (e.g. plugins/nvchad.lua) run a
  -- top-level `require("lib.*")` during the spec-import phase, and others
  -- reference "StefanBartl/lib.nvim" as a bare dependency string; either one
  -- can register a dir-less fragment (defaulting to lazy's managed dir)
  -- before plugins/personal/init.lua's dir-overriding fragment is merged in,
  -- which trips lazy's "changed dir ... already partially loaded" error.
  -- plugins/personal/init.lua still owns the full spec (lazy=false,
  -- priority, config); this only pins `dir` early enough to avoid the race.
  { "StefanBartl/lib.nvim", dir = libpath },
  { import = "nvchad.plugins" },
  -- { import = "nvchad.blink.lazyspec" },
  { import = "plugins" },
  { import = "plugins.colorscheme" },
  { import = "plugins.ai" },
}, lazy_config)

-- Load base46 cache
pcall(dofile, vim.g.base46_cache .. "syntax")
pcall(dofile, vim.g.base46_cache .. "defaults")
pcall(dofile, vim.g.base46_cache .. "statusline")

-- =============================================================================
-- STARTUP PHASES
-- =============================================================================
-- Policy and rationale: docs/ARCHITECTURE/startup.md
-- Timeline and pending-phase check at runtime: :StartupReport
--
-- Two triggers only, and each phase must justify which one it uses:
--   startup.now(..)             synchronous — must exist before the first paint
--                               or before an event that fires during startup
--   startup.on("UIReady", ..)  after the UI is interactive — nothing can be
--                               typed or invoked before that point
--
-- Wall-clock timers (the old `defer_fn(.., 10|50)`) are deliberately not an
-- option: they cannot run before the event loop goes idle, which is ~2s AFTER
-- VimEnter here, so phases registering VimEnter/BufReadPost handlers silently
-- did nothing.
local startup = require("startup")
startup.setup_usercmds()
require("bindings.usrcmds.update_repos").enable()
require("bindings.usrcmds.plugin_repos").enable()
require("bindings.usrcmds.who_locks").enable()
require("bindings.usrcmds.docmap_all").enable()

-- --- synchronous ------------------------------------------------------------

-- Host environment snapshot (OS/shell/paths). Lives in lib.nvim now; the
-- `publish_globals` feature mirrors it to vim.g.is_windows/is_wsl/... for the
-- few consumers that read the globals (e.g. plugins/markdown.lua). `rpc_pipe`
-- starts the predictable Windows named-pipe RPC server (no-op off Windows).
-- `info_usercmd` registers :SystemInfo (cross-platform system info float,
-- formerly inline in bindings/mappings/general.lua).
-- Sync: publishes globals that later phases and plugin specs read.
startup.now("system", function()
  require("lib.nvim.system").setup({
    publish_globals = true,
    rpc_pipe = true,
    info_usercmd = true,
  })
end)

-- Sync: options shape how the first buffer is rendered.
startup.now("options", function()
  require("options")
end)

-- Sync: cheap monkeypatch, no reason to defer it. Fixes vim.ui.open() on
-- Windows truncating URLs at the first unescaped `&` (see config/ui_open.lua).
startup.now("ui_open", function()
  require("config.ui_open").setup()
end)

-- Sync: sets highlight groups and vim.diagnostic.config. Highlights must land
-- before the first paint to avoid a visible flash; the diagnostic config must
-- precede the first LSP attach.
startup.now("wkdoptions", function()
  require("wkdoptions").setup({ highlights = true, options = true, italic_keywords = true })
end)

-- Sync: THIS IS THE ONE THAT WAS BROKEN. autocmds/general registers a VimEnter
-- handler (kitty spacing) and autocmds/text a BufReadPost handler (last_loc).
-- Under the old 10ms timer both were registered ~2s after their events had
-- already fired, so neither ever ran. Registration must happen before VimEnter.
startup.now("autocmds", function()
  require("autocmds")
end)

-- Sync: lsp.setup() only registers configs and an LspAttach handler; servers
-- themselves start on FileType via vim.lsp.enable. Capabilities must be applied
-- globally before any client attaches, which can happen on the first
-- BufReadPost of a startup-argument file.
vim.env.LUA_LS_PROFILE = "normal" -- "minimal"|"normal"|"full"
startup.now("lsp", function()
  require("lsp").setup({ ensure_installing = false })

  local ok_caps, caps = pcall(require, "lsp.core.capabilities")
  if ok_caps and type(caps.apply_globally) == "function" then
    local applied, cap_warnings = caps.apply_globally()
    local cap_notify = require("lib.nvim.notify").create("[lsp.capabilities]")
    for _, w in ipairs(cap_warnings or {}) do
      -- w.level is "warn"|"error" (LspCaps.Warning); notify()'s own level
      -- param is a vim.log.levels integer, so route through the matching
      -- convenience method instead of passing the string through raw.
      if w.level == "error" then
        cap_notify.error(w.msg)
      else
        cap_notify.warn(w.msg)
      end
    end
    if not applied then
      cap_notify.error("Failed to apply capabilities globally")
    end
  end
end)

-- --- after the UI is interactive --------------------------------------------

-- UIReady: user commands cannot be invoked before the command line is usable.
startup.on("UIReady", "usrcmds", function()
  require("bindings.usrcmds")
end)

-- UIReady: keymaps cannot be pressed before the UI accepts input. This pulls
-- in ~19 submodules and is the single largest phase body, so keeping it off the
-- synchronous path is what actually shortens time-to-first-paint.
startup.on("UIReady", "mappings", function()
  require("bindings.mappings").setup()
end)

-- DAP setup (adapters, launch configs, UI, keymaps) lives in
-- StefanBartl/dap.nvim, loaded via lua/plugins/personal/init.lua (event =
-- "VeryLazy"). The former lua/wkddap prototype has been extracted there.

-- Show startup time
vim.defer_fn(function()
  if vim.g.start_time then
    local load_time = (vim.uv.hrtime() - vim.g.start_time) / 1e6
    vim.notify(string.format("Config loaded in %.2f ms", load_time), vim.log.levels.INFO)
  end
end, 0)

-- Für einen harten Kontrast: Weißer Hintergrund, schwarzer Text
vim.api.nvim_set_hl(0, "Visual", { bg = "#FFFFFF", fg = "#000000", bold = true })
