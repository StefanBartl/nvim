---@module 'config.neotest.init.windows_fixes'
---@brief Two fixes for running neotest on Windows, applied before `neotest.setup()`.
---
--- Background and the measurements behind both:
--- docs/ROADMAP/handovers/neotest_HANDOVER.md

local M = {}

--- Never let neotest open its parse-subprocess listener.
---
--- `neotest.lib.subprocess.init()` is the only place that calls `serverstart("localhost:0")`
--- (an unauthenticated TCP RPC server: any local process can run Lua in this session) and spawns
--- the helper `nvim --embed --headless`. The client calls it only while `subprocess.enabled()` is
--- false, and `neotest.lib` reaches the module through `lazy_require`, which looks `init` up on
--- every call, so replacing it here is enough. With it disabled neotest parses on the main thread
--- (`lib.treesitter`, `not lib.subprocess.enabled()`), which is also what happened before: the
--- helper never started because `NVIM_LISTEN_ADDRESS` was inherited.
function M.disable_parse_subprocess()
  local ok, subprocess = pcall(require, "neotest.lib.subprocess")
  if ok and type(subprocess) == "table" and type(subprocess.init) == "function" then
    subprocess.init = function() end
  end
end

--- Make neotest-plenary test runs work on Windows.
---
--- Two independent faults, both reproduced without any harness:
--- 1. The test child is a `nvim --headless` that inherits `NVIM_LISTEN_ADDRESS`, which
---    `lib.nvim` `rpc_pipe` exports. Neovim then tries to bind the session's pipe and dies in C
---    ("address already in use"): every run failed. An empty value for the child is enough.
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
    for i, part in ipairs(spec.command) do
      if type(part) == "string" and part:find("^lua _run_tests%(") then
        spec.command[i] = (part:gsub("\\", "/"))
      end
    end
    spec.env = vim.tbl_extend("force", spec.env or {}, { NVIM_LISTEN_ADDRESS = "" })
    return spec
  end
  adapter._windows_fixed = true
  return adapter
end

return M
