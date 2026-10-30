-- TESTS/bindings/copy_ctrl_c_spec.lua -- <C-c> in bindings.mappings.general: in visual mode it
-- yanks the selection to `+`; in normal mode it copies the whole buffer only in a file window
-- (buftype "", also in a float such as :UI zen) and says so; a terminal, prompt or picker buffer is never copied.
-- The copy goes to register `a` here: this runner has no fake clipboard, and a spec must not
-- write the user's `+` (XP-08).

return function(H)
  local eq, ok = H.eq, H.ok
  local general = require("bindings.mappings.general")
  general.setup()

  local x = vim.fn.maparg("<C-c>", "x", false, true)
  eq(x.rhs, '"+y', "visual <C-c> yanks the selection to the system clipboard")
  ok(vim.fn.maparg("<C-c>", "n", false, true).callback ~= nil, "normal <C-c> is a function")

  local notes = {}
  local orig_notify = vim.notify
  vim.notify = function(msg)
    notes[#notes + 1] = msg
  end
  local cok, cerr = pcall(function()
    -- a file window: the whole buffer, linewise, and a message
    local file = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(file, vim.fn.tempname() .. "/copy_me.txt")
    vim.api.nvim_buf_set_lines(file, 0, -1, false, { "one", "two", "three" })
    vim.api.nvim_win_set_buf(0, file)
    vim.fn.setreg("a", "before")
    eq(general.copy_file(0, "a"), 3, "a file window is copied")
    eq(vim.fn.getreg("a", 1, 1), { "one", "two", "three" }, "the whole buffer")
    eq(vim.fn.getregtype("a"), "V", "linewise")
    eq(notes[#notes], "Copied 3 lines of copy_me.txt", "and it says what it copied")

    -- not a file window: nothing is copied, nothing is said
    local n = #notes
    vim.fn.setreg("a", "before")
    local nofile = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(nofile, 0, -1, false, { "picker", "lines" })
    vim.api.nvim_win_set_buf(0, nofile)
    eq(general.copy_file(0, "a"), nil, "a nofile (picker/prompt) buffer is not copied")

    -- a picker's float holds a nofile buffer: not copied
    local float = vim.api.nvim_open_win(
      nofile,
      true,
      { relative = "editor", row = 1, col = 1, width = 10, height = 2 }
    )
    eq(general.copy_file(float, "a"), nil, "a picker float is not copied")
    vim.api.nvim_win_close(float, true)

    local term = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_term(term, {})
    vim.api.nvim_win_set_buf(0, term)
    eq(vim.bo[term].buftype, "terminal", "a terminal buffer")
    eq(general.copy_file(0, "a"), nil, "a terminal buffer (its scrollback) is not copied")

    eq(vim.fn.getreg("a"), "before", "the register kept its value")
    eq(#notes, n, "no message for a window that is not copied")

    -- a file in a float (`:UI zen` edits there) is copied like in a split
    local zen = vim.api.nvim_open_win(
      file,
      true,
      { relative = "editor", row = 1, col = 1, width = 10, height = 2 }
    )
    eq(general.copy_file(zen, "a"), 3, "a file buffer in a float is copied")
    vim.api.nvim_win_close(zen, true)
  end)
  vim.notify = orig_notify
  if not cok then
    error(cerr, 0)
  end
end
