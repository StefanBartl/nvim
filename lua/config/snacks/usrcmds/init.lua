---@module 'config.snacks.usrcmds'
---@brief Main entrypoint for snacks usercommands
---@description
--- This module provides a centralized usercommand system for snacks.nvim features.
--- It orchestrates all submodules and provides the main `:Snacks` command with
--- autocompletion support.
---
--- Usage:
---   require("config.snacks.usrcmds").setup({
---     find = { enabled = true },
---     git = { enabled = true },
---     -- ... more options
---   })
---
--- After setup, commands are available:
---   :SnacksFindFiles
---   :SnacksGitBranches
---   :Snacks find files    (with autocompletion)
---   :Snacks git branches  (with autocompletion)

local usercmd = require("lib.usercmd")
local notify = require("lib.notify").create("[config.snacks.usrcmds]")

local M = {}

---@type boolean
local is_setup = false

---Default configuration
---@type config.snacks.usrcmds.Opts
local default_opts = {
  find = {
    enabled = true,
  },
  git = {
    enabled = true,
  },
  github = {
    enabled = true,
  },
  grep = {
    enabled = true,
  },
  search = {
    enabled = true,
  },
  lsp = {
    enabled = true,
  },
  misc = {
    enabled = true,
  },
}

---Command mapping for the main :Snacks command
---Format: { category, subcategory, command_name }
---@type table<string, {[1]: string, [2]: string|nil, [3]: string}>
local command_map = {
  -- Misc (no category prefix)
  ["explorer"] = { "misc", nil, "SnacksExplorer" },
  ["notifications"] = { "misc", nil, "SnacksNotifications" },
  ["command-history"] = { "misc", nil, "SnacksCommandHistory" },

  -- Find
  ["find buffers"] = { "find", "buffers", "SnacksFindBuffers" },
  ["find files"] = { "find", "files", "SnacksFindFiles" },
  ["find git-files"] = { "find", "git-files", "SnacksFindGitFiles" },
  ["find config"] = { "find", "config", "SnacksFindConfig" },
  ["find recent"] = { "find", "recent", "SnacksFindRecent" },
  ["find projects"] = { "find", "projects", "SnacksFindProjects" },

  -- Git
  ["git branches"] = { "git", "branches", "SnacksGitBranches" },
  ["git log"] = { "git", "log", "SnacksGitLog" },
  ["git log-line"] = { "git", "log-line", "SnacksGitLogLine" },
  ["git status"] = { "git", "status", "SnacksGitStatus" },
  ["git stash"] = { "git", "stash", "SnacksGitStash" },
  ["git diff"] = { "git", "diff", "SnacksGitDiff" },
  ["git log-file"] = { "git", "log-file", "SnacksGitLogFile" },

  -- GitHub
  ["github issues"] = { "github", "issues", "SnacksGithubIssues" },
  ["github issues-all"] = { "github", "issues-all", "SnacksGithubIssuesAll" },
  ["github prs"] = { "github", "prs", "SnacksGithubPRs" },
  ["github prs-all"] = { "github", "prs-all", "SnacksGithubPRsAll" },

  -- Grep
  ["grep"] = { "grep", nil, "SnacksGrep" },
  ["grep lines"] = { "grep", "lines", "SnacksGrepLines" },
  ["grep buffers"] = { "grep", "buffers", "SnacksGrepBuffers" },
  ["grep word"] = { "grep", "word", "SnacksGrepWord" },

  -- Search
  ["search registers"] = { "search", "registers", "SnacksSearchRegisters" },
  ["search history"] = { "search", "history", "SnacksSearchHistory" },
  ["search autocmds"] = { "search", "autocmds", "SnacksSearchAutocmds" },
  ["search commands"] = { "search", "commands", "SnacksSearchCommands" },
  ["search command-history"] = { "search", "command-history", "SnacksSearchCommandHistory" },
  ["search diagnostics"] = { "search", "diagnostics", "SnacksSearchDiagnostics" },
  ["search diagnostics-buffer"] = { "search", "diagnostics-buffer", "SnacksSearchDiagnosticsBuffer" },
  ["search help"] = { "search", "help", "SnacksSearchHelp" },
  ["search highlights"] = { "search", "highlights", "SnacksSearchHighlights" },
  ["search icons"] = { "search", "icons", "SnacksSearchIcons" },
  ["search jumps"] = { "search", "jumps", "SnacksSearchJumps" },
  ["search keymaps"] = { "search", "keymaps", "SnacksSearchKeymaps" },
  ["search loclist"] = { "search", "loclist", "SnacksSearchLoclist" },
  ["search marks"] = { "search", "marks", "SnacksSearchMarks" },
  ["search man"] = { "search", "man", "SnacksSearchMan" },
  ["search lazy"] = { "search", "lazy", "SnacksSearchLazy" },
  ["search qflist"] = { "search", "qflist", "SnacksSearchQflist" },
  ["search resume"] = { "search", "resume", "SnacksSearchResume" },
  ["search undo"] = { "search", "undo", "SnacksSearchUndo" },
  ["search colorschemes"] = { "search", "colorschemes", "SnacksSearchColorschemes" },

  -- LSP
  ["lsp definitions"] = { "lsp", "definitions", "SnacksLspDefinitions" },
  ["lsp declarations"] = { "lsp", "declarations", "SnacksLspDeclarations" },
  ["lsp references"] = { "lsp", "references", "SnacksLspReferences" },
  ["lsp implementations"] = { "lsp", "implementations", "SnacksLspImplementations" },
  ["lsp type-definitions"] = { "lsp", "type-definitions", "SnacksLspTypeDefinitions" },
  ["lsp incoming-calls"] = { "lsp", "incoming-calls", "SnacksLspIncomingCalls" },
  ["lsp outgoing-calls"] = { "lsp", "outgoing-calls", "SnacksLspOutgoingCalls" },
  ["lsp symbols"] = { "lsp", "symbols", "SnacksLspSymbols" },
  ["lsp workspace-symbols"] = { "lsp", "workspace-symbols", "SnacksLspWorkspaceSymbols" },
}

---Completion function for :Snacks command
---@param arg_lead string
---@param cmd_line string
---@param cursor_pos number
---@return string[]
---@private
---@diagnostic disable-next-line: unused-local
local function complete_snacks(arg_lead, cmd_line, cursor_pos)
  local args = vim.split(cmd_line, "%s+", { trimempty = true })
  local num_args = #args - 1 -- subtract command name

  -- Get all available keys
  local completions = {}
  for key in pairs(command_map) do
    local parts = vim.split(key, "%s+")
    if num_args == 0 then
      -- First argument: suggest main categories and standalone commands
      if #parts == 1 then
        table.insert(completions, key)
      else
        local category = parts[1]
        if not vim.tbl_contains(completions, category) then
          table.insert(completions, category)
        end
      end
    elseif num_args == 1 then
      -- Second argument: suggest subcategories
      local category = args[2]
      if #parts > 1 and parts[1] == category then
        table.insert(completions, parts[2])
      end
    end
  end

  -- Filter by arg_lead
  local filtered = {}
  for _, comp in ipairs(completions) do
    if vim.startswith(comp, arg_lead) then
      table.insert(filtered, comp)
    end
  end

  table.sort(filtered)
  return filtered
end

---Execute a snacks command
---@param args Lib.UserCommand.Args
---@private
local function execute_snacks(args)
  local input = args.args:lower()

  -- Try to find matching command
  local cmd_name = command_map[input]
  if cmd_name then
    vim.cmd(cmd_name[3])
    return
  end

  -- If not found, show error with suggestions
  notify.error(("Unknown snacks command: '%s'"):format(args.args))
  notify.info("Available commands: :Snacks <tab> for completion")
end

---Setup snacks usercommands
---@param opts? config.snacks.usrcmds.Opts Configuration options
function M.setup(opts)
  if is_setup then
    notify.warn("snacks usercommands already set up")
    return
  end

  opts = vim.tbl_deep_extend("force", default_opts, opts or {})

  -- Register all submodule commands
  local submodules = {
    { name = "find", opts = opts.find },
    { name = "git", opts = opts.git },
    { name = "github", opts = opts.github },
    { name = "grep", opts = opts.grep },
    { name = "search", opts = opts.search },
    { name = "lsp", opts = opts.lsp },
    { name = "misc", opts = opts.misc },
  }

  for _, mod in ipairs(submodules) do
    local ok, module = pcall(require, "config.snacks.usrcmds." .. mod.name)
    if ok and type(module.register) == "function" then
      local reg_ok, err = pcall(module.register, mod.opts)
      if not reg_ok then
        notify.error(("Failed to register %s commands: %s"):format(mod.name, err))
      end
    else
      notify.warn(("Failed to load submodule: %s"):format(mod.name))
    end
  end

  -- Register main :Snacks command with completion
  usercmd.create("Snacks", execute_snacks, {
    desc = "[snacks] Execute snacks commands with autocompletion",
    nargs = "+",
    complete = complete_snacks,
  })

  is_setup = true
  -- notify.debug("snacks usercommands registered successfully")
end

---@type config.snacks.usrcmds.Module
return M
