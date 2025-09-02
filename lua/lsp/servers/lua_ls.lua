---@module 'lsp.servers.lua_ls'
--- Lua language server setup tailored for Neovim plugin and general Lua projects.
--- Goals:
---   • Strict, predictable root selection.
---   • Conditional inclusion of ~/.config/nvim/lua/{@types,types} only when working inside the Neovim config tree.
---   • Automatic discovery of project-local "types" and "@types" directories (depth- and result-limited, pruned).
---   • Conservative workspace size for faster startup and reduced indexing overhead.

---@class LuaLsServer
local M = {}

-- Prefer modern libuv handle (Neovim 0.10+: vim.uv; older: vim.loop)
local uv = vim.uv or vim.loop

-- Compatibility helper for vararg unpack in LuaJIT / Lua 5.1+
local unpack = table.unpack or unpack

-- ──────────────────────────────────────────────────────────────────────────────
-- Small filesystem helpers
-- ──────────────────────────────────────────────────────────────────────────────

--- Check if a path is an existing directory.
---@param p string
---@return boolean
local function is_dir(p)
  local st = uv.fs_stat(p)
  return (st and st.type == "directory") or false
end

--- Join path components using Neovim's cross-platform helper.
---@param parts string[]
---@return string
local function join(parts)
  return vim.fs.joinpath(unpack(parts))
end

--- Normalize a path to avoid duplicate representations.
---@param p string
---@return string
local function norm(p)
  return vim.fs.normalize(p)
end

--- Deduplicate and normalize a list of paths.
---@param entries string[]
---@return string[]
local function dedup(entries)
  ---@type table<string, boolean>
  local seen = {}
  ---@type string[]
  local out = {}
  for _, p in ipairs(entries) do
    local n = norm(p)
    if not seen[n] then
      seen[n] = true
      table.insert(out, n)
    end
  end
  return out
end

--- Return current working directory.
---@return string|nil
local function startpath_from()
  return uv.cwd()
end

--- Find the directory that contains any of the given basenames by walking upward.
---@param names string[]  -- e.g. { ".git", "stylua.toml" }
---@param from string     -- start path (file or directory)
---@return string|nil     -- directory that contains the found item
local function find_upward_dir(names, from)
  local found = vim.fs.find(names, { path = from, upward = true })
  if found and found[1] then
    return vim.fs.dirname(found[1])
  end
  return nil
end

--- Check whether `path` is equal to or inside directory `base`.
--- Enforces a boundary at directory separators to avoid prefix false-positives.
---@param path string
---@param base string
---@return boolean
local function is_subpath(path, base)
  path, base = norm(path), norm(base)
  if path == base then return true end
  if #path <= #base then return false end
  local sep = package.config:sub(1, 1) or "/"
  if base:sub(-1) ~= sep then base = base .. sep end
  return path:sub(1, #base) == base
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Root computation (strict and predictable)
-- ──────────────────────────────────────────────────────────────────────────────

--- Compute a strict root directory:
---   1) Prefer VCS markers (.git / .hg / .svn).
---   2) Else common Lua project markers (.luarc.json, .neoconf.json, selene.toml, stylua.toml).
---   3) Else, if the CWD is inside stdconfig (~/.config/nvim), collapse to stdconfig.
---   4) Else fallback to the current directory (keeps scope small; never $HOME).
---@return string|nil
local function strict_root()
  local start = startpath_from()
  if not start then
    return nil
  end

  local vcs_root = find_upward_dir({ ".git", ".hg", ".svn" }, start)
  if vcs_root then
    return vcs_root
  end

  local lua_markers = find_upward_dir({ ".luarc.json", ".neoconf.json", "selene.toml", "stylua.toml" }, start)
  if lua_markers then
    return lua_markers
  end

  local stdconfig = vim.fn.stdpath("config")
  if is_subpath(start, stdconfig) then
    return stdconfig
  end

  return start
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Discovery of project-local "types" / "@types" directories
-- ──────────────────────────────────────────────────────────────────────────────

--- Find all directories named "types" or "@types" under `root`, with pruning:
---   • Skips heavy/irrelevant dirs (node_modules, .git, build, dist, target, zig-cache, etc.)
---   • Skips most hidden entries starting with "." (except ".config" which is common under stdconfig)
---   • Depth-limited and result-limited to keep scans fast.
---
---@param root string
---@param opts { max_results?: integer, max_depth?: integer }|nil
---@return string[]  -- absolute directories suitable for Lua.workspace.library
local function find_type_dirs(root, opts)
  opts = opts or {}
  local MAX_RESULTS = opts.max_results or 200
  local MAX_DEPTH   = opts.max_depth   or 12

  ---@type table<string, boolean>
  local PRUNE = {
    [".git"] = true, [".hg"] = true, [".svn"] = true,
    ["node_modules"] = true, [".pnpm-store"] = true,
    [".venv"] = true, [".direnv"] = true,
    [".mypy_cache"] = true, [".cache"] = true, ["__pycache__"] = true,
    ["build"] = true, ["dist"] = true, ["target"] = true,
    ["zig-cache"] = true, ["zig-out"] = true,
  }

  ---@type string[]
  local matches = {}
  ---@type { path: string, depth: integer }[]
  local stack = { { path = norm(root), depth = 0 } }

  while #stack > 0 and #matches < MAX_RESULTS do
    local node = table.remove(stack)
    if node.depth > MAX_DEPTH then
      goto continue
    end

    local it = uv.fs_scandir(node.path)
    if not it then
      goto continue
    end

    while true do
      local name, kind = uv.fs_scandir_next(it)
      if not name then
        break
      end

      -- Skip most dot-directories early (keep '.config' as an exception)
      if name:sub(1, 1) == "." and name ~= ".config" then
        goto inner_continue
      end

      if kind == "directory" then
        if PRUNE[name] then
          goto inner_continue
        end
        local child = norm(join({ node.path, name }))
        if name == "types" or name == "@types" then
          table.insert(matches, child)
        end
        -- Continue traversal to discover nested types/@types
        table.insert(stack, { path = child, depth = node.depth + 1 })
      end

      ::inner_continue::
    end

    ::continue::
  end

  return matches
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Build workspace.library with conditional stdconfig types
-- ──────────────────────────────────────────────────────────────────────────────

--- Build the final library list:
---   1) Neovim + plugin runtime files (standard practice for Neovim plugin dev).
---   2) ~/.config/nvim/lua/{@types,types} ONLY if the workspace root is inside stdconfig.
---   3) Project-local types/@types found under the project (preferring <root>/lua if it exists).
--- The result is normalized and deduplicated.
---
---@param root string|nil
---@return string[]
local function build_library(root)
  --- 1) Neovim + plugins runtime (files and dirs)
  ---@type string[]
  local lib = vim.api.nvim_get_runtime_file("", true)

  --- 2) Include stdconfig types only when working inside the Neovim config tree
  local stdconfig = vim.fn.stdpath("config")
  if root and is_subpath(root, stdconfig) then
    local cfg_atypes = join({ stdconfig, "lua", "@types" })
    local cfg_types  = join({ stdconfig, "lua", "types" })
    if is_dir(cfg_atypes) then table.insert(lib, cfg_atypes) end
    if is_dir(cfg_types)  then table.insert(lib, cfg_types)  end
  end

  --- 3) Discover project-local types/@types (prefer scanning under <root>/lua)
  if root and is_dir(root) then
    local lua_root = join({ root, "lua" })
    local scan_base = is_dir(lua_root) and lua_root or root
    local found = find_type_dirs(scan_base, { max_results = 200, max_depth = 12 })
    for _, p in ipairs(found) do
      table.insert(lib, p)
    end
  end

  return dedup(lib)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Public setup
-- ──────────────────────────────────────────────────────────────────────────────

--- Setup lua_ls through lspconfig with performance-minded defaults.
--- Notes:
---   • `completion.workspaceWord=false` reduces scanning of unrelated files.
---   • `semantic.enable=false` relies on Treesitter for highlighting (less server work).
---   • `single_file_support=true` prevents extra workspaces from being spawned.
---
---@param shared table  -- common LSP opts: capabilities, on_attach, on_init
---@return nil
function M.setup(shared)
  if type(shared) ~= "table" then
    return
  end

  local ok_lsp, lspconfig = pcall(require, "lspconfig")
  if not ok_lsp then
    return
  end

  local root = strict_root()

  ---@type table
  local settings = {
    Lua = {
      runtime = { version = "LuaJIT" }, -- Neovim uses LuaJIT
      hint = { enable = true },         -- Inlay hints (optional; keep if you like them)
      diagnostics = {
        -- Declare common Neovim globals to avoid 'undefined global' warnings.
        globals = { "vim", "vim.uv", "vim.loop", "vim.fn", "vim.inspect" },
      },
      completion = {
        callSnippet = "Replace",
        workspaceWord = false,
      },
      semantic = { enable = false },
      workspace = {
        checkThirdParty = false,
        --- Aggressively ignore heavy directories (glob patterns allowed).
        ---@type string[]
        ignoreDir = {
          ".git",
          "**/node_modules",
          "**/.venv", "**/.direnv",
          "**/.cache", "**/.mypy_cache",
          "**/build", "**/dist", "**/target",
          "**/zig-cache", "**/zig-out",
        },
        useGitIgnore = true,
        maxPreload = 1500,      -- default 5000; reduce initial preload
        preloadFileSize = 200,  -- KB; default 500
        --- Feed our computed library (runtime + conditional config types + project types)
        ---@type string[]|string
        library = build_library(root),
      },
      telemetry = { enable = false },
    },
  }

  lspconfig.lua_ls.setup({
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
    root_dir = strict_root,       -- function reference (called by lspconfig)
    single_file_support = true,   -- prevents extra project workspaces
    settings = settings,
  })
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Debug helpers (optional)
-- ──────────────────────────────────────────────────────────────────────────────

--- Return the current computation of workspace root (for inspection).
---@nodiscard
---@return string|nil
function M.debug_root()
  return strict_root()
end

--- Return the current computation of workspace.library (for inspection).
---@nodiscard
---@return string[]
function M.debug_library()
  return build_library(strict_root())
end

return M
