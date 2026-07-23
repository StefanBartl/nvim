---@module 'config.ui_open'
--- Neovim core's vim.ui.open() on Windows builds
--- `{ "cmd.exe", "/c", "start", "", <path> }` and hands it to `vim.system()`.
--- `vim.system`/libuv only quotes an argv entry that contains whitespace, so a
--- URL with no spaces but an unescaped `&` (any link with 2+ query params,
--- e.g. "...?id=x&number=y") reaches cmd.exe unquoted. cmd.exe re-tokenizes
--- its own command line and treats the bare `&` as a command separator, so
--- only the part before the first `&` actually gets opened -- silently, no
--- error, just a truncated URL (symptom: page loads but "access denied" /
--- wrong content, works fine when pasted directly into the browser).
--- `explorer.exe <path>` hands the target straight to the registered
--- protocol/file handler without any shell tokenizing in between, so it is
--- immune to this. See share/nvim/runtime/lua/vim/ui.lua:_get_open_cmd().

local M = {}

function M.setup()
  if vim.fn.has("win32") == 0 then
    return
  end

  local orig_get_open_cmd = vim.ui._get_open_cmd
  vim.ui._get_open_cmd = function()
    return { "explorer.exe" }, nil
  end
  M._orig_get_open_cmd = orig_get_open_cmd
end

return M
