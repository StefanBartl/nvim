---@module 'bindings.usrcmds.plugin_repos.machine'
---@brief `:MyPlugins machine [--pull]` - the machine-switch check of `scripts/sync-machine.ps1`.
---@description
--- Runs the PowerShell script (`-Json`) in the background and shows the result in a scratch
--- buffer, one line per repo under `$REPOS_DIR` (plugins, vaults, the native apps): behind,
--- ahead, dirty, and whether a native build is older than its sources. Unlike
--- `:MyPlugins sync` it does not stop at the plugin list.
---
--- The report is the way to catch up, one key each:
---  - `<CR>` / double click   fast-forward the repo under the cursor (`git pull --ff-only`)
---  - `P`                     fast-forward every repo that can be (clean, on main, behind)
---  - `b`                     copy the build command of the repo under the cursor
---  - `R`                     run the check again
---  - `q`                     close
--- Only a repo the script marked `Pullable` is ever pulled (clean tree, nothing unpushed,
--- on main/master, behind); every other line explains why it is left alone.
--- With `--pull` the script itself fast-forwards before the report is shown.
--- Doc: `tasks-vault/TOOLS/machine-sync.md`.

local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos.machine]")
local open_named_scratch = require("lib.nvim.window.open_named_scratch")

local M = {}

local SCRATCH_NAME = "MyPlugins-machine"

---@class MyPlugins.MachineItem
---@field Repo string
---@field Path string
---@field State string
---@field Note string
---@field Behind integer
---@field Ahead integer
---@field Dirty integer
---@field Pullable boolean
---@field Build string
---@field Hint string

---Path of the script inside the config this module was loaded from (so a worktree or a
---junctioned config finds its own copy, not the one under stdpath("config")).
---@return string
function M.script_path()
  local src = debug.getinfo(1, "S").source:sub(2)
  local root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(src)))))
  return vim.fs.joinpath(root, "scripts", "sync-machine.ps1")
end

---Argv that runs the script (pwsh when installed, else Windows PowerShell).
---@param opts? { pull?: boolean, only?: string, shell?: string, script?: string, json?: boolean }
---@return string[]
function M.build_cmd(opts)
  opts = opts or {}
  local shell = opts.shell or (vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell")
  local cmd = { shell, "-NoProfile", "-File", opts.script or M.script_path() }
  if opts.json then
    cmd[#cmd + 1] = "-Json"
  end
  if opts.pull then
    cmd[#cmd + 1] = "-Pull"
  end
  if opts.only and opts.only ~= "" then
    cmd[#cmd + 1] = "-Only"
    cmd[#cmd + 1] = opts.only
  end
  return cmd
end

---Decode the script's `-Json` output; nil plus a reason when it is not the expected array.
---@param text string
---@return MyPlugins.MachineItem[]|nil items
---@return string|nil err
function M.parse(text)
  local from = text:find("%[")
  if not from then
    return nil, "no JSON in the script output"
  end
  local ok, data = pcall(vim.json.decode, text:sub(from))
  if not ok or type(data) ~= "table" then
    return nil, "unreadable JSON: " .. tostring(data)
  end
  return data
end

---Why a line is not pulled (nil: it can be).
---@param item MyPlugins.MachineItem
---@return string|nil
function M.why_not(item)
  if item.Pullable then
    return nil
  end
  if item.Behind == 0 then
    return "nothing to pull"
  end
  if item.Dirty > 0 then
    return "uncommitted files - commit or stash first"
  end
  if item.Ahead > 0 then
    return "has unpushed commits (diverged) - rebase by hand"
  end
  return "not on main/master - switch branch first"
end

---Fixed-width report lines plus the map line number -> item.
---@param items MyPlugins.MachineItem[]
---@return string[] lines
---@return table<integer, MyPlugins.MachineItem> by_line
function M.render(items)
  local lines = {
    "MyPlugins machine - <CR> pull repo  P pull all  b copy build cmd  R recheck  q close",
    "",
  }
  local by_line = {}
  local pullable = 0
  for _, it in ipairs(items) do
    local mark = it.Pullable and "v" or " "
    if it.Pullable then
      pullable = pullable + 1
    end
    lines[#lines + 1] = ("%s %-24s %-14s %s"):format(mark, it.Repo, it.State, it.Note)
    by_line[#lines] = it
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = ("%d repo(s), %d can be pulled (v)"):format(#items, pullable)
  return lines, by_line
end

---Repos that `P` pulls.
---@param items MyPlugins.MachineItem[]
---@return MyPlugins.MachineItem[]
function M.pullable(items)
  local out = {}
  for _, it in ipairs(items) do
    if it.Pullable then
      out[#out + 1] = it
    end
  end
  return out
end

---@type { items: MyPlugins.MachineItem[], by_line: table<integer, MyPlugins.MachineItem>, opts: table }
local current = { items = {}, by_line = {}, opts = {} }

---Fast-forward the given repos (in parallel), then re-run the check.
---@param repos MyPlugins.MachineItem[]
local function pull(repos)
  if #repos == 0 then
    notify.info("Nothing to pull.")
    return
  end
  local pending, failed = #repos, {}
  notify.info(("Pulling %d repo(s) ..."):format(#repos))
  for _, it in ipairs(repos) do
    vim.system(
      { "git", "-C", it.Path, "pull", "--ff-only", "--quiet" },
      { text = true },
      function(res)
        vim.schedule(function()
          if res.code ~= 0 then
            failed[#failed + 1] = it.Repo .. ": " .. vim.trim(res.stderr or "")
          end
          pending = pending - 1
          if pending == 0 then
            if #failed > 0 then
              notify.warn("Pull failed:\n" .. table.concat(failed, "\n"))
            else
              notify.info(("Pulled %d repo(s)."):format(#repos))
            end
            M.run(current.opts)
          end
        end)
      end
    )
  end
end

---@param bufnr integer
local function set_keymaps(bufnr)
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = bufnr, nowait = true, silent = true, desc = desc })
  end
  local function under_cursor()
    return current.by_line[vim.api.nvim_win_get_cursor(0)[1]]
  end
  local function pull_here()
    local it = under_cursor()
    if not it then
      return
    end
    local reason = M.why_not(it)
    if reason then
      notify.info(it.Repo .. ": " .. reason)
      return
    end
    pull({ it })
  end
  map("<CR>", pull_here, "Pull the repo under the cursor (ff-only)")
  map("<2-LeftMouse>", pull_here, "Pull the repo under the cursor (ff-only)")
  map("P", function()
    pull(M.pullable(current.items))
  end, "Pull every repo that can be fast-forwarded")
  map("b", function()
    local it = under_cursor()
    if not it or it.Hint == "" then
      notify.info("No build hint for this line.")
      return
    end
    vim.fn.setreg("+", it.Hint)
    notify.info("Copied: " .. it.Hint)
  end, "Copy the build command of the repo under the cursor")
  map("R", function()
    M.run(current.opts)
  end, "Run the check again")
  map("q", "<Cmd>close<CR>", "Close the report")
end

---@param lines string[]
local function show(lines)
  local bufnr = open_named_scratch(SCRATCH_NAME, lines, {
    filetype = "myplugins-machine",
    split = "below",
    modifiable = false,
  })
  set_keymaps(bufnr)
end

---Run the check; the report opens in a scratch buffer when the script ends.
---@param opts? { pull?: boolean, only?: string }
function M.run(opts)
  opts = opts or {}
  current.opts = opts
  local script = M.script_path()
  if not (vim.uv or vim.loop).fs_stat(script) then
    notify.error("Script not found: " .. script .. " (pull the nvim config)")
    return
  end
  notify.info(
    "Checking all repos" .. (opts.pull and " (fast-forwarding clean ones)" or "") .. " ..."
  )
  vim.system(
    M.build_cmd(vim.tbl_extend("force", opts, { json = true })),
    { text = true },
    function(res)
      vim.schedule(function()
        local items, err = M.parse(res.stdout or "")
        if not items then
          show(
            vim.split((err or "") .. "\n\n" .. (res.stdout or "") .. (res.stderr or ""), "\r?\n")
          )
          notify.error("The check failed: " .. tostring(err))
          return
        end
        local lines, by_line = M.render(items)
        current.items, current.by_line = items, by_line
        show(lines)
        if res.code == 0 then
          notify.info("All repos current.")
        else
          notify.warn("Some repos need attention - see the report.")
        end
      end)
    end
  )
end

---@return table[]
function M.routes()
  return {
    {
      path = { "machine" },
      flags = {
        {
          name = "pull",
          bool = true,
          desc = "Fast-forward clean repos on main before the report (git pull --ff-only)",
        },
        { name = "only", type = "STRING", desc = "Comma list of repo names to check" },
      },
      desc = "Machine-switch check over ALL repos in $REPOS_DIR (plugins, vaults, native apps): behind / ahead / dirty and stale native builds in a scratch buffer; <CR> pulls the repo under the cursor, P pulls all that can be, b copies the build command, R rechecks. --pull fast-forwards before the report, --only=a,b limits the run. Runs scripts/sync-machine.ps1",
      run = function(ctx)
        M.run({ pull = ctx.flags.pull == true, only = ctx.flags.only })
      end,
    },
  }
end

return M
