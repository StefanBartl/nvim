---@module 'plugins.snacks'
---@brief Lazy-spec for folke/snacks.nvim with defensive setup and a first-class custom dashboard section for sessions.
---@description
--- This module registers Snacks.nvim as a Lazy plugin with a hardening focus:
--- - Single point of configuration with pcall guards (no hard crashes on API shifts).
--- - Explicit module enablement (opt-in) for predictable behavior.
--- - Dashboard keeps upstream defaults; we REPLICATE the default sections and INSERT one extra section ("Sessions") using Snacks' public sections API.
--- - Picker stays disabled to avoid overlap with Telescope/fzf-lua stacks.
--- - Bigfile is enabled to protect UI responsiveness on large files.
--- - Keymaps use a safe dispatcher to avoid runtime errors when submodules change.
---
--- Design notes (rules applied):
--- - Errors guarded via pcall; UI-layer notify only.  -- safety
--- - Single Responsibility: one plugin configured here. -- modularity
--- - No globals; locals only.                           -- cleanliness
--- - Import order: core(vim) → plugin(require) → helpers.
---
--- Dashboard API reference:
--- - Custom sections are added by assigning functions to `require('snacks.dashboard').sections[NAME]`
---   and then referencing them with `{ section = NAME }` in `opts.dashboard.sections`.  -- matches docs/types
---   Built-in defaults are `{ {section="header"}, {section="keys", ...}, {section="startup"} }`.  -- we replicate + extend
---   Each item supports fields `icon|title|desc|action|key|...`; `action` may be string/func.  -- compatible formats

---@class SnacksModuleOpts
---@field enabled boolean
---@field [string] any

---@class SnacksSetup
---@field debug SnacksModuleOpts|nil
---@field dim SnacksModuleOpts|nil
---@field profiler SnacksModuleOpts|nil
---@field quickfile SnacksModuleOpts|nil
---@field scope SnacksModuleOpts|nil
---@field scratch SnacksModuleOpts|nil
---@field toggle SnacksModuleOpts|nil
---@field words SnacksModuleOpts|nil
---@field bigfile SnacksModuleOpts|nil
---@field dashboard table|nil
---@field picker SnacksModuleOpts|nil

---@type table
return {

	-- disable nvchad dashboard to prevent crash with custom snacks dashboard
  {
    "nvchad/ui",
    optional = true,
    ---@param _ any
    ---@param opts table
    opts = function(_, opts)
      opts = opts or {}
      opts.nvdash = opts.nvdash or {}
      opts.nvdash.load_on_startup = false
      opts.nvdash.enabled = false
      return opts
    end,
  },

	{
		"folke/snacks.nvim",
		event = "VeryLazy", -- defer until UI is ready; quickfile still accelerates single-file cold open

		---@param _ any
		---@return SnacksSetup|table
		opts = function(_)
			--- keep configuration isolated; never mutate shared tables
			---@type SnacksSetup
			local cfg = {
				debug     = { enabled = true },
				dim       = { enabled = true },
				profiler  = { enabled = false }, -- enable only when profiling to avoid overhead
				quickfile = { enabled = true },
				scope     = { enabled = true },
				scratch   = { enabled = true },
				toggle    = { enabled = true },
				words     = { enabled = true },

				-- Safeguard for very large files
				bigfile   = { enabled = true },

				-- Dashboard: replicate defaults and insert our custom "sessions" section.
				-- According to Snacks docs, defaults are: header, keys, startup.
				-- We keep those and add our own section in between keys and startup.
				dashboard = {
					enabled = true,
					sections = {
						{ section = "header" }, -- default
						{ section = "keys", gap = 1, padding = 1 }, -- default
						{ title = "Sessions", icon = "󰆓 ", section = "my_sessions", indent = 2, padding = 1 }, -- custom
						{ section = "startup" }, -- default
					},
				},

				-- Keep Snacks' own picker disabled to avoid redundancy with Telescope/fzf-lua
				picker    = { enabled = false },
			}
			return cfg
		end,

		---@param _ any
		---@param opts SnacksSetup
		config = function(_, opts)
			-- Defensive setup with pcall; UI-layer notify is acceptable per rules.
			local ok, snacks = pcall(require, "snacks")
			if not ok then
				vim.notify("[snacks] not available", vim.log.levels.WARN)
				return
			end

			-- Define our custom dashboard section BEFORE setup, so the resolver can find it.
			-- This follows Snacks' documented model: sections are looked up by name and called with (item).
			do
				--- Sessions storage root (must match your sessions module)
				local SESS_ROOT = (vim.fn.stdpath("config") .. "/lua/sessions/storage")

				--- Create a dashboard section that lists sessions from stdpath('config')/lua/sessions/storage.
				--- Sorting by mtime desc; items use {icon,title,desc,action} as per dashboard types.
				---@diagnostic disable snacks.dashboard/[item/section] exists
				---@param _ snacks.dashboard.Item # item (unused)
				---@return snacks.dashboard.Section|nil
				---@diagnostic enable
				local function my_sessions_section(_)
					-- English comments inside code by request:
					-- Cheap dependencies / locals
					local uv = vim.uv or vim.loop
					local fn = vim.fn
					-- If directory does not exist, return nil to keep the section empty.
					local st = uv.fs_stat(SESS_ROOT)
    if not (st and st.type == "directory") then
      return {
        { icon = " ", title = "No sessions found", action = function() end, hidden = false },
      }
    end

					-- Enumerate session files (fast path: glob); accept any files to be robust.
					---@type string[]
					local files = fn.glob(SESS_ROOT .. "/*", false, true)

					-- If empty, keep the section but show a subtle placeholder.
					if #files == 0 then
						return {
							{
								icon = " ",
								title = "No sessions found",
								desc = fn.fnamemodify(SESS_ROOT, ":~"),
								hidden = false,
								action = function() end, -- no-op
							},
						}
					end

					-- Build index + mtimes for sort
					local n = #files
					---@type integer[]  -- indices
					local ix = { [n] = 0 }
					---@type integer[]  -- mtimes
					local mt = { [n] = 0 }
					for i = 1, n do
						ix[i] = i
						local s = uv.fs_stat(files[i])
						mt[i] = (s and s.mtime and s.mtime.sec) or 0
					end
					table.sort(ix, function(a, b) return mt[a] > mt[b] end)

					-- Emit items in sorted order; preallocate result
					---@type snacks.dashboard.Item[]
					local items = { [n] = false } --- pre-size table (values will be overwritten)
					for k = 1, n do
						local p = files[ix[k]]
						local name = fn.fnamemodify(p, ":t:r")
						items[k] = {
							icon = " ",
							title = name,
							-- Action calls your sessions plugin's load(name)
							action = function()
								local okS, S = pcall(require, "sessions")
								local load = okS and S and S.load
								if type(load) ~= "function" then
									vim.notify("[sessions] load() not available", vim.log.levels.ERROR)
									return
								end
								local ok2, err2 = load(name)
								if not ok2 then
									vim.notify("[sessions] load failed: " .. tostring(err2), vim.log.levels.ERROR)
								end
							end,
						}
					end
					return items
				end

				-- Register the custom section under a distinct name.
				local ok_dash, dash = pcall(require, "snacks.dashboard")
				if ok_dash and type(dash) == "table" then
					dash.sections = dash.sections or {}
					-- Only assign if not already present to avoid duplicate redefinitions on reload.
					if type(dash.sections.my_sessions) ~= "function" then
						dash.sections.my_sessions = my_sessions_section
					end
				end
			end

			-- Explicit setup: only modules marked enabled will activate.
			local ok_setup, err = pcall(snacks.setup, opts)
			if not ok_setup then
				vim.notify("[snacks] setup() failed: " .. tostring(err), vim.log.levels.ERROR)
				return
			end

			-- Optional: ensure the dashboard opens (useful on reload).
			-- One can comment this out if auto-opening is not desired.
			-- do
			--   local ok_dash, dash = pcall(require, "snacks.dashboard")
			--   if ok_dash and type(dash.open) == "function" then
			--     -- Defer a tick to let Lazy finish; tiny overhead.
			--     vim.defer_fn(function() pcall(dash.open) end, 10)
			--   end
			-- end

			-- Small discoverability hint (non-intrusive, once).
			vim.api.nvim_create_autocmd("VimEnter", {
				once = true,
				callback = function()
					vim.defer_fn(function()
						vim.notify("Snacks ready · dashboard with Sessions loaded", vim.log.levels.DEBUG)
					end, 50)
				end,
				desc = "Snacks init hint",
			})
		end,

		---@return table[]
		keys = function()
			-- Safe dispatcher to insulate from upstream API changes.
			---@param mod string
			---@param fn string
			---@param ... any
			---@return boolean ok
			local function safe_call(mod, fn, ...)
				local ok_mod, M = pcall(require, "snacks." .. mod)
				if not ok_mod or type(M[fn]) ~= "function" then
					vim.notify(string.format("[snacks] missing %s.%s()", mod, fn), vim.log.levels.WARN)
					return false
				end
				local ok_fn, err = pcall(M[fn], ...)
				if not ok_fn then
					vim.notify(string.format("[snacks] %s.%s(): %s", mod, fn, tostring(err)), vim.log.levels.ERROR)
					return false
				end
				return true
			end

			---@type (string|function|table)[]
			local maps = { [11] = false }

			maps[1]    = { "<leader>ud", function() safe_call("debug", "open") end, desc = "Snacks Debug: Open Inspector" }
			maps[2]    = { "<leader>uD", function() safe_call("debug", "toggle") end, desc = "Snacks Debug: Toggle Overlay" }
			maps[3]    = { "<leader>uf", function() safe_call("dim", "toggle") end, desc = "Snacks Dim: Toggle Focus Scope" }

			maps[4]    = { "<leader>ps", function() safe_call("profiler", "start") end, desc = "Snacks Profiler: Start" }
			maps[5]    = { "<leader>pS", function() safe_call("profiler", "stop") end, desc = "Snacks Profiler: Stop" }
			maps[6]    = { "<leader>pr", function() safe_call("profiler", "report") end, desc = "Snacks Profiler: Report" }

			maps[7]    = { "<leader>uq", function() safe_call("quickfile", "disable") end, desc =
			"Snacks Quickfile: Disable (session)" }

			maps[8]    = { "]s", function() safe_call("scope", "jump_next") end, desc = "Snacks Scope: Next" }
			maps[9]    = { "[s", function() safe_call("scope", "jump_prev") end, desc = "Snacks Scope: Prev" }

			maps[10]   = { "<leader>ns", function() safe_call("scratch", "open") end, desc = "Snacks Scratch: Open" }
			maps[11]   = { "<leader>nS", function() safe_call("scratch", "new") end, desc = "Snacks Scratch: New" }

			return maps
		end,
	},
}
