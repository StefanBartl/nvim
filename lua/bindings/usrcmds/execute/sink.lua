---@module 'bindings.usrcmds.execute.sink'
---@brief Runs an `Execute.Plan` and puts the result where the user wants it.
---@description
--- Two steps, kept apart so a spec can drive each one:
---
---   `run(plan, cb)`        executes the plan and calls `cb` once with an `Execute.Result`
---   `deliver(how, ...)`    shows / copies the result
---
--- How each kind runs:
---   ex     every command through `nvim_exec2(..., { output = true })`, in the window that was current, so
---          `:set wrap` or `:echo expand("%")` act on the buffer the text came from. Stops at the first error.
---   lua    the chunk is tried as an expression first (`vim.o.shiftwidth` shows its value), else as
---          statements. `print` is captured. A returned value is appended through `vim.inspect`.
---   shell  every command line through `vim.fn.jobstart` with a command string, which uses 'shell' and
---          'shellcmdflag' like `:!` does (so quoting is the shell's own). Asynchronous, one command after
---          the other, stops at the first non-zero exit.
---
--- Where the result goes (`how`):
---   cmdline / clipboard   not run: the command is typed into the command line / copied
---   run                   run, then show the output as a message
---   split / vsplit / tab  run, then show the output in a scratch buffer of that kind
---   float                 run, then show the output in a floating viewer
---   result                run, then copy the output to the + register
---
--- Not its job: finding the text (`execute.source`), classifying it (`execute.kind`), asking the user
--- (`execute.init`).

local notify = require("lib.nvim.notify").create("[Execute]")

local M = {}

---Every value `how` takes, in the order the completion shows them.
---@type string[]
M.HOW = { "cmdline", "run", "split", "vsplit", "tab", "float", "clipboard", "result" }

---What each `how` value means (shown by the completion).
---@type table<string, string>
M.HOW_DESC = {
  cmdline = "type it into the command line, do not run it (the default without a bang)",
  run = "run it, show the output as a message (the default with a bang)",
  split = "run it, show the output in a horizontal split",
  vsplit = "run it, show the output in a vertical split",
  tab = "run it, show the output in a new tab",
  float = "run it, show the output in a floating window",
  clipboard = "copy the command text to the + register, do not run it",
  result = "run it, copy the output to the + register",
}

---@alias Execute.How "cmdline"|"run"|"split"|"vsplit"|"tab"|"float"|"clipboard"|"result"

---The `how` values that run the plan.
---@type table<string, boolean>
M.RUNS = { run = true, split = true, vsplit = true, tab = true, float = true, result = true }

---What running a plan gave.
---@class Execute.Result
---@field ok boolean        false when a command failed
---@field lines string[]    the output (and the error text), in order

-- ── running ──────────────────────────────────────────────────────────────────

---The lines of a command's output with line-ending noise removed. A buffered job gives a trailing empty
---string for the final newline.
---@param data string[]|nil
---@return string[]
local function clean(data)
  local out = {}
  for _, line in ipairs(data or {}) do
    out[#out + 1] = (line:gsub("\r$", ""))
  end
  while #out > 0 and out[#out] == "" do
    out[#out] = nil
  end
  return out
end

---Split output text into lines.
---@param text string
---@return string[]
local function to_lines(text)
  if text == "" then
    return {}
  end
  return clean(vim.split(text, "\n", { plain = true }))
end

---Run Ex commands. Synchronous.
---@param commands string[]
---@return Execute.Result
local function run_ex(commands)
  local lines = {}
  for _, cmd in ipairs(commands) do
    local ok, res = pcall(vim.api.nvim_exec2, cmd, { output = true })
    if not ok then
      lines[#lines + 1] = tostring(res)
      return { ok = false, lines = lines }
    end
    vim.list_extend(lines, to_lines(res.output or ""))
  end
  return { ok = true, lines = lines }
end

---Run a Lua chunk. Synchronous.
---@param chunk string
---@return Execute.Result
local function run_lua(chunk)
  local lines = {}
  local env = setmetatable({
    print = function(...)
      local parts = {}
      for i = 1, select("#", ...) do
        parts[i] = tostring((select(i, ...)))
      end
      vim.list_extend(lines, to_lines(table.concat(parts, "\t")))
    end,
  }, { __index = _G, __newindex = _G })

  -- an expression first, so `vim.o.shiftwidth` answers; a statement is a syntax error there
  local fn = load("return " .. chunk, "=execute", "t", env)
  if not fn then
    local err
    fn, err = load(chunk, "=execute", "t", env)
    if not fn then
      return { ok = false, lines = to_lines(tostring(err)) }
    end
  end
  local ok, res = pcall(fn)
  if not ok then
    vim.list_extend(lines, to_lines(tostring(res)))
    return { ok = false, lines = lines }
  end
  if res ~= nil then
    vim.list_extend(lines, to_lines(type(res) == "string" and res or vim.inspect(res)))
  end
  return { ok = true, lines = lines }
end

---Run shell command lines one after the other. Asynchronous; `cb` runs once.
---@param commands string[]
---@param cb fun(res: Execute.Result)
local function run_shell(commands, cb)
  local lines = {}
  local function step(i)
    if i > #commands then
      return cb({ ok = true, lines = lines })
    end
    local cmd = commands[i]
    if #commands > 1 then
      lines[#lines + 1] = "$ " .. cmd
    end
    local out, err = {}, {}
    local id = vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      stderr_buffered = true,
      on_stdout = function(_, data)
        out = clean(data)
      end,
      on_stderr = function(_, data)
        err = clean(data)
      end,
      on_exit = function(_, code)
        vim.schedule(function()
          vim.list_extend(lines, out)
          vim.list_extend(lines, err)
          if code ~= 0 then
            lines[#lines + 1] = ("[exit %d]"):format(code)
            return cb({ ok = false, lines = lines })
          end
          step(i + 1)
        end)
      end,
    })
    if id <= 0 then
      lines[#lines + 1] = ("cannot start: %s"):format(cmd)
      cb({ ok = false, lines = lines })
    end
  end
  step(1)
end

---Execute a plan.
---@param plan Execute.Plan
---@param cb fun(res: Execute.Result)  called once, possibly after the function returned (shell)
---@return nil
function M.run(plan, cb)
  if plan.kind == "shell" then
    return run_shell(plan.commands, cb)
  end
  cb(plan.kind == "lua" and run_lua(plan.commands[1]) or run_ex(plan.commands))
end

-- ── delivering ───────────────────────────────────────────────────────────────

---A scratch buffer in the current window, filled with `lines`.
---@param lines string[]
---@return nil
local function fill_current(lines)
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

---Copy text to the + register and say so.
---@param text string
---@param what string  for the message
---@return boolean ok
local function copy(text, what)
  local ok = require("lib.nvim.cross.copy_to_clipboard")(text)
  if ok then
    notify.info("Copied " .. what)
  else
    notify.error("Could not write to the clipboard")
  end
  return ok and true or false
end

---Show or copy what a run gave.
---@param how Execute.How  one of the `RUNS` values
---@param res Execute.Result
---@param plan Execute.Plan
---@return nil
function M.deliver(how, res, plan)
  local lines = res.lines
  local title = plan.display:match("^[^\n]*") or "Execute"

  if how == "result" then
    copy(table.concat(lines, "\n"), ("%d line(s) of output"):format(#lines))
    return
  end

  if how == "run" then
    if #lines == 0 then
      if plan.kind == "shell" then
        notify.info(res.ok and "done, no output" or "failed, no output")
      end
      return
    end
    (res.ok and notify.info or notify.error)(table.concat(lines, "\n"))
    return
  end

  local shown = #lines > 0 and lines or { "(no output)" }
  if how == "float" then
    require("lib.nvim.output.viewer").show_lines(title, shown)
  elseif how == "split" then
    vim.cmd("new")
    fill_current(shown)
  elseif how == "vsplit" then
    vim.cmd("vnew")
    fill_current(shown)
  elseif how == "tab" then
    vim.cmd("tabnew")
    fill_current(shown)
  end
end

---Type `text` into the command line without running it.
---@param text string  without the leading ":"
---@return nil
function M.to_cmdline(text)
  -- "n": no remapping; the "t" flag makes it look typed, so the command line opens as if the user pressed ":"
  vim.api.nvim_feedkeys(":" .. text, "nt", false)
end

---Copy the command text of a plan.
---@param plan Execute.Plan
---@return boolean ok
function M.copy_command(plan)
  local text = table.concat(plan.commands, "\n")
  return copy(
    text,
    plan.kind == "lua" and "the Lua chunk" or ("%d command(s)"):format(#plan.commands)
  )
end

return M
