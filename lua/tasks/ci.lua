---@module 'tasks.ci'
---@brief The vault gate for CI: rule check, index freshness and a Markdown lint of the generated indexes.
---@description
--- One command a pipeline can run (`tasks ci`, or `scripts/tasks-ci.lua`):
---
---  1. `check`: every rule finding of `tasks.check` (an `error` fails the run;
---     warnings only with `strict`)
---  2. `index --check`: no `ROADMAP/TASKS.md` is missing, outdated or an orphan
---     (`check` already reports it per area; this step is the explicit,
---     counted form, and it also fails on an index that cannot be rendered)
---  3. `md_lint`: the vault's `TOOLS/scripts/md_lint.lua` over every generated
---     `ROADMAP/TASKS.md` (relative links, anchors, table columns, and -- with
---     lsp.nvim on the runtimepath -- `$VAR/...` links)
---
--- Exit code: 0 all steps passed, 1 something failed. A step that cannot run
--- (no `md_lint.lua`, no Neovim to run it) fails unless `lint = false`: a gate
--- that silently skips a check is not a gate.
---
--- Key responsibilities:
---  - run the steps, collect the lines, print a short summary
---  - `run_lint` is injectable so a spec does not start a child Neovim
---
--- Not its job: writing or fixing anything (`tasks index` regenerates).

local check = require("tasks.check")
local fsio = require("tasks.fsio")
local index = require("tasks.index")
local vault = require("tasks.vault")

local M = {}

---Files per md_lint call (keeps the command line short on Windows).
M.LINT_CHUNK = 40

---@class Tasks.CiOpts
---@field root? string                # Vault root (default: `vault.root()`).
---@field strict? boolean             # Warnings fail the run too.
---@field lint? boolean               # Run `md_lint` (default true).
---@field md_lint? string             # Path of `md_lint.lua` (default: `<vault>/TOOLS/scripts/md_lint.lua`).
---@field nvim? string                # Neovim executable for md_lint (default: the running one).
---@field run_lint? fun(files: string[], md_lint: string): integer, string  # Replaces the child process (specs): exit code, output.

---@class Tasks.CiResult
---@field ok boolean
---@field code integer
---@field failed string[]   # Names of the failed steps.
---@field lines string[]    # What was printed.

---@param files string[]
---@param md_lint string
---@param nvim string
---@return integer code
---@return string output
local function child_lint(files, md_lint, nvim)
  local cmd = { nvim, "--headless", "-u", "NONE", "-l", md_lint }
  vim.list_extend(cmd, files)
  local ok, res = pcall(function()
    return vim.system(cmd, { text = true }):wait(120000)
  end)
  if not ok then
    return 1, "cannot start Neovim: " .. tostring(res)
  end
  return res.code, (res.stdout or "") .. (res.stderr or "")
end

---Run the gate.
---@param opts? Tasks.CiOpts
---@param say? fun(line: string)  # Default: collect only.
---@return Tasks.CiResult
function M.run(opts, say)
  opts = opts or {}
  local result = { ok = true, code = 0, failed = {}, lines = {} }
  ---@param line string
  local function out(line)
    result.lines[#result.lines + 1] = line
    if say then
      say(line)
    end
  end
  ---@param name string
  ---@param why string
  local function fail(name, why)
    result.ok, result.code = false, 1
    result.failed[#result.failed + 1] = name
    out(("tasks-ci: %s FAILED: %s"):format(name, why))
  end

  local root, rerr = vault.root(opts)
  if not root then
    fail("vault", tostring(rerr))
    return result
  end

  -- 1. rule check
  local res, cerr = check.run({ root = root })
  if not res then
    fail("check", tostring(cerr))
  else
    for _, f in ipairs(res.findings) do
      out(check.format(f, root))
    end
    local bad = res.errors + (opts.strict and res.warnings or 0)
    local line = ("check: %d error(s), %d warning(s) in %d area(s), %d task file(s) read"):format(
      res.errors,
      res.warnings,
      res.areas,
      res.tasks
    )
    if bad > 0 then
      fail("check", line .. (opts.strict and " (strict: warnings count)" or ""))
    else
      out("tasks-ci: " .. line .. " -- ok")
    end
  end

  -- 2. index freshness, and the list of indexes md_lint gets
  local results, errors = index.write_all({ root = root, check = true })
  local indexes = {}
  if not results then
    fail("index", tostring(errors and errors[1]))
  else
    local stale = 0
    for _, r in ipairs(results) do
      if r.action == "stale" then
        stale = stale + 1
        out(("index: %s is %s: %s"):format(r.area, r.reason or "stale", r.path))
      elseif r.action ~= "removed" and fsio.is_file(vault.index_path(root, r.area)) then
        indexes[#indexes + 1] = vault.index_path(root, r.area)
      end
    end
    for _, e in ipairs(errors or {}) do
      out("index: error: " .. tostring(e))
    end
    if stale > 0 or #(errors or {}) > 0 then
      fail(
        "index",
        ("%d stale, %d error(s) in %d area(s)"):format(stale, #(errors or {}), #results)
      )
    else
      out(("tasks-ci: index --check: %d area(s) up to date -- ok"):format(#results))
    end
  end

  -- 3. md_lint over the generated indexes
  if opts.lint == false then
    out("tasks-ci: md_lint skipped (lint=false)")
  elseif #indexes == 0 then
    out("tasks-ci: md_lint: no generated index to lint -- ok")
  else
    local md_lint = opts.md_lint or (root .. "/TOOLS/scripts/md_lint.lua")
    if not fsio.is_file(md_lint) then
      fail("md_lint", "script not found: " .. md_lint)
    else
      local runner = opts.run_lint
        or function(files, script)
          return child_lint(files, script, opts.nvim or vim.v.progpath)
        end
      local bad_chunks, problems = 0, {}
      for i = 1, #indexes, M.LINT_CHUNK do
        local chunk = {}
        for j = i, math.min(i + M.LINT_CHUNK - 1, #indexes) do
          chunk[#chunk + 1] = indexes[j]
        end
        local code, text = runner(chunk, md_lint)
        if code ~= 0 then
          bad_chunks = bad_chunks + 1
          for line in (text or ""):gmatch("[^\r\n]+") do
            if not line:match("^OK") then
              problems[#problems + 1] = line
            end
          end
        end
      end
      for _, line in ipairs(problems) do
        out("md_lint: " .. line)
      end
      if bad_chunks > 0 then
        fail("md_lint", ("problems in the generated indexes (%d file(s) linted)"):format(#indexes))
      else
        out(("tasks-ci: md_lint: %d index file(s) clean -- ok"):format(#indexes))
      end
    end
  end

  if result.ok then
    out("tasks-ci: OK")
  else
    out("tasks-ci: FAILED (" .. table.concat(result.failed, ", ") .. ")")
  end
  return result
end

return M
