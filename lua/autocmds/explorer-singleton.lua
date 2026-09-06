---@module 'autocmds.explorer-singleton'
--- Keeps neo-tree (filetree.nvim's tree, `<A-l>`) and snacks.picker's
--- `explorer` source (`<leader>.`, via pickers.nvim) from being open at the
--- same time — two competing "browse the filesystem" UIs otherwise have no
--- awareness of each other at all (neither plugin knows the other exists).
---
--- Rule: opening one closes the other, and remembers which one it displaced.
--- Closing the displacer reopens the displaced one ONCE, then forgets — so
--- closing that reopened one afterwards leaves nothing open, rather than
--- cascading back through more history. Concretely, for the scenario this
--- was built for: neo-tree open on the left, `<leader>.` opens snacks'
--- explorer (closing neo-tree first); closing the explorer reopens neo-tree;
--- closing THAT neo-tree leaves both closed.
---
--- Known imprecision: the "is the explorer open" check is
--- `Snacks.picker.get({source="explorer"})`, not "is the window I just
--- entered that picker" — the `snacks_picker_list` filetype is shared by
--- every snacks picker, so entering another one while an explorer instance
--- sits in a background window also (harmlessly) closes neo-tree. Recoverable
--- with `<A-l>`; not worth the internal-API surface to disambiguate.
---
--- Single-tab only: `_displaced` is one global, not per-tab.
---
--- Verified against the smoke test alongside this file (stubbed
--- neo-tree/snacks), NOT a live session — confirm the cascade feels right in
--- real use before trusting it.

local M = {}

---@type nil|"neotree"|"snacks_explorer"
local _displaced = nil

---@return integer? winid
local function neotree_win()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(w)
    if vim.bo[buf].filetype == "neo-tree" then
      return w
    end
  end
  return nil
end

---@return boolean
local function snacks_explorer_active()
  local ok, Snacks = pcall(require, "snacks")
  if not ok or not Snacks.picker then
    return false
  end
  local ok2, pickers = pcall(Snacks.picker.get, { source = "explorer" })
  return ok2 and pickers ~= nil and #pickers > 0
end

local function close_neotree()
  pcall(function()
    require("neo-tree.command").execute({ action = "close" })
  end)
end

local function open_neotree()
  pcall(function()
    require("neo-tree.command").execute({
      action = "show",
      position = "left",
      reveal = true,
      reveal_force_cwd = true,
    })
  end)
end

local function close_snacks_explorer()
  local ok, Snacks = pcall(require, "snacks")
  if not ok or not Snacks.picker then
    return
  end
  local ok2, pickers = pcall(Snacks.picker.get, { source = "explorer" })
  if not ok2 then
    return
  end
  for _, picker in ipairs(pickers) do
    pcall(function()
      picker:close()
    end)
  end
end

local function open_snacks_explorer()
  pcall(function()
    require("snacks").explorer()
  end)
end

---@param opts { enabled?: boolean }?
function M.setup(opts)
  opts = opts or {}
  if opts.enabled == false then
    return
  end

  local autocmd = require("lib.nvim.bindings.autocmd")
  -- Raw augroup, not autocmd.group(): that caches by name and would stop
  -- re-clearing on a second M.setup() call (e.g. re-sourcing config),
  -- stacking a duplicate pair of handlers instead of replacing them.
  local group = vim.api.nvim_create_augroup("WkdExplorerSingleton", { clear = true })

  autocmd.create("WinEnter", function()
    -- Deferred a tick and re-reads win/buf at execution time, not from the
    -- event args: at the instant WinEnter fires a fresh window (a floating
    -- picker especially) can still report the PREVIOUS window's buffer.
    -- Acting on that transient state misfired — see the smoke test for the repro.
    vim.schedule(function()
      pcall(function()
        local win = vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[buf].filetype

        if ft == "neo-tree" then
          if snacks_explorer_active() then
            close_snacks_explorer()
            _displaced = "snacks_explorer"
          end
        elseif ft == "snacks_picker_list" and snacks_explorer_active() and neotree_win() then
          close_neotree()
          _displaced = "neotree"
        end
      end)
    end)
  end, {
    group = group,
    desc = "Close the other file-explorer UI when one opens",
  })

  autocmd.create("WinClosed", function()
    if not _displaced then
      return
    end
    -- Deferred: the closing window's own teardown hasn't necessarily
    -- settled yet (neo-tree's WinClosed fallout, snacks' picker cleanup),
    -- so re-checking "is the other one really gone" needs to run after
    -- that settles, not synchronously inside this event.
    vim.schedule(function()
      if _displaced == "neotree" and not snacks_explorer_active() then
        _displaced = nil
        open_neotree()
      elseif _displaced == "snacks_explorer" and not neotree_win() then
        _displaced = nil
        open_snacks_explorer()
      end
    end)
  end, {
    group = group,
    desc = "Reopen the displaced explorer UI once, then forget it",
  })
end

return M
