---@module 'custom.repo_pickers.dispatch'
--- Engine resolution and direct execution helpers (no need for engine-specific user commands).
local notify = require("lib.nvim.notify").create("[custom.repo_pickers.dispatch]")

require("custom.repo_pickers.@types.types")

local M = {}

--- Resolve the effective engine ("fzf"|"telescope") for files based on config and installed plugins.
---@param cfg RepoPickers.Config
---@return "fzf"|"telescope"
function M.resolve_engine_for_files(cfg)
  local eng = cfg.engine or "auto"
  if eng == "fzf" then
    return "fzf"
  end
  if eng == "telescope" then
    return "telescope"
  end
  -- auto: prefer fzf if available
  if pcall(require, "fzf-lua") then
    return "fzf"
  end
  return "telescope"
end

--- Resolve the effective engine ("fzf"|"telescope") for grep based on config and installed plugins.
---@param cfg RepoPickers.Config
---@return "fzf"|"telescope"
function M.resolve_engine_for_grep(cfg)
  local eng = cfg.engine or "auto"
  if eng == "fzf" then
    return "fzf"
  end
  if eng == "telescope" then
    return "telescope"
  end
  if pcall(require, "fzf-lua") then
    return "fzf"
  end
  return "telescope"
end

--- Run a "files" picker for a given engine and directory.
---@param engine "fzf"|"telescope"
---@param dir RepoPickers.RepoDir
---@return nil
function M.run_files_by_engine(engine, dir)
  if engine == "fzf" then
    local ok, fzf = pcall(require, "fzf-lua")
    if not ok then
      notify.error("repo_pickers: fzf-lua not available")
      return
    end
    fzf.files({ cwd = dir })
    return
  end
  local ok, tb = pcall(require, "telescope.builtin")
  if not ok then
    notify.error("repo_pickers: telescope.builtin not available")
    return
  end
  tb.find_files({ cwd = dir })
end

--- Run a "live_grep" picker for a given engine and directory.
---@param engine "fzf"|"telescope"
---@param dir RepoPickers.RepoDir
---@return nil
function M.run_grep_by_engine(engine, dir)
  if engine == "fzf" then
    local ok, fzf = pcall(require, "fzf-lua")
    if not ok then
      notify.error("repo_pickers: fzf-lua not available")
      return
    end
    fzf.live_grep({ cwd = dir })
    return
  end
  local ok, tb = pcall(require, "telescope.builtin")
  if not ok then
    notify.error("repo_pickers: telescope.builtin not available")
    return
  end
  tb.live_grep({ cwd = dir })
end

return M
