-- TESTS/strip_coauthor/repin_spec.lua -- scripts/strip_coauthor/repin.lua: old SHAs become the rewritten ones.
--
-- Pure text work: references `repo@sha` (abbreviations keep their length) and `engine.lock`. A reference
-- that is not an old SHA of that repository, or a hex run inside a longer word, must stay as it is.
--
-- The SHAs below are made up on purpose. This file is a tracked text file of the config, so the real
-- `repin.lua --apply` after the rewrite of 2026-10-19 translated the real ones it held (809f7c32:
-- in the first case the lib.nvim SHA a83821f became a561474 and the tasks.nvim one 865c0c6 became
-- e913a76), and the fixture no longer matched its own map. Made-up SHAs occur in no real map, so no repin run can touch them.

return function(H)
  local eq = H.eq
  local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
  local config_root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(here))))
  vim.env.STRIP_REPIN_AS_MODULE = "1"
  local repin = dofile(config_root .. "/scripts/strip_coauthor/repin.lua")

  local old_lib = "a1b2c3d" .. string.rep("0", 33)
  local new_lib = "1111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  local old_tasks = "e4f5a6b" .. string.rep("0", 33)
  local new_tasks = "2222222bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  local maps = {
    ["lib.nvim"] = { [old_lib] = new_lib },
    ["tasks.nvim"] = { [old_tasks] = new_tasks },
  }
  local index = repin.index(maps)

  local function t(text)
    return repin.translate_text(text, maps, index)
  end

  local out, n = t("done_in: lib.nvim@a1b2c3d and tasks.nvim@e4f5a6b.")
  eq(out, "done_in: lib.nvim@1111111 and tasks.nvim@2222222.", "abbreviations keep their length")
  eq(n, 2, "two replacements")

  out = (t("see lib.nvim@" .. old_lib .. " now"))
  eq(out, "see lib.nvim@" .. new_lib .. " now", "a full SHA is replaced by a full SHA")

  out, n = t("tasks.nvim@a1b2c3d is another repository's SHA")
  eq(
    { out, n },
    { "tasks.nvim@a1b2c3d is another repository's SHA", 0 },
    "a SHA of another repository is left alone"
  )

  local n41 = select(2, t("lib.nvim@deadbeef and unknown.nvim@a1b2c3d"))
  eq(n41, 0, "an unknown SHA and an unknown repository are left alone")

  local n44 = select(2, t("lib.nvim@a1b2c3dg is a word, not a SHA"))
  eq(n44, 0, "a hex run inside a longer word is left alone")

  out = (t("line one\r\nlib.nvim@a1b2c3d\r\nline three\r\n"))
  eq(out, "line one\r\nlib.nvim@1111111\r\nline three\r\n", "CRLF stays")

  local lock = table.concat({
    "# pinned",
    "repo       = https://github.com/StefanBartl/tasks.nvim",
    "commit     = " .. old_tasks,
    "lib_repo   = https://github.com/StefanBartl/lib.nvim",
    "lib_commit = " .. old_lib,
    "",
  }, "\n")
  local lock_out, lock_n = repin.translate_lock(lock, maps, index)
  eq(lock_n, 2, "both pins translated")
  eq(
    lock_out,
    table.concat({
      "# pinned",
      "repo       = https://github.com/StefanBartl/tasks.nvim",
      "commit     = " .. new_tasks,
      "lib_repo   = https://github.com/StefanBartl/lib.nvim",
      "lib_commit = " .. new_lib,
      "",
    }, "\n"),
    "engine.lock is rewritten line by line, the rest untouched"
  )

  -- Two old SHAs that share an abbreviation: refusing is safer than guessing.
  local ambiguous = {
    ["x"] = { ["abcdef1" .. string.rep("0", 33)] = "n1", ["abcdef1" .. string.rep("1", 33)] = "n2" },
  }
  eq(
    repin.translate(ambiguous, repin.index(ambiguous), "x", "abcdef1"),
    nil,
    "an ambiguous abbreviation is not translated"
  )
end
