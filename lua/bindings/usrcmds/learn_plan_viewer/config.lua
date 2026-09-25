---@module 'bindings.usrcmds.learn_plan_viewer.config'
--- Where the CLI-Lernplan week pages live, and how they are named. See
--- docs/ROADMAP/LONG_RUN/learn-cli.nvim.md ("Phase 0") for the concept this
--- module implements.

local M = {}

--- Directory holding week-01.md .. week-12.md.
---@return string
function M.weeks_dir()
  return vim.fs.joinpath(vim.fn.stdpath("config"), "docs", "ROADMAP", "CLI_Lernplan")
end

M.week_count = 12

--- Absolute path of a given week's page.
---@param n integer 1..week_count
---@return string
function M.week_path(n)
  return vim.fs.joinpath(M.weeks_dir(), string.format("week-%02d.md", n))
end

--- Where the "last opened week" is remembered across sessions, so
--- `:LearnPlanViewer` without an argument resumes where you left off.
---@return string
function M.state_file()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "learn_plan_viewer_state.json")
end

return M
