---@module 'plugins.personal'
--- Personal and local development plugins (myterm, mygrep, cmdlog, etc.)

if not vim.env.REPOS_DIR then
  vim.notify("[PLUGINS PERSONAL] Environment variable 'REPOS_DIR' not set. Personal plugins not available.", 3)
  return {}
end

---@type LazyPluginSpec[]
return {

	{
    dir = vim.fn.expand(vim.env.REPOS_DIR .. "/mdview.nvim"),
    name = "mdview.nvim",
    lazy = false,
    -- do not automatically run setup; the plugin exposes :MarkdownViewStart / :MarkdownViewStop
    config = function()
      -- optional: expose server port if different than default
      -- vim.g.mdview_server_port = 43219
      -- minimal setup placeholder (future: require('mdview').setup({...}))
      if pcall(require, "mdview") then
         require("mdview").setup()
      else
        vim.notify("mdview.nvim: module not found after loading plugin files", vim.log.levels.ERROR)
      end
    end,
    -- make the commands discoverable to lazy if desired
    cmd = { "MarkdownViewStart", "MarkdownViewStop" },
  },

  {
    -- "StefanBartl/nvim-cmdlog",
    dir = vim.env.REPOS_DIR .. "/nvim-cmdlog",
    lazy = false,
    cmd = { "CmdlogOpen", "CmdlogSearch" }, -- or map keys
    -- keys = {
    -- 	{ "<leader>cl", "<cmd>CmdlogOpen<cr>", desc = "Cmdlog: Open" },
    -- },
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- do NOT hard-depend on telescope if you also support fzf-lua
      -- load whichever backend on demand in your code
      -- { "nvim-telescope/telescope.nvim" },
      -- { "ibhagwan/fzf-lua",             optional = true },
    },
    config = function()
      require("cmdlog").setup({
        -- defer backend require until actually used
        picker = "telescope",
        -- picker = "fzf",
      })
    end,
  },

  -- {
  -- 	dir = [[E:\repos\objtrack]], -- Repo-Root mit lua/ darunter
  -- 	name = "objtrack",
  -- 	main = "objtrack",         -- lädt lua/objtrack/init.lua als Haupteinstieg
  -- 	lazy = false,              -- fürs Debuggen: hart beim Start laden
  -- 	config = function()
  -- 		require("objtrack").setup({
  -- 			view_mode = "float",
  -- 			prefer_telescope = true,
  -- 			auto_rescan = false,
  -- 			border = "rounded",
  -- 			max_preview_lines = 5000,
  -- 			blacklist_filetypes = { "help", "TelescopePrompt", "neo-tree", "lazy" },
  -- 			keymaps = { pick = "<leader>op", rescan = "<leader>os" },
  -- 		})
  -- 	end,
  -- },

  {
    dir = vim.fn.expand(vim.env.REPOS_DIR .. "/replacer"),
    -- "StefanBartl/replacer",
    cmd = { "Replace" },
    dependencies = {
      -- wähle je nach Engine:
      "ibhagwan/fzf-lua", -- für engine="fzf"
      -- "nvim-telescope/telescope.nvim", -- für engine="telescope"
    },
    config = function()
			---@diagnostic disable-next-line
      require("replacer").setup({
        engine = "telescope",
        -- engine = "telescope",
        default_scope = "%",
      })
    end,
  },

  {
    dir = vim.env.REPOS_DIR .. "/gopath.nvim", -- or "wkdsteve/gopath.nvim"
    opts = {
      -- Modi: "builtin" | "treesitter" | "lsp" | "hybrid"
      mode = "hybrid",

      -- Provider-Reihenfolge für "hybrid":
      -- 1) Treesitter-Pass (inkl. value_origin ⇒ springt zur Initialisierung)
      -- 2) LSP-Definition
      -- 3) Builtin (cfile, require-Pfad)
      order = { "treesitter", "lsp", "builtin" },

      -- LSP Sync Timeout in ms (kurz halten, um UI nie zu blocken)
      lsp_timeout_ms = 200,

      -- Sprachen: wenn `resolvers` fehlt/nil -> es werden ALLE Resolver für die Sprache genutzt.
      languages = {
        lua = {
          enable = true,
          -- resolvers = nil,  -- nil = alle (require_path, binding_index, alias_index, chain,
          --        value_origin, symbol_locator)
        },
        -- Beispiel für spätere Sprachen:
        -- typescript = { enable = true, resolvers = nil },
      },
    },
    cmd = { "GopathResolve", "GopathOpen", "GopathCopy", "GopathDebugUnderCursor" },
    keys = {
      {
        "gP",
        function()
          require("gopath").commands.resolve_and_open("edit")
        end,
        desc = "gopath: open here",
      },
      {
        "g|",
        function()
          require("gopath").commands.resolve_and_open("window")
        end,
        desc = "gopath: open in split",
      },
      {
        "g\\",
        function()
          vim.cmd("GopathOpen window_vsplit")
        end,
        desc = "gopath: open in vsplit",
      },
      {
        "g}",
        function()
          require("gopath").commands.resolve_and_open("tab")
        end,
        desc = "gopath: open in tab",
      },
      {
        "gY",
        function()
          vim.cmd("GopathCopy")
        end,
        desc = "gopath: copy path:line:col",
      },
      {
        "g?",
        function()
          vim.cmd("GopathDebugUnderCursor")
        end,
        desc = "gopath: debug under cursor",
      },
    },
  },

  {
    -- dir = vim.fn.expand(vim.env.REPOS_DIR .. "/mdlinks"),
    "StefanBartl/mdlinks",
    ft = "markdown",
    config = function()
      require("mdlinks.config").setup({
        debug = true,
        open_url_cmd = { "cmd.exe", "/c", "start", "" },
        open_cmd = { "cmd.exe", "/c", "start", "" },
        anchor_levels = { 1, 2, 3, 4, 5, 6 }, -- ATX levels to match
      })
    end,
  },

  -- nvim-containers: Manage container engines from Neovim
  -- {
  --   dir = vim.fs.joinpath(vim.env.REPOS_DIR, "/nvim-containers"),
  --   event = "VeryLazy",
  --   config = function()
  --     require("containers").setup({})
  --   end,
  -- },
  --
  -- nvim-cmdlog: Command history management (remote plugin)
  -- Optional: local dev version of cmdlog
  -- {
  --   dir = repo("nvim-cmdlog"),
  --   cond = exists(repo("nvim-cmdlog")),
  --   config = function()
  --     require("cmdlog").setup({ picker = "telescope" })
  --   end,
  -- },

  --[[

    -- reposcope.nvim: GitHub repo explorer
    {
      dir = repo("reposcope.nvim"),
      cond = exists(repo("reposcope.nvim")),
      name = "reposcope",
      event = "VeryLazy",
      config = function()
        require("reposcope.init").setup({})
      end,
    },

    ]]
  --

  -- myterm.local: Custom terminal interface with layout switching
  --[[
    {
      name = "myterm.local",
      dir = myterm_local_dir(),
      cond = exists(myterm_local_dir()),
      lazy = false,
      config = function()
        require("custom.myterm")
      end,
    },
    ]]
  --

  -- mygrep.nvim: Grep interface with memory, history, favorites
  -- {
  --   dir = repo("mygrep.nvim"),
  --   cond = exists(repo("mygrep.nvim")),
  --   name = "mygrep",
  --   lazy = false,
  --   config = function()
  --     require("mygrep").setup({
  --       tool_picker_style = "ui",
  --     })
  --   end,
  -- },

  {
    -- Pfad anpassen: hier als lokales Modul im config-Repo
    dir = vim.fn.stdpath("config") .. "/lua/usrcmds/filecycle",
    name = "filecycle",
    lazy = true,
    config = function()
      require("usrcmds.filecycle").setup({
        open_target = "current", -- "current"|"split"|"vsplit"|"tab"|"background"
        keep_focus = true, -- bei Split/Vsplit Fokus im Ursprungsfenster behalten
        include_hidden = false, -- Dotfiles ignorieren
        wrap = true, -- am Ende/Anfang umbrechen
        follow_symlinks = true, -- echte Pfade für Vergleich/Öffnen nutzen
        root = "buffer_dir", -- "buffer_dir"|"cwd"
        confirm_on_modified = true, -- :confirm edit bei geänderten Buffern
        case_insensitive = true, -- alphabetische Sortierung/Matching ohne Groß/Kleinschreibung
      })
    end,
    keys = {
      {
        "<leader>nf",
        function()
          require("usrcmds.filecycle").open("next")
        end,
        desc = "[filecycle] Next file",
      },
      {
        "<leader>pf",
        function()
          require("usrcmds.filecycle").open("prev")
        end,
        desc = "[filecycle] Previous file",
      },
    },
    cmd = { "NextFile", "PreviousFile" },
  },
}
