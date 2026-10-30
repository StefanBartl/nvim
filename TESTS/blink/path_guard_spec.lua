-- TESTS/blink/path_guard_spec.lua -- config/blink_path_guard.lua: blink.cmp's cmdline
-- `get_completions` shortens vim.env.PATH around getcompletion() and restores it without
-- pcall, so a throw left the shortened PATH in the session (inherited by every child).
-- The guard must restore PATH on a throw, rethrow the original error, keep the success
-- path's return values, and install only once.

return function(H)
  local eq, ok = H.eq, H.ok
  local guard = require("config.blink_path_guard")

  local orig_path = vim.env.PATH
  local done, err = pcall(function()
    -- Fake utils with the upstream shape: mutate PATH, call something that throws.
    local fake = {}
    function fake.get_completions(pattern)
      vim.env.PATH = "shortened"
      if pattern == "boom" then
        error("E475: Invalid argument: boom", 0)
      end
      vim.env.PATH = orig_path
      return { pattern }, nil, 3
    end

    ok(guard.install(fake), "install on a utils table succeeds")
    local wrapped = fake.get_completions
    ok(guard.install(fake), "a second install reports success")
    ok(fake.get_completions == wrapped, "a second install does not wrap twice")

    local a, b, c = fake.get_completions("x")
    eq(a, { "x" }, "success path: first return value")
    eq(b, nil, "success path: nil in the middle survives")
    eq(c, 3, "success path: trailing return value")
    eq(vim.env.PATH, orig_path, "success path: PATH unchanged")

    local thrown, msg = pcall(fake.get_completions, "boom")
    ok(not thrown, "the error is rethrown")
    eq(msg, "E475: Invalid argument: boom", "the original error message is kept")
    eq(vim.env.PATH, orig_path, "PATH is restored after the throw")

    ok(not guard.install({}), "a table without get_completions is not patched")

    -- The real module, when lazy.nvim has it: an invalid completion type makes
    -- getcompletion() throw after blink dropped System32 from PATH (native Windows).
    local blink = vim.fn.stdpath("data") .. "/lazy/blink.cmp"
    if vim.fn.has("win32") == 1 and vim.fn.isdirectory(blink) == 1 then
      vim.opt.rtp:prepend(blink)
      local loaded, utils = pcall(require, "blink.cmp.sources.cmdline.utils")
      if loaded then
        ok(guard.install(utils), "install on the real blink module")
        local real_ok = pcall(utils.get_completions, "x", "no_such_type", "shellcmd")
        ok(not real_ok, "the real getcompletion throws on an invalid type")
        eq(vim.env.PATH, orig_path, "real blink: PATH is restored after the throw")
      end
    end
  end)
  vim.env.PATH = orig_path
  if not done then
    error(err, 0)
  end
end
