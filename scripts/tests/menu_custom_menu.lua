--- Headless check of the right-click menu's general section
--- (`config.menu.custom_menu`): selection capture for "Copy/Delete Marked",
--- and that every entry (incl. Save / Save All) exists and is callable.
---
--- Run:  nvim --headless -u NONE -c "luafile scripts/tests/menu_custom_menu.lua"
--- Exits non-zero on the first failing assertion.

local repos = vim.env.REPOS_DIR or "B:/repos"
vim.g.have_nerd_font = 1
vim.opt.rtp:prepend(repos .. "/lib.nvim")
vim.opt.rtp:prepend(repos .. "/ui.nvim")
vim.opt.rtp:prepend(vim.fn.stdpath("config"))

local failures = 0

---@param name string
---@param ok boolean
local function check(name, ok)
  print((ok and "PASS " or "FAIL ") .. name)
  if not ok then
    failures = failures + 1
  end
end

local function items()
  return require("config.menu.custom_menu")({})
end

--- The callable entry whose label contains `label`, searched through fly-outs.
---@param list table[]
---@param label string
---@return table|nil
local function find(list, label)
  for _, it in ipairs(list) do
    if it.name and it.name:find(label, 1, true) and it.cmd then
      return it
    end
    if it.items then
      local r = find(it.items, label)
      if r then
        return r
      end
    end
  end
end

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "alpha beta", "gamma delta", "epsilon" })

-- The menu is built while Visual mode is live; the entry runs after it ended.
vim.fn.setpos(".", { 0, 1, 7, 0 })
vim.cmd("normal! v")
vim.fn.setpos(".", { 0, 2, 3, 0 })
local built = items()
vim.cmd("normal! \27")
find(built, "Copy Marked").cmd()
check("copy marked copies the selection, not the buffer", vim.fn.getreg("+") == "beta\ngam")

vim.fn.setreg("+", "")
find(items(), "Copy Marked").cmd()
check(
  "copy marked without a selection copies the buffer",
  vim.fn.getreg("+"):find("epsilon") ~= nil
)

vim.fn.setpos(".", { 0, 1, 1, 0 })
vim.cmd("normal! v")
vim.fn.setpos(".", { 0, 1, 6, 0 })
built = items()
vim.cmd("normal! \27")
find(built, "Delete Marked").cmd()
check(
  "delete marked removes only the selection",
  vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "beta"
)

local tmp = vim.fn.tempname()
vim.cmd("file " .. vim.fn.fnameescape(tmp))
local save = find(items(), "Save")
check("Save entry exists", save ~= nil and find(items(), "Save All") ~= nil)
save.cmd()
check("Save writes the file", vim.fn.filereadable(tmp) == 1)
vim.fn.delete(tmp)

for _, l in ipairs({
  "Format Buffer",
  "Code Actions",
  "Inspect",
  "Copy All",
  "Paste Content",
  "Delete All",
  "Delete File",
  "Open in terminal",
  "Color Picker",
  "Unicode Table",
}) do
  check("entry present: " .. l, find(items(), l) ~= nil)
end

vim.cmd(failures == 0 and "qa!" or "cquit 1")
