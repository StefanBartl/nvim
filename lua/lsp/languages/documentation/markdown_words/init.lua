---@module 'lsp.languages.documentation.markdown_words'
--- nvim-cmp source that provides project-wide word completions for Markdown files.
---
--- How it works:
---   1. Scans all .md / .mdx files under a configurable root directory (defaults to cwd).
---   2. Tokenises every file into words, deduplicates them, and caches the result.
---   3. Registers itself as a cmp source named "md_words".
---   4. The cache is rebuilt lazily (once per session unless manually invalidated).
---
--- Integration:
---   Call `require("lsp.languages.documentation.markdown_words").setup()` once, e.g. from
---   your markdown language module or from lsp/init.lua after cmp is loaded.
---
--- User commands (registered in setup()):
---   :MdSetRoot [path]   – change the scan root (omit path = use cwd).
---   :MdRebuildWords     – force a full cache rebuild from the current root.
---   :MdWordStats        – show how many unique words are cached and the current root.

local M = {}

-- ============================================================================
-- Internal state
-- ============================================================================

---@class MdWords.State
---@field root string|nil         Current scan root
---@field words table<string,true>  Deduped word set
---@field items table[]|nil        Cached cmp items (nil = needs rebuild)
---@field building boolean         Guard against concurrent scans

---@type MdWords.State
local state = {
  root    = nil,
  words   = {},
  items   = nil,
  building = false,
}

-- ============================================================================
-- Configuration
-- ============================================================================

---@class MdWords.Config
---@field max_files   integer   Hard cap on number of files scanned (default 500)
---@field max_filesize integer  Skip files larger than this (bytes, default 200 KB)
---@field min_word_len integer  Minimum word length to include (default 3)
---@field max_word_len integer  Maximum word length to include (default 60)
---@field filetypes   string[]  File extensions to scan (default {"md","mdx"})
---@field debounce_ms integer   Debounce before auto-rebuild on DirChanged (default 3000)

---@type MdWords.Config
local cfg = {
  max_files    = 500,
  max_filesize = 200 * 1024,
  min_word_len = 3,
  max_word_len = 60,
  filetypes    = { "md", "mdx" },
  debounce_ms  = 3000,
}

-- ============================================================================
-- Filesystem helpers
-- ============================================================================

local uv = vim.uv or vim.loop

--- Collect all markdown files under `root` up to `cfg.max_files`.
---@param root string
---@return string[]
local function collect_files(root)
  local files = {}
  local stack = { root }

  -- Directories we never descend into
  local ignore = {
    [".git"] = true, ["node_modules"] = true, [".cache"] = true,
    [".hg"]  = true, [".svn"]         = true, ["dist"]   = true,
    ["build"] = true, ["target"]       = true, [".next"]  = true,
    [".nuxt"] = true, ["vendor"]       = true,
  }

  -- Extension set for fast lookup
  local ext_set = {}
  for _, e in ipairs(cfg.filetypes) do
    ext_set[e] = true
  end

  while #stack > 0 and #files < cfg.max_files do
    local dir = table.remove(stack)
    local handle = uv.fs_scandir(dir)
    if not handle then goto continue end

    while true do
      local name, kind = uv.fs_scandir_next(handle)
      if not name then break end

      -- skip hidden entries except .config
      if name:sub(1, 1) == "." and name ~= ".config" then goto inner end

      local full = dir .. "/" .. name

      if kind == "directory" then
        if not ignore[name] then
          stack[#stack + 1] = full
        end
      elseif kind == "file" then
        local ext = name:match("%.([^.]+)$")
        if ext and ext_set[ext] then
          local stat = uv.fs_stat(full)
          if stat and stat.size <= cfg.max_filesize then
            files[#files + 1] = full
          end
        end
      end

      ::inner::
    end

    ::continue::
  end

  return files
end

-- ============================================================================
-- Word extraction
-- ============================================================================

--- Extract unique words from `text` into `word_set`.
---@param text string
---@param word_set table<string,true>
local function extract_words(text, word_set)
  -- Strip markdown syntax characters so we get clean words.
  -- We keep letters, digits, apostrophes/hyphens inside words.
  for raw in text:gmatch("[%w][%w%'%-]*[%w]?") do
    -- normalise: lowercase is optional but keeps completion case-insensitive;
    -- we keep original case for a nicer display.
    if #raw >= cfg.min_word_len and #raw <= cfg.max_word_len then
      word_set[raw] = true
    end
  end
end

--- Build the word set by scanning every file under `root`.
--- Runs synchronously but in small uv.fs_read chunks to stay non-blocking
--- via vim.schedule between files when called from an async context.
---@param root string
---@return table<string,true>
local function build_word_set(root)
  local word_set = {}
  local files = collect_files(root)

  for _, path in ipairs(files) do
    -- synchronous read (we are already in a deferred context)
    local fd = uv.fs_open(path, "r", 438)
    if fd then
      local stat = uv.fs_fstat(fd)
      if stat then
        local data = uv.fs_read(fd, stat.size, 0)
        if data then
          extract_words(data, word_set)
        end
      end
      uv.fs_close(fd)
    end
  end

  return word_set
end

-- ============================================================================
-- Cache management
-- ============================================================================

--- Convert word_set to sorted cmp items (done once, cached).
---@param word_set table<string,true>
---@return table[]
local function words_to_items(word_set)
  local items = {}
  for w in pairs(word_set) do
    items[#items + 1] = {
      label            = w,
      kind             = 1,  -- vim.lsp.protocol.CompletionItemKind.Text
      filterText       = w,
      insertText       = w,
      documentation    = { kind = "plaintext", value = "(md_words)" },
    }
  end
  -- stable sort
  table.sort(items, function(a, b) return a.label < b.label end)
  return items
end

--- Trigger an async rebuild of the word cache for `root`.
---@param root string
---@param on_done fun()|nil  Optional callback when finished
local function rebuild_async(root, on_done)
  if state.building then return end
  state.building = true

  vim.defer_fn(function()
    local ok, result = pcall(build_word_set, root)
    if ok then
      state.words  = result
      state.items  = words_to_items(result)
      state.root   = root
    end
    state.building = false
    if on_done then on_done() end
  end, 0)
end

--- Return (or lazily build) the cmp items.
---@return table[]
local function get_items()
  if state.items then return state.items end
  -- If we have no root yet, default to cwd
  local root = state.root or (uv.cwd and uv.cwd()) or vim.fn.getcwd()
  if not state.building then
    rebuild_async(root, nil)
  end
  -- Return whatever we have while building
  return state.items or {}
end

-- ============================================================================
-- nvim-cmp source
-- ============================================================================

---@class MdWords.Source
local Source = {}
Source.__index = Source

function Source.new()
  return setmetatable({}, Source)
end

function Source:is_available()
  local ft = vim.bo.filetype
  return ft == "markdown" or ft == "mdx" or ft == "markdown.mdx"
end

function Source:get_debug_name()
  return "md_words"
end

--- Trigger on any character (give cmp control via keyword_pattern)
function Source:get_keyword_pattern()
  return [[\%(-\?\d\+\%(\.\d\+\)\?\|\h\w*\%(-\w*\)*\)]]
end

function Source:complete(_, callback)
  callback({ items = get_items(), isIncomplete = false })
end

-- ============================================================================
-- Public API
-- ============================================================================

--- Change the scan root and trigger a rebuild.
---@param path string|nil  Nil = use cwd
function M.set_root(path)
  local root = path
  if not root or root == "" then
    root = (uv.cwd and uv.cwd()) or vim.fn.getcwd()
  end
  -- Expand ~ and env vars
  root = vim.fn.expand(root)
  -- Normalise trailing slash
  root = root:gsub("[/\\]+$", "")

  if root == state.root and state.items then
    vim.notify("[md_words] Root unchanged (" .. root .. "), cache still valid.", vim.log.levels.INFO)
    return
  end

  state.items = nil  -- invalidate cache
  rebuild_async(root, function()
    local count = 0
    for _ in pairs(state.words) do count = count + 1 end
    vim.schedule(function()
      vim.notify(
        string.format("[md_words] Rebuilt: %d unique words from %s", count, root),
        vim.log.levels.INFO
      )
    end)
  end)
end

--- Force a rebuild without changing the root.
function M.rebuild()
  state.items = nil
  local root = state.root or (uv.cwd and uv.cwd()) or vim.fn.getcwd()
  M.set_root(root)
end

--- Return stats for debugging.
---@return table
function M.stats()
  local count = 0
  for _ in pairs(state.words) do count = count + 1 end
  return {
    root      = state.root,
    words     = count,
    cached    = state.items ~= nil,
    building  = state.building,
  }
end

-- ============================================================================
-- Setup: register cmp source + autocmds + user commands
-- ============================================================================

---@param opts MdWords.Config|nil
function M.setup(opts)
  -- Merge user options
  if type(opts) == "table" then
    for k, v in pairs(opts) do
      if cfg[k] ~= nil then
        cfg[k] = v
      end
    end
  end

  -- Register with nvim-cmp if available
  local ok_cmp, cmp = pcall(require, "cmp")
  if ok_cmp then
    cmp.register_source("md_words", Source.new())
    -- Append our source to the markdown-filetype cmp config if possible.
    -- We do this lazily via FileType autocmd so cmp setup is already done.
    vim.api.nvim_create_autocmd("FileType", {
      pattern  = { "markdown", "mdx" },
      once     = false,
      callback = function()
        local ok_setup, cmp2 = pcall(require, "cmp")
        if not ok_setup then return end

        -- Retrieve current config for this buffer and append our source
        -- only if not already there.
        local current = cmp2.get_config()
        if not current then return end

        local sources = current.sources or {}
        for _, s in ipairs(sources) do
          if s.name == "md_words" then return end
        end

        -- Append with low priority (high number = lower priority)
        local new_sources = {}
        for _, s in ipairs(sources) do
          new_sources[#new_sources + 1] = s
        end
        new_sources[#new_sources + 1] = { name = "md_words", priority = 100 }

        cmp2.setup.buffer({ sources = new_sources })
      end,
    })
  else
    vim.notify(
      "[md_words] nvim-cmp not found. Source registered but will not appear in completions.",
      vim.log.levels.WARN
    )
  end

  -- Initial build from cwd when the first markdown buffer is opened
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "mdx" },
    once    = true,
    callback = function()
      if not state.root then
        local root = (uv.cwd and uv.cwd()) or vim.fn.getcwd()
        rebuild_async(root, nil)
        state.root = root
      end
    end,
  })

  -- Debounced rebuild when the working directory changes
  local debounce_timer = nil
  vim.api.nvim_create_autocmd("DirChanged", {
    callback = function()
      if debounce_timer then
        pcall(function()
          debounce_timer:stop()
          debounce_timer:close()
        end)
      end
      debounce_timer = uv.new_timer()
      if debounce_timer then
        debounce_timer:start(cfg.debounce_ms, 0, vim.schedule_wrap(function()
          -- Only rebuild if no explicit root was set by the user
          if not state._user_root then
            local new_root = (uv.cwd and uv.cwd()) or vim.fn.getcwd()
            if new_root ~= state.root then
              state.items = nil
              rebuild_async(new_root, nil)
            end
          end
        end))
      end
    end,
  })

  -- -------------------------------------------------------------------------
  -- User commands
  -- -------------------------------------------------------------------------

  vim.api.nvim_create_user_command("MdSetRoot", function(cmd_opts)
    local path = cmd_opts.args ~= "" and cmd_opts.args or nil
    state._user_root = path  -- remember that the user set this explicitly
    M.set_root(path)
  end, {
    nargs = "?",
    complete = "dir",
    desc = "[md_words] Set the project root for Markdown word scanning (empty = cwd)",
  })

  vim.api.nvim_create_user_command("MdRebuildWords", function()
    state.items = nil
    M.rebuild()
  end, {
    desc = "[md_words] Force a full rebuild of the project-wide word cache",
  })

  vim.api.nvim_create_user_command("MdWordStats", function()
    local s = M.stats()
    vim.notify(
      string.format(
        "[md_words]\n  root     : %s\n  words    : %d\n  cached   : %s\n  building : %s",
        tostring(s.root),
        s.words,
        tostring(s.cached),
        tostring(s.building)
      ),
      vim.log.levels.INFO
    )
  end, {
    desc = "[md_words] Show word-cache statistics",
  })
end

return M
