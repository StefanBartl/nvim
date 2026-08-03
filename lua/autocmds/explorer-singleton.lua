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
--- Known imprecision: the "did the user just open the EXPLORER specifically"
--- check is `Snacks.picker.get({source="explorer"})` returning anything for
--- the current tab, not "is the window I just entered specifically that
--- picker" — snacks' `snacks_picker_list` filetype is shared by every snacks
--- picker (files, grep, buffers, …), so entering some OTHER snacks picker
--- while an explorer instance happens to already be open in a background
--- window would also (harmlessly) close neo-tree. Narrow scenario, cheaply
--- recoverable (press `<A-l>` again) — not worth the extra internal-API
--- surface it'd take to disambiguate precisely.
---
--- The WinEnter handler defers a tick before reading current win/buf, rather
--- than trusting the event itself: a newly created window (a floating picker
--- in particular) can still briefly report the PREVIOUS window's buffer at
--- the exact instant WinEnter fires, before Neovim has settled which buffer
--- belongs to it — confirmed by this module's own smoke test failing without
--- the defer, then passing with it.
---
--- Verified against a scripted simulation (real windows/buffers, stubbed
--- neo-tree.command/snacks — see the smoke test alongside this file), NOT
--- against a live neo-tree + snacks session. Confirm the open/close/reopen
--- cascade actually feels right in real use before trusting it day to day.
---
--- Single-tab only: `_displaced` is one global, not per-tab. Multiple tabs
--- each running this dance independently isn't handled.

local M = {}

---@type nil|"neotree"|"snacks_explorer"
local _displaced = nil

---@return integer? winid
local function neotree_win()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(w)
    if vim.bo[buf].filetype == "neo-tree" then return w end
  end
  return nil
end

---@return boolean
local function snacks_explorer_active()
  local ok, Snacks = pcall(require, "snacks")
  if not ok or not Snacks.picker then return false end
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
      action = "show", position = "left", reveal = true, reveal_force_cwd = true,
    })
  end)
end

local function close_snacks_explorer()
  local ok, Snacks = pcall(require, "snacks")
  if not ok or not Snacks.picker then return end
  local ok2, pickers = pcall(Snacks.picker.get, { source = "explorer" })
  if not ok2 then return end
  for _, picker in ipairs(pickers) do
    pcall(function() picker:close() end)
  end
end

local function open_snacks_explorer()
  pcall(function() require("snacks").explorer() end)
end

---@param opts { enabled?: boolean }?
function M.setup(opts)
  opts = opts or {}
  if opts.enabled == false then return end

  local group = vim.api.nvim_create_augroup("WkdExplorerSingleton", { clear = true })

  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    desc = "Close the other file-explorer UI when one opens",
    callback = function()
      -- Deferred one tick, re-reading current win/buf at execution time
      -- rather than trusting the event args: a newly created window (a
      -- floating picker in particular) can still briefly report the
      -- PREVIOUS window's buffer at the exact instant WinEnter fires,
      -- before Neovim has fully settled which buffer belongs to it. Acting
      -- on that transient state was observed to misfire — see the module's
      -- own smoke test for the concrete repro this fixed.
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
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    desc = "Reopen the displaced explorer UI once, then forget it",
    callback = function()
      if not _displaced then return end
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
    end,
  })
end

return M
