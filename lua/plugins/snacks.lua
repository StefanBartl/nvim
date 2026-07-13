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

local picker_config = require("config.snacks.picker")

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
    -- event = "VimEnter", -- custom dashboard neesds to load early
    lazy = false,
    priority = 1000,

    ---@param _ any
    ---@return Plugins.Snacks.Setup|table
    opts = function(_)
      ---@type Plugins.Snacks.Setup
      local cfg = {
        debug = { enabled = true },
        dim = { enabled = false },
        profiler = { enabled = false },
        quickfile = { enabled = true },
        scope = { enabled = false },
        scratch = { enabled = false },
        toggle = { enabled = false },
        words = { enabled = false },
        -- In-terminal image rendering (kitty graphics protocol).
        -- Requires nvim to run inside a graphics-capable terminal (WezTerm on
        -- Windows) and the `magick` CLI in PATH for png/webp/svg conversion.
        -- Defaults already enable doc.inline + doc.float for markdown.
        image = { enabled = true },
        bigfile = { enabled = false },
        notifier = { enabled = false },
        dashboard = {
          enabled = false,
          sections = {
            { section = "header" }, -- default
            { section = "keys", gap = 1, padding = 1 }, -- default
            {
              title = "Sessions",
              icon = "󰆓 ",
              section = "my_sessions",
              indent = 2,
              padding = 1,
            }, -- custom
            { section = "startup" }, -- default
          },
        },

        picker = picker_config.get_config(),
      }
      return cfg
    end,

    keys = require("config.snacks.mappings").get_all_keys(),

    ---@param _ any
    ---@param opts Plugins.Snacks.Setup
    ---@diagnostic disable-next-line: unused-local
    config = function(_, opts)
      require("config.snacks.usrcmds").setup()

      --   -- Defensive require for snacks itself
      --   local ok_snacks, snacks = pcall(require, "snacks")
      --   if not ok_snacks then
      --     vim.notify("[snacks] not available", vim.log.levels.WARN)
      --     return
      --   end
      --
      --   -- Attempt to load the modular custom dashboard entrypoint.
      --   -- If it's not present, fall back to the old direct setup path.
      --   local ok_cd, cd = pcall(require, "config.snacks.custom_dashboard.init")
      --   if not ok_cd or type(cd.setup) ~= "function" then
      --     -- Fallback: old direct setup if custom_dashboard module missing
      --     local ok_setup, err = pcall(snacks.setup, opts)
      --     if not ok_setup then
      --       vim.notify("[snacks] setup() failed (fallback): " .. tostring(err), vim.log.levels.ERROR)
      --     end
      --     return
      --   end
      --
      --   -- Call the custom dashboard setup, passing snacks and opts.
      --   -- The custom module will ensure sections are registered BEFORE snacks.setup().
      --   local ok, err = pcall(cd.setup, snacks, opts)
      --   if not ok then
      --     vim.notify("[snacks.custom_dashboard] setup failed: " .. tostring(err), vim.log.levels.ERROR)
      --   end
      -- end,
      --
      -- keys = function()
      --   local ok, maps = pcall(require, "config.snacks.custom_dashboard.mappings")
      --   if ok and type(maps.keys) == "function" then
      --     return maps.keys()
      --   end
      --   return {}
    end,
  },
}
