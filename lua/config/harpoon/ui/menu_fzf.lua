---@module 'config.harpoon.ui.menu_fzf'
--- FZF-based Harpoon file list with shortened labels.
--- Falls back to Harpoon's own quick menu if fzf-lua is unavailable.

local M = {}

local notify = require("lib.nvim.notify").create("[config.harpoon.menu_fzf]")
local path_shorten = require("lib.nvim.fs.path_shorten")

---@type boolean  Whether the fzf-lua downgrade has already been announced.
local _warned_no_fzf = false

---@return boolean
local function has_fzf_lua()
  return pcall(require, "fzf-lua")
end

---@type boolean|nil  nil until the first preview asks
local _has_bat = nil

---Whether `bat` is on PATH, probed once per session.
---
---`vim.fn.executable()` does not cache, and fzf-lua calls `preview` once per
---item the cursor lands on -- so an uncached probe here runs on every arrow
---key. Measured on this machine: ~13.6 ms when the tool IS found, ~48 ms
---when it is not, because a miss walks every PATH entry against every
---PATHEXT suffix. That is a visible stutter while scrolling the list.
---
---Probed lazily rather than at module load, so the cost lands on the first
---preview instead of on startup. A `bat` installed mid-session is not
---picked up until the next start; that is the intended trade.
---@return boolean
local function has_bat()
  if _has_bat == nil then
    _has_bat = vim.fn.executable("bat") == 1
  end
  return _has_bat
end

---@param path string
---@return nil
local function open_file(path)
  -- Basic open; enhance to open in current window/split if desired
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

---@return nil
function M.open()
  local ok, harpoon = pcall(require, "harpoon")
  if not ok then
    return
  end

  local list = harpoon:list()
  if not (list and type(list.items) == "table") then
    return
  end

  if has_fzf_lua() then
    local fzf = require("fzf-lua")
    local items = list.items
    local n = #items
    local entries = { [n] = "" }
    for i = 1, n do
      local it = items[i]
      local v = (type(it) == "table") and it.value or tostring(it)
      entries[i] = string.format("%s\0%s", path_shorten(v, nil, { style = "label" }), v)
    end

    fzf.fzf_exec(entries, {
      prompt = "Harpoon> ",
      fzf_opts = {
        ["--with-nth"] = "1",
        ["--delimiter"] = "\\x00",
        ["--ansi"] = "1",
        ["--expect"] = table.concat({
          "enter",
          "ctrl-v",
          "ctrl-x",
          "ctrl-t",
        }, ","),
      },
      preview = function(item)
        local p = item:match("\0(.*)$") or ""
        -- Simple preview via bat if present; otherwise plain cat
        if has_bat() then
          return "bat --style=plain --color=always --pager=never " .. vim.fn.shellescape(p)
        end
        return "cat " .. vim.fn.shellescape(p)
      end,
      actions = {
        ["default"] = function(selected)
          local line = selected[1] or ""
          local p = line:match("\0(.*)$")
          if p then
            open_file(p)
          end
        end,
        ["ctrl-x"] = function(selected) -- split
          local line = selected[1] or ""
          local p = line:match("\0(.*)$")
          if p then
            vim.cmd("split " .. vim.fn.fnameescape(p))
          end
        end,
        ["ctrl-v"] = function(selected) -- vsplit
          local line = selected[1] or ""
          local p = line:match("\0(.*)$")
          if p then
            vim.cmd("vsplit " .. vim.fn.fnameescape(p))
          end
        end,
        ["ctrl-t"] = function(selected) -- tab
          local line = selected[1] or ""
          local p = line:match("\0(.*)$")
          if p then
            vim.cmd("tabedit " .. vim.fn.fnameescape(p))
          end
        end,
      },
    })
  else
    -- Fallback: Harpoon quick menu. Must go through the harpoon singleton's
    -- `ui` INSTANCE (require("harpoon").ui), not the harpoon.ui MODULE
    -- (require("harpoon.ui"), the bare class table) -- and as a method call
    -- (`:`), since toggle_quick_menu reads `self` off the first argument. A
    -- plain `require("harpoon.ui").toggle_quick_menu(list)` would pass `list`
    -- as `self` and nil as `list` (opens nothing), and calling it on the
    -- class table instead of the instance would track win_id/bufnr on a
    -- second, disconnected "menu" that the default quick menu never sees.
    -- `harpoon` here is the same singleton already required at the top of
    -- M.open().
    --
    -- UI-03: the downgrade is announced rather than silent -- the user asked
    -- for this menu and gets a visibly different one, which without a word
    -- reads as a bug in the keymap. Once per session, because the condition
    -- cannot change until fzf-lua is installed and Neovim restarted.
    if not _warned_no_fzf then
      _warned_no_fzf = true
      notify.warn("fzf-lua not available — falling back to Harpoon's own quick menu")
    end
    if harpoon.ui and type(harpoon.ui.toggle_quick_menu) == "function" then
      harpoon.ui:toggle_quick_menu(list)
    else
      -- Neither backend available: say so instead of returning as if the
      -- menu had been opened.
      notify.error("no Harpoon menu available (fzf-lua missing, quick menu unusable)")
    end
  end
end

return M
