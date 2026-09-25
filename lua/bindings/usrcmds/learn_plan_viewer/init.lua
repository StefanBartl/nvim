---@module 'bindings.usrcmds.learn_plan_viewer'
--- `:LearnPlanViewer [week N]` — standalone viewer for the CLI-Lernplan week
--- pages (`docs/ROADMAP/CLI_Lernplan/week-NN.md`). Independent of the
--- `learn-cli.nvim` plugin (which stays disabled, see
--- `docs/ROADMAP/LONG_RUN/learn-cli.nvim.md`, "Grundsatzfrage") — this is a
--- thin buffer + two keymaps + a checkbox toggle, not a second exercise
--- engine.
---
--- Opens a week page in a normal buffer for navigation/editing (checkbox
--- toggling), and can additionally push the current week to the browser via
--- mdview.nvim (`:MDView start`) for reading.
---
--- Commands:
---   :LearnPlanViewer            resume at the last-opened week (or week 1)
---   :LearnPlanViewer week N     jump straight to week N
---
--- Buffer-local keymaps (only in a week-page buffer):
---   <leader>ln   next week
---   <leader>lp   previous week
---   <leader>lx   toggle the checkbox on the current line
---   <leader>lb   open the current week in the browser (mdview.nvim)

local config = require("bindings.usrcmds.learn_plan_viewer.config")
local usercmd = require("lib.nvim.bindings.usercmd")
local json = require("lib.nvim.fs.json")
local notify = require("lib.nvim.notify").create("[learn_plan_viewer]")

local M = {}

--- Marks a buffer as "this is a Lernplan week page" so the keymaps below only
--- ever act on the right buffer, and so a second `:LearnPlanViewer` call
--- reuses an already-open window instead of stacking splits.
---@type table<integer, integer> bufnr -> week number
local open_weeks = {}

---@return integer
local function last_week()
  local state = json.read(config.state_file())
  local n = state and state.last_week
  if type(n) ~= "number" or n < 1 or n > config.week_count then
    return 1
  end
  return n
end

---@param n integer
local function remember_week(n)
  local ok, err = json.write(config.state_file(), { last_week = n })
  if not ok then
    notify.warn("Fortschritt konnte nicht gespeichert werden: " .. tostring(err))
  end
end

---@param n integer
---@return boolean
local function valid_week(n)
  return type(n) == "number" and n >= 1 and n <= config.week_count
end

--- Toggle `[ ]` <-> `[x]` on the current line (a repetition or "Woche
--- abgeschlossen" checkbox). No-op outside a checkbox line.
local function toggle_checkbox()
  local line = vim.api.nvim_get_current_line()
  local new_line, count = line:gsub("%[ %]", "[x]", 1)
  if count == 0 then
    new_line, count = line:gsub("%[x%]", "[ ]", 1)
  end
  if count == 0 then
    notify.info("Keine Checkbox in dieser Zeile")
    return
  end
  vim.api.nvim_set_current_line(new_line)
end

---@param n integer
local function open_week(n)
  if not valid_week(n) then
    notify.error(("Woche %s existiert nicht (1-%d)"):format(tostring(n), config.week_count))
    return
  end

  local path = config.week_path(n)
  if vim.fn.filereadable(path) ~= 1 then
    notify.error("Seite fehlt: " .. path)
    return
  end

  -- Reuse an already-open week buffer's window instead of stacking splits.
  for bufnr, week in pairs(open_weeks) do
    if week == n and vim.api.nvim_buf_is_valid(bufnr) then
      local win = vim.fn.bufwinid(bufnr)
      if win ~= -1 then
        vim.api.nvim_set_current_win(win)
        remember_week(n)
        return
      end
    end
  end

  vim.cmd("edit " .. vim.fn.fnameescape(path))
  local bufnr = vim.api.nvim_get_current_buf()
  open_weeks[bufnr] = n
  remember_week(n)

  local map = vim.keymap.set
  local opts = { buffer = bufnr, silent = true }
  map("n", "<leader>ln", function()
    open_week(n + 1)
  end, vim.tbl_extend("force", opts, { desc = "Lernplan: nächste Woche" }))
  map("n", "<leader>lp", function()
    open_week(n - 1)
  end, vim.tbl_extend("force", opts, { desc = "Lernplan: vorige Woche" }))
  map("n", "<leader>lx", toggle_checkbox, vim.tbl_extend("force", opts, { desc = "Lernplan: Checkbox umschalten" }))
  map("n", "<leader>lb", function()
    vim.cmd("MDView start " .. vim.fn.fnameescape(path))
  end, vim.tbl_extend("force", opts, { desc = "Lernplan: Woche im Browser öffnen (mdview.nvim)" }))

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = bufnr,
    once = true,
    callback = function()
      open_weeks[bufnr] = nil
    end,
  })
end

function M.enable()
  usercmd.create("LearnPlanViewer", function(args)
    local fargs = args.fargs
    if fargs[1] == "week" and fargs[2] then
      open_week(tonumber(fargs[2]))
      return
    end
    open_week(last_week())
  end, {
    nargs = "*",
    desc = "CLI-Lernplan-Viewer öffnen (optional: week N)",
    complete = function(_, cmdline)
      if cmdline:match("^LearnPlanViewer%s+%S*$") then
        return { "week" }
      end
      return {}
    end,
  })
end

return M
