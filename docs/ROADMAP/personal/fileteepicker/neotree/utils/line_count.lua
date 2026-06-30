---@module 'config.neotree.utils.line_count'
---@brief Counts lines in text and source files for Neo-tree node info display.
---@description
--- Pure utility: no side effects, no vim.api calls, no global state.
--- Returns nil for binary/image/archive files or on any I/O error.
--- File size is guarded (5 MiB cap) to avoid blocking the UI thread on
--- single-file operations triggered by the user.

local M = {}

local uv = vim.uv or vim.loop

-- ============================================================
-- Extension sets
-- ============================================================

---@type table<string, true>
local TEXT_EXTS = {
  -- Source code
  lua = true,
  py = true,
  js = true,
  ts = true,
  jsx = true,
  tsx = true,
  mjs = true,
  cjs = true,
  go = true,
  rs = true,
  c = true,
  cpp = true,
  h = true,
  hpp = true,
  cc = true,
  hh = true,
  cs = true,
  java = true,
  kt = true,
  kts = true,
  swift = true,
  dart = true,
  zig = true,
  sh = true,
  bash = true,
  zsh = true,
  fish = true,
  ksh = true,
  -- Web / templates
  html = true,
  astro = true,
  vue = true,
  svelte = true,
  css = true,
  scss = true,
  sass = true,
  less = true,
  -- Config / data
  json = true,
  toml = true,
  yaml = true,
  yml = true,
  xml = true,
  ini = true,
  cfg = true,
  conf = true,
  env = true,
  editorconfig = true,
  -- Docs / markup
  md = true,
  mdx = true,
  txt = true,
  rst = true,
  org = true,
  tex = true,
  adoc = true,
  -- Editor / build
  vim = true,
  vimrc = true,
  make = true,
  makefile = true,
  cmake = true,
  dockerfile = true,
  nix = true,
  -- Other text
  csv = true,
  tsv = true,
  log = true,
  diff = true,
  patch = true,
}

---@type table<string, true>
local BINARY_EXTS = {
  -- Images
  png = true,
  jpg = true,
  jpeg = true,
  gif = true,
  ico = true,
  bmp = true,
  tiff = true,
  webp = true,
  avif = true,
  -- Documents (binary)
  pdf = true,
  -- Archives
  zip = true,
  tar = true,
  gz = true,
  bz2 = true,
  xz = true,
  ["7z"] = true,
  rar = true,
  zst = true,
  -- Executables / libraries
  exe = true,
  dll = true,
  so = true,
  dylib = true,
  bin = true,
  obj = true,
  lib = true,
  a = true,
  o = true,
  -- Media
  mp4 = true,
  mp3 = true,
  avi = true,
  mkv = true,
  mov = true,
  wav = true,
  flac = true,
  ogg = true,
  -- Data / DBs
  db = true,
  sqlite = true,
  sqlite3 = true,
  -- Misc binary
  ttf = true,
  otf = true,
  woff = true,
  woff2 = true,
}

-- Max file size to attempt line counting (5 MiB).
-- Files larger than this return nil without opening.
local MAX_BYTES = 5 * 1024 * 1024

-- ============================================================
-- Public API
-- ============================================================

---Return true when a file extension is a known text/source type.
---Unknown extensions return false (conservative: do not read unknown files).
---@param ext string|nil Extension without leading dot, any case.
---@return boolean
function M.is_countable(ext)
  if not ext or ext == "" then
    return false
  end
  local lower = ext:lower()
  -- Explicit binary always wins
  if BINARY_EXTS[lower] then
    return false
  end
  return TEXT_EXTS[lower] == true
end

---Count newline-terminated lines in a file.
---Returns nil on any error (no file, binary, oversized, I/O failure).
---This call is synchronous and intended for on-demand single-file queries only.
---@param path string Absolute filesystem path.
---@param ext  string|nil File extension (without dot).
---@return integer|nil line_count Number of lines, or nil.
function M.count(path, ext)
  if not M.is_countable(ext) then
    return nil
  end
  if type(path) ~= "string" or path == "" then
    return nil
  end

  -- Guard: stat before open to check size and type cheaply
  local stat = uv.fs_stat(path)
  if not stat or stat.type ~= "file" then
    return nil
  end
  if stat.size > MAX_BYTES then
    return nil
  end
  -- Empty file → 0 lines
  if stat.size == 0 then
    return 0
  end

  local f = io.open(path, "r")
  if not f then
    return nil
  end

  local count = 0
  -- Allocate nothing per line; only increment the counter
  for _ in f:lines() do
    count = count + 1
  end
  f:close()

  return count
end

---Format a line count for human-readable display.
---@param count integer|nil
---@return string e.g. "142 lines", "1 line", or "" when nil.
function M.format(count)
  if not count then
    return ""
  end
  if count == 1 then
    return "1 line"
  end
  return tostring(count) .. " lines"
end

return M
