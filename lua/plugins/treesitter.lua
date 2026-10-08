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

-- Largest buffer (in lines) that still gets the treesitter indentexpr.
-- nvim-treesitter memoizes its whole-tree "indents" capture map by root:id(),
-- which changes on every edit + reparse, so the first Enter / o / O / == after
-- any edit re-runs the query over the ENTIRE tree (O(file size)). Measured on
-- this machine: +12 ms per Enter at 1.6k lines of Lua, +25..50 ms at 2-5k lines,
-- +130 ms at 20k lines of JSON. Above the limit the runtime's own indent script
-- (GetLuaIndent(), GetJSONIndent(), ...) stays in charge; it costs the same as no
-- indentexpr at all. The real fix (a range-limited iter_captures) belongs
-- upstream. Checked once, at FileType time.
local INDENT_MAX_LINES = 2000

local plugins = require("plugins.control.mode").new()

-- Disable repos centrally here (basename -> "disabled"), instead of setting
-- `enabled = false` in each individual spec below.
--
-- `nvim-treesitter-textobjects` is the switch for the `[b`/`]b` structure
-- motion (bindings/mappings/treesitter_structure.lua): disabling it here
-- means the mapping module never binds those two keys at all, instead of
-- binding them and erroring on press. The queries under
-- `after/queries/*/textobjects.scm` become ineffective too, but harmlessly --
-- they only extend a capture nobody queries.
plugins.modes({
  -- ["nvim-treesitter-textobjects"] = "disabled",
})

plugins.add({
  ---------------------------------------------------------------------------
  -- Core Treesitter
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",

    lazy = false,

    build = ":TSUpdate",

    -- Was pinned to main@f873ec29 (2026-04-01) because the next commit,
    -- c82bf96f ("feat!: drop support for Nvim 0.11"), rewrote
    -- get_available()/parser dedup to call vim.list.unique(), which only
    -- exists on Neovim 0.12+ -- crashing EVERY parser install on 0.11.x
    -- ("attempt to index field 'list' (a nil value)"), not a
    -- language-specific issue. Unpinned 2026-10-01 (externe-plugins report
    -- §9, reassessed): this Neovim is 0.12.2, so the blocking requirement is
    -- met. Checked the 85 commits between the pin and upstream main at the
    -- time -- only that one bumped the Neovim floor; the rest are routine
    -- parser/query updates and backward-compatible internal refactors, and
    -- the public API this config calls (get_installed/install/indentexpr,
    -- lua/nvim-treesitter/init.lua) is unchanged. Run `:Lazy update
    -- nvim-treesitter` (or `:Lazy sync`) to actually pull it; highlighting/
    -- folding/indent on a few buffers afterward is the real verification --
    -- a commit-log read isn't a substitute for that.

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
      -- $REPOS_DIR\lib.nvim\lua\lib\nvim\treesitter\parser_policy\README.md.
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
            notify.warn(err or ("could not set mode to " .. tostring(mode)))
          end
        end
      end, {
        nargs = "?",
        complete = function()
          return { "off", "prompt", "auto", "reset" }
        end,
        desc = "Show/set the treesitter parser install policy (off|prompt|auto|reset)",
      })

      -- LUA-96: one named augroup for all three FileType handlers below,
      -- cleared on (re)registration. Without it they land in the global,
      -- groupless set, and re-sourcing the config stacks a second copy of
      -- each -- every `FileType` would then start the parser, set foldexpr
      -- and set indentexpr twice.
      local ts_group = Autocmd.group("WkdTreesitterFileType", true)

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
      end, { group = ts_group, desc = "treesitter: start highlighting for this filetype" })

      -----------------------------------------------------------------------
      -- Folding
      -----------------------------------------------------------------------
      Autocmd.create("FileType", function(args)
        if guards.is_enabled(args.buf) then
          -- [0][0] = :setlocal. A plain vim.wo.<opt> = ... has :set semantics and
          -- would also overwrite the default every later window inherits (see
          -- :help vim.wo); nvim-treesitter's README and the runtime use [0][0].
          vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.wo[0][0].foldmethod = "expr"
        end
      end, { group = ts_group, desc = "treesitter: use treesitter folding for this filetype" })

      -----------------------------------------------------------------------
      -- Indentation (experimental)
      -----------------------------------------------------------------------
      Autocmd.create("FileType", function(args)
        -- Skipping (not clearing) leaves whatever the runtime indent script set.
        if
          guards.is_enabled(args.buf)
          and vim.api.nvim_buf_line_count(args.buf) <= INDENT_MAX_LINES
        then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end, {
        group = ts_group,
        desc = "treesitter: use treesitter indentation for this filetype (small buffers only)",
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- Textobjects
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    lazy = false,
  },
})

return plugins.export()
