-- TESTS/cdx/prompt_templates_spec.lua -- `:Cdx prompt <name>` takes every `*.md` of the PROMPT folder as its
-- parameter, completes the names, keeps the short names `base` / `review`, and fills `{SHA}` only where a
-- template has it.

return function(H)
  local ok, eq, has = H.ok, H.eq, H.has

  -- a config folder of its own, with a PROMPT folder
  local config = H.tmpdir()
  local prompt = config .. "/docs/NOTES/CDX/templates/PROMPT"
  H.write(prompt .. "/Base.md", "base prompt\n")
  H.write(prompt .. "/review_w_ultracode.md", "review prompt\n")
  H.write(prompt .. "/ultra_sha.md", "check {SHA} please\n")
  H.write(prompt .. "/full.md", "full prompt\n")
  H.write(prompt .. "/notes.txt", "not a template\n")
  vim.fn.mkdir(prompt .. "/sub.md", "p")

  local stdpath = vim.fn.stdpath
  vim.fn.stdpath = function(what)
    if what == "config" then
      return config
    end
    return stdpath(what)
  end

  -- capture the clipboard and the messages; the module binds both at load, so load it again
  local copied
  local copy_was = package.loaded["lib.nvim.cross.copy_to_clipboard"]
  package.loaded["lib.nvim.cross.copy_to_clipboard"] = function(text)
    copied = text
    return true
  end
  package.loaded["bindings.usrcmds.cdx"] = nil
  local notes = {}
  local notify_was = vim.notify
  vim.notify = function(msg, level)
    notes[#notes + 1] = { msg = msg, level = level }
  end

  local cdx = require("bindings.usrcmds.cdx")
  cdx.enable()

  eq(
    cdx.names(),
    { "Base", "full", "review", "review_w_ultracode", "ultra_sha" },
    "every .md file by stem, plus the short name that is no stem; no .txt, no folder"
  )
  eq(cdx.resolve("Base"), "Base.md")
  eq(cdx.resolve("base"), "Base.md", "the short name")
  eq(cdx.resolve("review"), "review_w_ultracode.md", "the other short name")
  eq(cdx.resolve("FULL"), "full.md", "any case")
  local none, err = cdx.resolve("nope")
  ok(none == nil and err:find("have: ", 1, true), "an unknown name lists what there is")

  -- a file added later is there at once
  H.write(prompt .. "/brand_new.md", "new prompt\n")
  ok(vim.tbl_contains(cdx.names(), "brand_new"), "a new template needs no registration")

  -- a file named like a short name wins over it, in any case typed
  H.write(prompt .. "/review.md", "own review prompt\n")
  eq(cdx.resolve("review"), "review.md", "the file wins over the short name")
  eq(cdx.resolve("REVIEW"), "review.md", "also when typed in another case")
  eq(
    cdx.resolve("review_w_ultracode"),
    "review_w_ultracode.md",
    "the long name still reaches the old file"
  )
  vim.uv.fs_unlink(prompt .. "/review.md")
  eq(cdx.resolve("review"), "review_w_ultracode.md", "without the file the short name is back")

  -- copy
  copied = nil
  cdx.copy_prompt("full", {})
  eq(copied, "full prompt", "the text, without the trailing blank")
  cdx.copy_prompt("brand_new", {})
  eq(copied, "new prompt")
  cdx.copy_prompt("ultra_sha", {})
  eq(copied, "check {SHA} please", "without a SHA the placeholder stays")
  cdx.copy_prompt("ultra_sha", { "abc1234,def5678", "0123abcd" })
  eq(copied, "check abc1234, def5678, 0123abcd please", "the SHAs fill the placeholder")

  copied, notes = nil, {}
  cdx.copy_prompt("ultra_sha", { "zzzz" })
  eq(copied, nil, "a bad SHA copies nothing")
  has(notes[1].msg, "not a commit SHA")

  copied, notes = nil, {}
  cdx.copy_prompt("Base", { "abc1234" })
  eq(copied, "base prompt", "arguments for a template without {SHA} are ignored")
  has(notes[1].msg, "has no {SHA}")

  copied, notes = nil, {}
  cdx.copy_prompt("missing", {})
  eq(copied, nil)
  has(notes[1].msg, "no prompt template")

  -- the command line: completion and the route
  local found = vim.fn.getcompletion("Cdx prompt ", "cmdline")
  eq(found, cdx.names(), "<Tab> offers the templates")
  eq(vim.fn.getcompletion("Cdx prompt ul", "cmdline"), { "ultra_sha" }, "and narrows by prefix")
  eq(
    vim.fn.getcompletion("Cdx prompt B", "cmdline"),
    { "Base", "brand_new" },
    "any case when narrowing"
  )

  copied = nil
  vim.cmd("Cdx prompt full")
  eq(copied, "full prompt", "the route copies")
  vim.cmd("Cdx prompt ultra_sha abc1234 def5678")
  eq(copied, "check abc1234, def5678 please", "SHAs after the name")
  vim.cmd("Cdx prompt review")
  eq(copied, "review prompt", "the old short name still works")

  -- --open: the text becomes a buffer and the clipboard stays untouched
  local function opened()
    local buf = vim.api.nvim_get_current_buf()
    return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"), buf
  end
  copied = nil
  vim.cmd("Cdx prompt full --open")
  local text1, buf1 = opened()
  eq(text1, "full prompt", "--open shows the text in the current window")
  eq(copied, nil, "--open leaves the clipboard alone")
  eq(vim.bo[buf1].filetype, "markdown")
  has(vim.api.nvim_buf_get_name(buf1), "cdx-prompt://")
  vim.cmd("Cdx prompt full --open")
  local text2, buf2 = opened()
  ok(buf2 ~= buf1, "a second --open is a buffer of its own")
  eq(text2, "full prompt")
  has(vim.api.nvim_buf_get_name(buf2), "cdx-prompt://")
  vim.cmd("Cdx prompt ultra_sha abc1234 def5678 --open")
  eq((opened()), "check abc1234, def5678 please", "--open also takes the SHAs")
  eq(copied, nil, "still no clipboard")
  vim.cmd("Cdx prompt full")
  eq(copied, "full prompt", "without --open it copies again")

  -- a window that refuses the buffer: an error message, no orphan buffer, no throw
  local keep = vim.api.nvim_get_current_buf()
  local count = #vim.api.nvim_list_bufs()
  vim.wo.winfixbuf = true
  notes = {}
  local thrown = pcall(vim.cmd, "Cdx prompt full --open")
  vim.wo.winfixbuf = false
  ok(thrown, "a refused buffer does not throw")
  eq(vim.api.nvim_get_current_buf(), keep, "the window keeps its buffer")
  eq(#vim.api.nvim_list_bufs(), count, "and no orphan buffer is left")
  has(notes[#notes].msg, "Could not open")

  for _, b in ipairs({ buf1, buf2, keep }) do
    pcall(vim.api.nvim_buf_delete, b, { force = true })
  end

  vim.notify = notify_was
  vim.fn.stdpath = stdpath
  package.loaded["lib.nvim.cross.copy_to_clipboard"] = copy_was
  package.loaded["bindings.usrcmds.cdx"] = nil
end
