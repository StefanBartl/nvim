-- TESTS/neotree/event_handlers_spec.lua -- the `neo_tree_window_after_open` handler of
-- lua/config/neotree/event_handlers must take exactly the tree window out of automatic
-- folding: 'foldmethod' = manual, 'foldenable' off, in THAT window only. It must set them
-- with :setlocal semantics (vim.wo[win][0]); a plain vim.wo[win] is :set and would also change
-- the window-"global" value, so every buffer shown in the window later (position = "current",
-- a file opened into the tree window) would silently lose its folds.

return function(H)
  local eq, ok = H.eq, H.ok

  local handlers = require("config.neotree.event_handlers")
  local handler
  for _, h in ipairs(handlers) do
    if h.event == "neo_tree_window_after_open" then
      handler = h.handler
    end
  end
  ok(type(handler) == "function", "the config subscribes a neo_tree_window_after_open handler")

  -- Pre-condition of the real bug: the editor window folds by expression.
  local saved = { fm = vim.o.foldmethod, fe = vim.o.foldenable, fx = vim.o.foldexpr }
  vim.o.foldmethod = "expr"
  vim.o.foldexpr = "0"
  vim.o.foldenable = true

  local win, created
  local done, err = pcall(function()
    local editor = vim.api.nvim_get_current_win()
    vim.cmd("topleft 30vsplit")
    win = vim.api.nvim_get_current_win()
    local tree_buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(tree_buf, "neo-tree filesystem [spec]")
    vim.api.nvim_win_set_buf(win, tree_buf)
    eq(vim.wo[win].foldmethod, "expr", "the new window inherits the editor window's foldmethod")

    handler({ winid = win })
    eq(vim.wo[win].foldmethod, "manual", "tree window: foldmethod manual")
    eq(vim.wo[win].foldenable, false, "tree window: foldenable off")
    eq(vim.wo[editor].foldmethod, "expr", "the editor window is untouched")
    eq(vim.wo[editor].foldenable, true, "the editor window still folds")

    -- No leak into the window-global value: a buffer shown in the tree window for the first
    -- time (`position = "current"`, a file opened into it) starts from the unchanged default.
    created = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_win_set_buf(win, created)
    eq(vim.wo[win].foldmethod, "expr", "a later buffer in the window keeps the default foldmethod")
    eq(vim.wo[win].foldenable, true, "a later buffer in the window keeps the default foldenable")

    -- A window split off the editor window is not affected either.
    vim.api.nvim_set_current_win(editor)
    vim.cmd("vsplit")
    eq(vim.wo.foldmethod, "expr", "a fresh split of the editor window folds as before")
    vim.cmd("close")

    -- neo-tree also opens windows without focusing them (`:Neotree show`): the editor window
    -- stays current, the handler must still reach the (non-current) tree window.
    vim.api.nvim_set_current_win(editor)
    handler({ winid = win })
    eq(vim.wo[win].foldmethod, "manual", "non-current tree window: foldmethod manual")
    eq(vim.wo[win].foldenable, false, "non-current tree window: foldenable off")
    eq(vim.api.nvim_get_current_win(), editor, "the handler does not move the focus")
    eq(vim.wo[editor].foldmethod, "expr", "the focused editor window is untouched")
    eq(vim.wo[editor].foldenable, true, "the focused editor window still folds")

    -- Hostile arguments: neo-tree passes a table with winid; nothing else may throw.
    for _, args in ipairs({ {}, { winid = -1 }, { winid = 999999 } }) do
      local ran, e = pcall(handler, args)
      ok(ran, "handler survives " .. vim.inspect(args) .. ": " .. tostring(e))
    end
    ok(pcall(handler), "handler survives no argument")
    ok(pcall(handler, nil), "handler survives nil")
  end)

  -- Restore, also when an assertion above failed.
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
  vim.o.foldmethod, vim.o.foldenable, vim.o.foldexpr = saved.fm, saved.fe, saved.fx
  if created and vim.api.nvim_buf_is_valid(created) then
    pcall(vim.api.nvim_buf_delete, created, { force = true })
  end
  if not done then
    error(err, 0)
  end
end
