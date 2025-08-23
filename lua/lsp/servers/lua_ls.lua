---@module 'lsp.servers.lua_ls'  -- LuaLS tuned setup for faster startup/indexing
--- This module configures lua-language-server (lua_ls) for Neovim with a focus on
--- reducing initial indexing time and avoiding overly large workspaces.

---@class LuaLsServer
local M = {}

--- Setup lua_ls with performance-oriented defaults.
---@param shared table  -- common LSP opts: capabilities, on_attach, on_init
---@return nil
function M.setup(shared)
  if type(shared) ~= "table" then return end

  local ok_lsp, lspconfig = pcall(require, "lspconfig")
  if not ok_lsp then return end

--- Determine a safe starting path.
---@return string | nil
local function startpath_from()
  -- Prefer the given filename, then current buffer, then CWD.
  return (vim.uv or vim.loop).cwd()
end

--- Find the directory that contains any of `names` by walking upward.
---@param names string[]  -- file/dir basenames to match
---@param from string     -- start path (file or directory)
---@return string|nil     -- directory that contains the found item
local function find_upward_dir(names, from)
  -- If `from` is a file, searching from that file is still fine: vim.fs.find
  -- will walk upward from its directory.
  local found = vim.fs.find(names, { path = from, upward = true })
  if found and found[1] then
    return vim.fs.dirname(found[1])
  end
  return nil
end

--- Compute a strict root directory.
local function strict_root()
  local start = startpath_from()
  if not start then return end
  -- 1) Prefer VCS markers
  local vcs_root = find_upward_dir({ ".git", ".hg", ".svn" }, start)
  if vcs_root then
    return vcs_root
  end

  -- 2) Common Lua project/config markers
  local lua_root = find_upward_dir({ ".luarc.json", ".neoconf.json", "selene.toml", "stylua.toml" }, start)
  if lua_root then
    return lua_root
  end

  -- 3) Fallback: keep it small and predictable (never $HOME).
  return vim.fn.expand("~/.config/nvim")
end

  local settings = {
    Lua = {
      runtime = { version = "LuaJIT" },       -- Neovim runs LuaJIT
      hint = { enable = true },               -- keep inlay hints if you like them
      diagnostics = { globals = { "vim", "vim.uv", "vim.fn", "vim.inspect", "vim.loop" }, }, -- declare vim as global
      completion = {
        callSnippet = "Replace",
        workspaceWord = false,                -- do not scan other files for words
      },
      semantic = { enable = false },          -- rely on Treesitter; reduces server work WATCH:
      workspace = {
        checkThirdParty = false,
        -- Aggressively ignore heavy directories (glob patterns, .gitignore grammar)
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
        -- Reduce preload to shorten the "workspace loading" phase WATCH:
        maxPreload = 1500,                    -- default is 5000
        preloadFileSize = 200,                -- default is 500 (KB)
        -- Keep library empty here; lazydev.nvim will inject what is needed.
        ---@type string[]|string
        library = {},
      },
      telemetry = {
        enable = false,
      }
    },
  }

  lspconfig.lua_ls.setup({
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
    root_dir = strict_root,
    single_file_support = true,               -- prevents extra workspaces
    settings = settings,
  })
end

return M
