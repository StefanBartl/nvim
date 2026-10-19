---@module 'bindings.usrcmds.plugin_repos.machine'
---@brief `:MyPlugins machine [--pull]` - the machine-switch check of `scripts/sync-machine.ps1`.
---@description
--- Runs the PowerShell script (`-Json`) in the background and shows the result in a scratch
--- buffer, one line per repo under `$REPOS_DIR` (plugins, vaults, the native apps): behind,
--- ahead, dirty, and whether a native build is older than its sources. Unlike
--- `:MyPlugins sync` it does not stop at the plugin list.
---
--- The report is sorted by what you can do about it (pullable first, then the dangerous ones:
--- unpushed / diverged / missing, then the rest); repos with nothing to do are hidden until
--- `a`. The window bar carries the totals, the cursor starts on the first actionable line.
--- `?` opens the cheat sheet. Keys (all buffer-local):
---  - `<CR>` / double click   fast-forward the repo under the cursor (`git pull --ff-only`)
---  - `P`                     fast-forward every repo that can be (clean, on main, behind)
---  - `b`                     copy the build command of the repo under the cursor
---  - `a`                     show / hide the repos that are current
---  - `]` / `[`               next / previous line that needs attention
---  - `R`                     run the check again
---  - `q`                     close
--- Only a repo the script marked `Pullable` is ever pulled (clean tree, nothing unpushed,
--- on main/master, behind); every other line explains why it is left alone.
--- With `--pull` the script itself fast-forwards before the report is shown.
--- Doc: `tasks-vault/TOOLS/machine-sync.md`.

local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos.machine]")
local open_named_scratch = require("lib.nvim.window.open_named_scratch")
local help_float = require("bindings.usrcmds.plugin_repos.help_float")

local M = {}

local SCRATCH_NAME = "MyPlugins-machine"
local NS = vim.api.nvim_create_namespace("MyPluginsMachine")
local HEADER_LINES = 2

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

---Does this repo need the person's attention (anything but "current, build current")?
---@param item MyPlugins.MachineItem
---@return boolean
function M.needs_attention(item)
  return item.State ~= "ok" or item.Build == "stale" or item.Build == "missing"
end

local SEVERE = {
  UNPUSHED = true,
  DIVERGED = true,
  ["FETCH FAILED"] = true,
  ["PULL FAILED"] = true,
  ["NO UPSTREAM"] = true,
}

---Is the state one that can lose work or leaves the repo unusable?
---@param item MyPlugins.MachineItem
---@return boolean
local function severe(item)
  return SEVERE[item.State] == true or item.State:sub(1, 7) == "MISSING" or item.Ahead > 0
end

---Sort rank: 1 pullable, 2 severe, 3 other attention, 4 current.
---@param item MyPlugins.MachineItem
---@return integer
function M.rank(item)
  if item.Pullable then
    return 1
  end
  if severe(item) then
    return 2
  end
  if M.needs_attention(item) then
    return 3
  end
  return 4
end

---Why a line is not pulled (nil: it can be).
---@param item MyPlugins.MachineItem
---@return string|nil
function M.why_not(item)
  if item.Pullable then
    return nil
  end
  if item.Behind == 0 then
    if item.Build == "stale" or item.Build == "missing" then
      return ("nothing to pull, but the build is %s - %s (b copies it)"):format(
        item.Build,
        item.Hint
      )
    end
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

---The totals shown in the window bar.
---@param items MyPlugins.MachineItem[]
---@return string
function M.summary(items)
  local pull, unpushed, dirty, build, current = 0, 0, 0, 0, 0
  for _, it in ipairs(items) do
    if it.Pullable then
      pull = pull + 1
    end
    if it.Ahead > 0 then
      unpushed = unpushed + 1
    end
    if it.Dirty > 0 then
      dirty = dirty + 1
    end
    if it.Build == "stale" or it.Build == "missing" then
      build = build + 1
    end
    if not M.needs_attention(it) then
      current = current + 1
    end
  end
  return ("%d pullable | %d unpushed | %d dirty | %d build | %d current"):format(
    pull,
    unpushed,
    dirty,
    build,
    current
  )
end

---Highlight group of a line.
---@param item MyPlugins.MachineItem
---@return string
function M.line_hl(item)
  local r = M.rank(item)
  if r == 1 then
    return "DiagnosticOk"
  elseif r == 2 then
    return "DiagnosticError"
  elseif r == 3 then
    return "DiagnosticWarn"
  end
  return "Comment"
end

---Items in display order (stable inside a rank); current repos only with `all`.
---@param items MyPlugins.MachineItem[]
---@param all? boolean
---@return MyPlugins.MachineItem[]
function M.order(items, all)
  local keyed = {}
  for i, it in ipairs(items) do
    if all or M.needs_attention(it) then
      keyed[#keyed + 1] = { it = it, rank = M.rank(it), idx = i }
    end
  end
  table.sort(keyed, function(a, b)
    if a.rank ~= b.rank then
      return a.rank < b.rank
    end
    return a.idx < b.idx
  end)
  return vim.tbl_map(function(k)
    return k.it
  end, keyed)
end

---Fixed-width report lines, the map line number -> item and the highlight of each line.
---@param items MyPlugins.MachineItem[]
---@param all? boolean  include the repos with nothing to do
---@return string[] lines
---@return table<integer, MyPlugins.MachineItem> by_line
---@return table<integer, string> hls  line number -> highlight group
function M.render(items, all)
  local lines = {
    "MyPlugins machine   <CR> pull   P pull all   b build cmd   a show current   R recheck   ? help",
    "",
  }
  local by_line, hls = {}, {}
  hls[1] = "Title"
  local shown = M.order(items, all)
  for _, it in ipairs(shown) do
    local mark = it.Pullable and "v" or " "
    local counts = ("%-3s %-3s %-3s"):format(
      it.Behind > 0 and ("v" .. it.Behind) or "",
      it.Ahead > 0 and ("^" .. it.Ahead) or "",
      it.Dirty > 0 and ("~" .. it.Dirty) or ""
    )
    local build = it.Build ~= "" and it.Build ~= "current" and ("build " .. it.Build) or ""
    local line = ("%s %-24s %s  %-14s %s"):format(mark, it.Repo, counts, it.State, build)
    lines[#lines + 1] = (line:gsub("%s+$", ""))
    by_line[#lines] = it
    hls[#lines] = M.line_hl(it)
  end
  lines[#lines + 1] = ""
  local hidden = #items - #shown
  lines[#lines + 1] = ("%d shown, %s  |  v behind  ^ ahead  ~ dirty"):format(
    #shown,
    all and "current ones included (a: hide)" or (hidden .. " current hidden (a: show)")
  )
  hls[#lines] = "Comment"
  return lines, by_line, hls
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

---The cheat sheet (`?`).
---@return string[]
function M.help_lines()
  return {
    " :MyPlugins machine ",
    "",
    " <CR> / 2-click   fast-forward the repo under the cursor",
    " P                fast-forward every repo marked v",
    " b                copy the build command of the repo",
    " a                show / hide the repos that are current",
    " ] / [            next / previous line that needs attention",
    " R                run the check again",
    " q                close",
    " ?                this help (any key closes it)",
    "",
    " Columns: v behind  ^ ahead  ~ uncommitted files",
    " Green   v       clean, on main, behind: <CR>/P pull it",
    " Red     unpushed / diverged / missing / fetch failed",
    " Yellow  dirty, off main, stale or missing build",
    " Only repos marked v are ever pulled (git pull --ff-only).",
    " Builds are never started here; b copies the command.",
    "",
  }
end

---@type { items: MyPlugins.MachineItem[], by_line: table<integer, MyPlugins.MachineItem>, opts: table, all: boolean }
local current = { items = {}, by_line = {}, opts = {}, all = false }

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

---Jump to the next / previous report line (they all need attention unless `a` is on).
---@param dir 1|-1
local function jump(dir)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.tbl_keys(current.by_line)
  table.sort(lines)
  local target
  for _, l in ipairs(lines) do
    local it = current.by_line[l]
    if M.needs_attention(it) then
      if dir == 1 and l > lnum then
        target = l
        break
      elseif dir == -1 and l < lnum then
        target = l
      end
    end
  end
  if target then
    vim.api.nvim_win_set_cursor(0, { target, 0 })
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
  map("a", function()
    current.all = not current.all
    M.redraw()
  end, "Show / hide the repos that are current")
  map("]", function()
    jump(1)
  end, "Next line that needs attention")
  map("[", function()
    jump(-1)
  end, "Previous line that needs attention")
  map("R", function()
    M.run(current.opts)
  end, "Run the check again")
  map("?", function()
    help_float.open(M.help_lines(), "MyPlugins_machine_help")
  end, "Cheat sheet")
  map("q", "<Cmd>close<CR>", "Close the report")
end

---Put lines (and optional highlights / window bar) into the report buffer.
---@param lines string[]
---@param hls? table<integer, string>
---@param bar? string
local function show(lines, hls, bar)
  local bufnr, winid = open_named_scratch(SCRATCH_NAME, lines, {
    filetype = "myplugins-machine",
    split = "below",
    modifiable = false,
  })
  vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)
  for lnum, group in pairs(hls or {}) do
    vim.api.nvim_buf_set_extmark(bufnr, NS, lnum - 1, 0, {
      end_row = lnum - 1,
      end_col = #lines[lnum],
      hl_group = group,
    })
  end
  vim.wo[winid].winbar = bar and (" " .. bar) or ""
  vim.wo[winid].cursorline = true
  set_keymaps(bufnr)
  return winid
end

---Render the current result again (after `a`), keeping the cursor on its repo.
function M.redraw()
  local before = current.by_line[vim.api.nvim_win_get_cursor(0)[1]]
  local lines, by_line, hls = M.render(current.items, current.all)
  current.by_line = by_line
  local winid = show(lines, hls, M.summary(current.items))
  local row = HEADER_LINES + 1
  for lnum, it in pairs(by_line) do
    if it == before then
      row = lnum
    end
  end
  vim.api.nvim_win_set_cursor(winid, { math.min(row, #lines), 0 })
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
  current.by_line = {}
  show({
    "MyPlugins machine",
    "",
    "Checking all repos" .. (opts.pull and " (fast-forwarding clean ones)" or "") .. " ...",
  }, { [1] = "Title", [3] = "Comment" }, "checking ...")
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
        current.items = items
        M.redraw()
        -- start on the first actionable line, not on the title
        local first
        for lnum in pairs(current.by_line) do
          first = (first == nil or lnum < first) and lnum or first
        end
        if first then
          vim.api.nvim_win_set_cursor(0, { first, 0 })
        end
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
      desc = "Machine-switch check over ALL repos in $REPOS_DIR (plugins, vaults, native apps): behind / ahead / dirty and stale native builds in a scratch buffer, sorted by what you can do; <CR> pulls the repo under the cursor, P pulls all that can be, b copies the build command, a shows the current ones, ? opens the cheat sheet. --pull fast-forwards before the report, --only=a,b limits the run. Runs scripts/sync-machine.ps1",
      run = function(ctx)
        M.run({ pull = ctx.flags.pull == true, only = ctx.flags.only })
      end,
    },
  }
end

return M
