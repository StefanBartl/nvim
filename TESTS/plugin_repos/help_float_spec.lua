-- TESTS/plugin_repos/help_float_spec.lua -- the key-help float shared by the :MyPlugins pickers.
--
-- Any key closes it and that key is discarded: it must not run in the window that keeps the
-- focus (the picker list), and the hook must be gone afterwards (the next key acts normally).

return function(H)
  local eq, ok = H.eq, H.ok
  local help = require("bindings.usrcmds.plugin_repos.help_float")

  local function flush()
    vim.wait(60, function()
      return false
    end)
  end
  local function keys(k)
    vim.api.nvim_feedkeys(vim.keycode(k), "mx", false)
    flush()
  end

  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "abcdef" })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  local wins_before = #vim.api.nvim_list_wins()

  local win, hbuf = help.open({ " Help ", "", " any key closes this " }, "help_float_spec")
  eq(#vim.api.nvim_list_wins(), wins_before + 1, "the float opens")
  ok(vim.api.nvim_get_current_win() ~= win, "...without taking the focus")

  keys("x") -- would delete "a" in the focused buffer
  eq(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "abcdef" }, "the closing key did not run")
  eq(#vim.api.nvim_list_wins(), wins_before, "the float is closed")
  ok(not vim.api.nvim_buf_is_valid(hbuf), "...and its buffer is gone")

  keys("x") -- the hook must be gone: this one acts again
  eq(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "bcdef" }, "the next key works normally")

  -- closed some other way first: the hook still fires once, nothing errors, no window is left
  win = help.open({ " Help " }, "help_float_spec")
  vim.api.nvim_win_close(win, true)
  keys("x")
  eq(#vim.api.nvim_list_wins(), wins_before, "closed from outside: nothing is left")
  eq(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "bcdef" }, "...the key was still swallowed")
  keys("x")
  eq(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "cdef" }, "...and then the hook is gone")
end
