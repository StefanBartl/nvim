---@module 'config.todo_comments.keywords'
--- The keyword table todo-comments.nvim highlights: icon, color category and
--- recognized aliases per keyword (FIX/INFO/DEBUG/TODO/ROADMAP/AUDIT/
--- HACK/...).

return {
  FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
  INFO = { icon = " ", color = "info" },
  DEBUG = { icon = " ", color = "hint" },
  TODO = { icon = " ", color = "info" },
  ROADMAP = { icon = " ", color = "info" },
  AUDIT = {
    icon = " ",
    color = "audit",
    alt = { "VERIFY", "REVIEW", "DOUBLECHECK", "QC", "CHECK", "CHECKIT", "RECHECK", "VALIDATE" },
  },
  HACK = { icon = " ", color = "warning" },
  WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
  PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
  NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
  TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
  EXP = { icon = "🔬", color = "test", alt = { "EXPERIMENT", "EXPERIMENTAL" } },
  REF = {
    icon = "󰁨 ",
    color = "hint",
    alt = { "REFACTOR", "REWRITE", "CLEANUP", "IMPROVE", "RESTRUCTURE" },
  },
  ADD = { icon = " ", color = "info", alt = { "EXT", "NEXT", "FUTURE", "ENHANCE", "HOOK" } },
  FEAT = { icon = " ", color = "info", alt = { "FEATURE" } },
  WATCH = {
    icon = " ",
    color = "warning",
    alt = { "MONITOR", "OBSERVE", "TRACK", "INSPECT", "SURVEILLANCE" },
  },
  REMOVE = { icon = " ", color = "warning", alt = { "DELETE", "DEL", "UNUSED" } },
  DEVONLY = { icon = "", color = "hint", alt = { "TEMP", "EXPERIMENTAL", "DEV", "WIP" } },
}
