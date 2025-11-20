---@module 'custom.repo_pickers.register'
--- Registration of public user commands and optional engine-specific extras.

local actions = require("custom.repo_pickers.actions")
local router = require("custom.repo_pickers.select.router")
local M = {}

--- Register the minimal public API: RepoFiles / RepoGrep.
--- Optionally, if cfg.expose_engine_cmds is true, also register engine-specific commands.
---@param cfg RepoPickersConfig
---@return nil
function M.usercmds(cfg)
  -- Minimal public interface (always registered)
  vim.api.nvim_create_user_command("RepoFiles", function()
    local sel = router.mk_selector(cfg, nil) -- router chooses based on cfg.selector and engine hint inside actions
    actions.repo_files(cfg, sel)
  end, { desc = "Select repository → files (engine per config)" })

  vim.api.nvim_create_user_command("RepoGrep", function()
    local sel = router.mk_selector(cfg, nil)
    actions.repo_grep(cfg, sel)
  end, { desc = "Select repository → live_grep (engine per config)" })

  -- Engine-specific commands are disabled by default; opt-in via expose_engine_cmds=true
  if not cfg.expose_engine_cmds then
    return
  end

  -- Optional: expose engine-specific commands (kept for power users)
  local function sreq(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
  end

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
      local sel = router.mk_selector(cfg, "fzf")
      actions.repo_files(vim.tbl_extend("force", cfg, { engine = "fzf" }), sel)
    end
  end, { desc = "[EXPOSED] fzf-lua: files (optional <dir>)", nargs = "?" })

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
      local sel = router.mk_selector(cfg, "fzf")
      actions.repo_grep(vim.tbl_extend("force", cfg, { engine = "fzf" }), sel)
    end
  end, { desc = "[EXPOSED] fzf-lua: live_grep (optional <dir>)", nargs = "?" })

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
      local sel = router.mk_selector(cfg, "telescope")
      actions.repo_files(vim.tbl_extend("force", cfg, { engine = "telescope" }), sel)
    end
  end, { desc = "[EXPOSED] Telescope: find_files (optional <dir>)", nargs = "?" })

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
      local sel = router.mk_selector(cfg, "telescope")
      actions.repo_grep(vim.tbl_extend("force", cfg, { engine = "telescope" }), sel)
    end
  end, { desc = "[EXPOSED] Telescope: live_grep (optional <dir>)", nargs = "?" })

  -- Optional short aliases; also gated by expose_engine_cmds
  vim.api.nvim_create_user_command("RepoFilesFzf", function(opts)
    vim.api.nvim_cmd({ cmd = "RepoFindFilesFzf", args = opts.fargs or {} }, {})
  end, { desc = "[ALIAS] RepoFindFilesFzf", nargs = "?" })
  vim.api.nvim_create_user_command("RepoFilesTelescope", function(opts)
    vim.api.nvim_cmd({ cmd = "RepoFindFilesTelescope", args = opts.fargs or {} }, {})
  end, { desc = "[ALIAS] RepoFindFilesTelescope", nargs = "?" })
end

---@param cfg RepoPickersConfig
---@return nil
function M.keymaps(cfg)
  local k = cfg.keymaps_lhs
  if not k then
    return
  end
  if type(k.repo_files) == "string" and k.repo_files ~= "" then
    vim.keymap.set("n", k.repo_files, function()
      require("custom.repo_pickers")._entry_files()
    end, { noremap = true, silent = true, desc = "Repo: files" })
  end
  if type(k.repo_grep) == "string" and k.repo_grep ~= "" then
    vim.keymap.set("n", k.repo_grep, function()
      require("custom.repo_pickers")._entry_grep()
    end, { noremap = true, silent = true, desc = "Repo: grep" })
  end
end

return M
