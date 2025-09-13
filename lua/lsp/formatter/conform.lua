---@module 'lsp.formatter.conform'
---@class ConformPolicy

local M = {}

-- Add mason/bin to PATH defensively (works even if mason isn't loaded yet)
local function ensure_mason_in_path()
	local sep = (package.config:sub(1, 1) == "\\") and ";" or ":"
	local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
	local PATH = vim.env.PATH or ""
	if not string.find(PATH, mason_bin, 1, true) then
		vim.env.PATH = mason_bin .. sep .. PATH
	end
end

-- Resolve an executable across common install locations (pipx, mason, pyenv, Windows)
local function resolve(cmd)
	local exepath = vim.fn.exepath(cmd)
	if exepath ~= nil and exepath ~= "" then return exepath end
	local uv = vim.uv or vim.loop
	local home = (uv.os_homedir and uv.os_homedir()) or os.getenv("HOME") or os.getenv("USERPROFILE") or ""
	local candidates = {
		-- mason/bin (added to PATH above, but check anyway)
		vim.fn.stdpath("data") .. "/mason/bin/" .. cmd .. (package.config:sub(1, 1) == "\\" and ".cmd" or ""),
		-- pipx/userbase
		home .. "/.local/bin/" .. cmd,
		home .. "/.pyenv/shims/" .. cmd,
		-- Windows pip user base
		home .. "/AppData/Roaming/Python/Scripts/" .. cmd .. ".exe",
	}
	for _, p in ipairs(candidates) do
		if type(p) == "string" and p ~= "" and (uv.fs_stat(p) or vim.fn.filereadable(p) == 1) then
			return p
		end
	end
	return cmd -- fallback; conform/exepath will try again
end

---@return nil
function M.setup()
	local ok, conform = pcall(require, "conform")
	if not ok then return end

	ensure_mason_in_path()

	conform.setup({
		formatters_by_ft = {
			lua = { "stylua" },
			go = { "goimports", "gofmt" },
			javascript = { "prettierd", "prettier" },
			typescript = { "prettierd", "prettier" },
			typescriptreact = { "prettierd", "prettier" },
			javascriptreact = { "prettierd", "prettier" },
			json = { "jq" },
			css = { "prettierd", "prettier" },
			html = { "prettierd", "prettier" },
			zig = { "zigfmt" },
			c = { "clang_format" },
			cpp = { "clang_format" },
			cs = { "csharpier" },
			markdown = { "mdformat", "prettierd", "prettier" },
		},

		-- Explicit commands so Conform can find the executables reliably
		formatters = {
			mdformat = {
				command = resolve("mdformat"),
				args = { "-" },
				stdin = true,
				env = { PYTHONIOENCODING = "utf-8", PYTHONUTF8 = "1" }, -- win
			},
			prettierd = {
				command = resolve("prettierd"),
			},
			prettier = {
				command = resolve("prettier"),
				prepend_args = { "--stdin-filepath", "$FILENAME" },
			},
		},

		notify_on_error = true,
	})
end

-- Small helper to show which formatter chain is configured & available for current buffer
---@param bufnr integer|nil
function M.which(bufnr)
	bufnr = bufnr or 0
	local ft = vim.bo[bufnr].filetype
	local chain = (ft == "markdown") and { "mdformat", "prettierd", "prettier" }
			or (ft == "markdown.mdx") and { "prettierd", "prettier" }
			or {}
	if #chain == 0 then
		vim.notify("No formatter chain known for filetype=" .. tostring(ft), vim.log.levels.INFO)
		return
	end
	local lines = { "Formatters for filetype=" .. ft .. ":" }
	for _, name in ipairs(chain) do
		local cmd = (name == "mdformat" and resolve("mdformat"))
				or (name == "prettierd" and resolve("prettierd"))
				or resolve("prettier")
		local found = vim.fn.exepath(cmd) or ""
		local ok = (found ~= "")
		table.insert(lines,
			string.format(" - %s: %s%s", name, (ok and found or cmd), ok and " (available)" or " (NOT FOUND)"))
	end
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

return M
