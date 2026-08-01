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

return {
  ---------------------------------------------------------------------------
  -- Core Treesitter
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",

    lazy = false,

    build = ":TSUpdate",

    config = function()
      -----------------------------------------------------------------------
      -- Guard module
      -----------------------------------------------------------------------
      local guards = require("lib.nvim.treesitter.guard")
      local Autocmd = require("lib.nvim.autocmd")

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
      -- Highlight activation
      -----------------------------------------------------------------------
      Autocmd.create("FileType", function(args)
        if guards.is_enabled(args.buf) then
          vim.treesitter.start(args.buf)
        end
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
          vim.bo[args.buf].indentexpr =
            "v:lua.require'nvim-treesitter'.indentexpr()"
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
}
