-- TESTS/strip_coauthor/repin_spec.lua -- scripts/strip_coauthor/repin.lua: old SHAs become the rewritten ones.
--
-- Pure text work: references `repo@sha` (abbreviations keep their length) and `engine.lock`. A reference
-- that is not an old SHA of that repository, or a hex run inside a longer word, must stay as it is.

return function(H)
  local eq = H.eq
  local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
  local config_root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(here))))
  vim.env.STRIP_REPIN_AS_MODULE = "1"
  local repin = dofile(config_root .. "/scripts/strip_coauthor/repin.lua")

  local old_lib = "a83821f63a91850cd8dc148ecc8fab516abae4b0"
  local new_lib = "1111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  local old_tasks = "865c0c669f14773912182e16c52872915fd780f0"
  local new_tasks = "2222222bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  local maps = {
    ["lib.nvim"] = { [old_lib] = new_lib },
    ["tasks.nvim"] = { [old_tasks] = new_tasks },
  }
  local index = repin.index(maps)

  local function t(text)
    return repin.translate_text(text, maps, index)
  end

  local out, n = t("done_in: lib.nvim@a83821f and tasks.nvim@865c0c6.")
  eq(out, "done_in: lib.nvim@1111111 and tasks.nvim@2222222.", "abbreviations keep their length")
  eq(n, 2, "two replacements")

  out = (t("see lib.nvim@" .. old_lib .. " now"))
  eq(out, "see lib.nvim@" .. new_lib .. " now", "a full SHA is replaced by a full SHA")

  out, n = t("tasks.nvim@a83821f is another repository's SHA")
  eq(
    { out, n },
    { "tasks.nvim@a83821f is another repository's SHA", 0 },
    "a SHA of another repository is left alone"
  )

  local n41 = select(2, t("lib.nvim@deadbeef and unknown.nvim@a83821f"))
  eq(n41, 0, "an unknown SHA and an unknown repository are left alone")

  local n44 = select(2, t("lib.nvim@a83821fg is a word, not a SHA"))
  eq(n44, 0, "a hex run inside a longer word is left alone")

  out = (t("line one\r\nlib.nvim@a83821f\r\nline three\r\n"))
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
