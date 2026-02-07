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
        image = { enabled = false },
        bigfile = { enabled = false },
        notifier = { enabled = true },
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

        picker = {
          enabled = true,
        },
      }
      return cfg
    end,

    keys = {

      -- Top Pickers & Explorer
      -- { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
      -- { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      -- { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
      {
        "<leader>:",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>N",
        function()
          Snacks.picker.notifications()
        end,
        desc = "Notification History",
      },
      {
        "<leader>F",
        function()
          Snacks.explorer()
        end,
        desc = "File Explorer",
      },
      -- find
      -- { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      -- { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
      -- { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
      -- { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files" },
      -- { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
      -- { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
      -- git
      {
        "<leader>gb",
        function()
          Snacks.picker.git_branches()
        end,
        desc = "Git Branches",
      },
      {
        "<leader>gl",
        function()
          Snacks.picker.git_log()
        end,
        desc = "Git Log",
      },
      {
        "<leader>gL",
        function()
          Snacks.picker.git_log_line()
        end,
        desc = "Git Log Line",
      },
      {
        "<leader>gs",
        function()
          Snacks.picker.git_status()
        end,
        desc = "Git Status",
      },
      {
        "<leader>gS",
        function()
          Snacks.picker.git_stash()
        end,
        desc = "Git Stash",
      },
      {
        "<leader>gd",
        function()
          Snacks.picker.git_diff()
        end,
        desc = "Git Diff (Hunks)",
      },
      {
        "<leader>gf",
        function()
          Snacks.picker.git_log_file()
        end,
        desc = "Git Log File",
      },
      -- gh
      {
        "<leader>gi",
        function()
          Snacks.picker.gh_issue()
        end,
        desc = "GitHub Issues (open)",
      },
      {
        "<leader>gI",
        function()
          Snacks.picker.gh_issue({ state = "all" })
        end,
        desc = "GitHub Issues (all)",
      },
      {
        "<leader>gp",
        function()
          Snacks.picker.gh_pr()
        end,
        desc = "GitHub Pull Requests (open)",
      },
      {
        "<leader>gP",
        function()
          Snacks.picker.gh_pr({ state = "all" })
        end,
        desc = "GitHub Pull Requests (all)",
      },
      -- Grep
      -- { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
      -- { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
      -- { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep" },
      -- { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },
      -- search
      -- { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
      -- { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History" },
      -- { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
      -- { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
      -- { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
      -- { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
      -- { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      -- { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
      {
        "<leader>sh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help Pages",
      },
      -- { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
      -- { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
      -- { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
      -- { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      -- { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
      -- { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
      {
        "<leader>sM",
        function()
          Snacks.picker.man()
        end,
        desc = "Man Pages",
      },
      -- { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
      -- { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
      -- { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
      -- { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
      {
        "<leader>ch",
        function()
          Snacks.picker.colorschemes()
        end,
        desc = "Colorschemes",
      },
      -- LSP
      {
        "GD",
        function()
          Snacks.picker.lsp_definitions()
        end,
        desc = "Goto Definition",
      },
      {
        "GD",
        function()
          Snacks.picker.lsp_declarations()
        end,
        desc = "Goto Declaration",
      },
      {
        "GR",
        function()
          Snacks.picker.lsp_references()
        end,
        nowait = true,
        desc = "References",
      },
      {
        "GI",
        function()
          Snacks.picker.lsp_implementations()
        end,
        desc = "Goto Implementation",
      },
      {
        "GY",
        function()
          Snacks.picker.lsp_type_definitions()
        end,
        desc = "Goto T[y]pe Definition",
      },
      {
        "GAI",
        function()
          Snacks.picker.lsp_incoming_calls()
        end,
        desc = "C[a]lls Incoming",
      },
      {
        "GAO",
        function()
          Snacks.picker.lsp_outgoing_calls()
        end,
        desc = "C[a]lls Outgoing",
      },
      {
        "<leader>SS",
        function()
          Snacks.picker.lsp_symbols()
        end,
        desc = "LSP Symbols",
      },
      {
        "<leader>sS",
        function()
          Snacks.picker.lsp_workspace_symbols()
        end,
        desc = "LSP Workspace Symbols",
      },
    },

    -- ---@param _ any
    -- ---@param opts Plugins.Snacks.Setup
    -- config = function(_, opts)
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
    -- end,
  },
}
