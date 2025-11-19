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
    event = "VimEnter", --FIX: Wenn lazy false, dann muss man das dashboard mit q schließen, weil es überdeckt
		-- lazy = false,

    ---@param _ any
    ---@return SnacksSetup|table
    opts = function(_)
      --- keep configuration isolated; never mutate shared tables
      ---@type SnacksSetup
      local cfg = {
        debug = { enabled = true },
        dim = { enabled = true },
        profiler = { enabled = false }, -- enable only when profiling to avoid overhead
        quickfile = { enabled = true },
        scope = { enabled = true },
        scratch = { enabled = true },
        toggle = { enabled = true },
        words = { enabled = true },

				image = { enabled = true },  -- AUDIT:

        -- Safeguard for very large files
        bigfile = { enabled = true },

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
        picker = { enabled = false },
      }
      return cfg
    end,

    ---@param _ any
    ---@param opts SnacksSetup
    config = function(_, opts)
      -- Defensive require for snacks itself
      local ok_snacks, snacks = pcall(require, "snacks")
      if not ok_snacks then
        vim.notify("[snacks] not available", vim.log.levels.WARN)
        return
      end

      -- Attempt to load the modular custom dashboard entrypoint.
      -- If it's not present, fall back to the old direct setup path.
      local ok_cd, cd = pcall(require, "config.snacks.custom_dashboard.init")
      if not ok_cd or type(cd.setup) ~= "function" then
        -- Fallback: old direct setup if custom_dashboard module missing
        local ok_setup, err = pcall(snacks.setup, opts)
        if not ok_setup then
          vim.notify("[snacks] setup() failed (fallback): " .. tostring(err), vim.log.levels.ERROR)
        end
        return
      end

      -- Call the custom dashboard setup, passing snacks and opts.
      -- The custom module will ensure sections are registered BEFORE snacks.setup().
      local ok, err = pcall(cd.setup, snacks, opts)
      if not ok then
        vim.notify("[snacks.custom_dashboard] setup failed: " .. tostring(err), vim.log.levels.ERROR)
      end
    end,

    keys = function()
      local ok, maps = pcall(require, "config.snacks.custom_dashboard.mappings")
      if ok and type(maps.keys) == "function" then
        return maps.keys()
      end
      return {}
    end,
  },
}
