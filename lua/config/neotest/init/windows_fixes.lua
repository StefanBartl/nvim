---@module 'config.neotest.init.windows_fixes'
---@brief Two fixes for running neotest on Windows, applied before `neotest.setup()`.
---
--- Background and the measurements behind both:
--- WKDBooks nvim-config/Backlog/TASKS/neotest-listener-und-windows-laeufe-2026-10-03.md

local M = {}

--- Never let neotest open its parse-subprocess listener.
---
--- `neotest.lib.subprocess.init()` is the only place that calls `serverstart("localhost:0")`
--- (an unauthenticated TCP RPC server: any local process can run Lua in this session) and spawns
--- the helper `nvim --embed --headless`. The client calls it only while `subprocess.enabled()` is
--- false, and `neotest.lib` reaches the module through `lazy_require`, which looks `init` up on
--- every call, so replacing it here is enough. With it disabled neotest parses on the main thread
--- (`lib.treesitter`, `not lib.subprocess.enabled()`), which is also what happened before: the
--- helper never started because `NVIM_LISTEN_ADDRESS` was inherited (`lib.nvim` `rpc_pipe` used
--- to export it; it no longer does by default).
function M.disable_parse_subprocess()
  local ok, subprocess = pcall(require, "neotest.lib.subprocess")
  if ok and type(subprocess) == "table" and type(subprocess.init) == "function" then
    subprocess.init = function() end
  end
end

--- Make neotest-plenary test runs work on Windows.
---
--- Two independent faults, both reproduced without any harness:
--- 1. The test child is a `nvim --headless` that inherits `NVIM_LISTEN_ADDRESS` (`lib.nvim`
---    `rpc_pipe` used to export it). Neovim then tries to bind the session's pipe and dies in C
---    ("address already in use"): every run failed. An empty value for the child is enough, and
---    stays as a guard for a variable that comes from outside (a shell, a parent nvim).
--- 2. The adapter splices Windows paths into `-c "lua _run_tests({file = 'C:\Users\...'})"`.
---    `\U` is an invalid escape in a Lua string, the `-c` fails and the headless child stays
---    alive forever. Forward slashes are valid in the string and on Windows.
---@param adapter table  the table returned by `require("neotest-plenary")`
function M.fix_plenary_adapter(adapter)
  if
    type(adapter) ~= "table"
    or type(adapter.build_spec) ~= "function"
    or adapter._windows_fixed
  then
    return adapter
  end
  local build_spec = adapter.build_spec
  adapter.build_spec = function(args)
    local spec = build_spec(args)
    if type(spec) ~= "table" or type(spec.command) ~= "table" then
      return spec
    end
    local ctx = type(spec.context) == "table" and spec.context or {}
    -- Only the two path values inside the `_run_tests` argument are rewritten, and each is
    -- re-escaped for the single-quoted Lua string (`'` -> `\'`, what the adapter does for the
    -- test file). A blanket `\` -> `/` over the argument would also turn that escape into
    -- `/'`, which ends the string early for a path containing an apostrophe.
    -- On other systems a backslash is a legal file name character: leave it alone.
    local windows = package.config:sub(1, 1) == "\\"
    local function slashed(p)
      if windows then
        p = p:gsub("\\", "/")
      end
      return (p:gsub("'", "\\'"))
    end
    local function original(p)
      return (p:gsub("'", "\\'"))
    end
    local function replace_plain(s, old, new)
      local from, to = s:find(old, 1, true)
      if not from then
        return s
      end
      return s:sub(1, from - 1) .. new .. s:sub(to + 1)
    end
    for i, part in ipairs(spec.command) do
      if type(part) == "string" and part:find("^lua _run_tests%(") then
        if type(ctx.results_path) == "string" then
          -- The adapter splices the temp path unescaped.
          part = replace_plain(
            part,
            "results = '" .. ctx.results_path .. "'",
            "results = '" .. slashed(ctx.results_path) .. "'"
          )
        end
        if type(ctx.file) == "string" then
          part = replace_plain(
            part,
            "file = '" .. original(ctx.file) .. "'",
            "file = '" .. slashed(ctx.file) .. "'"
          )
        end
        spec.command[i] = part
      end
    end
    spec.env = vim.tbl_extend("force", spec.env or {}, { NVIM_LISTEN_ADDRESS = "" })
    return spec
  end
  adapter._windows_fixed = true
  return adapter
end

return M
