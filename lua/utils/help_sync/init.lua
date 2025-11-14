
---@module 'utils.help_sync'
--- Aggregate scattered Vim help files from any "docs/" directory within your config
--- into a single "doc/" directory on the runtimepath, then run :helptags so they
--- become available via :help. Designed for Linux/macOS.
---
--- Key points:
--- - Recursively scans configured roots (by default: stdpath("config") and its "lua" subdir)
--- - Detects any directory named "docs" (you can add "doc" too via config)
--- - Collects all "*.txt" files below those "docs/" folders
--- - Mirrors them into "<STATE>/nvim/help-sync/<namespace>/doc" via symlinks (or copy fallback)
--- - Ensures the aggregator base is present in 'runtimepath'
--- - Generates tags with :helptags so :h finds everything
---
--- Complexity & cost:
--- - The scan uses vim.fs.walk (streaming iterator) and simple string tests
--- - The build makes N symlink/copy ops + a single :helptags
--- - Even with hundreds of help files, this is typically sub-second

local M = {}

local api, fn, uv = vim.api, vim.fn, (vim.uv or vim.loop)

-- Defaults --------------------------------------------------------------------

---@class HelpSyncConfig
---@field search_roots table|function
---@field docs_dirnames string[]
---@field aggregator_ns string
---@field prefer_symlink boolean
---@field clear_before_build boolean
---@field rebuild_on_start boolean
---@field notify_prefix string

local DEFAULTS ---@type HelpSyncConfig

DEFAULTS = {
  search_roots = (function()
    local cfg = fn.stdpath("config")
    return { cfg, (cfg .. "/lua") }
  end)(),
  docs_dirnames = { "docs" },  -- add "doc" here if you also stash files there
  aggregator_ns = "local",
  prefer_symlink = true,
  clear_before_build = true,
  rebuild_on_start = false,
  notify_prefix = "[HelpSync] ",
}

M.opts = DEFAULTS

-- Helpers ---------------------------------------------------------------------

--- Ensure a directory exists (mkdir -p semantics).
---@param dir FilePath
---@return boolean ok, string? err
local function ensure_dir(dir)
  if fn.isdirectory(dir) == 1 then return true, nil end
  local ok, err = pcall(fn.mkdir, dir, "p")
  if not ok then return false, "mkdir failed: " .. tostring(err) end
  if fn.isdirectory(dir) ~= 1 then return false, "mkdir returned non-directory" end
  return true, nil
end

--- Return aggregator base and its "doc" directory under an XDG-compliant state path.
---@return FilePath docdir, FilePath basedir
local function aggregator_docdir()
  local state = os.getenv("XDG_STATE_HOME")
      and (os.getenv("XDG_STATE_HOME") .. "/nvim/help-sync")
      or (os.getenv("HOME") .. "/.local/state/nvim/help-sync")
  local base = state .. "/" .. (M.opts.aggregator_ns or DEFAULTS.aggregator_ns)
  return (base .. "/doc"), base
end

--- Put a directory into 'runtimepath' if it's not already there.
---@param dir FilePath
---@return nil
local function ensure_in_rtp(dir)
  local rtp = vim.o.runtimepath
  for entry in string.gmatch(rtp, "([^,]+)") do
    if fn.fnamemodify(entry, ":p") == fn.fnamemodify(dir, ":p") then
      return
    end
  end
  vim.o.runtimepath = rtp .. "," .. dir
end

--- Recursively find all "*.txt" in folders named like any of M.opts.docs_dirnames.
---@param roots string[]
---@param docs_names string[]
---@return string[] files
local function find_help_files(roots, docs_names)
  ---@type string[]
  local results = {}
  -- Build a quick lookup for docs directory names
  local lookup = {}
  for _, d in ipairs(docs_names) do lookup[d] = true end

  for _, root in ipairs(roots) do
    -- Walk every entry
    for path, t in vim.fs.walk(root, { direction = "topdown" }) do
      if t == "directory" then
        -- If this directory itself is named "docs" (or configured name), scan its subtree for *.txt
        local base = vim.fs.basename(path)
        if lookup[base] then
          -- Collect *.txt beneath this docs folder
          for subpath, st in vim.fs.walk(path, { direction = "topdown" }) do
            if st == "file" and subpath:sub(-4) == ".txt" then
              results[#results + 1] = subpath
            end
          end
          -- Skip descending further from root when not necessary (optional)
        end
      end
    end
  end

  return results
end

--- Create or replace a symlink (preferred) or copy file as a fallback.
---@param src FilePath
---@param dst FilePath
---@param prefer_symlink boolean
---@return boolean ok, string? err
local function link_or_copy(src, dst, prefer_symlink)
  -- Remove existing wrong-type path
  local st = uv.fs_lstat(dst)
  if st then
    if st.type == "link" or st.type == "file" then
      local ok_rm, err_rm = uv.fs_unlink(dst)
      if not ok_rm then return false, "unlink failed: " .. tostring(err_rm) end
    else
      return false, "destination exists and is not file/link"
    end
  end

	---@diagnostic disable-next-line lib.uv
  if prefer_symlink and uv.fs_symlink then
	---@diagnostic disable-next-line lib.uv
    local ok_ln, _ = uv.fs_symlink(src, dst)
    if ok_ln then return true, nil end
    -- fallback to copy
  end

  -- Copy via Lua I/O
  local fin = io.open(src, "rb"); if not fin then return false, "open source failed" end
  local data = fin:read("*a"); fin:close()
  local fout = io.open(dst, "wb"); if not fout then return false, "open dest failed" end
  fout:write(data or ""); fout:flush(); fout:close()
  return true, nil
end

--- Make a flattened unique name from an absolute path by replacing "/" with "__".
--- Keeps the original ".txt" extension for helptags compatibility.
---@param abs_path FilePath
---@return string
local function flatten_name(abs_path)
  -- Normalize and replace path separators
  local p = fn.fnamemodify(abs_path, ":p")
  p = p:gsub("[/\\]+", "__")
  return p
end

--- Optionally clear all existing files in the aggregator docdir (not the dir itself).
---@param docdir FilePath
---@return boolean ok, string? err
local function clear_docdir(docdir)
  if fn.isdirectory(docdir) ~= 1 then return true, nil end
  for name, typ in vim.fs.dir(docdir) do
    local full = docdir .. "/" .. name
    if typ == "file" or typ == "link" then
      local ok, err = uv.fs_unlink(full)
      if not ok then return false, "failed to unlink: " .. tostring(err) end
    end
  end
  return true, nil
end

--- Build the aggregator and run helptags.
---@return boolean ok, string msg, integer count
local function rebuild()
  local docdir, basedir = aggregator_docdir()

  local okb, errb = ensure_dir(basedir); if not okb then
    return false, (M.opts.notify_prefix .. errb), 0
  end
  local okd, errd = ensure_dir(docdir); if not okd then
    return false, (M.opts.notify_prefix .. errd), 0
  end

  if M.opts.clear_before_build ~= false then
    local okc, errc = clear_docdir(docdir)
    if not okc then return false, (M.opts.notify_prefix .. errc), 0 end
  end

	---@diagnostic disable
  local sources = find_help_files(M.opts.search_roots or DEFAULTS.search_roots,
                                  M.opts.docs_dirnames or DEFAULTS.docs_dirnames)
---@diagnostic enable

	if #sources == 0 then
    -- Still ensure RTP so a later run of :HelpSyncRebuild has the path ready
    ensure_in_rtp(basedir)
    pcall(function() vim.cmd("silent! helptags " .. fn.shellescape(docdir)) end)
    return true, (M.opts.notify_prefix .. "no docs found"), 0
  end

  local created = 0
  for _, src in ipairs(sources) do
    local flat = flatten_name(src)
    local dst = docdir .. "/" .. flat
    local okL, errL = link_or_copy(src, dst, M.opts.prefer_symlink ~= false)
    if not okL then
      return false, (M.opts.notify_prefix .. "link/copy failed: " .. tostring(errL)), created
    end
    created = created + 1
  end

  ensure_in_rtp(basedir)
  pcall(function() vim.cmd("silent! helptags " .. fn.shellescape(docdir)) end)

  return true, (M.opts.notify_prefix .. ("indexed %d help files"):format(created)), created
end

-- Public API ------------------------------------------------------------------

--- Initialize configuration and optional auto-rebuild on startup.
---@param cfg HelpSyncConfig|nil
---@return nil
function M.setup(cfg)
  cfg = cfg or {}
  M.opts = {
    search_roots = cfg.search_roots or DEFAULTS.search_roots,
    docs_dirnames = cfg.docs_dirnames or DEFAULTS.docs_dirnames,
    aggregator_ns = cfg.aggregator_ns or DEFAULTS.aggregator_ns,
    prefer_symlink = (cfg.prefer_symlink ~= nil) and cfg.prefer_symlink or DEFAULTS.prefer_symlink,
    clear_before_build = (cfg.clear_before_build ~= nil) and cfg.clear_before_build or DEFAULTS.clear_before_build,
    rebuild_on_start = (cfg.rebuild_on_start ~= nil) and cfg.rebuild_on_start or DEFAULTS.rebuild_on_start,
    notify_prefix = cfg.notify_prefix or DEFAULTS.notify_prefix,
  }

  if M.opts.rebuild_on_start then
    api.nvim_create_autocmd("VimEnter", {
      callback = function()
        local ok, msg = rebuild()
        vim.schedule(function()
          vim.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.WARN)
        end)
      end,
      desc = "HelpSync: rebuild helptags from scattered docs",
    })
  end

  api.nvim_create_user_command("HelpSyncRebuild", function()
    local ok, msg = rebuild()
    vim.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.ERROR)
  end, { desc = "Aggregate all docs/ help files recursively and run :helptags" })
end

--- Manual rebuild from Lua.
---@return boolean ok, string msg, integer count
function M.rebuild()
  return rebuild()
end

return M

