---@module 'config.neotest.init.cmd'
--- The `cmd = {...}` trigger list for neotest's lazy.nvim spec -- every
--- `:Neotest*` command name that should load the plugin.
---
--- Complete on purpose: neotest loads on demand only, so a command missing
--- here does not exist until something else has loaded the plugin. The names
--- come from neotest itself (`:Neotest`, its own dispatcher),
--- `config.neotest.commands` and `config.neotest.utils.validate_consumer`.
---
--- `:Neotest` is not optional: without a stub of that exact name, typing it
--- matches the twelve stubs below as a prefix and fails with E464 (ambiguous).

return {
  "Neotest",
  "NeotestActions",
  "NeotestRunNearest",
  "NeotestRunFile",
  "NeotestRunAll",
  "NeotestDebugNearest",
  "NeotestSummaryToggle",
  "NeotestOutput",
  "NeotestOutputPanelToggle",
  "NeotestStop",
  "NeotestWatchToggle",
  "NeotestClearAll",
  "NeotestValidateConsumer",
}
