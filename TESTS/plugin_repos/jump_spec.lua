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

  -- jump(): opens the file on the head line.
  ok(jump.jump("braced.nvim", dir), "jump() reports success")
  eq(vim.fs.basename(vim.api.nvim_buf_get_name(0)), "a.lua", "the spec file is open")
  eq(vim.api.nvim_win_get_cursor(0), { 6, 4 }, "cursor on the head line")
  ok(not jump.jump("missing.nvim", dir), "jump() on an unknown plugin returns false")

  -- A failing :edit is a notification, not a raw error (E37 with 'nohidden' and a modified buffer).
  local old_hidden = vim.o.hidden
  vim.o.hidden = false
  vim.bo.modifiable = true
  vim.api.nvim_buf_set_lines(0, 0, 1, false, { "changed" })
  local ok_call, res = pcall(jump.jump, "fromreturn.nvim", dir)
  vim.o.hidden = old_hidden
  vim.bo.modified = false
  ok(ok_call, "a failing :edit does not raise")
  eq(res, false, "...and reports failure")
end
