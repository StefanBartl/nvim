-- TESTS/neotree/job_handle_close_spec.lua -- config/neotree/job_handle_close.lua: neo-tree's
-- `utils.job` spawned git with vim.uv.spawn and never closed the uv_process_t, so every
-- git status/rev-parse/ls-files left one inactive process handle in the loop for good
-- (984 after an 11-h session). The patch must close the handle once the job is finished,
-- still hand the caller's callback the same arguments, return the job unchanged, and
-- install only once.

return function(H)
  local eq, ok = H.eq, H.ok
  local uv = vim.uv or vim.loop
  local patch = require("config.neotree.job_handle_close")

  -- Live process handles that are not closing: what accumulated in the real session.
  local function open_processes()
    local n = 0
    uv.walk(function(h)
      if h:get_type() == "process" and not h:is_closing() then
        n = n + 1
      end
    end)
    return n
  end

  local function settle()
    -- Let pending close callbacks run.
    vim.wait(50, function()
      return false
    end)
  end

  local nvim = vim.v.progpath
  local CMD = { nvim, "--clean", "--headless", "-es", "+lua io.stdout:write('hi')", "+qa!" }

  -- Fake utils.job with the upstream shape: spawn, collect stdout, call on_exit, never close.
  local function fake_job(cmd, opts, on_exit)
    local out = {}
    local stdout = uv.new_pipe(false)
    local exited, closed, code = false, false, nil
    local function finish()
      if exited and closed and on_exit then
        on_exit(code, out, {})
      end
    end
    local spawnopts = opts or {}
    spawnopts.args = { unpack(cmd, 2) }
    spawnopts.stdio = { nil, stdout, nil }
    local handle, pid = uv.spawn(cmd[1], spawnopts, function(c)
      code, exited = c, true
      finish()
    end)
    stdout:read_start(function(_, data)
      if data then
        out[#out + 1] = data
      else
        stdout:close()
        closed = true
        finish()
      end
    end)
    return { handle = handle, pid = pid }, pid
  end

  local function run(job_fn, n)
    local results = {}
    for i = 1, n do
      local job = job_fn(CMD, nil, function(code, stdout)
        results[i] = { code = code, out = table.concat(stdout) }
      end)
      ok(job and job.handle, "the job comes back with its handle")
    end
    ok(
      vim.wait(20000, function()
        return #results == n
      end),
      "all jobs finished"
    )
    settle()
    return results
  end

  local base = open_processes()

  -- The bug, shown on the unpatched shape: every finished job leaves its handle open.
  run(fake_job, 3)
  eq(open_processes() - base, 3, "unpatched: three finished jobs leave three open handles")
  uv.walk(function(h)
    if h:get_type() == "process" and not h:is_closing() then
      h:close()
    end
  end)
  settle()
  base = open_processes()

  local fake = { job = fake_job }
  ok(patch.install(fake), "install on a utils table succeeds")
  local wrapped = fake.job
  ok(patch.install(fake), "a second install reports success")
  ok(fake.job == wrapped, "a second install does not wrap twice")

  local results = run(fake.job, 3)
  eq(open_processes() - base, 0, "patched: no handle stays open after the jobs finished")
  for i = 1, 3 do
    eq(results[i], { code = 0, out = "hi" }, "patched: callback " .. i .. " gets code and stdout")
  end

  -- No callback is allowed (upstream's on_exit is optional); the handle still closes.
  fake.job(CMD, nil, nil)
  ok(
    vim.wait(20000, function()
      settle()
      return open_processes() - base == 0
    end),
    "patched: a job without callback closes its handle too"
  )

  ok(not patch.install({}), "a table without job is not patched")

  -- The real module, when lazy.nvim has it.
  local data = vim.fn.stdpath("data") .. "/lazy/neo-tree.nvim"
  if vim.fn.isdirectory(data) == 1 then
    vim.opt.rtp:prepend(data)
    local loaded, utils = pcall(require, "neo-tree.utils")
    if loaded and type(utils.job) == "function" then
      ok(patch.install(utils), "install on the real neo-tree.utils")
      base = open_processes()
      local real = run(utils.job, 3)
      eq(open_processes() - base, 0, "real neo-tree: no handle stays open after the jobs finished")
      eq(real[1], { code = 0, out = "hi" }, "real neo-tree: callback gets code and stdout")
    end
  end
end
