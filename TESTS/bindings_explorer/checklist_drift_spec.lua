-- TESTS/bindings_explorer/checklist_drift_spec.lua -- `bindings_audit.drift`: the read-only diff
-- between the hand-edited runtime checklist and a freshly generated one.
--
-- `:BindingsRuntimeChecklist!` regenerates the file and resets every tick, so finding dead entries
-- needs a diff that ignores ticks, notes and descriptions and only compares section, group and the
-- box's code span.

return function(H)
  local drift = require("bindings.usrcmds.bindings_audit.drift")

  local generated = {
    "# Bindings — runtime checklist",
    "",
    "## Keymaps",
    "",
    "### Ai",
    "",
    "- [ ] `<leader>aia` -- Ai: Ask (prompt for text)",
    "- [ ] `<leader>aie` -- Ai: Explain current context",
    "",
    "### Session",
    "",
    "- [ ] `<leader>ha` -- Session: add mark",
    "",
    "## Usercmds",
    "",
    "### :Session",
    "",
    "- [ ] `:Session save` -- Save the session",
    "- [ ] `:Session load` -- Load session [name]",
  }

  -- The file as a person left it: ticks, an auto note, a changed description, one dead keymap,
  -- one dead command, and `:Session load` not added yet.
  local file = {
    "# Bindings — runtime checklist",
    "",
    "## Keymaps",
    "",
    "### Ai",
    "",
    "- [x] `<leader>aia` -- Ai: Ask (prompt for text) _(auto 2026-10-29: x_spec.lua grün)_",
    "- [ ] `<leader>aie` -- Ai: Explain (old description)",
    "- [ ] `<leader>aiz` -- Ai: removed in the meantime",
    "  Notiz: a note line under a box is not an entry",
    "",
    "### Session",
    "",
    "- [x] `<leader>ha` -- Session: add mark",
    "",
    "## Usercmds",
    "",
    "### :Session",
    "",
    "- [ ] `:Session save` -- Save the session",
    "- [ ] `:Session purge` -- gone",
  }

  -- entries(): headings set section/group, only box lines with a code span count.
  local entries = drift.entries(file)
  H.eq(#entries, 6, "six box lines with a code span")
  H.eq(entries[1].section, "Keymaps", "section from the ## heading")
  H.eq(entries[1].group, "Ai", "group from the ### heading")
  H.eq(entries[1].span, "<leader>aia", "span without backticks")
  H.eq(entries[1].lnum, 7, "lnum of the box line in the file")
  H.eq(entries[6].section, "Usercmds", "a new ## heading switches the section")
  H.eq(entries[6].group, ":Session", "and the group under it")

  -- A ## heading resets the group: a box right under it has no group.
  local reset = drift.entries({ "### Old", "## Next", "- [ ] `x` -- y" })
  H.eq(reset[1].group, "", "## clears the previous ### group")

  -- Spans with a backtick: the generator writes the backtick key as ```, Markdown as `` x ``.
  local ticks = drift.entries({
    "- [ ] ``` -- Surround selection with backticks (`)",
    "- [ ] `` a`b `` -- a span that contains a backtick",
    "- [ ] no span -- not an entry",
  })
  H.eq(#ticks, 2, "both backtick forms are entries, a box without a span is not")
  H.eq(ticks[1].span, "`", "``` is the backtick key")
  H.eq(ticks[2].span, "a`b", "`` x `` is read as x")

  -- diff(): ticks, notes and descriptions are not drift.
  local d = drift.diff(file, generated)
  local gone = vim.tbl_map(function(e)
    return e.span .. "@" .. e.lnum
  end, d.gone)
  local new = vim.tbl_map(function(e)
    return e.span
  end, d.new)
  H.eq(
    gone,
    { "<leader>aiz@9", ":Session purge@21" },
    "the two dead entries, with their file lines"
  )
  H.eq(new, { ":Session load" }, "the one entry missing from the file")

  -- The same span in another group is a different entry (the checklist lists it twice).
  local moved = drift.diff({ "## Keymaps", "### A", "- [ ] `<Tab>` -- a" }, {
    "## Keymaps",
    "### B",
    "- [ ] `<Tab>` -- b",
  })
  H.eq(#moved.gone, 1, "an entry that moved group is gone in the old group")
  H.eq(#moved.new, 1, "and new in the new group")

  -- No drift against itself.
  local same = drift.diff(generated, generated)
  H.eq(#same.gone + #same.new, 0, "a checklist has no drift against itself")

  -- The real checklist of this checkout parses: every box line is found, none is lost.
  local spec_file = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
  local config_root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(spec_file))))
  local real =
    vim.fs.joinpath(config_root, "docs/ROADMAP/Final_Checks/BINDINGS-RUNTIME-CHECKLIST.md")
  if vim.fn.filereadable(real) == 1 then
    local lines = vim.fn.readfile(real)
    local boxes = 0
    for _, l in ipairs(lines) do
      if l:match("^%s*%- %[.%]%s+`") then
        boxes = boxes + 1
      end
    end
    H.eq(#drift.entries(lines), boxes, "every box of the real checklist is an entry")
    H.ok(boxes > 1000, "the real checklist has its ~1800 boxes: " .. boxes)
  end
end
