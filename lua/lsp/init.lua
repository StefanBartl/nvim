---@module 'lsp'
-- Native LSP bootstrap for Neovim ≥ 0.11.

local M = {}

local create_user_command = vim.api.nvim_create_user_command

---@type boolean
M._initialized = false

---@class MyLspInit
---@field ensure_installing boolean|nil

---@param cfg MyLspInit
---@return boolean ok
function M.setup(cfg)
	if M._initialized then
		return true
	end

	do
		local ok_h, handlers = pcall(require, "lsp.core.handlers")
		if ok_h and handlers and type(handlers.setup) == "function" then
			pcall(handlers.setup)
		end
	end
	do
		local ok_diag, diagnostics = pcall(require, "lsp.core.diagnostics")
		if ok_diag and diagnostics and type(diagnostics.setup) == "function" then
			pcall(diagnostics.setup)
		end
	end
	do
		local ok_ts, treesitter = pcall(require, "lsp.core.treesitter")
		if ok_ts and treesitter and type(treesitter.setup) == "function" then
			pcall(treesitter.setup)
		end
	end

	local caps = (function()
		local ok, mod = pcall(require, "lsp.core.capabilities")
		if ok and mod and type(mod.get) == "function" then
			return mod.get()
		end
		return vim.lsp.protocol.make_client_capabilities()
	end)()

	local attach_api = (function()
		local ok, mod = pcall(require, "lsp.core.attach")
		if ok and mod and type(mod.build) == "function" then
			return mod.build({ use_workspace_diagnostics = true, use_lazydev = true })
		end
		return {
			on_attach = function() end,
			on_init = function()
				return true
			end,
		}
	end)()

	local formatter = (function()
		local ok, mod = pcall(require, "lsp.formatter.init")
		if ok and mod and type(mod.build) == "function" then
			return mod.build({ format_on_save = false, timeout_ms = 1500 })
		end
		return {
			format = function(_)
				return false
			end,
			enable = function()
				return false
			end,
			disable = function()
				return true
			end,
			toggle = function()
				return false
			end,
			is_enabled = function()
				return false
			end,
		}
	end)()
	do
		local ok, conform_mod = pcall(require, "lsp.formatter.conform")
		if ok and conform_mod and type(conform_mod.setup) == "function" then
			pcall(conform_mod.setup)
		end
	end
	vim.g._formatter_api = formatter

	pcall(create_user_command, "LspFormat", function(_)
		formatter.format(0)
	end, { bang = true, desc = "LSP/Conform: format current buffer once (silent)" })
	pcall(create_user_command, "LspFormatToggle", function()
		formatter.toggle()
	end, { desc = "LSP/Conform: toggle format-on-save (silent)" })
	pcall(create_user_command, "LspFormatOn", function()
		formatter.enable()
	end, { desc = "LSP/Conform: enable format-on-save (silent)" })
	pcall(create_user_command, "LspFormatOff", function()
		formatter.disable()
	end, { desc = "LSP/Conform: disable format-on-save (silent)" })
	pcall(create_user_command, "LspFormatStatus", function()
		local state = formatter.is_enabled() and "true" or "false"
		vim.notify("LSP/Conform state: " .. state, vim.log.levels.INFO)
	end, { desc = "LSP/Conform: show state of formater" })
	pcall(create_user_command, "LspFormatWhich", function()
		local ok, mod = pcall(require, "lsp.formatter.conform")
		if ok and type(mod.which) == "function" then
			mod.which(0)
		else
			vim.notify("Conform helper unavailable", vim.log.levels.WARN)
		end
	end, { desc = "Show formatter chain & availability for current buffer" })

	-- AUDIT: 'lspconfig'-builtin comands

	local function _active_servers()
		local ok, reg = pcall(require, "lsp.core.registry")
		if not ok or type(reg) ~= "table" then
			return {}
		end
		return { "lua_ls", "ts_ls", "gopls", "marksman" }
	end

	local function _buf_clients(bufnr)
		return vim.lsp.get_clients({ bufnr = bufnr or 0 })
	end

	pcall(vim.api.nvim_create_user_command, "LspStartHere", function()
		for _, name in ipairs(_active_servers()) do
			pcall(vim.lsp.enable, name) -- (neu) native API
		end
	end, { desc = "Start/attach configured LSP servers for current buffer (vim.lsp)" })

	pcall(vim.api.nvim_create_user_command, "LspStopHere", function()
		local ids = {}
		for _, c in ipairs(_buf_clients(0)) do
			ids[#ids + 1] = c.id
		end
		if #ids > 0 then
			vim.lsp.stop_client(ids, true)
		end
	end, { desc = "Stop LSP clients attached to current buffer" })

	pcall(vim.api.nvim_create_user_command, "LspRestartHere", function()
		local ids = {}
		for _, c in ipairs(_buf_clients(0)) do
			ids[#ids + 1] = c.id
		end
		if #ids > 0 then
			vim.lsp.stop_client(ids, true)
		end
		vim.defer_fn(function()
			for _, name in ipairs(_active_servers()) do
				pcall(vim.lsp.enable, name)
			end
		end, 50)
	end, { desc = "Restart LSP for current buffer (vim.lsp)" })

	local shared = {
		capabilities = caps,
		on_attach = attach_api.on_attach,
		on_init = attach_api.on_init,
		formatter = formatter,
	}

	local ok_reg, registry = pcall(require, "lsp.core.registry")
	if not ok_reg or not registry or type(registry.setup_all) ~= "function" then
		vim.notify("LSP registry missing; skipping server setup", vim.log.levels.WARN)
		return false
	end

	do
		local ok, langs = pcall(require, "lsp.languages")
		if ok and langs and type(langs.enable_all) == "function" then
			pcall(langs.enable_all)
		end
	end

	local names = registry.setup_all(shared)
	if type(names) == "table" and #names > 0 then
		pcall(vim.lsp.enable, names)
	end

	vim.diagnostic.config({
		update_in_insert = false,
		severity_sort = true,
		virtual_text = { spacing = 2, prefix = "●" },
		float = { border = "rounded", source = "if_many" },
	})

	require("lsp.lspdoctor").setup({
		use_notify = false,
		list_limit = 8,
		formatter_priority = { "eslint", "null-ls", "lua_ls" },
		semantic_tokens_timeout = 300,
		scratch_filetype = "markdown",
	})
	require("lsp.lspdoctor").enable_usercmd()

	if cfg.ensure_installing == true then
		require('config.mason.ensure_install').enable({
			lsp = true,
			dap = true,
			linters = true,
			formatters = true,
			overrides = {
				lsp = {
					["java-language-server"]   = false, -- keep off unless 'mvn' is available
					["csharp-language-server"] = false, -- prefer 'omnisharp' if dotnet exists
					-- ["omnisharp"]              = require('config.mason.ensure_install').has_dotnet and true or false, -- you can compute booleans beforehand
				},
				dap = {
					["node-debug2-adapter"] = false, -- deprecated; use js-debug-adapter
				},
				linters = {
					["eslint_d"] = true, -- ensure enabled
				},
				formatters = {
					["prettier"] = true, -- ensure enabled
				},
			},
		})
	end

	M._initialized = true
	return true
end

return M
