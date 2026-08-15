---@module 'config.neotest.init.cmd'
--- The `cmd = {...}` trigger list for neotest's lazy.nvim spec -- every
--- `:Neotest*` command name that should load the plugin.

return {
  "NeotestRunNearest",
  "NeotestRunFile",
  "NeotestRunAll",
  "NeotestDebugNearest",
  "NeotestSummaryToggle",
  "NeotestOutput",
  "NeotestOutputPanelToggle",
  "NeotestStop",
  "NeotestWatchToggle",
}
