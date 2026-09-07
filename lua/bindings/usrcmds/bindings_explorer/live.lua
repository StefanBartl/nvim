---@module 'bindings.usrcmds.bindings_explorer.live'
--- Live-grep-in-picker over `pickers.nvim`'s **engine** layer
--- (`pickers.engines`, `M.live_grep(opts)`), not the `sources/*` layer:
--- `sources/*` is tied to filesystem source objects (cwd/folder/repos/drives)
--- with no generic "picker over this directory list" entry point. The engine
--- layer below it is deliberately generic — `live_grep(opts)` takes
--- `opts.roots` as an arbitrary directory list, uniform across
--- telescope/fzf-lua/snacks.
---
--- No hard fallback here: with no engine (or no `ripgrep`), `M.open` reports
--- it via its return value and the caller (`init.lua`) switches to the static
--- search (`search.lua` + `ui.lua`'s `kit.select`).

local M = {}

--- Open live-grep over `roots`.
---@param roots string[]
---@param opts { query: string|nil, prompt: string|nil }|nil
---@return boolean ok true when a picker engine took over
function M.open(roots, opts)
  opts = opts or {}

  local ok, engines = pcall(require, "pickers.engines")
  if not ok then
    return false
  end

  local engine = engines.load()
  if not engine or type(engine.live_grep) ~= "function" then
    return false
  end

  engine.live_grep({
    roots = roots,
    prompt = opts.prompt or "Bindings",
    query = opts.query,
  })
  return true
end

return M
