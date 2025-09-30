---@module 'custom.repo_pickers.register'
--- User-command and keymap registration for repo_pickers.

local actions  = require("custom.repo_pickers.actions")
local router   = require("custom.repo_pickers.select.router")
local dispatch = require("custom.repo_pickers.dispatch")
local nvim_create_user_command = vim.api.nvim_create_user_command
local notify = vim.notify

local M = {}

local function sreq(name) local ok, mod = pcall(require, name); return ok and mod or nil end

function M.usercmds(cfg)
  -- Generic entry (engine from cfg at call time; selector matches that engine unless vim_select is forced)
  nvim_create_user_command("RepoFiles", function()
    local eng = dispatch.resolve_engine_for_files(cfg)
    actions.repo_files(cfg, router.mk_selector(cfg, eng))
  end, { desc = "Select repo → file picker (engine-matched selector)" })

  nvim_create_user_command("RepoGrep", function()
    local eng = dispatch.resolve_engine_for_grep(cfg)
    actions.repo_grep(cfg, router.mk_selector(cfg, eng))
  end, { desc = "Select repo → live_grep (engine-matched selector)" })

  -- fzf-lua commands: selector fixed to fzf unless cfg.selector == "vim_select"
  nvim_create_user_command("RepoFilesFzf", function(opts)
    local dir = opts and opts.fargs and opts.fargs[1] or nil
    local fzf = sreq("fzf-lua")
    if not fzf then
      notify("repo_pickers: fzf-lua not available", vim.log.levels.ERROR)
      return
    end
    if dir and dir ~= "" then
      fzf.files({ cwd = dir })
    else
      actions.repo_files(vim.tbl_extend("force", cfg, { engine = "fzf" }), router.mk_selector(cfg, "fzf"))
    end
  end, { desc = "fzf-lua: files (optional <dir>)", nargs = "?" })

  nvim_create_user_command("RepoGrepFzf", function(opts)
    local dir = opts and opts.fargs and opts.fargs[1] or nil
    local fzf = sreq("fzf-lua")
    if not fzf then
      notify("repo_pickers: fzf-lua not available", vim.log.levels.ERROR)
      return
    end
    if dir and dir ~= "" then
      fzf.live_grep({ cwd = dir })
    else
      actions.repo_grep(vim.tbl_extend("force", cfg, { engine = "fzf" }), router.mk_selector(cfg, "fzf"))
    end
  end, { desc = "fzf-lua: live_grep (optional <dir>)", nargs = "?" })

  -- Telescope commands: selector fixed to telescope unless cfg.selector == "vim_select"
  nvim_create_user_command("RepoFilesTelescope", function(opts)
    local dir = opts and opts.fargs and opts.fargs[1] or nil
    local tb = sreq("telescope.builtin")
    if not tb then
      notify("repo_pickers: telescope.builtin not available", vim.log.levels.ERROR)
      return
    end
    if dir and dir ~= "" then
      tb.find_files({ cwd = dir })
    else
      actions.repo_files(vim.tbl_extend("force", cfg, { engine = "telescope" }), router.mk_selector(cfg, "telescope"))
    end
  end, { desc = "Telescope: find_files (optional <dir>)", nargs = "?" })

  nvim_create_user_command("RepoGrepTelescope", function(opts)
    local dir = opts and opts.fargs and opts.fargs[1] or nil
    local tb = sreq("telescope.builtin")
    if not tb then
      notify("repo_pickers: telescope.builtin not available", vim.log.levels.ERROR)
      return
    end
    if dir and dir ~= "" then
      tb.live_grep({ cwd = dir })
    else
      actions.repo_grep(vim.tbl_extend("force", cfg, { engine = "telescope" }), router.mk_selector(cfg, "telescope"))
    end
  end, { desc = "Telescope: live_grep (optional <dir>)", nargs = "?" })
end

function M.keymaps(cfg)
  local k = cfg.keymaps_lhs
  if not k then return end
  if type(k.repo_files) == "string" and k.repo_files ~= "" then
    vim.keymap.set("n", k.repo_files, function()
      require("custom.repo_pickers")._entry_files()
    end, { silent = true, noremap = true, desc = "Repo: files" })
  end
  if type(k.repo_grep) == "string" and k.repo_grep ~= "" then
    vim.keymap.set("n", k.repo_grep, function()
      require("custom.repo_pickers")._entry_grep()
    end, { silent = true, noremap = true, desc = "Repo: grep" })
  end
end

return M
