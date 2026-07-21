---@module 'config.snacks.mappings.standard'
--- Keymap definitions previously calling `snacks.picker.*` directly. Routed
--- through pickers.nvim instead, so they work the same regardless of which
--- picker engine is active (telescope/fzf-lua/snacks) — see
--- pickers.nvim's docs/BUILTINS.md and docs/COMMANDS.md.
---
--- Three dispatch shapes:
---   scope_action(scope, action)  -- files/grep with pickers.nvim's own
---                                    roots/find-flags handling, e.g. cwd files
---   builtin(name, opts?)         -- native pickers (git/lsp/search/…),
---                                    dispatched to whichever engine is active
---   call(fn)                     -- NOT a picker (snacks.explorer()) — stays
---                                    a direct snacks call, out of scope for
---                                    pickers.nvim entirely
---
--- Only the previously *active* (non-commented) keymaps from the old version
--- of this file are reproduced here. More native pickers are available via
--- `:Pickers builtin <Tab>` if you want to bind additional ones yourself.

local M = {}

---@param scope string
---@param action "files"|"grep"
local function scope_action(scope, action)
  return function()
    local ok, cmd = pcall(require, "pickers.command")
    if not ok then
      return
    end
    cmd.handle({ fargs = { scope, action } })
  end
end

---@param name string
---@param opts table|nil
local function builtin(name, opts)
  return function()
    local ok, builtins = pcall(require, "pickers.builtins")
    if not ok then
      return
    end
    builtins.run(name, opts)
  end
end

--- Safely require snacks and call a non-picker function (e.g. explorer).
--- @param fn fun(snacks: table)
local function call(fn)
  return function()
    local ok, snacks = pcall(require, "snacks")
    if not ok then
      return
    end
    fn(snacks)
  end
end

--- Return keymap table compatible with lazy.nvim `keys = ...`.
--- Each entry follows: { lhs, rhs, mode?, desc?, ... }
--- @return table[]
function M.keys()
  ---@type table[]
  local maps = {}

  ---------------------------------------------------------------------------
  -- Top pickers & explorer
  ---------------------------------------------------------------------------

  maps[#maps + 1] = {
    "<leader>:",
    builtin("command_history"),
    mode = "n",
    desc = "[pickers] Command History",
  }

  maps[#maps + 1] = {
    "<leader>N",
    builtin("notifications"),
    mode = "n",
    desc = "[pickers] Notification History",
  }

  maps[#maps + 1] = {
    "<leader>F",
    call(function(snacks)
      snacks.explorer()
    end),
    mode = "n",
    desc = "[snacks] File Explorer",
  }

  ---------------------------------------------------------------------------
  -- Find
  ---------------------------------------------------------------------------

  maps[#maps + 1] = {
    "<leader>ff",
    scope_action("cwd", "files"),
    mode = "n",
    desc = "[pickers] Find Files",
  }

  maps[#maps + 1] = {
    "<leader>pro",
    builtin("projects"),
    mode = "n",
    desc = "[pickers] Projects",
  }

  maps[#maps + 1] = {
    "<leader>old",
    builtin("recent"),
    mode = "n",
    desc = "[pickers] Recent Files",
  }

  ---------------------------------------------------------------------------
  -- Git
  ---------------------------------------------------------------------------

  maps[#maps + 1] = {
    "<leader>gb",
    builtin("git_branches"),
    mode = "n",
    desc = "[pickers] Git Branches",
  }

  maps[#maps + 1] = {
    "<leader>gl",
    builtin("git_log"),
    mode = "n",
    desc = "[pickers] Git Log",
  }

  maps[#maps + 1] = {
    "<leader>gL",
    builtin("git_log_line"),
    mode = "n",
    desc = "[pickers] Git Log Line",
  }

  maps[#maps + 1] = {
    "<leader>gs",
    builtin("git_status"),
    mode = "n",
    desc = "[pickers] Git Status",
  }

  maps[#maps + 1] = {
    "<leader>gS",
    builtin("git_stash"),
    mode = "n",
    desc = "[pickers] Git Stash",
  }

  maps[#maps + 1] = {
    "<leader>gd",
    builtin("git_diff"),
    mode = "n",
    desc = "[pickers] Git Diff (Hunks)",
  }

  maps[#maps + 1] = {
    "<leader>gf",
    builtin("git_log_file"),
    mode = "n",
    desc = "[pickers] Git Log File",
  }

  ---------------------------------------------------------------------------
  -- GitHub
  ---------------------------------------------------------------------------

  maps[#maps + 1] = {
    "<leader>gi",
    builtin("gh_issue"),
    mode = "n",
    desc = "[pickers] GitHub Issues (open)",
  }

  maps[#maps + 1] = {
    "<leader>gI",
    builtin("gh_issue_all"),
    mode = "n",
    desc = "[pickers] GitHub Issues (all)",
  }

  maps[#maps + 1] = {
    "<leader>gp",
    builtin("gh_pr"),
    mode = "n",
    desc = "[pickers] GitHub Pull Requests (open)",
  }

  maps[#maps + 1] = {
    "<leader>gP",
    builtin("gh_pr_all"),
    mode = "n",
    desc = "[pickers] GitHub Pull Requests (all)",
  }

  ---------------------------------------------------------------------------
  -- Grep
  ---------------------------------------------------------------------------

  maps[#maps + 1] = {
    "<leader>cb",
    builtin("lines"),
    mode = "n",
    desc = "[pickers] Buffer Lines",
  }

  maps[#maps + 1] = {
    "<leader>cB",
    builtin("grep_buffers"),
    mode = "n",
    desc = "[pickers] Grep Open Buffers",
  }

  maps[#maps + 1] = {
    "<leader><leader>",
    scope_action("cwd", "grep"),
    mode = "n",
    desc = "[pickers] Grep",
  }

  ---------------------------------------------------------------------------
  -- Search
  ---------------------------------------------------------------------------

  maps[#maps + 1] = {
    "<leader>com",
    builtin("commands"),
    mode = "n",
    desc = "[pickers] Commands",
  }

  maps[#maps + 1] = {
    "<leader>fk",
    builtin("keymaps"),
    mode = "n",
    desc = "[pickers] Keymaps",
  }

  maps[#maps + 1] = {
    "<leader>sM",
    builtin("man"),
    mode = "n",
    desc = "[pickers] Man Pages",
  }

  maps[#maps + 1] = {
    "<leader>help",
    builtin("help"),
    mode = "n",
    desc = "[pickers] Help Pages",
  }

  maps[#maps + 1] = {
    "<leader>ch",
    builtin("colorschemes"),
    mode = "n",
    desc = "[pickers] Colorschemes",
  }

  ---------------------------------------------------------------------------
  -- LSP
  ---------------------------------------------------------------------------

  maps[#maps + 1] = {
    "GD",
    builtin("lsp_definitions"),
    mode = "n",
    desc = "[pickers] Goto Definition",
  }

  maps[#maps + 1] = {
    "gD",
    builtin("lsp_declarations"),
    mode = "n",
    desc = "[pickers] Goto Declaration",
  }

  maps[#maps + 1] = {
    "GR",
    builtin("lsp_references"),
    mode = "n",
    desc = "[pickers] References",
    nowait = true,
  }

  maps[#maps + 1] = {
    "GI",
    builtin("lsp_implementations"),
    mode = "n",
    desc = "[pickers] Goto Implementation",
  }

  maps[#maps + 1] = {
    "GY",
    builtin("lsp_type_definitions"),
    mode = "n",
    desc = "[pickers] Goto Type Definition",
  }

  maps[#maps + 1] = {
    "GAI",
    builtin("lsp_incoming_calls"),
    mode = "n",
    desc = "[pickers] Calls Incoming",
  }

  maps[#maps + 1] = {
    "GAO",
    builtin("lsp_outgoing_calls"),
    mode = "n",
    desc = "[pickers] Calls Outgoing",
  }

  maps[#maps + 1] = {
    "<leader>SS",
    builtin("lsp_symbols"),
    mode = "n",
    desc = "[pickers] LSP Symbols",
  }

  maps[#maps + 1] = {
    "<leader>sS",
    builtin("lsp_workspace_symbols"),
    mode = "n",
    desc = "[pickers] LSP Workspace Symbols",
  }

  return maps
end

return M
