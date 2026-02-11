---@module 'config.snackss.@types.usrcmds'
---@brief Type definitions for snacks usercommands module
---@description
--- This file contains all type definitions and annotations for the snacks
--- usercommands module to provide proper LuaLS type checking and IDE support.

---@class config.snacks.usrcmds.Module
---@field setup fun(opts?: config.snacks.usrcmds.Opts) äSetup snacks usercommands

---@class config.snacks.usrcmds.CategoryOpts
---@field enabled boolean Whether this category is enabled

---@class config.snacks.usrcmds.FindOpts : config.snacks.usrcmds.CategoryOpts
---@field buffers? boolean Enable buffers command
---@field files? boolean Enable files command
---@field git_files? boolean Enable git_files command
---@field config? boolean Enable config command
---@field recent? boolean Enable recent command
---@field projects? boolean Enable projects command

---@class config.snacks.usrcmds.GitOpts : config.snacks.usrcmds.CategoryOpts
---@field branches? boolean Enable branches command
---@field log? boolean Enable log command
---@field log_line? boolean Enable log_line command
---@field status? boolean Enable status command
---@field stash? boolean Enable stash command
---@field diff? boolean Enable diff command
---@field log_file? boolean Enable log_file command

---@class config.snacks.usrcmds.GithubOpts : config.snacks.usrcmds.CategoryOpts
---@field issues? boolean Enable issues command
---@field issues_all? boolean Enable issues (all) command
---@field prs? boolean Enable pull requests command
---@field prs_all? boolean Enable pull requests (all) command

---@class config.snacks.usrcmds.GrepOpts : config.snacks.usrcmds.CategoryOpts
---@field grep? boolean Enable grep command
---@field lines? boolean Enable buffer lines command
---@field buffers? boolean Enable grep buffers command
---@field word? boolean Enable grep word/selection command

---@class config.snacks.usrcmds.SearchOpts : config.snacks.usrcmds.CategoryOpts
---@field registers? boolean Enable registers command
---@field history? boolean Enable search history command
---@field autocmds? boolean Enable autocmds command
---@field commands? boolean Enable commands command
---@field command_history? boolean Enable command history command
---@field diagnostics? boolean Enable diagnostics command
---@field diagnostics_buffer? boolean Enable buffer diagnostics command
---@field help? boolean Enable help pages command
---@field highlights? boolean Enable highlights command
---@field icons? boolean Enable icons command
---@field jumps? boolean Enable jumps command
---@field keymaps? boolean Enable keymaps command
---@field loclist? boolean Enable location list command
---@field marks? boolean Enable marks command
---@field man? boolean Enable man pages command
---@field lazy? boolean Enable plugin specs command
---@field qflist? boolean Enable quickfix list command
---@field resume? boolean Enable resume picker command
---@field undo? boolean Enable undo history command
---@field colorschemes? boolean Enable colorschemes command

---@class config.snacks.usrcmds.LspOpts : config.snacks.usrcmds.CategoryOpts
---@field definitions? boolean Enable definitions command
---@field declarations? boolean Enable declarations command
---@field references? boolean Enable references command
---@field implementations? boolean Enable implementations command
---@field type_definitions? boolean Enable type definitions command
---@field incoming_calls? boolean Enable incoming calls command
---@field outgoing_calls? boolean Enable outgoing calls command
---@field symbols? boolean Enable symbols command
---@field workspace_symbols? boolean Enable workspace symbols command

---@class config.snacks.usrcmds.MiscOpts : config.snacks.usrcmds.CategoryOpts
---@field explorer? boolean Enable file explorer command
---@field notifications? boolean Enable notifications command
---@field command_history? boolean Enable command history command

---@class config.snacks.usrcmds.Opts
---@field find? config.snacks.usrcmds.FindOpts Find-related commands configuration
---@field git? config.snacks.usrcmds.GitOpts Git-related commands configuration
---@field github? config.snacks.usrcmds.GithubOpts GitHub-related commands configuration
---@field grep? config.snacks.usrcmds.GrepOpts Grep-related commands configuration
---@field search? config.snacks.usrcmds.SearchOpts Search-related commands configuration
---@field lsp? config.snacks.usrcmds.LspOpts LSP-related commands configuration
---@field misc? config.snacks.usrcmds.MiscOpts Miscellaneous commands configuration

return {}
