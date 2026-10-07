-- TESTS/clipboard/snippets_spec.lua -- `:Clipboard remove citeX` copies the Ex command that strips
-- "[cite: N]" markers; the copied text must do exactly that when run.

return function(H)
  local eq, ok = H.eq, H.ok

  -- The stubs must not leak into later specs, also when an assertion below fails.
  local saved_copy = package.loaded["lib.nvim.cross.copy_to_clipboard"]
  local saved_mod = package.loaded["bindings.usrcmds.clipboard"]

  local copied
  package.loaded["lib.nvim.cross.copy_to_clipboard"] = function(text)
    copied = text
    return true
  end
  package.loaded["bindings.usrcmds.clipboard"] = nil
  local clip = require("bindings.usrcmds.clipboard")
  clip.enable()

  local done, err = pcall(function()
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

    -- Extra snippets via enable(); a bad entry is ignored.
    clip.enable({ snippets = { ["say hi"] = { text = "hi", desc = "Say hi" }, bad = { text = 5 } } })
    ok(clip.SNIPPETS["say hi"], "extra snippet registered")
    eq(clip.SNIPPETS.bad, nil, "invalid snippet ignored")
    ok(not clip.copy_snippet("nope"), "unknown snippet reports failure")
  end)
  package.loaded["lib.nvim.cross.copy_to_clipboard"] = saved_copy
  package.loaded["bindings.usrcmds.clipboard"] = saved_mod
  if not done then
    error(err, 0)
  end
end
