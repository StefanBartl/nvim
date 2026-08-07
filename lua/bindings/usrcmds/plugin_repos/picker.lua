---@module 'bindings.usrcmds.plugin_repos.picker'
---@brief Interactive multi-select for `:MyPlugins picker` — batch different
---actions onto different plugins in one pass.
---@description
--- `M.open(path)` opens a `Snacks.picker` listing every entry in
--- `plugins.personal.list`. `<Tab>` cycles the highlighted plugin through a
--- per-presence action cycle (present: update → pull → fetch → remove →
--- reclone → none; missing: clone → none), shown as a one-letter marker in
--- front of the entry. `<CR>` closes the picker and runs every assigned
--- action in one batch — the two-machine `dir`-mode sync case this whole
--- command exists for (see `init.lua`'s module doc) is exactly "some repos
--- need `update`, maybe one needs `reclone` because it got into a weird
--- state, pick them all at once and go".
---
--- Execution reuses `ops.lua` — the same primitives `init.lua`'s flat
--- `fetch`/`pull`/`update`/`clone`/`remove`/`reclone` subcommands call — so
--- a batch run here has exactly the same safety checks (removal only after
--- `git status --porcelain --branch` comes back clean) and confirmation
--- prompt (naming exactly what gets deleted) as running those commands by
--- hand.

local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos.picker]")
local ops = require("bindings.usrcmds.plugin_repos.ops")
local plugin_list = require("plugins.personal.list")

local M = {}

local loop, fn = vim.uv or vim.loop, vim.fn

-- Cycle order per presence state. "none" (nil in `pending`) is always the
-- implicit first/last step, i.e. cycling past the last entry clears it.
local PRESENT_CYCLE = { "update", "pull", "fetch", "remove", "reclone" }
local MISSING_CYCLE = { "clone" }

---@type table<string, {[1]: string, [2]: string}>
local MARKER = {
  update = { "U", "DiagnosticInfo" },
  pull = { "P", "DiagnosticInfo" },
  fetch = { "F", "DiagnosticInfo" },
  remove = { "R", "DiagnosticError" },
  reclone = { "X", "DiagnosticWarn" },
  clone = { "C", "DiagnosticOk" },
}

-- "statusline" reports into the shared lib.nvim.progress registry — same
-- convention as init.lua and every other personal-plugin usrcmd here.
local ok_progress, progress_mod = pcall(require, "lib.nvim.progress")
---@param title string
local function new_progress(title)
  if not ok_progress then
    return nil
  end
  return progress_mod.create({ title = title, style = "statusline" })
end

---@param cycle string[]
---@param current string|nil
---@return string|nil
local function next_action(cycle, current)
  if not current then
    return cycle[1]
  end
  for i, action in ipairs(cycle) do
    if action == current then
      return cycle[i + 1] -- nil past the last entry → "none"
    end
  end
  return cycle[1]
end

---Runs `fetch_one`/`pull_one`/`update_one` over a plain list of `{name=...}`
---planned entries, notifying one summary. Mirrors `init.lua`'s
---`run_listed_op`, just against an already-known set instead of re-deriving
---presence from disk — including its "changed vs already up to date"
---breakdown, when `op_fn` reports it (fetch/pull/update all do).
---@param gerund string
---@param past string
---@param op_fn fun(path: string, on_done: fun(ok: boolean, err: string|nil, changed: boolean|nil))
---@param planned {name: string}[]
---@param base_dir string
---@param on_done fun()
local function run_git_phase(gerund, past, op_fn, planned, base_dir, on_done)
  if #planned == 0 then
    on_done()
    return
  end
  local prog = new_progress(("[usrcmds.plugin_repos.picker] %s"):format(gerund:lower()))
  notify.info(("%s %d plugin(s)..."):format(gerund, #planned))

  local changed_count, unchanged_count = 0, 0

  ops.run_sequential(
    planned,
    function(p, cb)
      op_fn(base_dir .. "/" .. p.name, function(ok, err, changed)
        if ok and changed ~= nil then
          if changed then
            changed_count = changed_count + 1
          else
            unchanged_count = unchanged_count + 1
          end
        end
        cb(ok, err)
      end)
    end,
    function(p) return p.name end,
    function(ok_items, failed)
      if prog then
        prog:finish(("%d %s, %d failed"):format(#ok_items, past, #failed))
      end
      local detail = ""
      if changed_count + unchanged_count > 0 then
        detail = (" (%d changed, %d already up to date)"):format(changed_count, unchanged_count)
      end
      if #failed > 0 then
        local lines = {}
        for _, f in ipairs(failed) do
          lines[#lines + 1] = f.item.name .. ": " .. f.err
        end
        notify.warn(("%d %s%s, failed:\n%s"):format(#ok_items, past, detail, table.concat(lines, "\n")))
      else
        notify.info(("%d repositor%s %s%s"):format(#ok_items, #ok_items == 1 and "y" or "ies", past, detail))
      end
      on_done()
    end,
    prog
  )
end

---Clones every planned entry (already filtered to "should be cloned"),
---notifies one summary, then continues the pipeline.
---@param planned {name: string, repo: string}[]
---@param base_dir string
---@param on_done fun()
local function run_clone_phase(planned, base_dir, on_done)
  if #planned == 0 then
    on_done()
    return
  end
  local prog = new_progress("[usrcmds.plugin_repos.picker] cloning")
  notify.info(("Cloning %d plugin(s)..."):format(#planned))
  ops.run_sequential(
    planned,
    function(p, cb)
      ops.clone_one(p, base_dir, function(status, err) cb(status ~= "failed", err) end)
    end,
    function(p) return p.name end,
    function(ok_items, failed)
      if prog then
        prog:finish(("%d cloned, %d failed"):format(#ok_items, #failed))
      end
      if #failed > 0 then
        local lines = {}
        for _, f in ipairs(failed) do
          lines[#lines + 1] = f.item.name .. ": " .. f.err
        end
        notify.warn(("%d cloned, failed:\n%s"):format(#ok_items, table.concat(lines, "\n")))
      else
        notify.info(("%d repositor%s cloned"):format(#ok_items, #ok_items == 1 and "y" or "ies"))
      end
      on_done()
    end,
    prog
  )
end

---Safety-checks, confirms and deletes the "remove"/"reclone" set, then hands
---off whatever needs cloning (reclone's safe entries, plus every plain
---"clone"/reclone-of-missing entry) to `run_clone_phase`, then the
---fetch/pull/update phases, in that order.
---@param removal {name: string, repo: string, action: "remove"|"reclone"}[]
---@param direct_clone {name: string, repo: string}[]
---@param fetch_items {name: string}[]
---@param pull_items {name: string}[]
---@param update_items {name: string}[]
---@param base_dir string
local function run_batch(removal, direct_clone, fetch_items, pull_items, update_items, base_dir)
  local function after_removal(to_clone)
    vim.list_extend(to_clone, direct_clone)
    run_clone_phase(to_clone, base_dir, function()
      run_git_phase("Fetching", "fetched", ops.fetch_one, fetch_items, base_dir, function()
        run_git_phase("Pulling", "pulled", ops.pull_one, pull_items, base_dir, function()
          run_git_phase("Updating", "updated", ops.update_one, update_items, base_dir, function()
            notify.info("MyPlugins picker: batch finished")
          end)
        end)
      end)
    end)
  end

  if #removal == 0 then
    after_removal({})
    return
  end

  local prog = new_progress("[usrcmds.plugin_repos.picker] checking")
  notify.info(("Checking %d plugin(s) for uncommitted/unpushed work..."):format(#removal))
  ops.run_sequential(
    removal,
    function(p, cb) ops.check_removable(base_dir .. "/" .. p.name, cb) end,
    function(p) return p.name end,
    function(safe, failed)
      if prog then
        prog:finish(("%d clean, %d left alone"):format(#safe, #failed))
      end
      if #failed > 0 then
        local lines = {}
        for _, f in ipairs(failed) do
          lines[#lines + 1] = f.item.name .. " (" .. f.err .. ")"
        end
        notify.warn("Left alone (not clean, not touched):\n" .. table.concat(lines, "\n"))
      end
      if #safe == 0 then
        after_removal({})
        return
      end

      local names = {}
      for _, p in ipairs(safe) do
        names[#names + 1] = ("%s (%s)"):format(p.name, p.action)
      end
      local msg = ("Delete %d repositor%s from %s?\n\n%s"):format(
        #safe, #safe == 1 and "y" or "ies", base_dir, table.concat(names, "\n"))
      local choice = fn.confirm(msg, "&Yes, delete\n&No", 2)
      if choice ~= 1 then
        notify.info("Deletion cancelled — remove/reclone skipped for this batch.")
        after_removal({})
        return
      end

      local to_clone, delete_failed = {}, {}
      for _, p in ipairs(safe) do
        if ops.delete_one(base_dir .. "/" .. p.name) then
          if p.action == "reclone" then
            to_clone[#to_clone + 1] = p
          end
        else
          delete_failed[#delete_failed + 1] = p.name
        end
      end
      if #delete_failed > 0 then
        notify.error("Failed to remove: " .. table.concat(delete_failed, ", "))
      end
      after_removal(to_clone)
    end,
    prog
  )
end

---@param path string|nil
function M.open(path)
  local ok_snacks, Snacks = pcall(require, "snacks")
  if not ok_snacks or not Snacks.picker then
    notify.error("snacks.nvim picker is not available")
    return
  end

  local base_dir = ops.resolve_base_dir(path)
  if not base_dir then
    notify.error("No repository directory provided and REPOS_DIR is not set")
    return
  end

  local entries, err = plugin_list.read()
  if not entries then
    notify.error(tostring(err))
    return
  end

  ---@type table<string, string>
  local pending = {}

  local items = {}
  for _, entry in ipairs(entries) do
    items[#items + 1] = {
      text = entry.name .. " " .. entry.repo,
      name = entry.name,
      repo = entry.repo,
      present = loop.fs_stat(base_dir .. "/" .. entry.name) ~= nil,
    }
  end

  Snacks.picker({
    source = "myplugins_repos",
    title = "MyPlugins — <Tab> cycle action, <CR> run batch",
    items = items,
    format = function(item)
      local action = pending[item.name]
      local mark, hl = "\194\183", "Comment" -- "·"
      if action then
        mark, hl = MARKER[action][1], MARKER[action][2]
      end
      return {
        { "[", "Comment" },
        { mark, hl },
        { "] ", "Comment" },
        { item.present and "+ " or "- ", item.present and "DiagnosticOk" or "DiagnosticHint" },
        { item.name },
        { "  " },
        { item.repo, "Comment" },
      }
    end,
    actions = {
      myplugins_cycle = function(picker, item)
        if not item then
          return
        end
        local cycle = item.present and PRESENT_CYCLE or MISSING_CYCLE
        pending[item.name] = next_action(cycle, pending[item.name])
        picker:refresh()
      end,
      myplugins_confirm = function(picker)
        picker:close()

        local removal, direct_clone, fetch_items, pull_items, update_items = {}, {}, {}, {}, {}
        for _, item in ipairs(items) do
          local action = pending[item.name]
          if action == "remove" or action == "reclone" then
            if item.present then
              removal[#removal + 1] = { name = item.name, repo = item.repo, action = action }
            elseif action == "reclone" then
              direct_clone[#direct_clone + 1] = { name = item.name, repo = item.repo }
            end
          elseif action == "clone" then
            direct_clone[#direct_clone + 1] = { name = item.name, repo = item.repo }
          elseif action == "fetch" then
            fetch_items[#fetch_items + 1] = { name = item.name }
          elseif action == "pull" then
            pull_items[#pull_items + 1] = { name = item.name }
          elseif action == "update" then
            update_items[#update_items + 1] = { name = item.name }
          end
        end

        if #removal + #direct_clone + #fetch_items + #pull_items + #update_items == 0 then
          notify.info("No actions assigned — nothing to do")
          return
        end

        vim.schedule(function()
          run_batch(removal, direct_clone, fetch_items, pull_items, update_items, base_dir)
        end)
      end,
    },
    win = {
      input = {
        keys = {
          ["<Tab>"] = { "myplugins_cycle", mode = { "n", "i" } },
          ["<CR>"] = { "myplugins_confirm", mode = { "n", "i" } },
        },
      },
      list = {
        keys = {
          ["<Tab>"] = "myplugins_cycle",
          ["<CR>"] = "myplugins_confirm",
        },
      },
    },
  })
end

return M
