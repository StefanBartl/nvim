---@module 'plugins.personal'
--- Personal and local development plugins - the SPEC IMPLEMENTATION only.
---
--- All source control (which repo loads locally / remotely / not at all, the
--- global OVERRIDE switch, machine-role handling and the per-repo mode table)
--- lives in plugins.personal.source. This file just registers the specs and
--- exports them for lazy:
---   local plugins = require("plugins.personal.source")
---   plugins.add({ ...specs... })
---   return plugins.export()
--- To turn a repo off or switch it local/remote, edit plugins/personal/source.lua,
--- not this file.

local personal_utils = require("plugins.personal.utils")
local machine = require("machine")
local plugins = require("plugins.personal.source")

-- ===========================================================================
-- PLUGIN SPECS
-- ===========================================================================

plugins.add({

  -- ==========================================================================
  -- 1. CORE / INFRASTRUCTURE, UTILITIES & SYSTEM
  -- ==========================================================================

  {
    "StefanBartl/lib.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- TODO: Das muss anders gemacht werden: helptags generell; usrcmds als normales userconfig nicht extra
      require("lib.nvim_usrcmds").setup({
        helptags = true,
        cwd_here = true,
        powershell_profile = true,
      })
    end,
  },

  {
    -- The whole LSP subsystem, extracted from this config's former lua/lsp/**
    -- (see docs/ROADMAP/personal/lsp.nvim.md). Module root is still `lsp`, so
    -- every existing require("lsp.…") keeps resolving -- which also means this
    -- plugin and a local lua/lsp/** cannot coexist: the config would shadow it.
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
    -- Eager: setup() registers the VimEnter autoload and the VimLeavePre
    -- autosave. Both are startup/shutdown events, so a lazy trigger would have
    -- to fire before VimEnter to be of any use -- which is what `lazy = false`
    -- means.
    "stefanbartl/sessions.nvim",
    lazy = false,
    dependencies = { "stefanbartl/lib.nvim" },
    opts = {
      -- Bare `nvim` (no file args) resumes the last-loaded session — see
      -- docs/ROADMAP/casedesk/SESSIONS.md §4.3.
      -- autoload = true,
    },
  },

  {
    -- Eager: setup() derives roughly twenty keymaps from the `collections`
    -- table below (`<leader>mnf`, `<leader>wkg`, ...). Lazy-loading on `keys`
    -- would mean listing every one of those lhs in the spec as well, kept in
    -- step with the table by hand -- two sources for the same bindings, and
    -- the drift only shows up as a key that silently does nothing.
    "StefanBartl/pickers.nvim",
    lazy = false,
    dependencies = { "StefanBartl/lib.nvim" },
    config = function()
      local repos = personal_utils.repos_path
      require("pickers").setup({
        engine = "snacks",
        repos_dir = repos,
        collections = {
          {
            name = "notes",
            dir = repos .. "/Notes",
            keys = { files = "<leader>mnf", grep = "<leader>mng", smart = "<leader>mns" },
          },
          {
            name = "notes_lua",
            dir = repos .. "/WKDBooks/Development/wkdbook-Lua",
            keys = { files = "<leader>mlf", grep = "<leader>mlg" },
          },
          {
            name = "notes_nvim",
            dir = repos .. "/WKDBooks/Development/wkdbook-Neovim",
            keys = { files = "<leader>mvf", grep = "<leader>mvg" },
          },
          {
            name = "checklists",
            dir = repos .. "/WKDBooks/Development/wkdbook-Lua/Checklists",
            keys = { files = "<leader>chf", grep = "<leader>chg" },
          },
          {
            name = "spickzettel",
            dir = repos .. "/WKDBooks/Spickzettel",
            keys = { files = "<leader>spf", grep = "<leader>spg" },
          },
          {
            name = "wkdbooks",
            dir = repos .. "/WKDBooks",
            prefix = "wkdbook-",
            keys = { files = "<leader>wkf", grep = "<leader>wkg", smart = "<leader>wks" },
          },
          {
            name = "wkdbooks_lua",
            dir = repos .. "/WKDBooks/Development/wkdbook-Lua",
            keys = { files = "<leader>wlf", grep = "<leader>wlg" },
          },
          {
            name = "wkdbooks_nvim",
            dir = repos .. "/WKDBooks/Development/wkdbook-Neovim",
            keys = { files = "<leader>wvf", grep = "<leader>wvg" },
          },
        },

        keymaps = {
          -- Smart action: one picker running grep (content) + find (filenames)
          -- for the same query, merged and ranked by relevance. See
          -- pickers.nvim docs/COMMANDS.md#the-smart-action.
          cwd_smart = "<leader>cw", -- smart grep+find in CWD
          config_smart = "<leader>cf", -- smart grep+find in nvim config
        },

        history = {
          enabled = true,
          fzf_scope = "patch", -- patches telescope + fzf-lua setup() itself, no config change needed elsewhere
        },

        keys = {
          -- Keep the old config.telescope.keymaps horizontal-scroll bindings
          -- (that module is now redundant/removed) instead of the plugin's
          -- own <C-Left>/<C-Right> default.
          preview_scroll_left = "<M-Left>",
          preview_scroll_right = "<M-Right>",
        },
      })
    end,
  },

  {
    "StefanBartl/buffer-ctx.nvim",
    cmd = {
      "Insert",
      "Copy",
      "Format",
      "Mark",
      "MarkLineToggle",
      "MarkLinesYank",
      "CopyFilepathAbsolute",
      "CopyFilepathRelative",
    },
    keys = { "<leader>cnl", "<leader>cnm", "<leader>cnf", "<S-m>", "<C-p>" },
    -- `main` because lazy.nvim infers "buffer-ctx" from the repo name and the
    -- module is `buffer_ctx`.
    main = "buffer_ctx",
    opts = {},
  },

  {
    "StefanBartl/open.nvim",
    -- All three names are needed: the viewer commands are registered by
    -- open.nvim's setup(), so lazy-loading on "Open" alone would leave
    -- :UrlView / :MDLinksView undefined until something else pulled the
    -- plugin in.
    cmd = { "Open", "UrlView", "MDLinksView" },
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {},
  },

  {
    "StefanBartl/images.nvim",
    -- Ersetzt snacks.image, das hier prinzipiell nicht funktionieren kann:
    -- es sendet nur Kitty-APC, und das wird aus Neovim heraus in WezTerm nie
    -- gezeichnet. images.nvim nutzt stattdessen OSC 1337.
    --
    -- Beide Namen nötig: `:Image` deckt den Command ab, die Filetypes sorgen
    -- dafür, dass <leader>im und der Doppelklick auch ohne vorherigen
    -- Command-Aufruf in Markdown-Buffern gesetzt sind.
    cmd = { "Image" },
    ft = { "markdown", "vimwiki", "norg", "text" },
    dependencies = { "StefanBartl/lib.nvim" },
    -- cell_aspect: measured width/height ratio of this WezTerm setup (the 0.5
    -- default in images.scale leaves an empty strip below images).
    --
    -- terminal_padding is deliberately NOT set here: it lives in the stored
    -- calibration written by `:Image calibrate` (stdpath("data")/images.nvim),
    -- and an explicit option here would silently override it. draw_inset
    -- catches whatever sub-cell remainder is left after that.
    opts = {
      display = { cell_aspect = 0.46 },
    },
  },

  {
    "StefanBartl/sandbox.nvim",
    event = "VeryLazy",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- `image pull`/`push` and the devcontainer build report into the shared
      -- lib.nvim.progress registry, rendered by the statusline's
      -- "plugin_progress" module.
      progress_style = "statusline",
    },
  },

  {
    "StefanBartl/documentation.nvim",
    cmd = { "DocMap", "DocBrowse", "DocMapAll", "DocMapAllFull" },
    dependencies = { "StefanBartl/lib.nvim" },
    -- Kein `root`: die Commands mappen bewusst das aktuelle Arbeitsverzeichnis,
    -- weil hier reihenweise Repos nebeneinander liegen und ein fixes Ziel genau
    -- das Falsche waere. `source` leitet documentation.config aus dem Root ab
    -- (lua/<name>, wenn lua/ genau einen Kandidaten enthaelt).
    opts = function(_, opts)
      opts.progress_style = "statusline"
      -- `require-not-declared` false positives, confirmed 2026-08-16 by
      -- tracing every hit back to the actual require site (not fixed here,
      -- not fixable in the checker without a real capability it doesn't
      -- have): the checker treats "own[first segment]" as sufficient proof a
      -- require belongs to this tree, which is right except for two cases.
      -- (1) `nvchad.*` (stl.utils, tabufline, themes, term, utils, nvdash,
      -- mason, colorify, lsp.signature, winmes, configs.lspconfig, ...)
      -- resolves to the real NvChad plugins' (`NvChad`/`ui`) own
      -- `lua/nvchad/*` tree, which happens to share this repo's own
      -- `lua/nvchad/` top segment -- 24 of the 31 remaining
      -- `require-not-declared` hits. (2) `config.harpoon.api.lua`'s
      -- `require("config.harpoon.ui.menu_" .. kind)` is a dynamic require;
      -- the checker only ever sees the pre-concatenation literal
      -- `"config.harpoon.ui.menu_"`, never the resolved `menu_telescope`/
      -- `menu_fzf` it actually loads. `:DocMap check` will keep listing
      -- these 25 as warnings -- known, not drift.
      -- Experimental (2026-08-10): a "Compiler Explorer" link next to every
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
      -- All five are real shapes in this tree: `map` is `vim.g.__map_helper`
      -- (same argument order as vim.keymap.set, which is why it can reuse
      -- that layout), `usercmd.create`/`autocmd.create` are lib.nvim's, and
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
      -- entry below. `plugins.personal.export.projects()` is the same
      -- resolved entry list `config.telemetry.build()` reads, so nothing
      -- here has to be kept in sync with `plugins/personal/init.lua` by
      -- hand -- add a plugin to the spec below and both wirings pick it up.
      local export = require("plugins.personal.export")
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
          -- that its data is wanted -- see bindings.usrcmds.docmap_all's old
          -- header (now removed) for the "never infer" reasoning this
          -- overrides deliberately, once, here.
          autoload = true,
        }
      end

      return opts
    end,
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
    "StefanBartl/spotlight.nvim",
    dependencies = { "StefanBartl/lib.nvim" },
    event = "VeryLazy",
    opts = {},
  },

  -- ==========================================================================
  -- 2. NAVIGATION, FILE SYSTEM, SEARCH & TREES
  -- ==========================================================================

  {
    "StefanBartl/fileops.nvim",
    event = "VeryLazy",
    -- auto_mkdir, conflict_marks and the cycle keymaps used to live in this
    -- config's own autocmds/ and were moved into the plugin; they are on by
    -- default there, so nothing has to be repeated here.
    opts = {
      cycle = { open_target = "current" }, -- default is a split
    },
  },

  {
    "StefanBartl/gopath.nvim",
    event = "VeryLazy",
    -- Optional, not required: every nvim-treesitter call in gopath.nvim
    -- (health.lua's parser check, providers/treesitter.lua's Neovim-0.9
    -- ts_utils fallback) is pcall-guarded; almost everything else runs on
    -- built-in vim.treesitter. Kept here only because telescope.lua already
    -- pulls it in as a hard dep, so listing it costs nothing and documents
    -- the (optional) coupling explicitly.
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      mode = "hybrid",
      alternate = {
        enable = true,
        similarity_threshold = 75,
      },
      external = {
        enable = true,
      },
      mappings = {
        open_here = { "gF", "<2-LeftMouse>" },
        open_split = "g|",
        open_vsplit = "g\\",
        open_tab = "g}",
        copy_location = "gY",
        debug = "g?",
      },
    },
  },

  {
    "StefanBartl/replacer.nvim",
    cmd = { "Replace", "Replacer", "Surround", "Wrap" },
    dependencies = {
      "ibhagwan/fzf-lua",
      "StefanBartl/lib.nvim",
      -- "j-hui/fidget.nvim"
    },
    opts = {
      engine = "telescope", -- plugin default is "auto" (fzf-lua first)
      progress_style = "statusline", -- "auto" | "notify" | "statusline" | "fidget" | "float" (needs lib.nvim)
    },
  },

  {
    "StefanBartl/insights.nvim",
    -- Not `cmd = "Insights"`: the conflicts / unimported / devserver
    -- autocmds are registered by setup(), so lazy-loading on the command would
    -- mean they never fire. Set their `enable = false` to opt out instead.
    lazy = false,
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- Building the cwd symbol index runs one rg pass per language pattern;
      -- reports into the shared lib.nvim.progress registry.
      symbols = { progress_style = "statusline" },
    },
  },

  -- {
  --   "StefanBartl/neotree-fs-refactor",
  --   lazy = false,
  --   config = function()
  --     require("neotree-fs-refactor").setup({
  --       enabled = false,
  --       auto_save = true,
  --       notify_on_refactor = true,
  --       ignore_patterns = require("lib.nvim.fs.ignore.list").as_luals_patterns(),
  --       file_types = {
  --         lua = true,
  --         typescript = true,
  --         javascript = true,
  --         typescriptreact = true,
  --         javascriptreact = true,
  --         python = true,
  --       },
  --       max_file_size = 10 * 1024 * 1024,
  --       debounce_ms = 10,
  --     })
  --   end,
  -- },

  {
    "StefanBartl/filetree.nvim",
    event = "VeryLazy", -- must load AFTER the tree plugin's config function runs
    dependencies = {
      "StefanBartl/lib.nvim", -- shared helpers (neo-tree node utils, etc.)
      -- only ONE tree plugin is needed:
      "nvim-neo-tree/neo-tree.nvim",
      -- or: "nvim-tree/nvim-tree.lua",
    },
    config = function()
      -- Every feature is on by default; cwd_sync is opt-in (auto-chdir), so
      -- enable it explicitly. It anchors the cwd to the nearest .git ancestor on
      -- buffer switch. reveal = false because neo-tree already follows the cwd
      -- (bind_to_cwd + follow_current_file) — so cwd_sync only sets the cwd and
      -- lets neo-tree root/reveal, instead of the two fighting each other.
      require("filetree").setup({
        adapter = "neotree",
        features = {
          cwd_sync = { enabled = true, reveal = false },
          -- The mode badge (PROJECT/LOCK/…) is shown in wkdnvchad's own
          -- statusline instead (modules/filetree_cwd_mode) via cwd_mode's
          -- external-statusline API (badge()/component()). indicator.enabled
          -- must stay false here, or the mode shows twice: once in the
          -- shared statusline, once as a float in the tree window (with
          -- laststatus=3 there is no per-window statusline for it to use,
          -- so it would fall back to exactly that float).
          -- labels.follow is "" upstream by design: filetree's own in-tree
          -- badge is meant to be invisible while no policy is active. In a
          -- shared statusline that reads as "the component is broken" rather
          -- than "no mode" — so give follow a visible label. Everything else
          -- keeps filetree's defaults (PROJECT/PKG/LOCK/MANUAL/TREE).
          cwd_mode = {
            indicator = {
              enabled = false,
              labels = { follow = "FOLLOW" },
            },
          },
          -- Mark the currently-focused file with a sign-column icon (on top of
          -- neo-tree's own fg colour for all opened files). opened_sync is on by
          -- default and keeps those opened-file colours in sync as buffers open/
          -- close, so no config needed for it.
          current_hl = { enabled = true, icon = "▸" },
          -- Trash and watcher_quarantine are on by default in filetree.nvim
          -- (not in its DEFAULT_DISABLED list) - listed here only to make
          -- that explicit, no functional effect.
          trash = { enabled = true },
          watcher_quarantine = { enabled = true },
          -- handle_guard: actually closes neo-tree's leaked directory-watcher
          -- handles before a rename/move so the Windows EPERM file-lock can't
          -- happen (watcher_quarantine only hides the error). Opt-in / default
          -- off; enabled here to test whether the sporadic lock stops recurring.
          handle_guard = { enabled = true },
          -- context_menu: left on its default (<RightMouse>, opt-out) -
          -- filetree.nvim is now the sole right-click implementation for the
          -- tree. config/menu/neotree/ (the old hand-maintained entries) is
          -- gone, and config/menu/mappings.lua's global RightMouse handler no
          -- longer special-cases neo-tree - filetree's own buffer-local
          -- binding shadows it inside the tree, same items() source either
          -- way. Non-tree right-click (markdown, everything else) still goes
          -- through the global handler, unaffected.
          -- statusline defaults to true, but that blanks the tree window's
          -- local 'statusline' — harmless under laststatus=2 (per-window),
          -- but with laststatus=3 (global statusline, see options.lua) that
          -- blank local override becomes the content of the ONE shared
          -- statusline whenever the tree is focused. Disabled here so
          -- filetree leaves the global statusline alone.
          -- highlights_isolate confirmed working in real interactive use -
          -- replaces config.neotree's window/{disable_statusline,highlight}.lua
          -- + autocmds/init.lua, all removed.
          window_style = { statusline = false, highlights_isolate = true },
        },
      })
    end,
  },

  -- {
  --   "StefanBartl/filetreepicker.nvim",
  --   event = "VeryLazy",
  --   dependencies = { "nvim-neo-tree/neo-tree.nvim" },
  --   config = function()
  --     require("filetreepicker").setup({})
  --   end,
  -- },

  {
    "StefanBartl/reposcope.nvim",
    name = "reposcope",
    event = "VeryLazy",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- `:Reposcope update`/`status` walk a whole directory of clones; both
      -- report into the shared lib.nvim.progress registry.
      progress_style = "statusline",
    },
  },

  -- {
  --   "StefanBartl/mygrep.nvim",
  --   name = "mygrep",
  --   lazy = false,
  --   config = function()
  --     require("mygrep").setup({
  --       tool_picker_style = "ui",
  --     })
  --   end,
  -- },

  -- ==========================================================================
  -- 3. CODE QUALITY, UI, LOGGING & PRODUCTIVITY
  -- ==========================================================================

  {
    "StefanBartl/debugging.nvim",
    -- cmd = "Debug",
    event = "VeryLazy",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {}, -- features.neotree is off in the plugin's own defaults
  },

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
    -- "<leader>d" alone collides with existing git/fzf mappings
    -- (dc = DiffviewClose, di = ToggleInlineDiff, do = FzfLua diagnostics)
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
    "StefanBartl/diff.nvim",
    cmd = { "Diff", "DiffClear", "DiffOrig", "DiffExit" },
    opts = {}, -- all three features are on by default
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
    "StefanBartl/emojis.nvim",
    cmd = "Emojis",
    opts = {}, -- default_scope is already "%"
  },

  {
    "StefanBartl/github_stats.nvim",
    event = "VimEnter",
    dependencies = { "StefanBartl/lib.nvim" },
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
          "StefanBartl/language.nvim",
          "StefanBartl/lib.nvim",
          "StefanBartl/lsp.nvim",
          "StefanBartl/markdown.nvim",
          "StefanBartl/mdview.nvim",
          "StefanBartl/migrate.nvim",
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
    "StefanBartl/learn-cli.nvim",
    lazy = false,
    config = function()
      require("learn_cli").setup({
        exercises_dir = vim.fs.joinpath(
          vim.fn.stdpath("config"),
          "lua",
          "plugins",
          "learn-cli.nvim",
          "exercises"
        ),
      })
    end,
  },

  -- ==========================================================================
  -- 4. FILE TYPES (MARKDOWN & DOCUMENTS)
  -- ==========================================================================

  {
    "StefanBartl/cascade.nvim",
    ft = { "markdown", "markdown.mdx", "text", "tex", "norg" },
    event = "VeryLazy",
    -- Every other option in this domain is already the plugin's default; only
    -- the keymap preset has to be asked for (cascade ships `preset = false`,
    -- so the opinionated keys are opt-in). The per-feature switches and what
    -- they bind are documented in cascade's own config/DEFAULTS.lua.
    opts = {
      keymaps = { preset = true }, -- bind the opinionated default keys
    },
  },

  {
    "StefanBartl/pdfport.nvim",
    cmd = {

      "PdfPort",
      "PdfPortText",
      "PdfPortFloat",
      "PdfPortSystem",
      "PdfPortTerminal",
      "PdfPortHealth",
    },
    opts = {
      default_backend = "auto",
      fallback_chain = { "pdftotext", "pdfplumber", "marker", "docling", "ollama", "claude" },
      extract_opts = { max_pages = nil, timeout_ms = 30000 },
      render_opts = { mode = "buffer", split = "current", focus = true },
      claude_api_key = nil,
      -- OCR/AI backends run for minutes on a large PDF. Not cancellable from
      -- the indicator (see pdfport's docs), so a non-interactive style only.
      progress_style = "statusline",
      ollama_host = "http://localhost:11434",
      ollama_model = "qwen2.5-coder:7b",
      debug = false,
    },
  },

  {
    -- Finds/rewrites deprecated Neovim API calls (vim.highlight.* ->
    -- vim.hl.*, vim.lsp.buf_get_clients() -> vim.lsp.get_clients(), ...) in
    -- the current line, a range, the whole buffer, or cwd, with a Telescope
    -- picker+preview past single-line scope. Useful directly on this
    -- config's own Lua as it moves across Neovim versions.
    "StefanBartl/migrate.nvim",
    dependencies = { "StefanBartl/lib.nvim" },
    cmd = { "MigrateOpt", "MigrateNotify", "MigrateHl", "MigrateLsp" },
    opts = {}, -- opt + notify + hl + lsp all enabled by default
  },

  {
    "StefanBartl/markdown.nvim",
    ft = { "markdown", "mdx", "md" },
    -- Soft dependency: markdown.nvim's fenced_scope feature consumes
    -- color_my_ascii's fence API when present (falls back to a built-in scanner
    -- otherwise). Listing it here just guarantees load order in this config.
    dependencies = { "StefanBartl/color_my_ascii.nvim" },
    opts = {},
  },

  {
    "StefanBartl/color_my_ascii.nvim",
    ft = "markdown",
    dependencies = { "StefanBartl/lib.nvim" }, -- optional, enables graceful keymap/notify integration
    -- Typing `opts` as ColorMyAscii.Config makes lua_ls offer value completion
    -- inside the config (e.g. `preset = "…"` suggests the fence-line presets).
    -- Requires the plugin's types on the LSP path (lazydev/neodev or workspace lib).
    opts = {
      -- Force the CommonMark-correct heuristic scanner for fence-block
      -- detection instead of treesitter: the installed markdown grammar
      -- version can differ machine-to-machine (no lockfile pinning), and
      -- some versions mis-parse a shorter fence nested inside a longer one
      -- as its own block, causing spurious fence-line highlights.
      treesitter = { block_detection = false },
    },
  },

  {
    "StefanBartl/mdview.nvim",
    dependencies = { "StefanBartl/lib.nvim" },
    build = "npm ci && npm run build:go && npm run build" ,
    ft = { "markdown" },
    cmd = { "MDView" },
    config = function()
      require("mdview").setup({
        browser = {
          -- theme = "github", -- P1-6: neues Theme (auch: catppuccin, dark-dimmed, plain, github) -> FUNKTioNNERTT
          highlighter = "hljs", -- P1-5: shiki-Bug wird untersucht (siehe mdview.nvim-Session-Notizen); hljs bleibt bis dahin Default
          focus = "nvim", -- P2-9: Fokus bleibt in nvim. Bug (jobstart-Quoting) war in b794c27 bereits gefixt, jetzt aktiviert.

          cursor_marker = "caret",
        },
        -- Release-Variante (v0.3.0 von GitHub Releases, kein Toolchain nötig).
        -- Die dev/standalone-Overrides zeigten auf E:/repos (Checkout liegt jetzt
        -- unter C:/repos) und auf mdview-server.exe - `npm run build:go` erzeugt
        -- unter Windows aber mdview-server OHNE .exe. Zum Testen eines lokal
        -- gebauten Relays (siehe docs/development.md) wieder einkommentieren:
        -- dev = {
          -- binary_path = vim.env.REPOS_DIR .. "/mdview.nvim/native/server/mdview-server",
          -- web_root = vim.env.REPOS_DIR .. "/mdview.nvim/dist/client",
        -- },
        -- standalone = {
          -- binary_path = vim.env.REPOS_DIR .. "/mdview.nvim/native/server/mdview-server",
        -- },
        experimental = {
          line_diff = true, -- P?: nur geänderte Zeilen senden -> FUnktnioert -> postives/negatives abwägen ob default
          click_navigate = true, -- P0-3: relativer Link öffnet Datei in nvim -> FUNKTIONERT -> als Default setzen
          reverse_scroll = true, -- P1: im Browser scrollen bewegt nvim-Cursor -> funktioniert fast ideal (siehe feedback punkte)
          -- webtransport = true,  -- fällt transparent auf WebSocket zurück (kein Backend) --> FUnktinoert -> abwägen ob DEFULT positives/negatives
        },
      })
    end,
  },
  {
    "StefanBartl/recommender.nvim",
    ft = { "lua" },
    cmd = { "Recommender" },
    opts = {},
  },

  {
    "StefanBartl/language.nvim",
    event = "VeryLazy",
    dependencies = {
      "StefanBartl/lib.nvim",
      "folke/trouble.nvim", -- optional: nicer list; pcall-guarded in the plugin
    },
    config = function()
      require("language").setup({
        spell = {
          -- Panel is the default UI; set view = "quickfix" for the classic
          -- diagnostics + quickfix session flow instead.
          ui = { view = "picker", preview = true },
          -- Covers general nvim/Lua plugin-dev vocabulary (nvim, buffer,
          -- function, table, bindings, ...) so `:Spellcheck de` stops
          -- flagging it in German notes about plugin development.
          programming_dict = true,
          -- Tricentis/TOSCA support vocabulary, same reasoning — see
          -- lua/spell_wordlists.lua. Load unconditionally: a few hundred
          -- `:spellgood!` calls, scheduled off the hot path, is not worth
          -- gating behind machine.is("workstation").
          extra_wordlists = require("spell_wordlists"),
        },
        -- The commands (:Translate/:TranslateReplace/...) already work with
        -- zero config (engine = "google", keyless, is the plugin's own
        -- default) — this just claims the motion/visual keymaps, off by
        -- default upstream "to avoid claiming keys". <leader>lt sits next to
        -- this config's other <leader>l* (LSP/language) bindings; <leader>t*
        -- itself is already all tab-navigation here.
        translate = {
          keymaps = { operator = "<leader>lt", visual = "<leader>lt" },
        },
      })
    end,
  },
})

return plugins.export()
