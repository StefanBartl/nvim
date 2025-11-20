---@module 'custom.markdown.codeblock_formatter.init'
--- Initialization module for custom.markdown.codeblock_formatter
--- Wire up configuration, merge formatters, register commands and provide setup API.
--- Call require('custom.markdown.codeblock_formatter.init').setup(opts)
local M = {}

local cfg_mod = require("custom.markdown.codeblock_formatter.config")
local fmt_mod = require("custom.markdown.codeblock_formatter.formatters")
-- local run_mod = require("custom.markdown.codeblock_formatter.run")
local usercmds = require("custom.markdown.codeblock_formatter.usercmds")

--- Merge user options into runtime config and install commands.
--- opts table may include:
---   formatters = { ... } to merge/override default formatters
---   notify_level = vim.log.levels.*
---   prefer_treesitter = boolean
---   lang_aliases = table
function M.setup(opts)
  opts = opts or {}
  -- base config
  local t = {
    formatters = fmt_mod.default_formatters,
    notify_level = cfg_mod.default.notify_level,
    prefer_treesitter = cfg_mod.default.prefer_treesitter,
    lang_aliases = cfg_mod.default.lang_aliases,
  }
  -- merge user provided formatters if any
  if opts.formatters then
    t.formatters = vim.tbl_extend("force", t.formatters, opts.formatters)
  end
  if opts.notify_level then
    t.notify_level = opts.notify_level
  end
  if opts.prefer_treesitter ~= nil then
    t.prefer_treesitter = opts.prefer_treesitter
  end
  if opts.lang_aliases then
    t.lang_aliases = vim.tbl_extend("force", t.lang_aliases, opts.lang_aliases)
  end

  -- -- publish to run module
  -- run_mod._config.formatters = t.formatters
  -- run_mod._config.notify_level = t.notify_level
  -- run_mod._config.prefer_treesitter = t.prefer_treesitter
  -- run_mod._config.lang_aliases = t.lang_aliases
  --
  -- -- ensure supported_langs table present for finder
  -- -- (finder takes supported set based on run_mod._config.formatters)
  -- run_mod._config.supported_langs = {}
  -- for k, _ in pairs(t.formatters) do run_mod._config.supported_langs[k] = true end

  -- register commands
  usercmds.SetupCommands()

  vim.schedule(function()
    vim.notify("custom.markdown.codeblock_formatter initialized", vim.log.levels.INFO, { title = "md-codefmt" })
  end)
end

-- auto-setup with defaults on require
M.setup()

return M
