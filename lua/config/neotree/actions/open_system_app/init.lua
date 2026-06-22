---@module 'config.neotree.actions.open_system_app'
---@brief Opens files with their OS-default application from within neo-tree.
---@description
--- Follows the same `attach(opts)` pattern used by other neotree config
--- modules (find_or_grep_menu, current_hl, marks, …).
---
--- How it works:
---
---   1. Call `require("config.neotree.actions.open_system_app").attach(opts)`
---      inside `config = function(_, opts)` BEFORE `require("neo-tree").setup(opts)`.
---   2. The module injects a custom command `"open_system_app"` into `opts.commands`
---      and wires `<Tab>` / `<CR>` in every source's `window.mappings` so that
---      nodes whose extension is in the configured set are handed off to the OS;
---      all other nodes fall through to neo-tree's native `"open"` action.
---
--- Cross-platform opener:
---   • Linux   → xdg-open   (async via uv.spawn, detached)
---   • macOS   → open       (async via uv.spawn, detached)
---   • Windows → cmd /c start
---
--- Usage in plugins/neotree.lua:
---
---   config = function(_, opts)
---     require("config.neotree.actions.open_system_app").setup({
---       extra_filetypes = { "docx", "xlsx" },   -- add to defaults
---       notify_on_open  = true,
---     })
---     require("config.neotree.actions.open_system_app").attach(opts)
---
---     require("config.neotree.actions.find_or_grep_menu").attach(opts)
---     require("config.neotree.current_hl").attach(opts)
---     require("neo-tree").setup(opts)
---     ...
---   end,
---
---@see config.neotree.actions.open_system_app.types

-- ─────────────────────────────────────────────────────────────────────────────
-- Imports
-- ─────────────────────────────────────────────────────────────────────────────

local notify = require("lib.nvim.notify").create("[neotree.open_system_app]")

-- ─────────────────────────────────────────────────────────────────────────────
-- Module
-- ─────────────────────────────────────────────────────────────────────────────

---@class OpenSysApp.Module
local M = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Defaults
-- ─────────────────────────────────────────────────────────────────────────────

---Default filetypes that are opened with the system application.
---@type string[]
M.DEFAULT_FILETYPES = {
  -- Documents
  "pdf",

  -- Raster images
  "png", "jpg", "jpeg", "gif", "bmp", "webp", "tiff", "tif", "ico", "heic", "heif",

  -- Vector / design
  "svg", "ai", "psd", "xcf", "sketch", "fig",

  -- Video
  "mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "m4v",

  -- Audio
  "mp3", "wav", "flac", "ogg", "aac", "m4a", "opus",

  -- Office / binary documents
  "docx", "doc", "odt", "xlsx", "xls", "ods", "pptx", "ppt", "odp",

  -- Archives (open with system manager, not Neovim)
  "zip", "tar", "gz", "bz2", "xz", "7z", "rar",
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal state
-- ─────────────────────────────────────────────────────────────────────────────

---@type OpenSysApp.Config
local _cfg = {
  filetypes      = {},   -- populated by setup()
  notify_on_open = true,
  notify_on_error = true,
}

---@type boolean
local _setup_done = false

-- ─────────────────────────────────────────────────────────────────────────────
-- Platform detection
-- ─────────────────────────────────────────────────────────────────────────────

---@return OpenSysApp.OpenCmd
local function detect_opener()
  local ok, cross = pcall(require, "lib.nvim.cross")
  if ok and type(cross) == "table" then
    if cross.is_windows and cross.is_windows() then return "cmd.exe" end
    if cross.is_mac    and cross.is_mac()     then return "open"     end
    return "xdg-open"
  end

  local uv     = vim.uv or vim.loop
  local uname  = uv.os_uname()
  local sys    = (uname and uname.sysname or ""):lower()

  if sys:find("windows") then return "cmd.exe" end
  if sys == "darwin"     then return "open"     end
  return "xdg-open"
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

---Extract the lowercase extension of a path (without leading dot).
---@param path string
---@return string
local function ext(path)
  return (path:match("%.([^./\\]+)$") or ""):lower()
end

---@param list string[]
---@return table<string, true>
local function to_set(list)
  local s = {}
  for i = 1, #list do
    s[list[i]:lower():gsub("^%.", "")] = true
  end
  return s
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public: query
-- ─────────────────────────────────────────────────────────────────────────────

---Returns true when *path*'s extension should be opened by the system app.
---@param path string
---@return boolean
function M.is_handled(path)
  if type(path) ~= "string" or path == "" then return false end
  return _cfg.filetypes[ext(path)] == true
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public: open
-- ─────────────────────────────────────────────────────────────────────────────

---Asynchronously open *path* with the OS-default application.
---@param path string  Absolute path to the file.
---@return nil
function M.open(path)
  if type(path) ~= "string" or path == "" then
    if _cfg.notify_on_error then
      notify.error("open(): received empty or invalid path")
    end
    return
  end

  local uv     = vim.uv or vim.loop
  local opener = detect_opener()
  local args   = opener == "cmd.exe"
    and { "/c", "start", '""', path }
    or  { path }

  local handle
  local ok, spawn_err = pcall(function()
    handle = uv.spawn(opener, {
      args   = args,
      detach = true,
      stdio  = { nil, nil, nil },
    }, function(code)
      if handle then handle:close() end
      if code ~= 0 and _cfg.notify_on_error then
        vim.schedule(function()
          notify.error(string.format(
            "'%s' exited with code %d  (%s)",
            opener, code, vim.fn.fnamemodify(path, ":t")
          ))
        end)
      end
    end)
  end)

  if not ok or not handle then
    if _cfg.notify_on_error then
      notify.error(string.format(
        "Failed to spawn '%s': %s", opener, tostring(spawn_err)
      ))
    end
    return
  end

  if _cfg.notify_on_open then
    notify.info(string.format(
      "Opening with system app: %s",
      vim.fn.fnamemodify(path, ":t")
    ))
  end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public: setup
-- ─────────────────────────────────────────────────────────────────────────────

---Configure the module once. Safe to call multiple times (idempotent).
---@param opts? OpenSysApp.Opts
---@return nil
function M.setup(opts)
  if _setup_done then return end

  opts = type(opts) == "table" and opts or {}

  -- Resolve filetype set.
  local base = (type(opts.filetypes) == "table" and #opts.filetypes > 0)
    and opts.filetypes
    or  M.DEFAULT_FILETYPES

  local extra = type(opts.extra_filetypes) == "table"
    and opts.extra_filetypes
    or  {}

  -- Merge base + extra into a lookup set.
  local merged = {}
  for i = 1, #base  do merged[#merged + 1] = base[i]  end
  for i = 1, #extra do merged[#merged + 1] = extra[i]  end

  _cfg.filetypes      = to_set(merged)
  _cfg.notify_on_open = opts.notify_on_open  ~= false
  _cfg.notify_on_error = opts.notify_on_error ~= false

  _setup_done = true
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public: attach  (called before require("neo-tree").setup(opts))
-- ─────────────────────────────────────────────────────────────────────────────

---Inject the `open_system_app` command and mapping into *opts* in-place.
---Must be called BEFORE `require("neo-tree").setup(opts)`.
---@param opts table  The neo-tree opts table (mutated in place).
---@return nil
function M.attach(opts)
  -- Ensure setup() has run with at least the defaults.
  if not _setup_done then
    M.setup()
  end

  -- ── 1. Register the command ──────────────────────────────────────────────

  opts.commands = opts.commands or {}

  ---The neo-tree command that drives the feature.
  opts.commands["open_system_app"] = function(state)
    local node = state.tree:get_node()
    if not node then return end

    local path = node:get_id()

    if M.is_handled(path) then
      M.open(path)
    else
      -- Fall through to neo-tree's built-in open for everything else.
      require("neo-tree.sources.common.commands").open(state)
    end
  end

  -- ── 2. Wire the mapping into every source ────────────────────────────────
  --
  -- Sources that carry their own window.mappings table:
  local sources_with_window = {
    "filesystem",
    "buffers",
    "git_status",
    "document_symbols",
    "diagnostics",
    "tests",
  }

  -- Helper: merge the two keys into a mappings table.
  local function inject(mappings)
    mappings = mappings or {}
    mappings["<Tab>"] = "open_system_app"
    mappings["<CR>"]  = "open_system_app"
    return mappings
  end

  -- Top-level window mappings (shared fallback).
  opts.window = opts.window or {}
  opts.window.mappings = inject(opts.window.mappings)

  -- Per-source window mappings (override the shared ones when present).
  for _, src in ipairs(sources_with_window) do
    local src_cfg = opts[src]
    if type(src_cfg) == "table" then
      src_cfg.window = src_cfg.window or {}
      src_cfg.window.mappings = inject(src_cfg.window.mappings)
    end
  end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public: get_config
-- ─────────────────────────────────────────────────────────────────────────────

---@return OpenSysApp.Config
function M.get_config()
  return {
    filetypes       = vim.tbl_extend("force", {}, _cfg.filetypes),
    notify_on_open  = _cfg.notify_on_open,
    notify_on_error = _cfg.notify_on_error,
  }
end

return M
