---@module 'plugins.personal.specs.project'
--- Personal plugin specs: Project & repos.
---
--- Repository tooling, project documentation, sandboxes, stats and case work.
---
--- Category names follow the plugin website's registry
--- (wkd/src/data/registry.json). Source control -- local vs. remote vs.
--- disabled -- is NOT decided here but in plugins.personal.core.source; this
--- file only declares the specs. Registered from plugins/personal/init.lua.

local machine = require("machine")

--- The compose file names sandbox.nvim knows (its `util.compose_file`) plus the
--- usual variants (`docker-compose.override.yml`, `compose.prod.yaml`), as
--- autocmd patterns. They are matched by name because Neovim gives them the
--- plain filetype `yaml` -- there is no `yaml.docker-compose`.
local COMPOSE_FILES =
  { "compose.y*ml", "compose.*.y*ml", "docker-compose*.y*ml", "podman-compose*.y*ml" }

---@return string[]
local function compose_file_events()
  local events = {}
  for _, pattern in ipairs(COMPOSE_FILES) do
    events[#events + 1] = "BufReadPost " .. pattern
    events[#events + 1] = "BufNewFile " .. pattern
  end
  return events
end

---@type LazyPluginSpec[]
return {
  {
    "StefanBartl/sandbox.nvim",
    -- Its own triggers instead of VeryLazy, where it cost every start ~110 ms
    -- (six engine adapters, a PATH search per engine) for a plugin that
    -- registers no global key or autocmd: outside its own buffers it is the
    -- `:Sandbox` / `:Sbx` commands and a hover.nvim preview for image
    -- references, and those live in Dockerfiles and compose files.
    -- `yaml` is deliberately not a filetype trigger: it would load the plugin
    -- (~110 ms, plus a second FileType round for every plugin) on the first CI
    -- config or k8s manifest, where the plugin has nothing to offer.
    -- Trade-off: the preview itself is not filetype-bound, so an image
    -- reference elsewhere (k8s or workflow YAML, devcontainer.json, a shell
    -- script, Markdown) gets it only once one of these triggers has loaded the
    -- plugin. `devcontainer.json`, `*.containerfile` and `docker-bake.hcl` are
    -- deliberately no triggers either (~110 ms on the first hit each session).
    -- Likewise `:checkhealth sandbox` finds nothing until it is
    -- loaded: run `:Sandbox engine get` first.
    cmd = { "Sandbox", "Sbx" },
    ft = "dockerfile",
    event = compose_file_events(),
    -- ui.nvim: ui.contextmenu (right-click menu) and ui.kit (kit.input() prompts).
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    opts = {
      -- Container engine: "podman" | "docker" | "nerdctl". nil detects the first
      -- one on PATH that answers; naming one here skips detection entirely.
      -- engine = nil, -- Sandbox.Engine

      -- Ask before remove/prune/kill; false acts immediately.
      -- confirm_destructive = true,
      -- Shell `container exec` uses when none is given.
      -- default_shell = "sh",
      -- Milliseconds between automatic refreshes of a visible list view; nil/0 disables.
      -- refresh_interval = nil, -- integer
      -- Window placement of list views: "above" | "below" | "left" | "right".
      -- list_split = "left",
      -- Width (left/right) or height (above/below) of a list split; nil uses Neovim's sizing.
      -- list_size = nil, -- integer

      -- Indicator while pull/push/build/compose/prune run: "auto" | "notify" |
      -- "statusline" | "fidget" | "float" | "kit". `image pull`/`push` and the
      -- devcontainer build report into the shared lib.nvim.progress registry;
      -- "statusline" draws nothing itself and lets the statusline's
      -- "plugin_progress" module render it.
      -- Default: "auto" (fidget.nvim when installed, else vim.notify).
      progress_style = "statusline",

      -- Register an on-request hover.nvim preview for image references in a
      -- Dockerfile or compose file. No-op without hover.nvim.
      -- hover = true,
      -- How much of an unrecognized adapter error reaches the notification; the
      -- full text always goes to sandbox.logger.
      -- max_error_length = 200,
      -- How long a statusline reading / a completion listing stays cached, in ms.
      -- status_cache_ttl_ms = 3000,
      -- completion_cache_ttl_ms = 4000,

      -- List-view keymap overrides: `false` binds none; otherwise a table per
      -- list kind (list, containers, images, volumes, networks, each with a
      -- `*_visual` twin for bulk actions, plus inspect and logs) of
      -- `action = lhs | lhs[] | false`. Every key keeps its default unless named.
      -- keymaps = nil, -- table|false

      -- menu = {
      --   -- Right-click context menu on list-view buffers (nvzone/menu, soft
      --   -- dependency; off automatically when it is not installed).
      --   enable = true,
      -- },
    },
  },

  {
    "StefanBartl/github_stats.nvim",
    event = "VimEnter",
    -- ui.nvim: init.lua's own require("github_stats.dashboard") pulls in
    -- ui.contextmenu at module load, before setup() runs. ui.nvim is already
    -- loaded eagerly; the entry documents the dependency.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    config = function()
      require("github_stats").setup({
        -- Notify at startup whether a fetch was performed or not.
        -- notify_fetch = true,
        -- Repositories tracked individually ("owner/repo"); the list replaces
        -- the default one (a short list of the author's repositories).
        -- An explicit list instead of `watch_users` auto-discovery, because every
        -- repo costs one curl process per metric (4 metrics), spawned in a tight
        -- synchronous loop: the list length bounds the spawn burst on machines
        -- where process creation is slow (AV/EDR scanning each spawn).
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
        -- Where the GitHub token comes from: "env" | "file". Equals the default,
        -- set explicitly so the choice is visible here.
        token_source = "env",
        -- Environment variable read when token_source = "env". Equals the
        -- default, set explicitly.
        token_env_var = "GITHUB_TOKEN",
        -- Path to a token file, read when token_source = "file".
        -- token_file = nil, -- string
        -- Timeout for one GitHub API request, in ms.
        -- api_timeout_ms = 15000,
        -- Byte cap for one API response, enforced via curl --max-filesize (5 MiB).
        -- api_max_response_bytes = 5242880,
        -- Hours between fetch cycles. Equals the default, set explicitly.
        fetch_interval_hours = 24,
        -- Pages followed when listing a watched user's repos (100 per page); past
        -- the cap, later repos are silently not tracked.
        -- max_user_repo_pages = 30,
        -- "all" | "errors" | "silent". Equals the default, set explicitly.
        notification_level = "all",
        -- Indicator for manual fetches only (`:GithubStatsFetch`, dashboard
        -- refresh keys): "auto" | "notify" | "statusline" | "fidget" | "float" |
        -- "kit". The background cycle deliberately never shows one.
        -- Default: "auto".
        progress_style = "statusline",
        -- Custom config directory.
        -- config_dir = nil, -- string; default stdpath("config")/lua/plugins/github-stats
        -- Custom data directory.
        -- data_dir = nil, -- string; default <config_dir>/data
        -- Where the per-repository digest for other programs is written. Local to
        -- one machine on purpose, hence a setup() option and not part of the
        -- synced config.json.
        -- digest_dir = nil, -- string; default stdpath("data")/github_stats.nvim
        -- Days of daily values a digest keeps.
        -- digest_daily_days = 400,
        -- GitHub usernames whose public repositories are auto-discovered and
        -- tracked in addition to `repos`.
        -- watch_users = {},

        background = {
          -- Master switch of the silent background fetch cycle. "workstation"
          -- only reads the already-committed data/ snapshots (the dashboard,
          -- :GithubStatsShow, ... read from disk regardless); it just never runs
          -- the fetch cycle itself. Default: true.
          enabled = not machine.is("workstation"),
          -- Delay before the first cycle, in ms; keeps the fetch out of startup.
          -- initial_delay_ms = 1000,
        },

        -- Retention: archive/prune old metric files after a fetch.
        -- retention = {
        --   enabled = true,
        --   -- clones/views: age in days after which a day's value is folded into the archive.
        --   cutoff_days = 15,
        --   -- referrers/paths: snapshots older than this are deleted (the newest is kept).
        --   prune_days = 15,
        -- },

        -- Date range presets for the dashboard/commands.
        -- date_presets = {
        --   enabled = true,
        --   -- Enabled built-in presets; the list replaces the default one.
        --   builtins = {
        --     "today",
        --     "yesterday",
        --     "last_week",
        --     "last_month",
        --     "last_quarter",
        --     "last_year",
        --     "this_week",
        --     "this_month",
        --     "this_quarter",
        --     "this_year",
        --   },
        --   -- Custom presets: name -> fun(): string, string (from, to).
        --   custom = {},
        -- },

        -- dashboard = {
        --   enabled = true,
        --   -- Open the dashboard automatically on VimEnter.
        --   auto_open = false,
        --   refresh_interval_seconds = 300,
        --   -- "clones" | "views" | "name" | "trend".
        --   sort_by = "clones",
        --   -- "7d" | "30d" | "90d" | "max" | "all" or any expression accepted by
        --   -- github_stats.analytics.parse_time_range.
        --   time_range = "30d",
        --   -- Trend compares the last N complete days against the N before them,
        --   -- whatever range is displayed.
        --   trend_window_days = 7,
        --   -- Width between the header box's borders, and of a row's daily sparkline.
        --   header_width = 72,
        --   sparkline_width = 24,
        --   -- Minimum time between dashboard renders, in ms.
        --   render_debounce_ms = 50,
        --   -- "default" | "minimal" | "compact" (reserved for future use).
        --   theme = "default",
        --   -- Right-click context menu (nvzone/menu, soft dependency).
        --   menu = {
        --     enable = true,
        --   },
        --   keybindings = {
        --     navigate_down = "j",
        --     navigate_up = "k",
        --     show_details = "<CR>",
        --     refresh_selected = "r",
        --     refresh_all = "R",
        --     force_refresh = "f",
        --     cycle_sort = "s",
        --     cycle_time_range = "t",
        --     custom_time_range = "T",
        --     max_time_range = "m",
        --     show_help = "?",
        --     quit = "q",
        --   },
        -- },
      })
    end,
  },

  {
    "StefanBartl/reposcope.nvim",
    name = "reposcope",
    -- Loaded on first use, not in the VeryLazy wave: require("reposcope") pulls
    -- in ~180 modules and setup() runs on top, 60-110 ms of blocking work in
    -- every session for a plugin used through one command and two keys. The
    -- stubs lazy.nvim creates for `cmd`/`keys` load the plugin on first use and
    -- are then replaced by the plugin's own :Reposcope and keymaps.
    -- Caveat: the hover.nvim source for `owner/repo` (registered in setup())
    -- only exists once reposcope was used in the session; set `hover = false`
    -- in opts if that distinction is unwanted.
    cmd = "Reposcope",
    keys = {
      { "<leader>rs", desc = "Reposcope: open the UI" },
      { "<leader>rc", desc = "Reposcope: close the UI" },
    },
    -- ui.kit backs the filter/sort prompts and the favorites/help/status views,
    -- required from init.lua's own top level.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    -- `opts` must exist (even empty): it makes lazy.nvim call
    -- require("reposcope").setup(opts) on load, and without that call neither
    -- the plugin's own <leader>rs / <leader>rc keymaps (set in setup()) nor
    -- its hover source ever exist. (The multi-repo dashboard lives in
    -- gitsuite.nvim's `:Git dashboard`; reposcope stays scoped to
    -- search/filter/clone.)
    opts = {},
    --
    -- OPTION REFERENCE (comment only, nothing here is executed). Copy entries
    -- into `opts` above to change them.
    --
    -- {
    --   -- Fields shown in the prompt: "prefix" | "keywords" | "owner" | "language" | "topic" | "stars".
    --   prompt_fields = { "prefix", "keywords", "owner", "language" },
    --   -- Search backend: "github" | "gitlab" | "codeberg".
    --   provider = "github",
    --   -- Fallback order tried when `request_tool` is unavailable.
    --   preferred_requesters = { "gh", "curl", "wget" },
    --   -- Tool for API requests: "gh" | "curl" | "wget" ("gh" needs provider = "github" and an explicit token).
    --   request_tool = "gh",
    --   -- Tokens raise the API rate limit; the defaults are read from
    --   -- $GITHUB_TOKEN / $GITLAB_TOKEN / $CODEBERG_TOKEN (else "").
    --   github_token = "",
    --   gitlab_token = "",
    --   codeberg_token = "",
    --   -- Maximum search results per query.
    --   results_limit = 25,
    --   -- UI layout; only "default" exists.
    --   layout = "default",
    --   clone = {
    --     -- Directory a selected repository is cloned into; default $REPOS_DIR, else "~/temp".
    --     std_dir = "~/temp",
    --     -- Clone tool: "" (= git) | "git" | "gh" | "curl" | "wget" (curl/wget pull a .zip).
    --     type = "",
    --   },
    --   -- Register a hover.nvim source: `owner/repo` under the cursor previews
    --   -- the cached README. No-op without hover.nvim.
    --   hover = true,
    --   -- Global keymaps; `false` or "" disables one.
    --   keymaps = {
    --     open = "<leader>rs",
    --     close = "<leader>rc",
    --   },
    --   -- Options passed to the two global keymaps above.
    --   keymap_opts = {
    --     silent = true,
    --     noremap = true,
    --   },
    --   -- Prompt-buffer keymaps; `false` or "" disables an action, a list maps several keys.
    --   prompt_keymaps = {
    --     confirm = "<CR>",
    --     nav_up = "<Up>",
    --     nav_down = "<Down>",
    --     focus_next = { "<C-w>", "<C-l>", "<Tab>" },
    --     focus_prev = { "<C-h>", "<S-Tab>" },
    --     open_viewer = "<C-v>",
    --     open_editor = "<C-b>",
    --     clone = "<C-c>",
    --     backspace = "<BS>",
    --     preview_scroll_down = "<C-d>",
    --     preview_scroll_up = "<C-u>",
    --     -- Draw the README's image over the preview; needs images.nvim with `display.remote.enabled = true`.
    --     preview_image = "<C-p>",
    --     -- Keymap cheatsheet (normal mode only).
    --     help = "?",
    --     toggle_favorite = "<C-f>",
    --   },
    --   -- Symbol in the `prefix` field; needs a Nerd Font, e.g. "> " for plain terminals.
    --   prompt_prefix_symbol = " \u{f002} ",
    --   -- Request timing and logging, for debugging only.
    --   metrics = false,
    --   -- Cap on the request log, in entries.
    --   log_max = 1000,
    --   -- Also record popup notifications in `:messages`; false for noice-like UIs.
    --   notify_messages = true,
    --   -- After a search, pre-cache the READMEs of this many top results (0 disables).
    --   readme_precache_count = 5,
    -- }
  },

  {
    "StefanBartl/documentation.nvim",
    cmd = { "DocMap", "DocBrowse", "DocMapAll", "DocMapAllFull" },
    dependencies = { "StefanBartl/lib.nvim" },
    -- No `root`: the commands resolve the repository per invocation from the
    -- current buffer (see `root_markers`), because rows of repos sit side by
    -- side here and a fixed target would be exactly wrong. `source` derives
    -- documentation.config from the root (lua/<name>, when lua/ contains
    -- exactly one candidate).
    opts = function(_, opts)
      -- Indicator while a long `:DocMap` runs (`full`'s LuaLS pass, `churn`'s
      -- history walk): "auto" | "notify" | "statusline" | "fidget" | "float" |
      -- "kit". "statusline" publishes the text for the statusline instead of
      -- opening a UI. Default: "auto".
      opts.progress_style = "statusline"
      -- Experimental: a "Compiler Explorer" link next to every module/function in
      -- the generated page, opening a real `luac -l -l -p` bytecode disassembly
      -- of that entity's source. Default: false.
      opts.godbolt = true

      -- Declares THIS config's own keymap/usercmd/autocmd helpers so
      -- `:DocMap bindings` extracts them too. The `vim.*` APIs need no
      -- declaration; these five do, and without them `:DocMap bindings` finds
      -- only a handful of registrations here.
      --
      -- The plugin cannot guess them: a bare `map(...)` is also the most natural
      -- name for a list-mapping helper, so guessing would report `vim.tbl_map`
      -- calls as keymaps. The caller knows its own helper names.
      --
      -- `map` is `lib.nvim.bindings.keymap` (same argument order as
      -- vim.keymap.set, which is why it can reuse that layout), `usercmd.create`
      -- and `autocmd.create` are lib.nvim's, and the two bare names are
      -- `local nvim_create_autocmd = api.nvim_create_autocmd`-style aliases
      -- (autocmds/terminals/init.lua). `composer.verb` is deliberately absent:
      -- it registers a whole verb tree rather than one command, so its first
      -- argument is not a command name and no built-in layout describes it.
      -- Default: no wrappers.
      opts.bindings = {
        wrappers = {
          ["map"] = "keymap",
          ["usercmd.create"] = "usercmd",
          ["autocmd.create"] = "autocmd",
          ["nvim_create_autocmd"] = "autocmd",
          ["nvim_create_user_command"] = "usercmd",
        },
      }

      -- `:DocMap all` / `:DocMapAll`: documentation.nvim owns the command, this
      -- config supplies only the data. `plugins.personal.core.export.projects()`
      -- is the same resolved entry list `config.telemetry.build()` reads, so
      -- nothing here has to be kept in sync with `plugins/personal/init.lua` by
      -- hand: add a plugin to the spec and both wirings pick it up.
      local export = require("plugins.personal.core.export")
      local projects = export.projects()
      local gen_projects = {}
      for _, p in ipairs(projects) do
        gen_projects[#gen_projects + 1] = { root = p.dir, title = p.name }
      end
      -- This config itself is appended by hand: it is not an installed plugin
      -- `export.projects()` could resolve, and `:MyPlugins`/the statusline badge
      -- read that same list for "which plugins are installed", a question this
      -- config is not an answer to. `vim.fn.stdpath("config")` is always right
      -- regardless of machine.
      gen_projects[#gen_projects + 1] = { root = vim.fn.stdpath("config"), title = "nvim-config" }
      if #gen_projects > 0 then
        opts.generate_all = {
          projects = gen_projects,
          -- Check each project for an already-written docs/map/module_map.json
          -- and generate (async) only the missing ones, once at setup() time.
          -- Listing a plugin in the spec is already the active signal that its
          -- data is wanted, so autoload is deliberately on here.
          -- Default: false (writing into other repositories' docs/map on every
          -- start is an uninvited side effect).
          autoload = true,
        }
      end

      -- Remaining options, defaults shown (assign as `opts.<name> = <value>`):
      --
      -- Directory the Lua module path is relative to.
      -- lua_root = "lua",
      -- Directory name holding type definitions, treated as a module attribute.
      -- types_dir = "@types",
      -- Output directory, relative to the root.
      -- out_dir = "docs/map",
      -- Directory (relative to the root) scanned for auto-derived test coverage.
      -- tests_dir = "TESTS",
      -- Name of the map command and of the editor-side map browser.
      -- command_name = "DocMap",
      -- browse_command_name = "DocBrowse",
      -- Register a hover.nvim source explaining the module under the cursor from
      -- the generated map. No-op without hover.nvim.
      -- hover = true,
      -- Ceiling for a `git log` over the full history (`churn`, the checklist's
      -- history pass, the MCP tool), in ms.
      -- git_log_timeout_ms = 120000,
      -- How long a telemetry read stays cached, in ms.
      -- telemetry_ttl_ms = 2000,
      --
      -- Repository root. nil resolves it per invocation from the current buffer.
      -- root = nil, -- string
      -- Marker names `vim.fs.root` walks up for when `root` is absent.
      -- root_markers = { ".git" },
      -- Directory of sibling checkouts whose committed maps name this project as
      -- a dependency; enables `consumer-require-missing` only.
      -- consumers = nil, -- string
      -- Directory (or directories) to scan, relative to the root. nil derives it
      -- (lua/<name> when lua/ holds exactly one candidate).
      -- source = nil, -- string|string[]
      -- Repository-relative paths the walk neither descends into nor reads.
      -- exclude = {},
      -- Backend names ("lua", "go", "tsx", ...) a scan may use; nil or {} = all.
      -- languages = nil, -- string[]
      -- Display name of the root node. nil = the root directory's name.
      -- title = nil, -- string
      -- Base URL for source links. nil derives it from the "origin" remote.
      -- repo_url = nil, -- string
      -- Branch used in source links. nil derives it from the current branch, else "main".
      -- branch = nil, -- string
      -- Repo-specific drift checks appended to the generic ones (functions).
      -- extra_checks = {},
      -- Also emit call edges guessed by unique-name match (drawn dashed).
      -- calls_heuristic = false,
      -- Also resolve documentation references written as a bare tree-unique function name.
      -- docs_heuristic = false,
      -- Also report published functions without a caller as dead-code candidates.
      -- dead_code = false,
      -- Layering rules for `layer-violation`: { from = "a.b", to = "c.d", why? = "..." }
      -- (module prefixes). Empty disables the check.
      -- layers = {},
      -- Merge `lua-language-server --doc` output into the map (costs seconds).
      -- luals = false,
      -- Kill the LuaLS run after this long, in ms.
      -- luals_timeout_ms = 60000,
      -- Longest stored context around a documentation mention, in bytes.
      -- context_max = 120,
      -- References kept per entity before the rest becomes a count.
      -- refs_per_entity = 20,
      -- Rebind or disable :DocBrowse keys by action name: string | string[] | false.
      -- keys = {},
      -- Register :DocBrowse's bindings with which-key when it is installed.
      -- which_key = true,
      -- Right-click context menu on :DocBrowse's list (nvzone/menu, soft dependency).
      -- menu = true,
      -- Collect per-stage scan timings and report them after a `:DocMap`.
      -- debug = false,
      -- install() only: rescan on BufWritePost under source/**.lua, debounced.
      -- watch = false,
      -- install() only: debounce interval for `watch`, in ms.
      -- watch_ms = 500,
      -- install() only: attach a narrow LSP client answering call-hierarchy requests.
      -- callhierarchy = false,
      -- install() only: publish findings as native vim.diagnostic entries.
      -- diagnostics = false,
      -- install() only: push a live Markdown rendering to a running mdview.nvim session.
      -- mdview = false,
      -- Doxygen TAGFILES equivalent: module prefix -> another project's docs/map directory.
      -- tag_files = {},
      -- Third-party plugins: module prefix -> "owner/repo" or
      -- { repo, branch?, lua_root?, name?, local_path? }.
      -- external_repos = {},
      -- Tuning for the Quicks verdicts.
      -- quicks = {
      --   -- Per-verdict cut points, merged over the built-in ones: { good = n, bad = n }.
      --   thresholds = {},
      --   limit_good = 5,
      --   limit_bad = 5,
      -- },
      -- Also write coverage.svg (doc-coverage badge).
      -- badge = false,
      -- Also write overview.pdf via pdfport.nvim (optional dependency).
      -- pdf = false,
      -- runtime-analysis.telemetry namespace joined for the `telemetry` browse mode.
      -- telemetry_namespace = nil, -- string; default: `title`
      -- rules.nvim gate name the `rules` browse mode runs live; unset = mode reports "no gate".
      -- rules_gate = nil, -- string
      -- Self-instrument this tree with runtime-analysis.telemetry. No-op without it.
      -- telemetry = true,
      -- Plugin-spec extraction: spec-registering helpers, by call text as written.
      -- plugins = {
      --   wrappers = {}, -- table<string, true>
      -- },
      -- Path to the startup flamegraph SVG baked into the page's Analysis panel.
      -- startup_flamegraph = nil, -- string; default: runtime-analysis.nvim's own report path
      -- Lines kept per function's embedded source snippet.
      -- snippet_max_lines = 40,
      -- How :DocBrowse presents itself.
      -- browse = {
      --   -- Fraction of the editor the layout uses.
      --   width = 0.86,
      --   height = 0.86,
      --   -- Fraction of the layout given to the list column.
      --   list_width = 0.38,
      --   theme = nil, -- Ui.Kit.ThemeArg; passed to the kit layout
      --   -- Initial dependency-walk depth.
      --   depth = 2,
      --   -- List :DocBrowse opens on when the command names none.
      --   mode = "structure",
      --   -- Debounce before the trail file is written, in ms.
      --   trail_write_ms = 400,
      -- },
      -- How `:DocMap dot` / `:DocMap mermaid` draw.
      -- diagram = {
      --   -- Mermaid flowchart direction: "TB" | "TD" | "BT" | "LR" | "RL".
      --   direction = "LR",
      --   -- Deepest node level `mermaid tree` draws.
      --   max_depth = 2,
      --   -- Level the require graph is rolled up to in `mermaid deps`.
      --   deps_depth = 1,
      --   -- Graphviz rank direction: "TB" | "BT" | "LR" | "RL".
      --   rankdir = "LR",
      --   -- Node level `dot` draws subgraph clusters at.
      --   cluster_depth = 2,
      --   -- Radius in edges of the neighbourhood `dot <module>` keeps.
      --   hops = 2,
      -- },
      -- Per-check policy by finding code: false switches a check off, a severity
      -- string ("error" | "warn" | "info") re-grades it.
      -- checks = {},
      -- Feature files / release checklist locations (first existing wins).
      -- features_dir = nil, -- string|string[]; default { "docs/FEATURES", "docs/features" }
      -- checklist_dir = nil, -- string|string[]; default docs/CHECKLIST[.md], then lowercase
      -- Directory holding install.json / INSTALL.md.
      -- install_dir = "docs",
      -- Theme baked into the generated page: "light" | "dark" | "system".
      -- theme = "system",
      -- Port `:DocMap serve` binds; 0 lets the OS pick.
      -- serve_port = 0,

      return opts
    end,
  },

  {
    -- One :Git <scope> <action> command tree: blame, merge-conflict resolution
    -- (co/ct/cb/c0/]x/[x), hunks, diff, browse, branch, status and a float around
    -- the real `lazygit` binary. Do not install vim-fugitive (defines its own
    -- :Git command) or git-conflict.nvim (sets the same buffer-local keys)
    -- alongside it.
    "StefanBartl/gitsuite.nvim",
    cmd = "Git",
    -- Conflict markers live in a buffer's text, so there is nothing to detect
    -- before one is read: gitsuite.nvim's conflict scan/highlight/keymap setup
    -- must not wait for the user to type :Git first.
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
    -- diff.nvim's own commands first.
    -- ui.nvim: the multi-repo `:Git dashboard` uses `ui.kit` for its
    -- popup/confirm dialogs.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/diff.nvim", "StefanBartl/ui.nvim" },
    keys = {
      -- Full-file blame (native `git blame --porcelain`).
      { "<leader>gb", "<cmd>Git blame full<cr>", desc = "[gitsuite.nvim] Blame (full)" },
      -- The real lazygit TUI, in gitsuite.nvim's own float.
      { "<leader>lg", "<cmd>Git ui lazygit<cr>", desc = "[gitsuite.nvim] Open lazygit" },
    },
    opts = {
      -- Toggle whole feature families off; a disabled family registers no routes
      -- at all (`:Git conflict ours` then fails like an unknown scope).
      -- features = {
      --   conflict = true, -- :Git conflict *
      --   hunk = true, -- :Git hunk *
      --   blame = true, -- :Git blame *
      --   diff = true, -- :Git diff * (diff.nvim-backed)
      --   browse = true, -- :Git browse *
      --   branch = true, -- :Git branch *
      --   ui = true, -- :Git ui * (lazygit/neogit/diffview launchers)
      --   status = true, -- :Git status *
      -- },

      -- Top-level user command name; rename it if `:Git` collides with something.
      -- commands = {
      --   git = "Git",
      -- },

      -- Default keymaps; each is a string lhs, a list of lhs, or `false` to drop
      -- that one mapping.
      -- keymaps = {
      --   blame_full = "<leader>gb", -- :Git blame full
      --   ui_lazygit = "<leader>lg", -- :Git ui lazygit
      --   hunk_inline = "<leader>di", -- :Git hunk inline
      --   diffview_open = "<leader>dv", -- :Git ui diffview open
      --   diffview_close = "<leader>dc", -- :Git ui diffview close
      --   diff_history = "<leader>dh", -- :Git diff history
      -- },

      -- browse = {
      --   -- Self-hosted GitHub/GitLab/Codeberg(Gitea) instances keyed by host,
      --   -- e.g. { ["git.example.org"] = "gitlab" }; only the three public hosts
      --   -- are recognized out of the box.
      --   hosts = {},
      -- },

      -- branch = {
      --   -- Opt-in: save/load the window/tab layout (sessions.nvim, optional soft
      --   -- dependency) around a `:Git branch switch` checkout. Off because an
      --   -- automatic load can discard unsaved buffers.
      --   sessions = false,
      -- },

      dashboard = {
        -- Directory `:Git dashboard` scans by default; "" resolves to $REPOS_DIR.
        -- base_dir = "",
        -- Repositories shown on the default page in addition to the scan. This
        -- config is a git repo of its own but lives outside `$REPOS_DIR`, so the
        -- normal scan never finds it; listing it surfaces it alongside every other
        -- plugin checkout in `:MyPlugins dashboard`/`:Git dashboard`. Each entry
        -- must itself be a repository (one that isn't is reported and skipped).
        -- Default: {}.
        extra_paths = { vim.fn.stdpath("config") },
        -- Named extra pages, `{ name = string, paths = string[] }`; a path is a
        -- repository or a directory scanned for its git-repository children.
        -- groups = {},
      },

      -- Indicator for `:Git dashboard`/`:Git dashboard update` (both report into
      -- the shared lib.nvim.progress registry): "auto" | "notify" | "statusline" |
      -- "fidget" | "float" | "kit".
      -- "kit" instead of "statusline": the first dashboard scan of a session reads
      -- 60+ clones (several seconds on Windows) before its float opens, and the
      -- statusline text is easy to miss meanwhile. "kit" is a themed corner float
      -- with an (n/total) counter that never takes focus.
      -- Default: "auto" (fidget.nvim when installed, else vim.notify).
      progress_style = "kit",
    },
    config = function(_, opts)
      require("gitsuite").setup(opts)
    end,
  },

  {
    -- casedesk: the `:Case` / `:Cases` / `:Tricentis` command tree for
    -- SAP-Support case work.
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
    -- Not a single active override: every path derives from $REPOS_DIR inside
    -- config/DEFAULTS.lua, so this machine has nothing to correct. Overrides
    -- belong here the day a machine disagrees about where WKDBook-Tricentis
    -- lives (`repo_root`); see the plugin's docs/configuration.md. The block
    -- below lists every option with its default. Lists replace the default,
    -- name-keyed tables (`sla`, `state_verbs`, `keymaps`, ...) merge key by key.
    "StefanBartl/casedesk.nvim",
    lazy = false,
    -- ui.nvim: casedesk.ui requires ui.kit at module load -- setup() fails
    -- without it, no fallback. ui.nvim is already loaded eagerly; the entry
    -- documents the dependency.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    opts = {
      -- Paths. Normally only `repo_root` needs setting; `root`, `cases_root`,
      -- `workflow_templates_dir`, `sla_doc_path` and every built-in area's `dir`
      -- follow it unless set explicitly (an explicit value is never recomputed).
      --
      -- The work knowledge repository as a whole (`Cases/`, `Workflow/`,
      -- `Notes/`, ... live below it).
      -- repo_root = "$REPOS_DIR/WKDBook-Tricentis", -- string; falls back to C:/repos
      -- The SAP support area.
      -- root = "<repo_root>/Cases/SAP_Support",
      -- The default area's case tree.
      -- cases_root = "<root>/Cases",
      -- Hand-written reply blocks `:Case template` offers.
      -- workflow_templates_dir = "<repo_root>/Workflow/Templates",
      -- Files in that directory that are not reply blocks.
      -- workflow_template_excludes = { "SummaryTemplate.md", "SummaryTemplateBefüllt.md" },

      -- Areas and states. A case's state IS the folder it sits in.
      --
      -- States (folder names) of the default (SAP) area; replaces the list.
      -- states = { "Open", "Closed", "Reassigned", "Solved", "Assigned", "Unassigned", "OtherAgent", "T2" },
      -- Where `:Case new` creates and what "open" means.
      -- default_state = "Open",
      -- State -> generated `:Case <verb>`; a state without an entry gets its lowercased name.
      -- state_verbs = { Closed = "close", Reassigned = "reassign" },
      -- Case trees, each with its own root and states; replaced wholesale when set.
      -- The first one is the default. Built-in directories follow `repo_root`.
      -- areas = {
      --   {
      --     name = "SAP",
      --     dir = "<cases_root>",
      --     states = { "Open", "Closed", "Reassigned", "Solved", "Assigned", "Unassigned", "OtherAgent", "T2" },
      --     default_state = "Open",
      --     snow_prefix = "SAP0000",
      --     id_prefix = nil, -- string; full-id prefix without year suffix
      --     sla = true,
      --   },
      --   {
      --     name = "CS",
      --     dir = "<repo_root>/Cases/CS",
      --     states = { "Open", "Closed", "Solved" },
      --     default_state = "Open",
      --     snow_prefix = nil, -- string; no ServiceNow id for this area
      --     id_prefix = "CS0",
      --     sla = false,
      --   },
      -- },
      -- Area `:Case new` creates in and the area-less path helpers assume.
      -- default_area = "SAP",
      -- Per-machine usage journal ordering `<Tab>` completion; deliberately not under repo_root.
      -- usage_path = "<stdpath('data')>/casedesk/usage.json",

      -- Case layout.
      --
      -- Per-case metadata sidecar.
      -- meta_filename = ".case.json",
      -- Case-local attachments folder.
      -- assets_dirname = "assets",
      -- Where a case's solution lives: <case>/<solution_dirname>/<solution_filename>.
      -- solution_dirname = "Solution",
      -- solution_filename = "Solution.md",
      -- `## Status` values of a Solution.md; order matters (first substring match wins).
      -- solution_statuses = { "Gelöst", "Workaround", "Offen" },
      -- States that, when reached, ask about the case's solution.
      -- solution_reminder_states = { "Solved", "Closed" },
      -- `:Cases doctor` stale-unconfirmed threshold: days an open case's Solution/ draft stays untouched.
      -- stale_unconfirmed_days = 14,
      -- `:Cases doctor` docs-thin threshold: minimum characters of a filed case's Notes/Summary.
      -- docs_thin_min_chars = 150,
      -- Reasons recorded instead of a solution when a case is filed away without one.
      -- case_outcomes = { "Keine Kundenantwort" },
      -- Departments `:Case route` / `:Cases routed_to` know.
      -- routing_targets = { "PAC", "PSO" },
      -- States that ask which department the case just went to.
      -- routing_prompt_states = { "Reassigned" },
      -- Plausible length range of a short case number.
      -- case_number_min_digits = 4,
      -- case_number_max_digits = 8,
      -- Format of the generated H1: case number, title, file name.
      -- headline_format = "# %s - `%s` - %s",
      -- Sidecar fields that each get a `:Cases <field>` filter route and an infocard row.
      -- infocard_fields = { "title", "company", "name", "notes", "priority", "tosca_version", "outcome", "routed_to" },
      -- Alias -> real infocard field (SNOW's Account/Contact vs. company/name).
      -- infocard_field_aliases = { account = "company", contact = "name" },
      -- Gap in minutes between file touches before `:Case timeline` starts a new session.
      -- timeline_session_gap_minutes = 120,
      -- Fallback target language of `:Case translate` (language.nvim).
      -- translate_default_target = "DE",
      -- `:Case ocr --preset=<name>`: named tesseract argument bundles.
      -- ocr_presets = {
      --   default = {},
      --   log = { "--psm", "6" },
      -- },

      -- Pinned case chip (ui.kit.chip) showing the focused buffer's case.
      -- pin = {
      --   enabled = true,
      --   -- "top-left" | "top-right" | "bottom-left" | "bottom-right".
      --   anchor = "bottom-right",
      --   -- "chip" | "rounded_chip" | "classic" (old names "rect" | "rounded" | "text" still work).
      --   shape = "chip",
      --   -- Highlight group name or { fg, bg }; nil uses the chip's own default.
      --   color = nil, -- string|table
      --   -- One line per entry: "casenumber" | "title" | "company" | "contact"; replaces the list.
      --   content = { "casenumber", "title" },
      -- },

      -- Keymap overrides (pickers.nvim-backed search): `action = lhs | lhs[] | false`,
      -- or `false` to bind none. Actions: find_files (<leader>cf), grep (<leader>cg),
      -- find_files_all (<leader>cF), grep_all (<leader>cG).
      -- keymaps = {},

      -- ServiceNow.
      --
      -- Ticket id = prefix + short number + 4-digit year.
      -- snow_prefix = "SAP0000",
      -- Instance URL enabling `:Case snow`; nil copies the ticket number instead.
      -- snow_url_format = nil, -- string

      -- SLA (contractual numbers; durations in seconds).
      --
      -- Opened by `:Case sla --doc`.
      -- sla_doc_path = "<repo_root>/Workflow/SLA_ServiceLevelAgreement.md",
      -- Business window; `days` uses os.date("*t").wday numbering (1 = Sunday).
      -- sla_business_hours = { from = 8, to = 18, days = { 2, 3, 4, 5, 6 } },
      -- Per priority level; merged key by key, so a single field can be overridden.
      -- `window`/`fix_window` are "24x7" or a business-hours table like `sla_business_hours`
      -- (the defaults below reference that very table). `cadence` has one or two
      -- intervals: without / with a confirmed product defect.
      -- sla = {
      --   ["1"] = {
      --     label = "Very High",
      --     window = "24x7",
      --     first_response = 3600,
      --     cadence = { 3600 },
      --     fix = 14400,
      --     fix_window = "24x7",
      --   },
      --   ["2"] = {
      --     label = "High",
      --     window = "24x7",
      --     first_response = 7200,
      --     cadence = { 21600 },
      --     fix = 108000,
      --     fix_window = { from = 8, to = 18, days = { 2, 3, 4, 5, 6 } },
      --   },
      --   ["3"] = {
      --     label = "Medium",
      --     window = { from = 8, to = 18, days = { 2, 3, 4, 5, 6 } },
      --     first_response = 14400,
      --     cadence = { 259200, 1209600 },
      --     fix = 3628800,
      --     fix_window = "24x7",
      --   },
      --   ["4"] = {
      --     label = "Low",
      --     window = { from = 8, to = 18, days = { 2, 3, 4, 5, 6 } },
      --     first_response = 36000,
      --     cadence = { 604800, 1814400 },
      --     fix = 3628800,
      --     fix_window = "24x7",
      --   },
      -- },
      -- Fraction of a clock's budget remaining below which it counts as urgent.
      -- sla_warn_at = 0.25,
      -- Priorities the statusline badge and the notifications fire for.
      -- sla_active_priorities = { "1", "2" },
      -- Push notifications on top of the statusline badge; false removes the only autocommand.
      -- sla_notifications_enabled = true,
      -- How often the background timer re-checks open cases, in seconds.
      -- sla_notify_interval_seconds = 900,
      -- `:Cases stale` idle threshold per priority, in days.
      -- sla_stale_days = { ["1"] = 1, ["2"] = 2, ["3"] = 5, ["4"] = 10 },
      -- Idle threshold for a case without a parseable priority.
      -- stale_days_default = 7,

      -- Artefact extraction.
      --
      -- `:Case versions <component>` -> where a component's version is found
      -- (a support-info header or a file name); merged key by key.
      -- version_components = {
      --   commander = { header = "Tosca Testsuite Version" },
      --   testsuite = { header = "Tosca Testsuite Version" },
      --   tbox = { file = "Tricentis.AutomationBase.dll" },
      --   api = { file = "Tricentis.Automation.Api.Core.dll" },
      --   sap = { file = "Tricentis.Automation.SapEngine.dll" },
      --   sapui5 = { file = "Tricentis.Automation.SAP.SAPUI5.dll" },
      --   html = { file = "Tricentis.Automation.HtmlEngine.dll" },
      --   chrome = { file = "Tricentis.Automation.ChromeEngine.dll" },
      --   edge = { file = "Tricentis.Automation.EdgeEngine.dll" },
      --   uia = { file = "Tricentis.Automation.UiaEngine.dll" },
      --   mobile = { file = "Tricentis.Automation.Mobile30Engine.dll" },
      --   webdriver = { file = "WebDriver.dll" },
      --   excel = { file = "Tricentis.Automation.ExcelEngine.dll" },
      --   pdf = { file = "Tricentis.Automation.PdfEngine.dll" },
      --   database = { file = "Tricentis.Automation.DatabaseEngine.dll" },
      --   ocr = { file = "Tesseract.dll" },
      --   licensing = { file = "CloudLicensingIntegrationService.dll" },
      -- },
      -- Libraries that get a permanent line in the versions digest.
      -- version_watch = { "Tesseract.dll", "WebDriver.dll" },
      -- Persisted `:Case versions` digest in the case root.
      -- versions_filename = "Versions.md",
      -- File-name prefixes the digest treats as a known dependency, not a support signal.
      -- known_vendor_prefixes = {
      --   "amqm", "Amqp.", "Antlr4.", "Apache.", "Avro", "AWSSDK.", "Azure.", "BouncyCastle.",
      --   "Castle.", "CloudLicensing", "CloudTestData", "CommandLine", "Commander", "Confluent.",
      --   "DevExpress.", "DocumentFormat.", "Duende.", "Experimental.", "ExtensionManager", "Fare",
      --   "Flexera", "Flx", "GdPicture.", "Gma.", "Google.", "Grpc.", "ICSharpCode.",
      --   "IdentityModel", "Interop.", "libcrypto", "libssl", "log4net", "LogViewer", "MailKit",
      --   "ManualExecution", "Microsoft.", "MimeKit", "Mobile.Connections", "ModelContextProtocol.",
      --   "NativeSDK.", "NCalc", "Newtonsoft.", "NHotkey.", "Open3270", "OpenMcdf", "Otp.NET",
      --   "Polly", "protobuf-net", "RabbitMQ.", "RestSharp.", "RtfPipe", "ServicesCPP",
      --   "Std.UriTemplate", "System.", "Tesseract", "TestData", "TestStepForm", "TOSCA",
      --   "Tricentis", "UIAComWrapper", "UIHelper", "WebDriver", "WpfAnimatedGif",
      --   "XamlAnimatedGif", "XmlDiffPatch.",
      -- },
      -- Known SNOW field labels in the trailing Stammdaten dump of an Activity Stream.
      -- stream_stammdaten_labels = {
      --   "Account", "Assignment group", "Business Impact", "Cloud System Type",
      --   "Component Change Request GPS", "Contact", "Description", "Escalation Request GPS",
      --   "Global MCC Escalation", "Impact", "Number", "Opened by", "Priority",
      --   "Priority raise request", "SAP Component", "Speedup Request GPS", "State", "Title",
      -- },

      -- Anonymization (`:Case anonymize`).
      --
      -- Stammdaten labels whose values carry personal/company data worth redacting.
      -- anonymize_pii_stammdaten_labels = { "Account", "Contact", "Opened by" },
      -- Pseudo-actors that are never redacted.
      -- anonymize_non_person_actors = { "SR", "SAP Resolve", "Integration API", "SAP", "System" },

      -- Blueprints and topics.
      --
      -- Blueprint used by `:Case new` when no company blueprint matches.
      -- default_blueprint = "default",
      -- Company name (as in `.case.json`) -> key in `blueprints`.
      -- company_blueprints = {},
      -- Shape of a new case. Node: { type = "dir" | "file", path, key?, headline?, open?,
      -- template? }; a node with a `key` generates `:Case <key>`; templates are the
      -- strings exported by casedesk.templates ($Summary, $Notes, ...).
      -- blueprints = {
      --   default = {
      --     { type = "dir", path = "Replies" },
      --     { type = "dir", path = "Research" },
      --     { type = "dir", path = "assets" }, -- follows `assets_dirname`
      --     { type = "file", path = "Summary.md", key = "summary", headline = false, template = "$Summary" },
      --     { type = "file", path = "Notes.md", key = "notes", template = "$Notes" },
      --     { type = "file", path = "Task.md", key = "task", template = "$Task" },
      --     { type = "file", path = "Research/00_Research.md", key = "research", open = true, template = "$Research" },
      --     { type = "file", path = "Research/JQL.md", key = "jql", template = "$JQL" },
      --     { type = "file", path = "Replies/00_PSO.md", key = "reply", template = "$Reply" },
      --     { type = "file", path = "SWAT/Technicals.md", key = "swat", template = "$SWAT" },
      --   },
      -- },
      -- Named shortcuts for `:Tricentis commands [topic]` -> repo-relative directory;
      -- first match labels a file, so narrow topics come before wide ones.
      -- command_topics = {
      --   { name = "enginelab", dir = "EngineLab" },
      --   { name = "mobile", dir = "Tosca/Notes/Tosca_Engines/Mobile_Engine" },
      --   { name = "api", dir = "Tosca/Notes/Tosca_Engines/API_Engine" },
      --   { name = "excel", dir = "Tosca/Notes/Tosca_Engines/Excel_Engine" },
      --   { name = "engines", dir = "Tosca/Notes/Tosca_Engines" },
      --   { name = "tosca", dir = "Tosca" },
      --   { name = "workflow", dir = "Workflow" },
      --   { name = "notes", dir = "Notes" },
      --   { name = "terminologie", dir = "Terminologie" },
      --   { name = "cases", dir = "Cases" },
      --   { name = "todo", dir = "ToDo-Collection" },
      -- },
    },
  },

  -- tasks.nvim: the task engine and its editor front ends (one Markdown file per task in a vault, generated
  -- overviews, dashboard, headless CLI). Loaded on `:Tasks` or on the first `require("tasks_nvim...")`, i.e.
  -- by the `:MyPlugins tasks|task|open` routes (lua/bindings/usrcmds/plugin_repos/init.lua mounts the
  -- plugin's route tree). No built-in vault path: it is set here.
  {
    "StefanBartl/tasks.nvim",
    main = "tasks_nvim",
    cmd = { "Tasks" },
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- The vault folder (one folder per area). Without it $TASKS_VAULT is read.
      -- Default: nil.
      vault = (vim.env.REPOS_DIR and vim.env.REPOS_DIR ~= "")
          and (vim.env.REPOS_DIR .. "/WKDBooks/Development/wkdbook-myplugins")
        or nil,
      -- Folders that are areas although they hold neither ROADMAP/ nor Backlog/.
      -- Default: {}.
      extra_areas = { "ALL", "nvim-config", "docmap-desktop", "migrate.nvim" },
      -- Dashboard behind `:Tasks list`.
      -- dashboard = {
      --   -- Refresh the list when a task or Backlog file changes (file watchers).
      --   -- watch = true,
      --   -- Quiet period after a change before the list is rescanned.
      --   -- debounce_ms = 250,
      --   -- The picker: "auto" (snacks if installed, else kit) | "snacks" | "kit" | "select".
      --   -- backend = "auto",
      -- },
      -- Staleness check (`--stale=refs`: last activity of a task read from git).
      -- staleness = {
      --   -- One `git log` call is killed after this many ms.
      --   -- git_timeout_ms = 20000,
      --   -- All git calls of one run share this budget (ms); the rest falls back to mtimes.
      --   -- budget_ms = 30000,
      --   -- Folders holding the repos by name (`<base>/<area>`); empty: derived from the vault and $REPOS_DIR.
      --   -- repo_bases = {},
      -- },
      -- `ci` command.
      -- ci = {
      --   -- The vault's `md_lint.lua` is killed after this many ms.
      --   -- lint_timeout_ms = 120000,
      --   -- Allow `ci` to run <vault>/TOOLS/scripts/md_lint.lua (code from the vault itself).
      --   -- trust_vault_lint = false,
      -- },
      -- After finishing a task.
      -- next = {
      --   -- Offer the next task to open in a small dialog (headless: a message).
      --   -- popup = true,
      --   -- Name ready tasks written `cdx` apart, never as your next task.
      --   -- cdx_hint = true,
      -- },
      -- Plan chaining.
      -- chain = {
      --   -- Documents whose `<!-- GENERATED:plan scope=... -->` blocks are refreshed after a task is
      --   -- finished; only these files are touched. The headless CLI reads $TASKS_MARKER_DOCS instead.
      --   -- marker_docs = {},
      -- },
      -- Plan steps in a task buffer.
      -- steps = {
      --   -- Ask whether to finish the task when the LAST open step of `## Plan` is ticked
      --   -- (adds an autocommand on task buffers).
      --   -- ask_finish = false,
      -- },
      -- Keys: action name -> key, or false to switch that action's key off. Unnamed actions keep their default.
      -- keys = {
      --   -- Dashboard list window.
      --   -- dashboard = {
      --   --   status = "s", -- advance status of marked (else current) tasks
      --   --   prio = "p", -- advance priority of marked (else current) tasks
      --   --   done = "D", -- finish (asks first)
      --   --   filter = "f", -- set a filter chip
      --   --   sort = "o", -- cycle the sort
      --   --   export = "e", -- export marked (else all shown) tasks
      --   --   rescan = "r", -- rescan now
      --   --   backlog = "gb", -- Backlog picker of the area under the cursor
      --   --   roadmap = "gr", -- ROADMAP of the area under the cursor
      --   --   preview = "gp", -- preview the task file in the browser
      --   --   help = "g?", -- help
      --   --   view = "v", -- switch between list and stage view
      --   --   assign = "P", -- give marked (else current) tasks a plan and a stage
      --   --   move_down = "J", -- stage view: move the task down in its stage
      --   --   move_up = "K", -- stage view: move the task up in its stage
      --   -- },
      --   -- Dashboard input window (normal and insert mode).
      --   -- dashboard_input = {
      --   --   status = "<M-s>",
      --   --   prio = "<M-p>",
      --   --   done = "<M-d>",
      --   --   filter = "<M-f>",
      --   --   sort = "<M-o>",
      --   --   export = "<M-e>",
      --   --   rescan = "<M-r>",
      --   --   backlog = "<M-b>",
      --   --   roadmap = "<M-m>",
      --   --   preview = "<M-v>",
      --   --   help = "<M-?>",
      --   --   view = "<M-g>",
      --   --   assign = "<M-a>",
      --   --   move_down = "<M-j>",
      --   --   move_up = "<M-k>",
      --   -- },
      --   -- Buffer-local keys of the `:Tasks new` form.
      --   -- form = {
      --   --   tick_space = "<Space>",
      --   --   tick_enter = "<CR>",
      --   --   submit = "<C-s>",
      --   --   cancel = "q",
      --   --   cancel_ctrl = "<C-q>",
      --   --   help = "g?",
      --   -- },
      -- },
    },
  },

  -- terminal.nvim: benannte Terminals pro Projekt (Float/Split/VSplit/Tab), Text und Befehle in
  -- Terminals tippen (`:Terminal send|run`), Quoting fuer argv. Ersetzt bindings/mappings/terminal.lua
  -- und den Snacks-Terminal-Toggle. Die Tasten (<A-h> usw.) sind global, darum wird beim Start
  -- (VeryLazy) geladen; setup() registriert nur Keymaps, Autocmds und den einen Befehl `:Terminal`.
  -- Debugging: `:checkhealth terminal`, `:lua =require("terminal").status()`,
  -- `:lua =require("terminal").list(true)` (alle Projekte).
  {
    "StefanBartl/terminal.nvim",
    event = "VeryLazy",
    cmd = { "Terminal" },
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- Welches Backend die Terminals stellt: "auto" | "native" | "wezterm" | "tmux".
      -- "wezterm" oeffnet Terminals als WezTerm-Panes (`wezterm cli`) und "tmux" als tmux-Panes
      -- (`tmux`-CLI); beide: keine Floats, kein `env`, Exit wird nicht gemeldet. `:Terminal pin`
      -- startet ein natives Terminal als Pane neu (ueberlebt Neovim), `:Terminal adopt` zeigt ein Pane
      -- schreibgeschuetzt. Ein nicht verfuegbares Backend faellt mit einer Warnung (Grund inklusive)
      -- auf "native" zurueck.
      -- "auto" = native: Terminals bleiben Neovim-Fenster, auch innerhalb von WezTerm/tmux.
      -- Default: "auto".
      -- backend = "auto",

      -- Wie ein Terminal angezeigt wird: "float" | "split" (unten) | "vsplit" (rechts) | "tab".
      -- Pro Aufruf ueberschreibbar: `:Terminal open --layout=vsplit`. Default: "float".
      -- layout = "float",

      -- Das schwebende Fenster (nur layout = "float").
      -- float = {
      --   -- Breite: Bruchteil des Editors (0 < x <= 1) oder absolute Spalten (> 1). Default: 0.8.
      --   width = 0.8,
      --   -- Hoehe: Bruchteil (0 < x <= 1) oder absolute Zeilen (> 1). Default: 0.8.
      --   height = 0.8,
      --   -- Rahmen: alles, was nvim_open_win akzeptiert ("rounded", "single", "none", {...}).
      --   border = "rounded",
      --   -- Namen des Terminals im Titel des Rahmens zeigen (nur mit Rahmen).
      --   title = true,
      --   -- Titelposition: "left" | "center" | "right".
      --   title_pos = "center",
      --   -- Transparenz: 0 (deckend) .. 100 (durchsichtig).
      --   winblend = 0,
      --   -- Stapelreihenfolge gegenueber anderen Floats.
      --   zindex = 50,
      -- },

      -- Die Groesse fuer layout = "split" / "vsplit".
      -- split = {
      --   -- Bruchteil des Editors (0 < x <= 1) oder absolute Zeilen/Spalten (> 1). Default: 0.3.
      --   size = 0.3,
      -- },

      -- Wo ein neues Terminal startet. Die Zugehoerigkeit zum Projekt (Wurzel + Name = Identitaet) ist
      -- immer die Git-Wurzel (sonst das cwd); nur das Startverzeichnis haengt von diesem Modus ab:
      --   "project" = Git-Wurzel des aktuellen Buffers, sonst das cwd (Default)
      --   "buffer"  = Ordner des aktuellen Buffers
      --   "cwd"     = das aktuelle Arbeitsverzeichnis
      -- cwd = "project",

      -- Die Shell: "" = die 'shell'-Option; sonst ein String ("pwsh") oder eine Argv-Liste
      -- ({ "pwsh", "-NoLogo" }). Auch fuer das Quoting von `run` massgeblich. Default: "".
      -- shell = "",

      -- Zusaetzliche Umgebungsvariablen fuer jedes neue Terminal, z.B. { FOO = "1" }. Default: {}.
      -- env = {},

      -- In den Terminal-Modus wechseln, wenn ein Terminal ueber die API Fokus bekommt
      -- (toggle/open). Default: true.
      -- start_insert = true,

      -- Was passiert, wenn der Job endet:
      --   "close"            = Fenster und Buffer entfernen (Default)
      --   "close_on_success" = nur bei Exit-Code 0; Fehlschlaege bleiben lesbar stehen
      --   "keep"             = immer stehen lassen (Ausgabe bleibt, `open` startet neu)
      -- on_exit = "close",

      -- Name des Terminals, das toggle()/open() ohne Name und ohne Count nehmen. `3<A-h>` oeffnet
      -- das Terminal "3". Default: "main".
      -- default_name = "main",

      -- Fensteroptionen, die bei TermOpen lokal auf jedes Terminal-Fenster gesetzt werden.
      -- window_options = {
      --   -- Aus: Terminal-Fenster unveraendert lassen. Default: true.
      --   enable = true,
      --   number = false,
      --   relativenumber = false,
      --   signcolumn = "no",
      --   spell = false,
      --   cursorline = false,
      -- },

      -- Nur in Kitty: beim Start engen Rand (padding/margin), beim Beenden wieder weiten Rand.
      -- Kommt aus dem frueheren bindings.autocmds.terminals und ersetzt es.
      -- kitty = {
      --   enable = true,
      --   enter_padding = 0,
      --   enter_margin = 0,
      --   leave_padding = 20,
      --   leave_margin = 10,
      -- },

      -- In JEDEM Terminal-Buffer automatisch in den Insert-Modus gehen (nicht nur ueber die API).
      -- auto_insert = {
      --   -- Default: false.
      --   enable = false,
      --   -- Ausloeser; "TermEnter" waere aggressiver (Insert bei jedem Fokus). Default: { "TermOpen" }.
      --   events = { "TermOpen" },
      -- },

      -- Das Terminal, das `:Terminal run` und `:Terminal send` ohne --name/Namen benutzen.
      -- run = {
      --   name = "run",
      -- },

      -- Tasten als benannte Aktionen (lib.nvim.bindings.keymap.register). Ein String verschiebt
      -- eine Taste, eine Liste belegt mehrere, `false` streicht sie, `preset = false` bindet
      -- gar nichts. Ein falscher Aktionsname wird gemeldet.
      keymaps = {
        -- preset = true,
        -- Terminal umschalten (n + t). Mit Count: `3<A-h>` = Terminal "3". Default: "<A-h>".
        -- toggle = "<A-h>",
        -- Terminal-Modus verlassen (Terminal-Normal). Default: { "<Esc>", "<C-c>" }.
        -- normal_mode = { "<Esc>", "<C-c>" },
        -- Plugin tippt `cls` / `clear` ins Terminal (nur Terminal-Modus). Default: false, denn
        -- <C-l> erreicht die Shell und leert dort den Bildschirm wie in jedem Terminal.
        -- clear = false,

        -- Fensterwechsel aus dem TERMINAL-Modus heraus: hier AUS (false), gewuenscht ist der
        -- Wechsel nur im Normal-Modus. Defaults waeren <C-h> <C-j> <C-k>; window_right ist
        -- ohnehin aus (sonst waere <C-l> nicht mehr das Clear der Shell).
        window_left = false,
        window_down = false,
        window_up = false,
        -- window_right = false,

        -- Fensterwechsel aus dem NORMAL-Modus ueber terminal.nvim (mit Count, `3<C-h>`, und mit
        -- Uebergabe an WezTerm/tmux am Rand). AKTIV auf <C-h/j/k/l>; die frueheren Belegungen
        -- in bindings/mappings/buf_win_tab.lua sind dafuer entfernt. Default: false.
        nav_left = "<C-h>",
        nav_down = "<C-j>",
        nav_up = "<C-k>",
        nav_right = "<C-l>",
      },

      -- Fensterwechsel ueber den Neovim-Rand hinaus: ist in der Richtung kein Fenster mehr, fokussiert
      -- das Multiplexer-Programm das Nachbar-Pane (`wezterm cli activate-pane-direction` bzw.
      -- `tmux select-pane`). Floats geben nie ab. Wirkt auf die Terminal-Modus-Tasten (<C-h/j/k>)
      -- und auf nav_*.
      -- navigate = {
      --   -- "auto" (tmux in tmux, WezTerm in WezTerm) | "tmux" | "wezterm" | { "wezterm" } | false.
      --   handoff = "auto",
      -- },

      -- Dem Terminal um Neovim herum mitteilen, was Neovim gerade tut (Modus, Datei, Branch,
      -- Diagnostics, Aufnahme): WezTerm liest es aus Pane-Variablen (Tab-Titel, Right-Status;
      -- Gegenstueck: Configs/terminals/wezterm/config/nvim_status.lua). Gesendet wird nur bei
      -- Aenderung, entprellt, in EINEM Schreibvorgang.
      -- status = {
      --   -- Default: true.
      --   enable = true,
      --   -- "auto" (jeder Exporter, dessen Umgebungssignal da ist: $WEZTERM_PANE) | "wezterm" |
      --   -- { "wezterm" } | false (nichts senden). Default: "auto".
      --   export = "auto",
      --   -- Ruhezeit nach einer Aenderung, bevor gesendet wird (ms). Default: 80.
      --   debounce_ms = 80,
      --   -- Groesse des Datensatzes: darueber wird gekuerzt, dann abgelehnt. Default: 1024.
      --   max_bytes = 1024,
      -- },

      -- Den Befehl `:Terminal` registrieren (toggle open hide close list send run). Default: true.
      -- commands = true,
    },
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
