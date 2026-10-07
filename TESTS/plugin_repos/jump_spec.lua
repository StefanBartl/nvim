-- TESTS/plugin_repos/jump_spec.lua -- `:MyPlugins jumpTo`: finding a plugin's install spec head.
--
-- A fixture directory stands in for plugins/personal/specs. The scan must accept the three real
-- spellings of a spec head (inline `{ "o/n"`, bare string after a lone `{`, bare string after
-- `return {`) and must not mistake a dependency, a comment or a second declaration for one.

return function(H)
  local eq, ok = H.eq, H.ok
  local jump = require("bindings.usrcmds.plugin_repos.jump")

  local dir = H.tmpdir()
  H.write(
    dir .. "/a.lua",
    table.concat({
      "return {", -- 1
      "  {", -- 2
      '    "Owner/inline.nvim",', -- 3  bare string after a lone `{`
      '    dependencies = { "Owner/dep.nvim" },', -- 4
      "  },", -- 5
      '  { "Owner/braced.nvim", lazy = false },', -- 6  inline head
      "  {", -- 7
      '    "Owner/dep.nvim",', -- 8  head of a second spec
      "    dependencies = {", -- 9
      '      "Owner/only-dep.nvim",', -- 10 dependency entry, not a head
      "    },", -- 11
      "  },", -- 12
      '  -- { "Owner/commented.nvim" },', -- 13
      "}",
    }, "\n")
  )
  H.write(
    dir .. "/b.lua",
    table.concat({
      "local function specs()", -- 1
      "  return {", -- 2
      '    "Owner/fromreturn.nvim",', -- 3 bare string after `return {`
      "    opts = {},", -- 4
      "  }", -- 5
      "end", -- 6
      "return {", -- 7
      "  { -- spec of the thing", -- 8
      '    "Owner/trailing.nvim",', -- 9  bare string after `{` + trailing comment
      "  },", -- 10
      '  { "Owner/inline.nvim" },', -- 11 second declaration: first match wins
      "}",
    }, "\n")
  )

  local function at(name)
    local hit = jump.find(name, dir)
    return hit and (vim.fs.basename(hit.file) .. ":" .. hit.lnum) or nil
  end

  eq(at("inline.nvim"), "a.lua:3", "bare string after a lone {")
  eq(at("braced.nvim"), "a.lua:6", "inline { head")
  eq(at("dep.nvim"), "a.lua:8", "a dependencies entry is skipped, the real head is found")
  eq(at("fromreturn.nvim"), "b.lua:3", "bare string after return {")
  eq(at("trailing.nvim"), "b.lua:9", "lone { with a trailing comment")
  eq(at("INLINE.nvim"), "a.lua:3", "case-insensitive; first declaration wins")
  eq(at("only-dep.nvim"), nil, "a pure dependency has no spec head")
  eq(at("commented.nvim"), nil, "a commented-out spec is not a head")
  eq(at("missing.nvim"), nil, "unknown plugin")

  local hit = jump.find("braced.nvim", dir)
  eq(hit.col, 5, "the column points at the opening quote")

  eq(jump.names(dir), {
    "braced.nvim",
    "dep.nvim",
    "fromreturn.nvim",
    "inline.nvim",
    "trailing.nvim",
  }, "names(): sorted, unique, heads only")
  eq(jump.names(dir .. "/does-not-exist"), {}, "names() on a missing directory")
  eq(jump.find("x", dir .. "/does-not-exist"), nil, "find() on a missing directory")

  -- Cache reuse and retry: an unchanged directory is not re-read; a file that could not be read
  -- is not cached as "no heads".
  local real_readfile = vim.fn.readfile
  local done_cache, err_cache = pcall(function()
    local reads = 0
    vim.fn.readfile = function(...)
      reads = reads + 1
      return real_readfile(...)
    end
    jump.names(dir)
    local after_first = reads
    jump.names(dir)
    jump.find("inline.nvim", dir)
    eq(reads, after_first, "an unchanged directory is served from the cache")
    local flaky = H.tmpdir()
    H.write(flaky .. "/f.lua", '{ "Owner/flaky.nvim" }')
    local fail = true
    vim.fn.readfile = function(path, ...)
      if fail and path:find("f.lua", 1, true) then
        error("simulated sharing violation")
      end
      return real_readfile(path, ...)
    end
    eq(jump.names(flaky), {}, "an unreadable file contributes nothing")
    fail = false
    eq(jump.names(flaky), { "flaky.nvim" }, "...and is retried, not cached as empty")
  end)
  vim.fn.readfile = real_readfile
  if not done_cache then
    error(err_cache, 0)
  end

  -- Cache: a changed file is picked up (signature = mtime + size), an unchanged one is reused.
  H.write(
    dir .. "/c.lua",
    [[{
  "Owner/late.nvim",
}
]]
  )
  eq(at("late.nvim"), "c.lua:2", "a new spec file is picked up")
  H.write(
    dir .. "/c.lua",
    [[{
  "Owner/late.nvim",
  { "Owner/later.nvim" },
}


]]
  )
  eq(jump.names(dir)[#jump.names(dir)], "trailing.nvim", "names() stays sorted after a rescan")
  ok(vim.tbl_contains(jump.names(dir), "later.nvim"), "a changed spec file is rescanned")
  vim.fn.delete(dir .. "/c.lua")
  eq(at("late.nvim"), nil, "a removed spec file is dropped")

  -- jump(): opens the file on the head line. A fresh tab keeps the other specs' buffers alone.
  vim.cmd("tabnew")
  local tab = vim.api.nvim_get_current_tabpage()
  local done, err = pcall(function()
    ok(jump.jump("braced.nvim", dir), "jump() reports success")
    eq(vim.fs.basename(vim.api.nvim_buf_get_name(0)), "a.lua", "the spec file is open")
    eq(vim.api.nvim_win_get_cursor(0), { 6, 4 }, "cursor on the head line")
    ok(not jump.jump("missing.nvim", dir), "jump() on an unknown plugin returns false")

    -- Same file with unsaved changes: only the cursor moves (a re-:edit would fail with E37).
    vim.api.nvim_buf_set_lines(0, 0, 1, false, { "return { -- changed" })
    ok(vim.bo.modified, "the buffer has unsaved changes")
    ok(jump.jump("inline.nvim", dir), "jump() within the modified current file succeeds")
    eq(vim.api.nvim_win_get_cursor(0), { 3, 4 }, "...and moves the cursor to the other head")
    eq(vim.api.nvim_buf_get_lines(0, 0, 1, false), { "return { -- changed" }, "...keeping the edit")

    -- Unsaved edits that shift the lines: the head is searched again in the live text.
    vim.api.nvim_buf_set_lines(0, 0, 0, false, { "-- 1", "-- 2", "-- 3", "-- 4", "-- 5" })
    ok(jump.jump("braced.nvim", dir), "jump() after lines were inserted above the target")
    eq(vim.api.nvim_win_get_cursor(0), { 11, 4 }, "...lands on the shifted head, not the disk line")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "gone" })
    ok(
      jump.jump("braced.nvim", dir),
      "a head gone from the buffer falls back to the disk line, clamped"
    )
    eq(vim.api.nvim_win_get_cursor(0)[1], 1, "...which is the last line of the shrunk buffer")

    -- The same file reached through a junction (another spelling of the path): still no re-:edit.
    local link = H.tmpdir() .. "/lnk"
    if vim.uv.fs_symlink(dir, link, { dir = true, junction = true }) then
      vim.cmd("edit! " .. vim.fn.fnameescape(dir .. "/a.lua"))
      vim.api.nvim_buf_set_lines(0, 0, 0, false, { "-- x" })
      ok(jump.jump("inline.nvim", link), "jump() recognises the file through a junction")
      eq(vim.api.nvim_win_get_cursor(0), { 4, 4 }, "...and finds the shifted head")
    end

    -- Another file with unsaved changes and 'nohidden': a notification, not a raw error (E37).
    local old_hidden = vim.o.hidden
    vim.o.hidden = false
    local ok_call, res = pcall(jump.jump, "fromreturn.nvim", dir)
    vim.o.hidden = old_hidden
    ok(ok_call, "a failing :edit does not raise")
    eq(res, false, "...and reports failure")
    eq(
      vim.fs.basename(vim.api.nvim_buf_get_name(0)),
      "a.lua",
      "...and stays in the modified buffer"
    )
  end)
  vim.bo.modified = false
  pcall(vim.cmd, "tabclose!")
  pcall(vim.cmd, "silent! %bwipeout!")
  if vim.api.nvim_tabpage_is_valid(tab) then
    pcall(vim.cmd, "tabonly!")
  end
  if not done then
    error(err, 0)
  end

  -- The path is literal: %, # and $VAR in a directory name are not expanded by :edit.
  local odd = H.tmpdir() .. "/pct%x#y$HOME"
  if vim.fn.mkdir(odd, "p") == 1 then
    H.write(
      odd .. "/s.lua",
      [[{
  "Owner/odd.nvim",
}
]]
    )
    vim.cmd("tabnew")
    local ok_odd = pcall(function()
      ok(jump.jump("odd.nvim", odd), "jump() into a directory with %, # and $")
      eq(
        vim.fs.normalize(vim.api.nvim_buf_get_name(0)),
        vim.fs.normalize(odd .. "/s.lua"),
        "literal path"
      )
    end)
    pcall(vim.cmd, "tabclose!")
    pcall(vim.cmd, "silent! %bwipeout!")
    ok(ok_odd, "odd directory name")
  end

  -- A missing directory is silent (no E484) and empty.
  eq(jump.names(dir .. "/missing"), {}, "names() on a missing directory")
end
