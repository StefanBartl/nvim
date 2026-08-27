---@module 'config.lazygit'
--- Bridge that lets LazyGit custom commands open files in the *parent* Neovim.
---
--- Registers the user commands that LazyGit calls via `nvr` (see README.md):
---   :LazygitBadd    <path>  -> add as background buffer        (LazyGit `O`)
---   :LazygitReplace <path>  -> replace the visible editor file (LazyGit `<C-o>`)
---
--- All logic lives in sibling files; this stays a thin wiring layer:
---   resolve_path.lua     path normalization (repo-relative -> absolute)
---   actions/badd.lua     :badd action
---   actions/replace.lua  focus-safe replace action

local notify = require("lib.nvim.notify").create("[cfg.lazygit]")
local usercmd = require("lib.nvim.bindings.usercmd")

local M = {}

--- Register the `:LazygitBadd` / `:LazygitReplace` commands. Idempotent; meant to
--- be called from the LazyGit plugin `config` hook.
function M.setup()
  if vim.fn.executable("nvr") == 0 then
    notify.warn(
      "nvr not found in PATH — LazyGit O/<C-o> need neovim-remote (pip install neovim-remote)"
    )
  end

  usercmd.create("LazygitBadd", function(opts)
    require("config.lazygit.actions.badd").run(opts.args)
  end, {
    nargs = 1, -- keeps spaces as part of the single path argument
    desc = "[LazyGit] Add file to buffer list (called via nvr)",
  })

  usercmd.create("LazygitReplace", function(opts)
    require("config.lazygit.actions.replace").run(opts.args)
  end, {
    nargs = 1,
    desc = "[LazyGit] Replace visible editor buffer with file (called via nvr)",
  })
end

return M
