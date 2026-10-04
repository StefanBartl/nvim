---@module 'bindings.usrcmds.plugin_repos.tasks_dash'
---@brief The interactive task dashboard behind `:MyPlugins tasks [<area>|all]` (concept section 6).
---@description
--- A `Snacks.picker` source (the engine `picker.lua` uses): one line per open
--- task, the task file as the preview, the counts and the filter chips in the
--- title. Without snacks.nvim a small `vim.ui.select` flow offers the same
--- actions for one task at a time (no batch).
---
--- Keys (list window; the input window has them as Alt chords, `<M-s>` `<M-p>` `<M-d>`
--- `<M-f>` `<M-o>` `<M-e>` `<M-r>` `<M-b>` (backlog) `<M-m>` (roadmap) `<M-?>`, in normal and insert mode):
---  - `<CR>` open the file(s)    `<Tab>` / `<S-Tab>` mark (snacks' own multi-select)
---  - `s` / `p`  advance status / prio of the marked (else the current) tasks,
---    ONE batch, ONE notification, each touched area's index regenerated once
---  - `D` finish (asks first)   `f` set a filter chip   `o` sort order   `e` export   `r` rescan
---  - `gb` / `gr` Backlog / ROADMAP.md of the area under the cursor   `g?` help
---
--- Prompting keys (`D`, `f`, `e`, `gb`, `gr`) close the picker first -- snacks
--- closes a picker whose window loses focus -- and `D` and `f` reopen it when
--- the prompt is over. `s` / `p` refresh in place.
---
--- Not its job: the rules about a line, a filter or a cycle (`tasks_dash_core`),
--- the delivery sinks (`tasks_view`), the rules of tasks (the engine).

local confirm = require("bindings.usrcmds.plugin_repos.confirm")
local core = require("bindings.usrcmds.plugin_repos.tasks_dash_core")
local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos.tasks_dash]")
local view = require("bindings.usrcmds.plugin_repos.tasks_view")

local M = {}

---Key under which the last filter is remembered (`lib.nvim.store.project`).
local STORE_KEY = "tasks/dashboard-filter"

---Most task lines the finish confirmation lists before it says "... and n more".
local MAX_CONFIRM_LINES = 8

---@class Plugin_repos.TasksDashState
---@field root string
---@field area string|nil
---@field filter Tasks.Filter
---@field sort string          # One of `model.SORTS` (`o` cycles it).
---@field shown Tasks.Task[]
---@field widths { area: integer, effort: integer, status: integer }
---@field persist boolean

---@class Plugin_repos.TasksDashOpts
---@field persist? boolean   # Remember the filter between sessions (default true).
---@field backend? "snacks"|"select"   # Force a backend (default: snacks when present).

-- ── small helpers ────────────────────────────────────────────────────────────

---@return table
local function cmd()
  return require("bindings.usrcmds.plugin_repos.tasks_cmd")
end

-- "statusline" reports into the shared lib.nvim.progress registry, like picker.lua.
local ok_progress, progress_mod = pcall(require, "lib.nvim.progress")
---@param title string
local function new_progress(title)
  if not ok_progress then
    return nil
  end
  return progress_mod.create({ title = title, style = "statusline" })
end

---@param state Plugin_repos.TasksDashState
local function persist(state)
  if not state.persist then
    return
  end
  local ok, store = pcall(require, "lib.nvim.store.project")
  if ok then
    pcall(
      store.save,
      STORE_KEY,
      { filter = core.filter_to_options(state.filter), sort = state.sort },
      { path = state.root }
    )
  end
end

---@param root string
---@return Tasks.Filter filter
---@return string sort
local function remembered(root)
  local ok, store = pcall(require, "lib.nvim.store.project")
  if not ok then
    return {}, "default"
  end
  local ok_load, data = pcall(store.load, STORE_KEY, { path = root })
  if not ok_load or type(data) ~= "table" then
    return {}, "default"
  end
  return core.filter_from_stored(data.filter), core.sort_from_stored(data.sort)
end

---Dashboard state for a `Plugin_repos.TasksView`: the command's own filter and
---sort order if it carried them, else the ones remembered from the last session.
---@param v Plugin_repos.TasksView
---@param opts? Plugin_repos.TasksDashOpts
---@return Plugin_repos.TasksDashState
function M.new_state(v, opts)
  opts = opts or {}
  local filter = v.filter or {}
  local sort = (v.sort and v.sort ~= "") and v.sort or "default"
  local do_persist = opts.persist ~= false
  if do_persist then
    local last_filter, last_sort = remembered(v.root)
    if core.filter_is_empty(filter) then
      filter = last_filter
    end
    if sort == "default" then
      sort = last_sort
    end
  end
  return {
    root = v.root,
    area = v.area,
    filter = filter,
    sort = sort,
    shown = {},
    widths = core.widths({}),
    persist = do_persist,
  }
end

---Rescan and refilter; the result is `state.shown`.
---@param state Plugin_repos.TasksDashState
---@return Tasks.Task[]
local function reload(state)
  local res, err = core.load({
    root = state.root,
    area = state.area,
    filter = state.filter,
    sort = state.sort,
  })
  if not res then
    notify.error(("cannot read the tasks: %s"):format(tostring(err)))
    state.shown = {}
  else
    state.shown = res.tasks
  end
  state.widths = core.widths(state.shown)
  return state.shown
end

---@param state Plugin_repos.TasksDashState
---@return string
local function title_of(state)
  return core.header(state.shown, state.filter, state.area, state.sort)
end

---@param tasks Tasks.Task[]
---@return string[] lines
local function describe(tasks)
  local lines = {}
  for i, t in ipairs(tasks) do
    if i > MAX_CONFIRM_LINES then
      lines[#lines + 1] = ("... and %d more"):format(#tasks - MAX_CONFIRM_LINES)
      break
    end
    lines[#lines + 1] = ("%s  %s"):format(t.id, t.title)
  end
  return lines
end

---The tasks of the vault's open list by id (for the refresh of buffers after a write).
---@param res Plugin_repos.TasksDashSetResult
local function refresh_buffers(res)
  local c = cmd()
  if type(c.refresh_buffers) ~= "function" then
    return
  end
  for _, ch in ipairs(res.changed) do
    c.refresh_buffers(ch.path)
  end
end

-- ── the actions (shared by the picker and the fallback) ──────────────────────

---`s` / `p`: advance the field of every target in one batch.
---@param state Plugin_repos.TasksDashState
---@param tasks Tasks.Task[]
---@param field "status"|"prio"
---@return Plugin_repos.TasksDashSetResult|nil result
function M.cycle(state, tasks, field)
  if #tasks == 0 then
    return nil
  end
  local prog = new_progress("[usrcmds.plugin_repos.tasks_dash] " .. field)
  local res = core.apply_set(core.plan_cycle(tasks, field), { root = state.root })
  refresh_buffers(res)
  local level, text = core.describe_set(field, res)
  if prog then
    prog:finish(("%d changed, %d failed"):format(#res.changed, #res.failed))
  end
  notify[level](text)
  return res
end

---`D`: ask once for the whole batch, then finish every target.
---@param state Plugin_repos.TasksDashState
---@param tasks Tasks.Task[]
---@param after fun(done: boolean)  # Called once, after the answer and the work.
function M.finish(state, tasks, after)
  if #tasks == 0 then
    after(false)
    return
  end
  local msg = ("Finish %d task%s?\n\n%s\n\nThey move to Backlog/."):format(
    #tasks,
    #tasks == 1 and "" or "s",
    table.concat(describe(tasks), "\n")
  )
  confirm.yesno(msg, "finish", function(accepted)
    if not accepted then
      notify.info("cancelled -- the tasks stay open")
      after(false)
      return
    end
    local ids = {}
    for _, t in ipairs(tasks) do
      ids[#ids + 1] = t.id
    end
    local prog = new_progress("[usrcmds.plugin_repos.tasks_dash] done")
    local res = core.apply_done(ids, { root = state.root })
    for _, d in ipairs(res.done) do
      cmd().retarget_buffers(d.from, d.to)
    end
    local level, text = core.describe_done(res)
    if prog then
      prog:finish(("%d finished, %d failed"):format(#res.done, #res.failed))
    end
    notify[level](text)
    after(#res.done > 0)
  end)
end

---`f`: pick a dimension, then a value; empty choices clear.
---@param state Plugin_repos.TasksDashState
---@param after fun()  # Called once, changed or not.
function M.set_filter(state, after)
  local dims = vim.deepcopy(core.FILTER_DIMS)
  dims[#dims + 1] = core.CLEAR_ALL
  local chips = core.chips(state.filter)
  vim.ui.select(dims, {
    prompt = "Filter: " .. (#chips > 0 and table.concat(chips, ", ") or "none"),
  }, function(dim)
    if not dim then
      after()
      return
    end
    if dim == core.CLEAR_ALL then
      state.filter = {}
      persist(state)
      after()
      return
    end
    if dim == "blocked" then
      state.filter = core.set_dim(state.filter, "blocked", not state.filter.blocked or nil)
      persist(state)
      after()
      return
    end
    local scope = core.load({ root = state.root, area = state.area, filter = {} })
    local choices = core.dim_choices(dim, scope and scope.tasks or {})
    table.insert(choices, 1, core.CLEAR)
    vim.ui.select(choices, { prompt = "Filter " .. dim }, function(value)
      if value then
        state.filter = core.set_dim(state.filter, dim, value ~= core.CLEAR and value or nil)
        persist(state)
      end
      after()
    end)
  end)
end

---`o`: the next sort order (default -> prio-effort -> severity -> default).
---@param state Plugin_repos.TasksDashState
function M.cycle_sort(state)
  state.sort = core.cycle_sort(state.sort)
  persist(state)
end

---`e`: ask where, deliver the tasks with the `--to=` sinks.
---@param state Plugin_repos.TasksDashState
---@param tasks Tasks.Task[]
---@param after fun(delivered: boolean)
function M.export(state, tasks, after)
  if #tasks == 0 then
    notify.info("nothing to export")
    after(false)
    return
  end
  vim.ui.select(core.EXPORT_CHOICES, {
    prompt = ("Export %d task%s"):format(#tasks, #tasks == 1 and "" or "s"),
    format_item = function(choice)
      return choice.label
    end,
  }, function(choice)
    if not choice then
      after(false)
      return
    end
    ---@param path string|nil
    local function deliver(path)
      local target, terr = core.export_target(choice, path)
      if not target then
        notify.warn(tostring(terr))
        after(false)
        return
      end
      if target.path then
        target.path = vim.fn.expand(target.path)
      end
      local chips = core.chips(state.filter)
      local sort_chip = core.sort_chip(state.sort)
      if sort_chip then
        chips[#chips + 1] = sort_chip
      end
      local ok, err = view.deliver(tasks, target, {
        format = choice.format,
        heading = ("Open tasks -- %s (%d)"):format(state.area or "all areas", #tasks),
        note = #chips > 0 and ("Filter: " .. table.concat(chips, ", ")) or nil,
        title = "myplugins://tasks/" .. (state.area or "all"),
      })
      if not ok then
        notify.error(("cannot export: %s"):format(tostring(err)))
        after(false)
        return
      end
      notify.info(("%d task(s) -> %s"):format(#tasks, choice.label))
      after(true)
    end
    if choice.ask_path then
      vim.ui.input({ prompt = "File path: ", completion = "file" }, deliver)
    else
      deliver(nil)
    end
  end)
end

---`gb` / `gr`: the Backlog picker, or ROADMAP.md, of an area.
---@param state Plugin_repos.TasksDashState
---@param task Tasks.Task|nil
---@param which "backlog"|"roadmap"
function M.open_area_doc(state, task, which)
  if not task then
    return
  end
  if which == "backlog" then
    cmd().open_area({ args = { area = task.area, folder = "backlog" }, flags = {} })
    return
  end
  local path = ("%s/%s/ROADMAP/ROADMAP.md"):format(state.root, task.area)
  if vim.fn.filereadable(path) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  else
    notify.warn(("%s has no ROADMAP/ROADMAP.md"):format(task.area))
  end
end

-- ── help ─────────────────────────────────────────────────────────────────────

M.HELP = {
  " Task dashboard ",
  "",
  " <CR>        open the file(s)",
  " <Tab>       mark / unmark (marked tasks are the target of s p D e)",
  " s           advance status of marked (else current) tasks",
  " p           advance prio:  none -> 1 -> 2 -> 3 -> none",
  " D           finish (asks first, moves to Backlog/)",
  " f           set a filter chip (status prio effort kind category severity tag blocked)",
  " o           cycle the sort: default -> prio-effort (small first) -> severity (critical first)",
  " e           export marked (else all shown) tasks",
  " r           rescan the vault",
  " gb / gr     Backlog picker / ROADMAP.md of the area under the cursor",
  " g?          this help",
  "",
  " Letters work in the list. In the input window use Alt:",
  " <M-s> <M-p> <M-d> <M-f> <M-o> <M-e> <M-r> <M-b>(backlog) <M-m>(roadmap) <M-?>",
  " (any key closes this help)",
}

---Float with the key help; any key closes it again (the picker keeps focus).
function M.show_help()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.HELP)
  local width = 0
  for _, l in ipairs(M.HELP) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = math.max(0, math.floor((vim.o.lines - #M.HELP) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
    width = width + 2,
    height = #M.HELP,
    style = "minimal",
    border = "rounded",
    zindex = 250,
  })
  local ns = vim.api.nvim_create_namespace("tasks_dash_help")
  vim.on_key(function()
    vim.on_key(nil, ns)
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end)
  end, ns)
end

-- ── snacks backend ───────────────────────────────────────────────────────────

local open_state

---@param Snacks table
---@param state Plugin_repos.TasksDashState
local function open_snacks(Snacks, state)
  ---Marked tasks, else (with `fallback`) the current one.
  ---@param picker table
  ---@param fallback boolean
  ---@return Tasks.Task[]
  local function targets(picker, fallback)
    local out = {}
    for _, item in ipairs(picker:selected({ fallback = fallback })) do
      if item and item.task then
        out[#out + 1] = item.task
      end
    end
    return out
  end

  ---Close the picker, run `fn`, and reopen the dashboard when `fn` says so.
  ---@param picker table
  ---@param fn fun(reopen: fun())
  local function detour(picker, fn)
    picker:close()
    vim.schedule(function()
      fn(function()
        open_state(state, { backend = "snacks" })
      end)
    end)
  end

  local function current_task(picker)
    local item = picker:current()
    return item and item.task or nil
  end

  local actions = {
    tasks_status = function(picker)
      if M.cycle(state, targets(picker, true), "status") then
        picker:refresh()
      end
    end,
    tasks_prio = function(picker)
      if M.cycle(state, targets(picker, true), "prio") then
        picker:refresh()
      end
    end,
    tasks_rescan = function(picker)
      picker:refresh()
    end,
    tasks_sort = function(picker)
      M.cycle_sort(state)
      picker:refresh()
    end,
    tasks_done = function(picker)
      local tasks = targets(picker, true)
      detour(picker, function(reopen)
        M.finish(state, tasks, function()
          reopen()
        end)
      end)
    end,
    tasks_filter = function(picker)
      detour(picker, function(reopen)
        M.set_filter(state, reopen)
      end)
    end,
    tasks_export = function(picker)
      local tasks = targets(picker, false)
      if #tasks == 0 then
        tasks = vim.deepcopy(state.shown)
      end
      detour(picker, function(reopen)
        M.export(state, tasks, function(delivered)
          if not delivered then
            reopen()
          end
        end)
      end)
    end,
    tasks_backlog = function(picker)
      local task = current_task(picker)
      picker:close()
      vim.schedule(function()
        M.open_area_doc(state, task, "backlog")
      end)
    end,
    tasks_roadmap = function(picker)
      local task = current_task(picker)
      picker:close()
      vim.schedule(function()
        M.open_area_doc(state, task, "roadmap")
      end)
    end,
    tasks_help = function()
      M.show_help()
    end,
  }

  -- Letters in the list window (nothing is typed there); Alt chords in the input
  -- window, so its normal-mode edits (`s` `p` `D` `e` ...) and the search typing
  -- in insert mode stay untouched.
  local letters = {
    s = { "tasks_status", "<M-s>" },
    p = { "tasks_prio", "<M-p>" },
    D = { "tasks_done", "<M-d>" },
    f = { "tasks_filter", "<M-f>" },
    o = { "tasks_sort", "<M-o>" },
    e = { "tasks_export", "<M-e>" },
    r = { "tasks_rescan", "<M-r>" },
    gb = { "tasks_backlog", "<M-b>" },
    gr = { "tasks_roadmap", "<M-m>" },
    ["g?"] = { "tasks_help", "<M-?>" },
  }
  local list_keys, input_keys = {}, {}
  for key, spec in pairs(letters) do
    list_keys[key] = spec[1]
    input_keys[spec[2]] = { spec[1], mode = { "n", "i" } }
  end

  Snacks.picker({
    source = "wkdbook_tasks",
    title = title_of(state),
    finder = function(_, ctx)
      local items = {}
      for _, t in ipairs(reload(state)) do
        items[#items + 1] = { text = core.search_text(t), file = t.path, task = t }
      end
      local picker = ctx and ctx.picker
      if picker then
        picker.title = title_of(state)
        vim.schedule(function()
          if not picker.closed then
            picker:update_titles()
          end
        end)
      end
      return items
    end,
    format = function(item)
      return core.parts(item.task, state.widths)
    end,
    preview = "file",
    confirm = "jump",
    -- An empty result (a filter that matches nothing) must stay open: `f` is how
    -- the user gets out of it.
    show_empty = true,
    actions = actions,
    win = { input = { keys = input_keys }, list = { keys = list_keys } },
  })
end

-- ── fallback backend ─────────────────────────────────────────────────────────

---@param state Plugin_repos.TasksDashState
local function open_select(state)
  local shown = reload(state)
  if #shown == 0 then
    notify.info("no open task matches (" .. title_of(state) .. ")")
    return
  end
  local function again()
    open_select(state)
  end
  vim.ui.select(shown, {
    prompt = title_of(state),
    format_item = function(t)
      return core.line(t, state.widths)
    end,
  }, function(task)
    if not task then
      return
    end
    ---@type { label: string, run: fun() }[]
    local menu = {
      {
        label = "open the file",
        run = function()
          vim.cmd("edit " .. vim.fn.fnameescape(task.path))
        end,
      },
      {
        label = "advance status",
        run = function()
          M.cycle(state, { task }, "status")
          again()
        end,
      },
      {
        label = "advance prio",
        run = function()
          M.cycle(state, { task }, "prio")
          again()
        end,
      },
      {
        label = "finish",
        run = function()
          M.finish(state, { task }, again)
        end,
      },
      {
        label = "filter ...",
        run = function()
          M.set_filter(state, again)
        end,
      },
      {
        label = "next sort order",
        run = function()
          M.cycle_sort(state)
          again()
        end,
      },
      {
        label = "export the list ...",
        run = function()
          M.export(state, vim.deepcopy(shown), function(delivered)
            if not delivered then
              again()
            end
          end)
        end,
      },
      {
        label = "Backlog of the area",
        run = function()
          M.open_area_doc(state, task, "backlog")
        end,
      },
      {
        label = "ROADMAP.md of the area",
        run = function()
          M.open_area_doc(state, task, "roadmap")
        end,
      },
    }
    vim.ui.select(menu, {
      prompt = task.id,
      format_item = function(m)
        return m.label
      end,
    }, function(choice)
      if choice then
        choice.run()
      end
    end)
  end)
end

-- ── entry ────────────────────────────────────────────────────────────────────

---@param state Plugin_repos.TasksDashState
---@param opts? Plugin_repos.TasksDashOpts
function open_state(state, opts)
  opts = opts or {}
  if opts.backend ~= "select" then
    local ok, Snacks = pcall(require, "snacks")
    if ok and type(Snacks) == "table" and Snacks.picker then
      local opened, err = pcall(open_snacks, Snacks, state)
      if opened then
        return
      end
      notify.warn(("snacks picker failed (%s), using the plain list"):format(tostring(err)))
    end
  end
  open_select(state)
end

---Open the dashboard for what `:MyPlugins tasks` collected. Never raises.
---@param v Plugin_repos.TasksView
---@param opts? Plugin_repos.TasksDashOpts
---@return Plugin_repos.TasksDashState|nil state
function M.open(v, opts)
  local ok, state = pcall(M.new_state, v, opts)
  if not ok then
    notify.error(("cannot open the dashboard: %s"):format(tostring(state)))
    return nil
  end
  local opened, err = pcall(open_state, state, opts)
  if not opened then
    notify.error(("cannot open the dashboard: %s"):format(tostring(err)))
    return nil
  end
  return state
end

return M
