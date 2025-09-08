---@module 'config.harpoon.ui.menu_fzf'
--- FZF-based Harpoon file list with shortened labels.
--- Falls back to Harpoon's own quick menu if fzf-lua is unavailable.

local M = {}

local label = require("config.harpoon.utils.path_label")

---@return boolean
local function has_fzf_lua()
  return pcall(require, "fzf-lua")
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
  if not ok then return end

  local list = harpoon:list()
  if not (list and type(list.items) == "table") then return end

  if has_fzf_lua() then
    local fzf = require("fzf-lua")
    local entries ---@type string[]
    entries = {}

    -- Build lines with a stable "label\0path" payload to avoid parsing collisions
    for i = 1, #list.items do
      local it = list.items[i]
      local v = (type(it) == "table") and it.value or tostring(it)
      local lbl = label.to_label(v)
      entries[#entries+1] = string.format("%s\0%s", lbl, v)
    end

    fzf.fzf_exec(entries, {
      prompt = "Harpoon> ",
      fzf_opts = {
        ["--with-nth"] = "1",
        ["--delimiter"] = "\\x00",
        ["--ansi"] = "1",
        ["--expect"] = table.concat({
          "enter", "ctrl-v", "ctrl-x", "ctrl-t",
        }, ","),
      },
      preview = function(item)
        local p = item:match("\0(.*)$") or ""
        -- Simple preview via bat if present; otherwise plain cat
        local ok_bat = vim.fn.executable("bat") == 1
        if ok_bat then
          return "bat --style=plain --color=always --pager=never " .. vim.fn.shellescape(p)
        end
        return "cat " .. vim.fn.shellescape(p)
      end,
      actions = {
        ["default"] = function(selected)
          local line = selected[1] or ""
          local p = line:match("\0(.*)$")
          if p then open_file(p) end
        end,
        ["ctrl-x"] = function(selected)  -- split
          local line = selected[1] or ""
          local p = line:match("\0(.*)$")
          if p then vim.cmd("split " .. vim.fn.fnameescape(p)) end
        end,
        ["ctrl-v"] = function(selected)  -- vsplit
          local line = selected[1] or ""
          local p = line:match("\0(.*)$")
          if p then vim.cmd("vsplit " .. vim.fn.fnameescape(p)) end
        end,
        ["ctrl-t"] = function(selected)  -- tab
          local line = selected[1] or ""
          local p = line:match("\0(.*)$")
          if p then vim.cmd("tabedit " .. vim.fn.fnameescape(p)) end
        end,
      },
    })
  else
    -- Fallback: Harpoon quick menu
    local ok_ui, ui = pcall(require, "harpoon.ui")
    if ok_ui and type(ui.toggle_quick_menu) == "function" then
      ui.toggle_quick_menu(list)
    end
  end
end

return M

