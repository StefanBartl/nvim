---@module 'custom.repo_pickers.register'
--- User-command and keymap registration for repo_pickers.

local actions  = require("custom.repo_pickers.actions")

local M = {}

--- Safe require helper.
--- @param name string
--- @return any|nil
local function sreq(name) local ok, mod = pcall(require, name); return ok and mod or nil end

--- Register module-owned user commands.
--- All engine-specific commands accept an optional path argument (nargs="?").
--- If no argument is given, they trigger the repo selection and then run.
--- @param cfg RepoPickersConfig
--- @param selector fun(cfg:RepoPickersConfig, repos:RepoDir[], on_choice:fun(dir:RepoDir))
--- @return nil
function M.usercmds(cfg, selector)
  -- Generic, engine-from-config entrypoints
  -- vim.api.nvim_create_user_command("RepoFiles", function()
  --   actions.repo_files(cfg, selector)
  -- end, { desc = "Select a repository then open file picker (engine-configured)" })

  -- vim.api.nvim_create_user_command("RepoGrep", function()
  --   actions.repo_grep(cfg, selector)
  -- end, { desc = "Select a repository then open live_grep (engine-configured)" })

  -- fzf-lua concrete commands
  vim.api.nvim_create_user_command("RepoFindFilesFzf", function(opts)
    local dir = opts and opts.fargs and opts.fargs[1] or nil
    local fzf = sreq("fzf-lua")
    if not fzf then
      vim.notify("repo_pickers: fzf-lua not available", vim.log.levels.ERROR)
      return
    end
    if dir and dir ~= "" then
      fzf.files({ cwd = dir })
    else
      actions.repo_files(vim.tbl_extend("force", cfg, { engine = "fzf" }), selector)
    end
  end, { desc = "fzf-lua: files (optional <dir>)", nargs = "?" })

  vim.api.nvim_create_user_command("RepoGrepFzf", function(opts)
    local dir = opts and opts.fargs and opts.fargs[1] or nil
    local fzf = sreq("fzf-lua")
    if not fzf then
      vim.notify("repo_pickers: fzf-lua not available", vim.log.levels.ERROR)
      return
    end
    if dir and dir ~= "" then
      fzf.live_grep({ cwd = dir })
    else
      actions.repo_grep(vim.tbl_extend("force", cfg, { engine = "fzf" }), selector)
    end
  end, { desc = "fzf-lua: live_grep (optional <dir>)", nargs = "?" })

  -- Telescope concrete commands
  vim.api.nvim_create_user_command("RepoFindFilesTelescope", function(opts)
    local dir = opts and opts.fargs and opts.fargs[1] or nil
    local tb = sreq("telescope.builtin")
    if not tb then
      vim.notify("repo_pickers: telescope.builtin not available", vim.log.levels.ERROR)
      return
    end
    if dir and dir ~= "" then
      tb.find_files({ cwd = dir })
    else
      actions.repo_files(vim.tbl_extend("force", cfg, { engine = "telescope" }), selector)
    end
  end, { desc = "Telescope: find_files (optional <dir>)", nargs = "?" })

  vim.api.nvim_create_user_command("RepoGrepTelescope", function(opts)
    local dir = opts and opts.fargs and opts.fargs[1] or nil
    local tb = sreq("telescope.builtin")
    if not tb then
      vim.notify("repo_pickers: telescope.builtin not available", vim.log.levels.ERROR)
      return
    end
    if dir and dir ~= "" then
      tb.live_grep({ cwd = dir })
    else
      actions.repo_grep(vim.tbl_extend("force", cfg, { engine = "telescope" }), selector)
    end
  end, { desc = "Telescope: live_grep (optional <dir>)", nargs = "?" })
end

--- Optional keymaps (call tiny entry wrappers).
--- @param cfg RepoPickersConfig
--- @return nil
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
