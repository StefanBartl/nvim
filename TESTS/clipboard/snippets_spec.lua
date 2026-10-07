-- TESTS/clipboard/snippets_spec.lua -- `:Clipboard remove citeX` copies the Ex command that strips
-- "[cite: N]" markers; the copied text must do exactly that when run. Also: snippet validation
-- (a bad entry must never break enable(), which usrcmds/init.lua calls unprotected).

return function(H)
  local eq, ok = H.eq, H.ok

  -- The stubs must not leak into later specs, also when an assertion below fails.
  local saved_copy = package.loaded["lib.nvim.cross.copy_to_clipboard"]
  local saved_mod = package.loaded["bindings.usrcmds.clipboard"]

  local copied, accept = nil, true
  package.loaded["lib.nvim.cross.copy_to_clipboard"] = function(text)
    copied = text
    return accept
  end
  package.loaded["bindings.usrcmds.clipboard"] = nil

  vim.cmd("enew")
  local scratch = vim.api.nvim_get_current_buf()

  local done, err = pcall(function()
    local clip = require("bindings.usrcmds.clipboard")
    clip.enable()

    vim.cmd("Clipboard remove citeX")
    eq(copied, [[:%s/\[cite: \d\+\]//g]], "the command is copied verbatim")

    -- Running the copied command removes the markers and nothing else.
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "A claim [cite: 3] and more [cite: 12].",
      "Keep [cite: x] and [other: 4].",
    })
    vim.cmd(copied)
    eq(vim.api.nvim_buf_get_lines(0, 0, -1, false), {
      "A claim  and more .",
      "Keep [cite: x] and [other: 4].",
    }, "markers are stripped, look-alikes stay")

    -- Completion comes from the generated routes.
    eq(
      vim.fn.getcompletion("Clipboard remove ", "cmdline"),
      { "citeX" },
      "completion of the snippet word"
    )
    ok(
      vim.tbl_contains(vim.fn.getcompletion("Clipboard ", "cmdline"), "remove"),
      "first word is offered"
    )

    -- A clipboard that refuses the text is reported as a failure.
    accept = false
    ok(not clip.copy_snippet("remove citeX"), "copy_snippet reports a refused clipboard")
    accept = true
    ok(not clip.copy_snippet("nope"), "unknown snippet reports failure")
    ok(clip.copy_snippet("remove   citeX"), "whitespace in the key is normalised")

    -- Valid extras; bad entries are ignored and never break enable().
    local function enable(snippets)
      local ok_enable, e = pcall(clip.enable, { snippets = snippets })
      ok(ok_enable, "enable() must not raise: " .. tostring(e))
    end
    enable({
      ["say hi"] = { text = "hi", desc = "Say hi" },
      ["a  b"] = { text = "ab" }, -- two spaces: normalised to "a b"
      [""] = { text = "root" }, -- would be a ROOT route
      ["   "] = { text = "root" },
      bad = { text = 5 },
      worse = { text = "w", desc = true }, -- non-string desc falls back to the default
      reports = { text = "x" }, -- collides with the target `reports`
      ["path reports"] = { text = "x" }, -- collides with `path reports`
    })
    ok(clip.SNIPPETS["say hi"], "extra snippet registered")
    ok(clip.SNIPPETS["a b"] and not clip.SNIPPETS["a  b"], "key normalised to single spaces")
    eq(clip.SNIPPETS[""], nil, "empty key rejected")
    eq(clip.SNIPPETS["   "], nil, "blank key rejected")
    eq(clip.SNIPPETS.bad, nil, "non-string text rejected")
    eq(clip.SNIPPETS.worse.desc, "Copy a snippet", "non-string desc replaced by the default")
    eq(
      vim.fn.getcompletion("Clipboard a ", "cmdline"),
      { "b" },
      "no empty token in the completion tree"
    )

    -- The collisions did not take over the target routes, and a second enable() still works.
    copied = nil
    enable({})
    vim.cmd("Clipboard say hi")
    eq(copied, "hi", "snippet route works after re-enabling")
    vim.cmd("Clipboard")
    eq(copied, "hi", "a bare :Clipboard copies nothing (no ROOT route)")
  end)

  pcall(vim.api.nvim_del_user_command, "Clipboard")
  package.loaded["lib.nvim.cross.copy_to_clipboard"] = saved_copy
  package.loaded["bindings.usrcmds.clipboard"] = saved_mod
  if vim.api.nvim_buf_is_valid(scratch) then
    pcall(vim.api.nvim_buf_delete, scratch, { force = true })
  end
  if not done then
    error(err, 0)
  end
end
