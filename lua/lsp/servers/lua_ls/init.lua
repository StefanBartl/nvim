---@module 'lsp.servers.lua_ls'
--- Lua language server setup using native LSP config/enable with strict root and scoped libraries.

---@class LuaLsServer
local M = {}

local ignore = require("lsp.servers.lua_ls.ignore")
local root_resolver = require("lsp.servers.lua_ls.rootresolver")

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
			root_dir = root_resolver(),
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
						ignoreDir = ignore.as_luals_patterns(),
						useGitIgnore = true,
						maxPreload = 1500,
						preloadFileSize = 200,
						-- library per Root (siehe on_new_config unten)
					},
					telemetry = { enable = false },
				},
			},
			on_new_config = function(new_config, new_root)
				if new_config and new_config.settings and new_config.settings.Lua then
					local build_library = require("lsp.servers.lua_ls.build_library")
					new_config.settings.Lua.workspace.library = build_library(new_root)
				end
			end,
		})
		if (opts or {}).enable ~= false then
			pcall(vim.lsp.enable, "lua_ls")
		end
	end
end

return M
