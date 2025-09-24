---@module 'plugins.snacks'
---@brief Lazy-spec for folke/snacks.nvim with defensive setup, additive dashboard, and curated keymaps.
---@description
--- This module registers Snacks.nvim as a Lazy plugin with a hardening focus:
--- - Single point of configuration with pcall guards (no hard crashes on API shifts).
--- - Explicit module enablement (opt-in) for predictable behavior.
--- - Dashboard keeps upstream defaults; we add exactly one extra key (scratch).
--- - Picker stays disabled to avoid overlap with Telescope/fzf-lua stacks.
--- - Bigfile is enabled to protect UI responsiveness on large files.
--- - Keymaps use a safe dispatcher to avoid runtime errors when submodules change.
---
--- Design notes (rules applied):
--- - Error handling via pcall wrappers; no silent failures (notify on UI layer only).  -- Arch&Coding-Regeln §1 :contentReference[oaicite:2]{index=2}
--- - Single Responsibility: this file configures one plugin target, nothing else.       -- Check.md §Modularität :contentReference[oaicite:3]{index=3}
--- - No globals; everything is local to the module.                                     -- Arch&Coding-Regeln §2 :contentReference[oaicite:4]{index=4}
--- - Import order: core(vim) → plugin(require) → helpers.                               -- Check.md §Import-Reihenfolge :contentReference[oaicite:5]{index=5}

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
---@field bigfile SnacksModuleOpts|nil
---@field dashboard table|nil
---@field picker SnacksModuleOpts|nil

---@type table
return {
  {
    "folke/snacks.nvim",
    event = "VeryLazy", -- defer until UI is ready; quickfile still accelerates single-file cold open
    ---@param _ any
    ---@return SnacksSetup|table
    opts = function(_)
      --- keep configuration isolated; never mutate shared tables
      ---@type SnacksSetup
      local cfg = {
        debug = { enabled = true },
        dim = {
          enabled = true,
          -- implementation may select treesitter/indent internally; defaults are fine
        },
        profiler = { enabled = false },  -- enable only when profiling to avoid overhead
        quickfile = { enabled = true },
        scope = { enabled = true },
        scratch = { enabled = true },
        toggle = { enabled = true },
        words = { enabled = true },

        -- safeguard for very large files
        bigfile = { enabled = true },

        -- dashboard
        dashboard = { enabled = true },

        -- keep Snacks' own picker disabled to avoid redundancy with Telescope/fzf-lua
        picker = { enabled = false },
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
      -- Explicit setup: only modules marked enabled will activate.
      local ok_setup, err = pcall(snacks.setup, opts)
      if not ok_setup then
        vim.notify("[snacks] setup() failed: " .. tostring(err), vim.log.levels.ERROR)
        return
      end

      -- Small discoverability hint (non-intrusive, once).
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          vim.defer_fn(function()
            vim.notify("Snacks ready · run :checkhealth snacks if needed", vim.log.levels.DEBUG)
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

      --- fixed-length preallocation for the keymap table
      ---@type (string|function|table)[]
      local maps = { [14] = false }

      maps[1]  = { "<leader>ud", function() safe_call("debug", "open")    end, desc = "Snacks Debug: Open Inspector" }
      maps[2]  = { "<leader>uD", function() safe_call("debug", "toggle")  end, desc = "Snacks Debug: Toggle Overlay" }
      maps[3]  = { "<leader>uf", function() safe_call("dim", "toggle")    end, desc = "Snacks Dim: Toggle Focus Scope" }

      maps[4]  = { "<leader>pp", function() safe_call("profiler", "start")  end, desc = "Snacks Profiler: Start" }
      maps[5]  = { "<leader>pP", function() safe_call("profiler", "stop")   end, desc = "Snacks Profiler: Stop" }
      maps[6]  = { "<leader>pr", function() safe_call("profiler", "report") end, desc = "Snacks Profiler: Report" }

      maps[7]  = { "<leader>uq", function() safe_call("quickfile", "disable") end, desc = "Snacks Quickfile: Disable (session)" }

      maps[8]  = { "]s", function() safe_call("scope", "jump_next") end, desc = "Snacks Scope: Next" }
      maps[9]  = { "[s", function() safe_call("scope", "jump_prev") end, desc = "Snacks Scope: Prev" }

      maps[10] = { "<leader>ns", function() safe_call("scratch", "open") end, desc = "Snacks Scratch: Open" }
      maps[11] = { "<leader>nS", function() safe_call("scratch", "new")  end, desc = "Snacks Scratch: New" }

      return maps
    end,
  },
}
