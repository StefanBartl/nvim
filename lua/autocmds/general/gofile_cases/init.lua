---@module 'autocmds.general.gofile_cases'
--- Loader/registry for gofile_cases.
--- Exposes a function `load_ordered_cases(cfg)` which returns an ordered list of case modules.
local M = {}

--- Deterministic list of module names in the intended invocation order.
--- @type string[]
local ORDER = {
  "autocmds.general.gofile_cases.p0_gopath",
  "autocmds.general.gofile_cases.p1_inline",
  "autocmds.general.gofile_cases.p2_reference",
  "autocmds.general.gofile_cases.p3_url",
  "autocmds.general.gofile_cases.p4_local",
}

--- Load modules from ORDER; modules must export `.call` function.
--- Returns list of loaded modules (in-order). Missing modules are skipped but logged via cfg.
--- @param cfg table
--- @return table[] loaded_modules
function M.load_ordered_cases(cfg)
  local mods = {}
  for _, name in ipairs(ORDER) do
    local ok, m = pcall(require, name)
    if ok and m and type(m.call) == "function" then
      -- Save module name for debugging if module provides no internal name.
      m._NAME = m._NAME or name
      table.insert(mods, m)
    else
      if cfg and cfg.goto_file and cfg.goto_file.debug then
        vim.notify(("md-gf: failed to load module '%s'"):format(name), vim.log.levels.WARN)
      end
    end
  end
  return mods
end

return M
