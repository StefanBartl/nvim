---@module 'autocmds.markdown'

-- Create (or clear) an augroup for Markdown-specific autocmds
vim.api.nvim_create_augroup("markdown_autocmds", { clear = true })

--- Set up a FileType-based autocmd for Markdown buffers
--- Registers a buffer-local keymap that wraps the current word as a Markdown link: [word]()
vim.api.nvim_create_autocmd("FileType", {
	group = "markdown_autocmds",
	pattern = "markdown",
	callback = function()
		---@diagnostic disable: undefined-global

		-- Get current buffer handle and validate buffer is modifiable
		---@type integer
		local buf = vim.api.nvim_get_current_buf()
		if not vim.bo[buf].modifiable then
			vim.notify("Buffer is not modifiable", vim.log.levels.WARN)
			return
		end

		-- Key and description for the mapping
		---@type string
		local key = "<leader>["
		---@type string
		local description = "Wrap current word in Markdown link syntax"

		-- Handler: wrap <cword> as [word]() and place cursor inside the parentheses
		---@type fun(): nil
		local handler = function()
			-- Defensive: ensure we're still in a markdown buffer
			if vim.bo.filetype ~= "markdown" then
				return
			end

			-- Get the word under cursor
			---@type string
			local word = vim.fn.expand("<cword>")
			if not word or word == "" then
				return
			end

			-- Save current cursor position (row: 1-based, col: 0-based)
			---@type integer, integer
			local row, col = unpack(vim.api.nvim_win_get_cursor(0))

			-- Replace the word with [word]() using a change-inner-word motion
			-- This keeps the action atomic and undo-friendly.
			vim.cmd("normal! ciw[" .. word .. "]()")

			-- Compute new column to place cursor inside the parentheses: [word](|)
			---@type integer
			local new_col = col + 2 + #word + 1

			-- Restore cursor to the calculated position
			vim.api.nvim_win_set_cursor(0, { row, new_col })
		end

		-- Buffer-local normal-mode mapping
		vim.keymap.set("n", key, handler, {
			desc = description,
			buffer = buf,
			noremap = true,
			silent = true,
		})
	end,
})

-- Debug toggle für markdown-gf:
-- Wenn true:
--   - gibt zusätzliche Informationen mit vim.notify aus
--   - zeigt an, welches Link-Ziel erkannt wurde,
--     wie Relativpfade aufgelöst werden (./, ../),
--     welches Arbeitsverzeichnis (cwd) benutzt wird
--     und welcher finale Pfad bzw. URL geöffnet wird.
-- Wenn false:
--   - läuft die Logik still ohne Ausgaben.
--   - nützlich für den normalen Alltag, wenn keine Debug-Ausgaben gewünscht sind.
local DEBUG_MARKDOWN_GF = false

-- Autocommand für FileType "markdown":
-- Dieses Autocommand überschreibt den Normalmodus-Befehl `gf`
-- NUR in Markdown-Buffern.
-- Anstatt wie üblich nach einer Datei unter dem Cursor zu suchen,
-- wird eine Treesitter-basierte Logik verwendet, um:
--   • Inline-Links [Text](path.md) zu erkennen
--   • Referenz-Links [foo] + Definitionen [foo]: ./bar.md aufzulösen
--   • URLs (http://…, https://…, file://…) oder nackte Domains (www.github.com, example.org)
--     automatisch im Standardbrowser zu öffnen (plattformabhängig)
--   • Relative Pfade wie ./ oder ../../ korrekt zum aktuellen Buffer-Pfad aufzulösen
-- Bei fehlender Erkennung fällt es zurück auf das normale gf-Verhalten.
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown" },
	group = "markdown_autocmds",
	callback = function()
		vim.keymap.set("n", "gf", function()
			local ts_utils = require("nvim-treesitter.ts_utils")
			local node = ts_utils.get_node_at_cursor()
			if not node then
				return vim.cmd("normal! gf")
			end

			local bufnr = vim.api.nvim_get_current_buf()
			local path

			local function log(msg, val)
				if DEBUG_MARKDOWN_GF then
					vim.notify(msg .. tostring(val), vim.log.levels.INFO, { title = "markdown-gf" })
				end
			end

			----------------------------------------------------------------------
			-- Helper: finde Elternknoten bestimmter Typen im Treesitter-Baum
			----------------------------------------------------------------------
			local function find_parent(n, types)
				while n and not vim.tbl_contains(types, n:type()) do
					n = n:parent()
				end
				return n
			end

			----------------------------------------------------------------------
			-- Case 1: Inline-Link [text](path.md)
			----------------------------------------------------------------------
			local dest = find_parent(node, { "link_destination" })
			if dest and dest:type() == "link_destination" then
				path = vim.treesitter.get_node_text(dest, bufnr)
				log("Inline-Link erkannt: ", path)
			end

			----------------------------------------------------------------------
			-- Case 2: Referenz-Link [foo] + Definition [foo]: ./bar.md
			----------------------------------------------------------------------
			if not path then
				local ref = find_parent(node, { "link_reference" })
				if ref then
					local label = vim.treesitter.get_node_text(ref, bufnr)
					label = label:gsub("^%[", ""):gsub("%]$", "")
					log("Referenz-Label: ", label)
					for lnum = 1, vim.api.nvim_buf_line_count(bufnr) do
						local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
						local pat = "^%[" .. vim.pesc(label) .. "%]%s*:%s*(.+)$"
						local m = line:match(pat)
						if m then
							path = m
							log("Referenz-Ziel gefunden: ", path)
							break
						end
					end
				end
			end

			if not path then
				return vim.cmd("normal! gf")
			end

			----------------------------------------------------------------------
			-- Normalize: Backslashes → Slashes
			----------------------------------------------------------------------
			path = path:gsub("\\", "/")
			log("Normalisiert: ", path)

			----------------------------------------------------------------------
			-- Case 3: URL oder Domain
			----------------------------------------------------------------------
			if path:match("^https?://")
					or path:match("^file://")
					or path:match("^www%.")
					or path:match("^[A-Za-z0-9%-_]+%.[A-Za-z]+")
			then
				if path:match("^www%.") or path:match("^[A-Za-z0-9%-_]+%.[A-Za-z]+") then
					path = "http://" .. path
					log("Auto-HTTP ergänzt: ", path)
				end

				local opener
				if vim.fn.has("macunix") == 1 then
					opener = { "open", path }
				elseif vim.fn.has("unix") == 1 then
					opener = { "xdg-open", path }
				elseif vim.fn.has("win32") == 1 then
					opener = { "cmd.exe", "/c", "start", "", path }
				end

				log("Opener: ", table.concat(opener or {}, " "))

				if opener then
					vim.fn.jobstart(opener, { detach = true })
					return
				end
			end

			----------------------------------------------------------------------
			-- Case 4: Lokale Datei
			----------------------------------------------------------------------
			local cwd = vim.fn.expand("%:p:h")
			log("CWD: ", cwd)

			if not path:match("^/") and not path:match("^[A-Za-z]:[\\/]") then
				path = cwd .. "/" .. path
				log("Relativer Pfad kombiniert: ", path)
			end

			local target = vim.fn.fnamemodify(path, ":p")
			log("Absoluter Pfad: ", target)

			vim.cmd("edit " .. vim.fn.fnameescape(target))
		end, { buffer = true, desc = "Follow Markdown link (TS+URLs+Debug)" })
	end,
})
