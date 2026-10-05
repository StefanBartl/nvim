-- TESTS/sync/sync_picker_action_spec.lua -- the `sync` action of `:MyPlugins picker`: it sits in
-- the per-plugin cycle (update -> pull -> fetch -> sync), shows as [S], and <CR> runs the marked
-- repos as ONE partial `:MyPlugins sync` (so the saved result of the others is kept).
-- Real Snacks picker, headless; `sync.run` is stubbed. Skipped when snacks.nvim is not installed.

return function(H)
  local eq, ok, has = H.eq, H.ok, H.has

  local function find_snacks()
    -- No ipairs: the first candidate is nil when $SNACKS_DIR is unset.
    local candidates = { vim.env.SNACKS_DIR or "", vim.fn.stdpath("data") .. "/lazy/snacks.nvim" }
    for _, dir in ipairs(candidates) do
      if dir ~= "" and vim.fn.isdirectory(dir .. "/lua/snacks/picker") == 1 then
        return dir
      end
    end
    return nil
  end
  local snacks_dir = find_snacks()
  if not snacks_dir then
    io.stdout:write("      (snacks.nvim not found: this spec is skipped)\n")
    return
  end
  vim.opt.rtp:append(snacks_dir)
  local Snacks = require("snacks")

  local picker_mod = require("bindings.usrcmds.plugin_repos.picker")
  local sync = require("bindings.usrcmds.plugin_repos.sync")
  local plugin_list = require("plugins.personal.core.list")

  local entries = assert(plugin_list.read())
  local first, second = entries[1].name, entries[2].name

  -- both exist on disk (as plain folders: the sync action only hands the names over)
  local base = H.tmpdir() .. "/repos"
  vim.fn.mkdir(base .. "/" .. first, "p")
  vim.fn.mkdir(base .. "/" .. second, "p")

  local orig_run, orig_notify = sync.run, vim.notify
  local ran = nil
  sync.run = function(opts)
    ran = opts
    if opts.on_done then
      opts.on_done({}, {})
    end
  end
  vim.notify = function() end

  local function wait_for(cond, ms)
    return vim.wait(ms or 5000, cond, 10)
  end
  local function flush()
    vim.wait(60, function()
      return false
    end)
  end
  local function current_picker()
    for _, p in ipairs(Snacks.picker.get({ source = "myplugins_repos" })) do
      if not p.closed then
        return p
      end
    end
    return nil
  end
  local function keys(k)
    vim.api.nvim_feedkeys(vim.keycode(k), "mx", false)
    flush()
  end

  local passed, err = pcall(function()
    picker_mod.open(base)
    ok(
      wait_for(function()
        local p = current_picker()
        return p ~= nil and p:count() == #entries and not p.finder.task:running()
      end),
      "the picker lists every plugin"
    )
    local p = assert(current_picker())
    flush()
    p:focus("list")
    flush()

    local function first_row()
      return vim.api.nvim_buf_get_lines(p.list.win.buf, 0, 1, false)[1]
    end
    has(first_row(), first, "the first row is the first entry of the list")
    -- present: update -> pull -> fetch -> sync
    keys("<Tab>")
    has(first_row(), "[U]", "first press: update")
    keys("<Tab>")
    has(first_row(), "[P]", "second press: pull")
    keys("<Tab>")
    has(first_row(), "[F]", "third press: fetch")
    keys("<Tab>")
    has(first_row(), "[S]", "fourth press: sync")

    -- the second entry gets sync too (<Tab> cycles in place; move down explicitly)
    keys("j")
    for _ = 1, 4 do
      keys("<Tab>")
    end

    keys("<CR>")
    ok(
      wait_for(function()
        return ran ~= nil
      end),
      "<CR> ran the batch and started a sync"
    )
    eq(ran.partial, true, "as a partial run (the saved result of the other repos stays)")
    eq(ran.names, { first, second }, "over exactly the repos marked [S], in list order")
    eq(
      vim.fs.normalize(ran.dir),
      (vim.fs.normalize(base):gsub("/+$", "")),
      "in the picker's directory"
    )
    ok(ran.only == nil, "not narrowed to one repo")
  end)

  sync.run, vim.notify = orig_run, orig_notify
  for _, p in ipairs(Snacks.picker.get({ source = "myplugins_repos" })) do
    pcall(p.close, p)
  end
  if not passed then
    error(err, 0)
  end
end
