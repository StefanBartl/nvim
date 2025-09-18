---@module 'lsp.servers.lua_ls'
--- Lua language server setup using native LSP config/enable with strict root and scoped libraries.

---@class LuaLsServer
local M = {}

local uv = vim.uv or vim.loop
local unpack = table.unpack or unpack

-- Filesystem helpers ----------------------------------------------------------

---@param p string
---@return boolean
local function is_dir(p)
  local st = uv.fs_stat(p)
  return (st and st.type == "directory") or false
end

---@param parts string[]
---@return string
local function join(parts)
  return vim.fs.joinpath(unpack(parts))
end

---@param p string
---@return string
local function norm(p)
  return vim.fs.normalize(p)
end

---@param entries string[]
---@return string[]
local function dedup(entries)
  local seen, out = {}, {}
  for _, p in ipairs(entries) do
    local n = norm(p)
    if not seen[n] then
      seen[n] = true
      out[#out + 1] = n
    end
  end
  return out
end

---@return string|nil
local function startpath_from()
  return uv.cwd()
end

---@param names string[]
---@param from string
---@return string|nil
local function find_upward_dir(names, from)
  local found = vim.fs.find(names, { path = from, upward = true })
  if found and found[1] then
    return vim.fs.dirname(found[1])
  end
  return nil
end

---@param path string
---@param base string
---@return boolean
local function is_subpath(path, base)
  path, base = norm(path), norm(base)
  if path == base then
    return true
  end
  if #path <= #base then
    return false
  end
  local sep = package.config:sub(1, 1) or "/"
  if base:sub(-1) ~= sep then
    base = base .. sep
  end
  return path:sub(1, #base) == base
end

-- Root computation ------------------------------------------------------------

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

-- Datei-/Buffer-basierte Strict-Root-Ermittlung
local function strict_root_from(fname)
  -- starte an der Verzeichnis-Komponente der Datei; Fallback: CWD
  local dir = (type(fname) == "string" and fname ~= "" and vim.fs.dirname(vim.fs.normalize(fname)))
    or ((vim.uv or vim.loop).cwd and (vim.uv or vim.loop).cwd())
    or vim.fn.getcwd()

  if not dir or dir == "" then
    return nil
  end

  local vcs_root = vim.fs.root(dir, { ".git", ".hg", ".svn" })
  if vcs_root then
    return vcs_root
  end

  local lua_markers = vim.fs.find(
    { ".luarc.json", ".neoconf.json", "selene.toml", "stylua.toml" },
    { path = dir, upward = true }
  )
  if lua_markers and lua_markers[1] then
    return vim.fs.dirname(lua_markers[1])
  end

  local stdconfig = vim.fn.stdpath("config")
  if is_subpath(dir, stdconfig) then
    return stdconfig
  end

  return dir
end

-- Polymorpher Resolver: akzeptiert (bufnr, cb) *oder* (fname)
local function make_root_dir_resolver()
  return function(arg, cb)
    local fname = ""
    if type(arg) == "number" then
      fname = vim.api.nvim_buf_get_name(arg) or ""
    elseif type(arg) == "string" then
      fname = arg
    end
    local root = strict_root_from(fname)
    if cb then
      cb(root)
    end
    return root
  end
end

-- Discover project-local "types"/"@types" ------------------------------------

---@param root string
---@param opts { max_results?: integer, max_depth?: integer }|nil
---@return string[]
local function find_type_dirs(root, opts)
  opts = opts or {}
  local MAX_RESULTS = opts.max_results or 200
  local MAX_DEPTH = opts.max_depth or 12

  local PRUNE = {
    [".git"] = true,
    [".hg"] = true,
    [".svn"] = true,
    ["node_modules"] = true,
    [".pnpm-store"] = true,
    [".venv"] = true,
    [".direnv"] = true,
    [".mypy_cache"] = true,
    [".cache"] = true,
    ["__pycache__"] = true,
    ["build"] = true,
    ["dist"] = true,
    ["target"] = true,
    ["zig-cache"] = true,
    ["zig-out"] = true,
  }

  local matches, stack = {}, { { path = norm(root), depth = 0 } }
  while #stack > 0 and #matches < MAX_RESULTS do
    local node = table.remove(stack)
    if node.depth <= MAX_DEPTH then
      local it = uv.fs_scandir(node.path)
      if it then
        while true do
          local name, kind = uv.fs_scandir_next(it)
          if not name then
            break
          end
          if name:sub(1, 1) == "." and name ~= ".config" then
            goto inner_continue
          end
          if kind == "directory" then
            if PRUNE[name] then
              goto inner_continue
            end
            local child = norm(join({ node.path, name }))
            if name == "types" or name == "@types" then
              matches[#matches + 1] = child
            end
            stack[#stack + 1] = { path = child, depth = node.depth + 1 }
          end
          ::inner_continue::
        end
      end
    end
  end
  return matches
end

---@param root string|nil
---@return string[]
local function build_library(root)
  local lib = vim.api.nvim_get_runtime_file("", true) ---@type string[]

  local stdconfig = vim.fn.stdpath("config")
  if root and is_subpath(root, stdconfig) then
    local cfg_atypes = join({ stdconfig, "lua", "@types" })
    local cfg_types = join({ stdconfig, "lua", "types" })
    if is_dir(cfg_atypes) then
      lib[#lib + 1] = cfg_atypes
    end
    if is_dir(cfg_types) then
      lib[#lib + 1] = cfg_types
    end
  end

  if root and is_dir(root) then
    local lua_root = join({ root, "lua" })
    local scan_base = is_dir(lua_root) and lua_root or root
    local found = find_type_dirs(scan_base, { max_results = 200, max_depth = 12 })
    for i = 1, #found do
      lib[#lib + 1] = found[i]
    end
  end

  return dedup(lib)
end

-- Public setup ----------------------------------------------------------------

---@param shared {capabilities?:table,on_attach?:fun(client,bufnr),on_init?:fun(client,init_result):boolean}|nil
---@param opts { enable?: boolean }|nil
---@return nil
function M.setup(shared, opts)
  shared = shared or {}
  opts = opts or {}

  if type(vim.lsp.config) == "table" then
    vim.lsp.config("lua_ls", {
      cmd = { "lua-language-server" },
      filetypes = { "lua" },
      -- WICHTIG: neuer Resolver (bufnr|fname kompatibel)
      root_dir = make_root_dir_resolver(),
      single_file_support = true,
      capabilities = shared.capabilities,
      on_attach = shared.on_attach,
      on_init = shared.on_init,
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          hint = { enable = true },
          diagnostics = { globals = { "vim", "vim.uv", "vim.loop", "vim.fn", "vim.inspect" } },
          completion = { callSnippet = "Replace", workspaceWord = false },
          semantic = { enable = false },
          workspace = {
            checkThirdParty = false,
            ignoreDir = {
              ".git",
              "**/node_modules",
              "**/.venv",
              "**/.direnv",
              "**/.cache",
              "**/.mypy_cache",
              "**/build",
              "**/dist",
              "**/target",
              "**/zig-cache",
              "**/zig-out",
            },
            useGitIgnore = true,
            maxPreload = 1500,
            preloadFileSize = 200,
            -- library per Root (siehe on_new_config unten)
          },
          telemetry = { enable = false },
        },
      },
      -- pro Root die Library sauber setzen
      on_new_config = function(new_config, new_root)
        if new_config and new_config.settings and new_config.settings.Lua then
          local function is_dir(p)
            local st = (vim.uv or vim.loop).fs_stat(p)
            return st and st.type == "directory"
          end
          local function join(parts)
            return vim.fs.joinpath(unpack(parts))
          end
          local lib = vim.api.nvim_get_runtime_file("", true)

          local stdconfig = vim.fn.stdpath("config")
          if new_root and new_root ~= "" and new_root:find(stdconfig, 1, true) == 1 then
            local atypes = join({ stdconfig, "lua", "@types" })
            local types = join({ stdconfig, "lua", "types" })
            if is_dir(atypes) then
              lib[#lib + 1] = atypes
            end
            if is_dir(types) then
              lib[#lib + 1] = types
            end
          end

          if new_root and is_dir(new_root) then
            local lua_root = join({ new_root, "lua" })
            local scan_base = is_dir(lua_root) and lua_root or new_root
            -- optional: deine find_type_dirs(...) hier wiederverwenden, wenn du willst
          end

          new_config.settings.Lua.workspace.library = lib
        end
      end,
    })
    if (opts or {}).enable ~= false then
      pcall(vim.lsp.enable, "lua_ls")
    end
  end
end

---@nodiscard
---@return string|nil
function M.debug_root()
  return strict_root()
end

---@nodiscard
---@return string[]
function M.debug_library()
  return build_library(strict_root())
end

return M
