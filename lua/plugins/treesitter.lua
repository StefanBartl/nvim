---@module 'plugins.treesitter'
---@brief Modern Treesitter setup (Neovim 0.12+, no deprecated install API)

local notify = require("lib.nvim.notify").create("[plugins.treesitter]")

-- Parsers that are never a buffer's own filetype - they only ever appear via
-- treesitter *injections* (LuaCATS doc-comments in ---@... lua comments,
-- :help vimdoc syntax). The old master-branch nvim-treesitter auto-installed
-- everything listed in `ensure_installed`; this "modern" API only installs
-- parsers on demand, so without an explicit step here a missing injection
-- parser degrades silently to plain `comment` highlighting instead of an
-- error - e.g. ---@module went unhighlighted for a while because luadoc.so
-- was never installed (see docs/ROADMAP/personal/lsp.md, 2026-07-26).
local INJECTION_PARSERS = { "luadoc", "vimdoc" }

local plugins = require("plugins.control.mode").new()

-- Repos hier zentral deaktivieren (Basename -> "disabled"), statt weiter unten
-- im jeweiligen Spec `enabled = false` zu setzen.
--
-- `nvim-treesitter-textobjects` ist der Schalter fuer die
-- Struktur-Bewegung `[b`/`]b` (bindings/mappings/treesitter_structure.lua):
-- wird es hier abgeschaltet, bindet das Mapping-Modul die beiden Tasten gar
-- nicht erst, statt sie zu belegen und beim Druecken zu klagen. Die Queries
-- unter `after/queries/*/textobjects.scm` sind dann ebenfalls wirkungslos,
-- aber harmlos -- sie erweitern nur eine Capture, die niemand abfragt.
plugins.modes({
  -- ["nvim-treesitter-textobjects"] = "disabled",
  -- ["nvim-treesitter-context"] = "disabled",
})

plugins.add({
  ---------------------------------------------------------------------------
  -- Core Treesitter
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",

    lazy = false,

    build = ":TSUpdate",

    -- Pinned: main@c82bf96f (2026-04-01, "feat!: drop support for Nvim 0.11")
    -- rewrote get_available()/parser dedup to call vim.list.unique(), which
    -- only exists on Neovim 0.12+. On 0.11.x that crashes EVERY parser
    -- install ("attempt to index field 'list' (a nil value)"), regardless of
    -- language - not a markdown-specific issue. f873ec29 is the last commit
    -- before that health-check bump (still requires only nvim-0.11). Unpin
    -- once this Neovim is on 0.12, or if nvim-treesitter restores 0.11
    -- compat.
    commit = "f873ec2955098fc4b7c3abfe891bdd49fa7947e2",

    config = function()
      -----------------------------------------------------------------------
      -- Guard module
      -----------------------------------------------------------------------
      local guards = require("lib.nvim.treesitter.guard")
      local Autocmd = require("lib.nvim.bindings.autocmd")

      -----------------------------------------------------------------------
      -- Ensure injection-only parsers (see INJECTION_PARSERS above)
      -----------------------------------------------------------------------
      do
        local ok_ts, ts = pcall(require, "nvim-treesitter")
        if ok_ts and type(ts.get_installed) == "function" then
          local installed = {}
          for _, lang in ipairs(ts.get_installed()) do
            installed[lang] = true
          end

          local missing = vim.tbl_filter(function(lang)
            return not installed[lang]
          end, INJECTION_PARSERS)

          if #missing > 0 and type(ts.install) == "function" then
            notify.info("Installing missing injection parsers: " .. table.concat(missing, ", "))
            pcall(ts.install, missing)
          end
        end
      end

      -----------------------------------------------------------------------
      -- Parser install policy for regular (buffer-filetype) parsers.
      -- See docs/NOTES/ExternPlugins/Bindings/Usercmds/Treesitter.md and
      -- E:\repos\lib.nvim\lua\lib\nvim\treesitter\parser_policy\README.md.
      -----------------------------------------------------------------------
      local parser_policy = require("lib.nvim.treesitter.parser_policy")
      parser_policy.setup({ mode = "prompt" })

      require("lib.nvim.bindings.usercmd").create("TSParserPolicy", function(cmd_args)
        local mode = cmd_args.args
        if mode == "" then
          notify.info(
            ("mode=%s declined=%s"):format(
              parser_policy.get_mode(),
              table.concat(parser_policy.declined(), ", ")
            )
          )
        elseif mode == "reset" then
          parser_policy.reset_declined()
          notify.info("cleared declined-parser list")
        else
          local ok, err = parser_policy.set_mode(mode)
          if ok then
            notify.info("mode set to " .. mode)
          else
            notify.warn(err)
          end
        end
      end, {
        nargs = "?",
        complete = function()
          return { "off", "prompt", "auto", "reset" }
        end,
        desc = "Show/set the treesitter parser install policy (off|prompt|auto|reset)",
      })

      -----------------------------------------------------------------------
      -- Highlight activation
      -----------------------------------------------------------------------
      Autocmd.create("FileType", function(args)
        if not guards.is_enabled(args.buf) then
          return
        end

        local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
        if lang then
          parser_policy.ensure(lang, {
            on_installed = function()
              pcall(vim.treesitter.start, args.buf)
            end,
          })
        end

        -- pcall: no-installed-parser is a real error from vim.treesitter.start,
        -- not a silent no-op - expected here whenever parser_policy just
        -- queued a prompt/install instead of installing synchronously.
        pcall(vim.treesitter.start, args.buf)
      end)

      -----------------------------------------------------------------------
      -- Folding
      -----------------------------------------------------------------------
      Autocmd.create("FileType", function(args)
        if guards.is_enabled(args.buf) then
          vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.wo.foldmethod = "expr"
        end
      end)

      -----------------------------------------------------------------------
      -- Indentation (experimental)
      -----------------------------------------------------------------------
      Autocmd.create("FileType", function(args)
        if guards.is_enabled(args.buf) then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end)
    end,
  },

  ---------------------------------------------------------------------------
  -- Textobjects
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    lazy = false,
  },

  ---------------------------------------------------------------------------
  -- Context (sticky code context window)
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter-context",

    event = "BufReadPost",

    opts = {
      enable = true,
      max_lines = 3,
    },
  },
})

return plugins.export()
