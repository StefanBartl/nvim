---@module 'plugins.personal.specs.project'
--- Project & repos -- personal plugin specs (Repository tooling, project documentation, sandboxes, stats and case work.)
---
--- Category names follow the plugin website's registry
--- (wkd/src/data/registry.json). Source control -- local vs. remote vs.
--- disabled -- is NOT decided here but in plugins.personal.core.source; this
--- file only declares the specs. Registered from plugins/personal/init.lua.

local machine = require("machine")

---@type LazyPluginSpec[]
return {
  {
    "StefanBartl/sandbox.nvim",
    event = "VeryLazy",
    -- ui.contextmenu/ui.kit (right-click menu, kit.input() prompts) moved
    -- out of lib.nvim.ui.kit/lib.nvim.contextmenu in the 2026-09 migration.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    opts = {
      -- `image pull`/`push` and the devcontainer build report into the shared
      -- lib.nvim.progress registry, rendered by the statusline's
      -- "plugin_progress" module.
      progress_style = "statusline",
    },
  },

  {
    "StefanBartl/github_stats.nvim",
    event = "VimEnter",
    -- ui.nvim: init.lua's own require("github_stats.dashboard") pulls in
    -- ui.contextmenu at module load, before setup() runs. Already loaded
    -- lazy=false above, listed here for documentation.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    config = function()
      require("github_stats").setup({
        -- Explicit allowlist instead of watch_users auto-discovery: discovery
        -- pulled in every public repo (~40), and fetch_all spawns one curl
        -- process per repo per metric (4 metrics) in a tight synchronous
        -- loop. On machines where process creation is slow (AV/EDR scanning
        -- each spawn), that many near-simultaneous spawns froze the UI for
        -- 45-90s. Capping the repo list keeps the spawn count small.
        repos = {
          "StefanBartl/buffer-ctx.nvim",
          "StefanBartl/cascade.nvim",
          "StefanBartl/color_my_ascii.nvim",
          "StefanBartl/debugging.nvim",
          "StefanBartl/diff.nvim",
          "StefanBartl/documentation.nvim",
          "StefanBartl/emojis.nvim",
          "StefanBartl/fileops.nvim",
          "StefanBartl/filetree.nvim",
          "StefanBartl/github_stats.nvim",
          "StefanBartl/gopath.nvim",
          "StefanBartl/hover.nvim",
          "StefanBartl/language.nvim",
          "StefanBartl/lib.nvim",
          "StefanBartl/lsp.nvim",
          "StefanBartl/markdown.nvim",
          "StefanBartl/mdview.nvim",
          "StefanBartl/cmdlog.nvim",
          "StefanBartl/sandbox.nvim",
          "StefanBartl/open.nvim",
          "StefanBartl/pdfport.nvim",
          "StefanBartl/pickers.nvim",
          "StefanBartl/insights.nvim",
          "StefanBartl/recommender.nvim",
          "StefanBartl/replacer.nvim",
          "StefanBartl/reposcope.nvim",
        },
        token_source = "env",
        token_env_var = "GITHUB_TOKEN",
        fetch_interval_hours = 24,
        notification_level = "all",
        -- Manual fetches only (`:GithubStatsFetch`, dashboard refresh keys) —
        -- the background cycle deliberately never shows an indicator.
        progress_style = "statusline",
        -- "workstation" only reads the already-committed data/ snapshots
        -- (dashboard, :GithubStatsShow, ... all read from disk regardless);
        -- it just never runs the fetch cycle itself.
        background = { enabled = not machine.is("workstation") },
      })
    end,
  },

  {
    "StefanBartl/reposcope.nvim",
    name = "reposcope",
    event = "VeryLazy",
    -- ui.kit backs the filter/sort prompts and favorites/help/status views,
    -- required from init.lua's own top level (moved out of
    -- lib.nvim.ui.kit in the 2026-09 migration).
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    -- The multi-repo git dashboard (and its `progress_style`/`dashboard.*`
    -- options) moved to gitsuite.nvim's `:Git dashboard` -- see that spec's
    -- `opts` below. reposcope stays scoped to search/filter/clone.
  },

  {
    "StefanBartl/documentation.nvim",
    cmd = { "DocMap", "DocBrowse", "DocMapAll", "DocMapAllFull" },
    dependencies = { "StefanBartl/lib.nvim" },
    -- No `root`: the commands deliberately map the current working directory,
    -- because rows of repos sit side by side here and a fixed target would be
    -- exactly wrong. `source` derives documentation.config from the root
    -- (lua/<name>, when lua/ contains exactly one candidate).
    opts = function(_, opts)
      opts.progress_style = "statusline"
      -- Experimental: a "Compiler Explorer" link next to every
      -- module/function in the generated page, real luac -l -l -p bytecode
      -- disassembly, not a workaround for Lua. Off by default upstream;
      -- turned on here explicitly per request.
      opts.godbolt = true

      -- `:DocMap bindings` (2026-08-15): declare THIS config's own keymap/
      -- usercmd/autocmd helpers so they are extracted too. The `vim.*` APIs
      -- need no declaration; these five do, and without them `:DocMap
      -- bindings` finds ~10 registrations here instead of ~300.
      --
      -- Why the plugin cannot just guess these: a bare `map(...)` is also
      -- the most natural name for a list-mapping helper, so guessing would
      -- silently report `vim.tbl_map` calls as keymaps. The caller knows its
      -- own helper names and the scanner cannot — see core/bindings.lua.
      --
      -- All five are real shapes in this tree: `map` is
      -- `lib.nvim.bindings.keymap` (same argument order as vim.keymap.set,
      -- which is why it can reuse that layout), `usercmd.create` and
      -- `autocmd.create` are lib.nvim's, and
      -- the two bare names are `local nvim_create_autocmd =
      -- api.nvim_create_autocmd`-style aliases (autocmds/terminals/init.lua).
      -- `composer.verb` is deliberately absent: it registers a whole verb
      -- tree rather than one command, so its first argument is not a command
      -- name and no built-in layout describes it.
      opts.bindings = {
        wrappers = {
          ["map"] = "keymap",
          ["usercmd.create"] = "usercmd",
          ["autocmd.create"] = "autocmd",
          ["nvim_create_autocmd"] = "autocmd",
          ["nvim_create_user_command"] = "usercmd",
        },
      }

      -- `:DocMap all` / `:DocMapAll` (2026-08-14): documentation.nvim owns
      -- the command, this config supplies only the data -- the same split
      -- runtime-analysis.nvim's own `opts.telemetry` already draws one
      -- entry below. `plugins.personal.core.export.projects()` is the same
      -- resolved entry list `config.telemetry.build()` reads, so nothing
      -- here has to be kept in sync with `plugins/personal/init.lua` by
      -- hand -- add a plugin to the spec below and both wirings pick it up.
      local export = require("plugins.personal.core.export")
      local projects = export.projects()
      local gen_projects = {}
      for _, p in ipairs(projects) do
        gen_projects[#gen_projects + 1] = { root = p.dir, title = p.name }
      end
      -- This config itself (2026-08-15) -- not a `plugins.personal` entry
      -- (it is the config, not an installed plugin `export.projects()` could
      -- ever resolve), so it is appended here by hand rather than made
      -- `export.projects()`'s problem: `:MyPlugins`/the statusline badge
      -- read that same list for "which plugins are installed", a question
      -- this config is not an answer to. `vim.fn.stdpath("config")` is the
      -- one thing here that is always right regardless of machine --
      -- already has `docs/map/` from a prior manual `:DocMap`, so this is
      -- "join the All sweep", not a first-time map.
      gen_projects[#gen_projects + 1] = { root = vim.fn.stdpath("config"), title = "nvim-config" }
      if #gen_projects > 0 then
        opts.generate_all = {
          projects = gen_projects,
          -- Listing a plugin in the spec below is already the active signal
          -- that its data is wanted, so autoload is deliberately on here.
          autoload = true,
        }
      end

      return opts
    end,
  },

  {
    -- One :Git <scope> <action> command tree. Replaces vim-fugitive (blame),
    -- vim-rhubarb (:Gbrowse), akinsho/git-conflict.nvim (:GitConflict* +
    -- co/ct/cb/c0/]x/[x) and kdheepak/lazygit.nvim (the float + the nvr O/
    -- <C-o> bridge) -- all four removed from plugins/git.lua. fugitive
    -- defines its own :Git command (a hard collision, not just redundancy);
    -- git-conflict.nvim would race gitsuite.nvim to set the same
    -- buffer-local keys; lazygit.nvim's wrapper is fully superseded by
    -- gitsuite's own float around the real `lazygit` binary.
    "StefanBartl/gitsuite.nvim",
    cmd = "Git",
    -- Conflict markers live in a buffer's text, so there is nothing to
    -- detect before one is read -- same eager-ish trigger git-conflict.nvim
    -- used, needed here too since gitsuite.nvim's conflict scan/highlight/
    -- keymap setup must not wait for the user to type :Git first.
    event = { "BufReadPost", "BufNewFile" },
    -- open.nvim deliberately NOT listed here: gitsuite.nvim's own browse
    -- feature already treats it as a genuinely optional, pcall-guarded
    -- adapter (features/browse/init.lua) -- a hard `dependencies` entry
    -- would force it to load eagerly on every buffer read (this spec's own
    -- `event` trigger) for a feature (:Git browse *) most sessions never
    -- touch. diff.nvim STAYS: lazy.nvim has no "load on require()" trigger
    -- (only cmd/event/ft/keys), and gitsuite's diff feature calls
    -- require("diff") directly -- without this entry, :Git diff * would
    -- error on a session where the user never separately triggered one of
    -- diff.nvim's own commands first. Found and fixed 2026-09-21.
    -- ui.nvim: the multi-repo `:Git dashboard` (moved from reposcope.nvim)
    -- uses `ui.kit` for its popup/confirm dialogs, same as reposcope's own
    -- prompt/filter UI did.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/diff.nvim", "StefanBartl/ui.nvim" },
    keys = {
      -- Was fugitive's `:Git blame`; gitsuite's own blame is a real
      -- implementation (native git blame --porcelain), not a stub.
      { "<leader>gb", "<cmd>Git blame full<cr>", desc = "[gitsuite.nvim] Blame (full)" },
      -- Was kdheepak/lazygit.nvim's `:LazyGit`; the UI is still the real
      -- lazygit TUI, just in gitsuite.nvim's own float now.
      { "<leader>lg", "<cmd>Git ui lazygit<cr>", desc = "[gitsuite.nvim] Open lazygit" },
    },
    opts = {
      -- `:Git dashboard`/`:Git dashboard update` walk a whole directory of
      -- clones; both report into the shared lib.nvim.progress registry.
      -- Moved from reposcope.nvim's own `progress_style` along with the
      -- dashboard itself.
      --
      -- "kit", not "statusline": the first `:Git dashboard` of a session
      -- reads 60+ clones (several seconds on Windows) and only then opens its
      -- float, and the statusline text is easy to miss meanwhile. That gap
      -- is presumably how a stray <CR> in the tree once landed on neo-tree's
      -- window picker right as the dashboard opened underneath it (not
      -- confirmed via last_call() or another diagnostic at the time -- ui.nvim
      -- windowpicker's own focus-cancel fix, 2db4c0a/79da6d4, addresses this
      -- exact race independently of which style shows the scan). "kit" is a
      -- themed corner float with an (n/total) counter that never takes focus.
      progress_style = "kit",
      dashboard = {
        -- This config is a git repo of its own but lives outside
        -- `$REPOS_DIR`, so the dashboard's normal scan never finds it --
        -- listing it here surfaces it alongside every other plugin
        -- checkout instead of it being invisible to `:MyPlugins
        -- dashboard`/`:Git dashboard` entirely.
        extra_paths = { vim.fn.stdpath("config") },
      },
    },
    config = function(_, opts)
      require("gitsuite").setup(opts)
    end,
  },

  {
    -- casedesk: the `:Case` / `:Cases` / `:Tricentis` command tree for
    -- SAP-Support case work, extracted from this config's former
    -- lua/bindings/usrcmds/case/** (docs/ROADMAP/casedesk/PLUGIN.md); that
    -- copy was deleted on 2026-09-25.
    --
    -- Eager on purpose. setup() registers the command tree AND starts the SLA
    -- watcher (sla/notify.lua: a background timer plus a FocusGained hook that
    -- re-checks P1/P2 deadlines). A `cmd = "Case"` trigger would hand back the
    -- commands but stay silent about deadlines until the first :Case of the
    -- session -- the wrong way round for a feature whose entire point is
    -- telling you about a clock you forgot. The statusline segment
    -- (config/ui_statusline/variant.lua, ui.nvim's casedesk module) reads
    -- casedesk.resolve on redraw and wants it loaded too.
    --
    -- `opts = {}` and not a single override: every path already derives from
    -- $REPOS_DIR inside config/DEFAULTS.lua, so this machine has nothing to
    -- correct. Overrides belong here the day a machine disagrees about where
    -- WKDBook-Tricentis lives -- see the plugin's docs/configuration.md.
    "StefanBartl/casedesk.nvim",
    lazy = false,
    -- ui.nvim: casedesk.ui requires ui.kit at module load -- setup() fails
    -- without it, no fallback. Already loaded lazy=false above, listed here
    -- for documentation.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    opts = {},
  },

  -- {
  -- "StefanBartl/learn-cli.nvim",
  -- lazy = false,
  -- config = function()
  -- require("learn_cli").setup({
  -- -- The plugin's own config key is exercises_path (see
  -- -- lua/learn_cli/config/init.lua); exercises_dir was silently
  -- -- ignored and the plugin fell back to its stdpath("config")/exercises
  -- -- default.
  -- exercises_path = vim.fs.joinpath(
  -- vim.fn.stdpath("config"),
  -- "lua",
  -- "plugins",
  -- "learn-cli.nvim",
  -- "exercises"
  -- ),
  -- })
  -- end,
  -- },
}
