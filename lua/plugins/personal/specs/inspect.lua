---@module 'plugins.personal.specs.inspect'
--- Debug & inspect -- personal plugin specs (Debugging, diffing, LSP, runtime analysis, code review and rule checking.)
---
--- Category names follow the plugin website's registry
--- (wkd/src/data/registry.json). Source control -- local vs. remote vs.
--- disabled -- is NOT decided here but in plugins.personal.core.source; this
--- file only declares the specs. Registered from plugins/personal/init.lua.

---@type LazyPluginSpec[]
return {
  -- Debugging is a mode you enter deliberately, so nothing here belongs in
  -- startup. On `event = "VeryLazy"` this cost 142-180ms (and once 328ms) on
  -- every launch, dependencies included, in sessions that never debugged
  -- anything. `keys`/`cmd` moves all of it to the first keypress: lazy.nvim
  -- installs stubs for both, so the mappings and `:Dap` behave exactly as
  -- before -- the first use just also loads the plugin.
  --
  -- The keys below MUST mirror wkddap.bindings.keymaps. `dap_prefix` is
  -- shared with opts so the two cannot drift apart; the suffixes are the ones
  -- that module maps (see its `map("n", prefix .. …)` calls). A binding
  -- missing here would simply never load the plugin and silently do nothing.
  (function()
    -- "<leader>d" alone collides with existing git/fzf mappings (dc = :Git
    -- ui diffview close, di = :Git hunk inline, do = FzfLua diagnostics --
    -- dc/di are gitsuite.nvim's since GS-08, not this config's own)
    local dap_prefix = "<leader>da"

    ---@type table[]
    local dap_keys = {}
    for _, m in ipairs({
      { "c", "Continue" },
      { "s", "Step Over" },
      { "i", "Step Into" },
      { "o", "Step Out" },
      { "t", "Terminate" },
      { "r", "Restart" },
      { "b", "Toggle Breakpoint" },
      { "B", "Conditional Breakpoint" },
      { "L", "Log Point" },
      { "l", "List Breakpoints" },
      { "u", "Toggle UI" },
      { "e", "Evaluate" },
      { "R", "Open REPL" },
    }) do
      dap_keys[#dap_keys + 1] = { dap_prefix .. m[1], desc = "[DAP] " .. m[2] }
    end
    -- `e` is mapped in visual mode too (evaluate the selection).
    dap_keys[#dap_keys + 1] = { dap_prefix .. "e", mode = "v", desc = "[DAP] Evaluate selection" }

    return {
      "StefanBartl/dap.nvim",
      cmd = "Dap",
      keys = dap_keys,
      dependencies = {
        "StefanBartl/lib.nvim",
        -- ui.kit backs breakpoint/validation prompts, moved out of
        -- lib.nvim.ui.kit in the 2026-09 migration.
        "StefanBartl/ui.nvim",
        "mfussenegger/nvim-dap",
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text",
        "jbyuki/one-small-step-for-vimkind",
        "igorlfs/nvim-dap-view", -- default panel UI (dap.nvim ui.provider = "dap-view")
      },
      opts = {
        keymaps = { prefix = dap_prefix },
        -- dap.nvim wires exactly one panel UI. nvim-dap-view is the default;
        -- switch to ui = { provider = "dap-ui" } to go back to nvim-dap-ui.
        ui = { provider = "dap-view" },
      },
      -- dap.nvim's own Lua module is "wkddap", not "dap" -- it depends on
      -- nvim-dap, which itself owns the top-level `dap` module (lua/dap.lua)
      -- and several submodule names (dap.ui, dap.utils) that would otherwise
      -- collide with this plugin's files if both used "dap" as their root.
      config = function(_, opts)
        require("wkddap").setup(opts)
      end,
    }
  end)(),

  {
    "StefanBartl/debugging.nvim",
    -- cmd = "Debug",
    event = "VeryLazy",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {}, -- features.neotree is off in the plugin's own defaults
  },

  {
    "StefanBartl/diff.nvim",
    cmd = { "Diff", "DiffClear", "DiffOrig", "DiffExit" },
    -- `<leader>gd` was fugitive's `:Gdiffsplit`; diff.nvim resolves
    -- `git:HEAD` for the current file itself, so the key moved here. A
    -- lazy `keys` entry rather than diff.nvim's own `keymaps.diff_head`
    -- option, because the plugin is command-lazy and an option-registered
    -- shortcut would only exist after the first `:Diff`.
    keys = {
      {
        "<leader>gd",
        "<cmd>Diff target=git:HEAD<cr>",
        desc = "[diff.nvim] Diff current file against HEAD",
      },
    },
    opts = {}, -- all three features are on by default
  },

  {
    -- The whole LSP subsystem (see docs/ROADMAP/personal/lsp.nvim.md).
    --
    -- No `opts`/`config` on purpose. init.lua calls setup() inside
    -- startup.now("lsp", ...) because capabilities have to be applied globally
    -- before the first client attaches; a lazy opts-block would hand that
    -- ordering to the plugin manager. `lazy = false` only guarantees the
    -- module is on the runtimepath by then.
    "StefanBartl/lsp.nvim",
    lazy = false,
    priority = 900,
    dependencies = { "StefanBartl/lib.nvim" },
  },

  {
    "StefanBartl/insights.nvim",
    -- Not `cmd = "Insights"`: the conflicts / unimported / devserver
    -- autocmds are registered by setup(), so lazy-loading on the command would
    -- mean they never fire. Set their `enable = false` to opt out instead.
    lazy = false,
    -- ui.nvim: devserver.prompt (default true) has no fallback if ui.kit is
    -- missing -- see insights.nvim's docs/installation.md.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    opts = {
      -- Building the cwd symbol index runs one rg pass per language pattern;
      -- reports into the shared lib.nvim.progress registry.
      symbols = { progress_style = "statusline" },
      -- The two keys todo-comments.nvim's spec used to bind, on the feature
      -- that replaced it (plugins/workflow.lua has the history): the picker
      -- on the lowercase key, the quickfix list on the uppercase one. The
      -- keyword table itself is insights' shipped default -- it was this
      -- config's table to begin with.
      keymaps = { todos = "<leader>sT", todos_qf = "<leader>ST" },
    },
  },

  {
    "StefanBartl/runtime-analysis.nvim",
    lazy = false,
    dependencies = { "StefanBartl/lib.nvim" },
    -- Telemetry auto-instrumentation (which of Stefan's plugins, with what
    -- settings) lives here, on this plugin's own spec, not a separate
    -- config file or a call before lazy.setup() -- see lua/config/
    -- telemetry.lua for the policy, runtime-analysis.telemetry.lazy for
    -- the mechanism this opts table drives.
    opts = function(_, opts)
      opts.telemetry = require("config.telemetry").build()
      return opts
    end,
  },

  {
    "StefanBartl/recommender.nvim",
    ft = { "lua" },
    cmd = { "Recommender" },
    -- ui.nvim: bindings/usrcmds.lua requires ui.kit at module load (the
    -- suggestion float's picker) -- setup() fails without it, no fallback.
    -- Already loaded lazy=false above, listed here for documentation.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    opts = {
      -- `cwd`/`path` scope (the one `:Recommender perf cwd` over this whole
      -- config actually uses) runs the directory walk + file reads
      -- asynchronously since 2026-09-03; reports into the shared
      -- lib.nvim.progress registry, rendered by the statusline's
      -- "plugin_progress" module -- same convention as sandbox.nvim,
      -- documentation.nvim, replacer.nvim, insights.nvim, reposcope.nvim,
      -- github_stats.nvim, pdfport.nvim above.
      progress_style = "statusline",
    },
  },

  {
    "StefanBartl/spotlight.nvim",
    -- ui.nvim: the spotlight list itself is built on ui.kit.select with no
    -- fallback -- see spotlight.nvim's docs/installation.md.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    event = "VeryLazy",
    opts = {},
  },

  {
    -- Eager on purpose, and `cmd = { "Cmdlog" }` is gone rather than kept
    -- alongside `lazy = false` (where lazy.nvim ignores it anyway, so it only
    -- read as if this were command-lazy). setup() starts the CmdlineLeave
    -- tracker that records every `:` command -- that recording *is* the
    -- plugin. Loading on `:Cmdlog` would start the tracker at the moment you
    -- first ask for the history, so the history would always be empty.
    -- Opt out with `track_commands = false`.
    "StefanBartl/cmdlog.nvim",
    lazy = false,
    opts = {}, -- picker already defaults to telescope
  },

  {
    "StefanBartl/rules.nvim",
    cmd = { "Rules" },
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- Whole Checklists tree, not just regeln/: the loader only picks up
      -- fenced ```rule blocks, so files still in the legacy table format are
      -- silently skipped rather than needing a narrower path per migrated
      -- family. All fourteen families are migrated (421 rules total):
      -- DEP-*/TS-*/SEC-*/CMT-*/ERR-*/UI-*/LUA-*/XP-*/LLS-* in
      -- regeln/LUA_NVIM.md, PRIN-*/PERF-* in their own regeln/*.md,
      -- NEW-*/REL-* (full 50/34, not just a pilot subset) in
      -- gates/{NEW_PROJECT,RELEASE}.md.
      rulesets = { vim.env.REPOS_DIR .. "/WKDBooks/Development/wkdbook-Lua/Checklists" },
      -- Gate-to-family mapping is config, not a rules.nvim opinion -- see
      -- docs/BINDINGS.md in the plugin repo. `review` mirrors exactly the
      -- families REVIEW.md's own Schnell-Check cites -- run the whole
      -- family per gate, not just the specific rows REVIEW.md quotes.
      gates = {
        new_project = { "NEW" },
        release = { "REL" },
        review = { "ERR", "LUA", "UI", "CMT", "SEC", "PRIN", "PERF" },
      },
    },
  },
}
