---@module 'config.neotest.init.cmd'
--- The `cmd = {...}` trigger list for neotest's lazy.nvim spec -- every
--- `:Neotest*` command name that should load the plugin.
---
--- Complete on purpose: neotest loads on demand only, so a command missing
--- here does not exist until something else has loaded the plugin. The names
--- come from `config.neotest.commands` and
--- `config.neotest.utils.validate_consumer`.

return {
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
