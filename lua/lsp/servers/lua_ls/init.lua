---@module 'lsp.servers.lua_ls'
--- Lua language server setup using native LSP config/enable with strict root and scoped libraries.
---@class LuaLsServer
local notify = require("lib.notify").create("[lsp.servers.lua_ls]")

local M = {}

-- Import required dependencies for ignore patterns and root resolution
local ignore = require("lsp.servers.lua_ls.ignore")
local root_resolver = require("lsp.servers.lua_ls.rootresolver")

---@param shared {capabilities?:table,on_attach?:fun(client,bufnr),on_init?:fun(client,init_result):boolean}|nil
---@param opts { enable?: boolean }|nil
---@return nil
function M.setup(shared, opts)
  -- Ensure shared and opts are tables, even if nil was passed
  shared = shared or {}
  opts = opts or {}

  -- Only proceed if Neovim's native LSP config API is available (Neovim 0.10+)
  if type(vim.lsp.config) == "table" then
    -- Register the lua_ls server configuration
    vim.lsp.config("lua_ls", {
      -- Command to launch the language server executable
      cmd = { "lua-language-server" },

      -- File types this server should attach to
      filetypes = { "lua" },

      -- Use our custom root directory resolver
      root_dir = root_resolver(),

      -- Allow the server to run even without a detected project root
      single_file_support = true,

      -- Pass through shared LSP capabilities (e.g., from cmp-nvim-lsp)
      capabilities = shared.capabilities,

      -- Pass through custom attach handler
      on_attach = function(client, bufnr)
        -- Wrap client to catch malformed requests
        local ok_err, err_handler = pcall(require, "lsp.servers.lua_ls.error_handler")
        if ok_err and type(err_handler.wrap_client) == "function" then
          pcall(err_handler.wrap_client, client)
        end

        if type(shared.on_attach) == "function" then
          shared.on_attach(client, bufnr)
        end
      end,

      -- Pass through initialization handler
      on_init = shared.on_init,

      -- Language server specific settings
      settings = {
        Lua = {
          -- Configure Lua runtime environment
          runtime = {
            version = "LuaJIT", -- Use LuaJIT for Neovim
          },

          -- Enable inlay hints for better code insight
          hint = { enable = true },

          -- Configure diagnostics and recognized globals
          diagnostics = {
            globals = {
              -- Neovim API globals
              "vim",
              "vim.uv", -- Async I/O library
              "vim.loop", -- Legacy name for vim.uv
              "vim.fn", -- Vimscript function access
              "vim.inspect", -- Table inspection
              "vim", -- Duplicate entry for safety

              -- Testing framework globals (busted/plenary)
              "describe",
              "it",
              "before_each",
              "after_each",
              "setup",
              "teardown",
              "assert",
              "spy",
              "stub",
              "mock",
            },
          },

          -- Configure completion behavior
          completion = {
            callSnippet = "Replace", -- Replace function signature when completing
            workspaceWord = false, -- Don't suggest words from entire workspace
          },

          -- Disable semantic token highlighting (use TreeSitter instead)
          semantic = { enable = false },

          -- Workspace scanning and library configuration
          workspace = {
            checkThirdParty = true, -- Check for third-party libraries

            -- Use our centralized ignore patterns to skip noisy directories
            ignoreDir = ignore.as_luals_patterns(),

            -- Respect .gitignore files
            useGitIgnore = true,

            -- Limit workspace scanning to prevent performance issues
            -- maxPreload = 3000, -- Maximum number of files to preload
            -- preloadFileSize = 500, -- Maximum file size in KB

            -- CRITICAL: Increase preload limits for type files
            maxPreload = 5000, -- Increased from 3000
            preloadFileSize = 1000, -- Increased from 500 (KB)

            -- library will be populated dynamically per root in on_new_config
          },

          -- Disable telemetry
          telemetry = { enable = false },
        },
      },

      -- Hook called when a new root directory is detected or config changes
      on_new_config = function(new_config, new_root)
        -- CRITICAL: Guard against nil config
        if not new_config then
          notify.error("[lua_ls] on_new_config: new_config is nil")
          return
        end

        if not new_config.settings then
          notify.error("[lua_ls] on_new_config: settings is nil")
          return
        end

        if not new_config.settings.Lua then
          notify.error("[lua_ls] on_new_config: settings.Lua is nil")
          return
        end

        -- Build project-specific library paths
        local build_library = require("lsp.servers.lua_ls.build_library")
        local per_root_lib = build_library(new_root) or {}

        -- Get all Neovim runtime paths
        local runtime_lib = vim.api.nvim_get_runtime_file("", true) or {}

        -- Merge libraries
        local merged = {}

        -- Add Neovim runtime paths
        for _, p in ipairs(runtime_lib) do
          merged[p] = true
        end

        -- Add project-specific library paths
        for k, v in pairs(per_root_lib) do
          merged[k] = v
        end

        -- Assign merged library to workspace configuration
        new_config.settings.Lua.workspace.library = merged
      end,
    })

    -- Automatically enable the server unless explicitly disabled
    if (opts or {}).enable ~= false then
      -- Use pcall to prevent errors if vim.lsp.enable is not available
      pcall(vim.lsp.enable, "lua_ls")
    end
  end

  require("lsp.servers.lua_ls.reload").setup()
end

return M
