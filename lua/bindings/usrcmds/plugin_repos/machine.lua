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
---  - `B`                     run that build in a float terminal, in the repo's folder (refused on the
---                            workstation, `native_repos/workstation.lua`: the EDR reports own builds)
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
local workstation = require("bindings.usrcmds.native_repos.workstation")

local M = {}

local SCRATCH_NAME = "MyPlugins-machine"
local NS = vim.api.nvim_create_namespace("MyPluginsMachine")
local HEADER_LINES = 2

---The last report: what the script answered, which line is which repo, the options of the run
---(so `R`, a pull and a finished build can run it again) and whether current repos are shown.
---@type { items: MyPlugins.MachineItem[], by_line: table<integer, MyPlugins.MachineItem>, opts: table, all: boolean }
local current = { items = {}, by_line = {}, opts = {}, all = false }

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
---@field Hint string     # what to do, for a person to read (may be prose: "run its setup.exe")
---@field Command? string # the command that builds it; "" when there is none (older scripts: absent)

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

---The command that builds the repo of a line, or nil when it has none.
---
---The script's `Command`, and nothing else: the desktop apps are built by their setup.exe, and
---their `Hint` ("run its setup.exe") is prose, not something to run or paste. Script and module
---live in the same config, so there is no older script without the field; a missing or `null`
---`Command` means no command, never "run the Hint".
---@param item MyPlugins.MachineItem|nil
---@return string|nil
function M.build_hint(item)
  if not item or type(item.Command) ~= "string" then
    return nil
  end
  local cmd = vim.trim(item.Command)
  return cmd ~= "" and cmd or nil
end

---What to tell the person when a line has no build command: the hint, which then says what
---to do by hand ("run its setup.exe"), or that there is nothing.
---@param item MyPlugins.MachineItem|nil
---@return string
function M.no_command_message(item)
  if item and type(item.Hint) == "string" and item.Hint ~= "" then
    return ("%s: no build command - %s"):format(item.Repo, item.Hint)
  end
  return "No build command for this line."
end

---The argv `B` runs: the build hint as one PowerShell command, started in the repo's folder
---by the caller (`cwd`), never through a `Set-Location` string -- the folder is a spawn option,
---so a path with quotes or spaces needs no escaping at all.
---
---PowerShell because the commands are written for it (the check is a PowerShell script too);
---`sh scripts/...` and `cmake ...` run there as well. pwsh when installed, else Windows
---PowerShell -- and off Windows without pwsh, nothing (nil plus the reason).
---
---**The exit code is the tool's.** Windows PowerShell 5.1 reports 1 for any failing native
---command, and a later succeeding statement would mask an earlier failure; so a failing cmdlet
---stops the run (`$ErrorActionPreference = 'Stop'`) and the last native exit code is passed on.
---`-NoProfile`: whatever only the profile puts on PATH (a VS dev shell, nvm) is not there.
---@param item MyPlugins.MachineItem|nil
---@param shell? string
---@return string[]|nil argv nil when the line has no build command, or there is no PowerShell
---@return string|nil why
function M.build_argv(item, shell)
  local cmd = M.build_hint(item)
  if not cmd then
    return nil, M.no_command_message(item)
  end
  if not shell then
    if vim.fn.executable("pwsh") == 1 then
      shell = "pwsh"
    elseif vim.fn.has("win32") == 1 then
      shell = "powershell"
    else
      return nil, "no PowerShell (pwsh) on this machine to run the build with"
    end
  end
  return {
    shell,
    "-NoProfile",
    "-Command",
    ("$ErrorActionPreference = 'Stop'; %s; exit $LASTEXITCODE"):format(cmd),
  }
end

---Folders with a build running from here (B), so a second B does not start another build in
---the same folder.
---@type table<string, boolean>
local building = {}

---Folders whose finished build waits for its float to close before the check runs again: the
---autocmd id, so a new B on the folder can drop it. Replacing the terminal of the same name
---closes the old float, and that close must not re-check while the new build runs.
---@type table<string, integer>
local pending_recheck = {}

---Run the check again -- unless a build of B is still running or another finished build's float
---is still open: the report takes the focus when it is shown, and under an open float the next key
---(`q`, `<CR>`) would land in it. The last float to close runs it.
---@type boolean A check was wanted and put off because another build was still out.
local recheck_owed = false
local function recheck_when_settled(wanted)
  if wanted then
    recheck_owed = true
  end
  if recheck_owed and next(building) == nil and next(pending_recheck) == nil then
    recheck_owed = false
    M.run(current.opts)
  end
end

---Run `fn` once `winid` is closed, or now when it already is. Returns the autocmd id when it
---waits.
---@param winid integer|nil
---@param fn fun()
---@return integer|nil autocmd
local function after_close(winid, fn)
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    fn()
    return nil
  end
  return vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(winid),
    once = true,
    callback = function()
      vim.schedule(fn)
    end,
  })
end

---Run the build of `item` in a float terminal, in its folder -- a terminal.nvim terminal
---(`build:<repo>`, so `:Terminal list` shows it), started with `direct = true`: the build IS
---the job, no shell in between, and its exit code comes back.
---
---The float stays open when the build ends, so the output can be read: `q` in normal mode
---closes it (`<Esc>` gets there from terminal mode). A build that succeeded runs the check again
----- but only
---once the float is closed: the report would otherwise take the focus while the float still
---covers it, and the key meant to close the float would land in the report (`<CR>` there pulls
---the repo under the cursor).
---@param item MyPlugins.MachineItem|nil
---@param deps? { terminal?: { run: fun(cmd: string[], opts: table): (boolean, string|nil, table|nil) }, shell?: string, on_done?: fun(code: integer, winid: integer|nil) }
---@return boolean started
function M.build_in_terminal(item, deps)
  deps = deps or {}
  -- the builds here are native programs (desktop apps, mdview's Go server): on the workstation the
  -- EDR reports them, so B refuses there; b (copy the command) stays
  if workstation.refused(":MyPlugins machine B (build)") then
    return false
  end
  if not item then
    notify.info("No build command for this line.")
    return false
  end
  local argv, why = M.build_argv(item, deps.shell)
  if not argv then
    notify.info(why or M.no_command_message(item))
    return false
  end
  if type(item.Path) ~= "string" or item.Path == "" or vim.fn.isdirectory(item.Path) ~= 1 then
    notify.warn(("%s: the folder is not there (%s)"):format(item.Repo, tostring(item.Path)))
    return false
  end
  if building[item.Path] then
    notify.info(item.Repo .. ": a build is already running here")
    return false
  end
  -- The float of the last build of this folder may still be open, waiting to re-check when it
  -- closes; this B replaces it, and that close must not re-check under the new build.
  if pending_recheck[item.Path] then
    pcall(vim.api.nvim_del_autocmd, pending_recheck[item.Path])
    pending_recheck[item.Path] = nil
  end
  local terminal = deps.terminal
  if not terminal then
    local ok_term, mod = pcall(require, "terminal")
    if not ok_term or type(mod) ~= "table" or type(mod.run) ~= "function" then
      notify.warn("terminal.nvim is not available - b copies the command instead")
      return false
    end
    terminal = mod
  end
  local on_done = deps.on_done
    or function(code, winid)
      if code ~= 0 then
        notify.warn(("%s: build failed (exit %d)"):format(item.Repo, code))
        -- A check another build put off is owed now -- after this float is closed too.
        if recheck_owed and winid then
          pending_recheck[item.Path] = after_close(winid, function()
            pending_recheck[item.Path] = nil
            recheck_when_settled(false)
          end)
        else
          recheck_when_settled(false)
        end
        return
      end
      if not winid then
        -- The float went before the build ended: a check now would take the focus wherever the
        -- reader is. Say so instead.
        notify.info(item.Repo .. ": build done - R re-checks")
        return
      end
      notify.info(item.Repo .. ": build done - close the window to re-check")
      pending_recheck[item.Path] = after_close(winid, function()
        pending_recheck[item.Path] = nil
        recheck_when_settled(true)
      end)
    end
  ---@type integer|nil
  local term_buf
  ---@type integer|nil
  local float_win
  building[item.Path] = true
  -- pcall: a terminal.nvim that throws (a setup or lazy-load error) must not leave the folder
  -- locked until a restart.
  local ran, started, _, handle = pcall(terminal.run, argv, {
    direct = true,
    name = "build:" .. item.Repo,
    layout = "float",
    cwd = item.Path,
    title = (" build: %s "):format(item.Repo),
    close = "never",
    -- A build is a one-off: a saved session must not start it again on the next launch.
    session = false,
    on_open = function(handle)
      term_buf = handle and handle.bufnr or nil
      -- `run` enters the float it opens: that window, not whichever other window may show the
      -- same buffer later (a split of it, another tab), is the one whose closing re-checks.
      local cur = vim.api.nvim_get_current_win()
      if term_buf and vim.api.nvim_win_get_buf(cur) == term_buf then
        float_win = cur
      end
      if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
        -- In terminal mode any key closes the finished terminal; in normal mode (after
        -- <C-\><C-n> to scroll the output) nothing would, so `q` does.
        vim.keymap.set(
          "n",
          "q",
          "<Cmd>close<CR>",
          { buffer = term_buf, nowait = true, desc = "Close" }
        )
      end
    end,
    on_exit = function(code)
      building[item.Path] = nil
      -- The float, if it is still open and still shows the build; else any window showing it
      -- (in any tab: the reader may have moved on); nil when none does (closed early, or a
      -- multiplexer backend).
      local winid = float_win
      if
        not (
          winid
          and vim.api.nvim_win_is_valid(winid)
          and vim.api.nvim_win_get_buf(winid) == term_buf
        )
      then
        winid = term_buf and vim.fn.win_findbuf(term_buf)[1] or nil
      end
      on_done(code, winid)
    end,
  })
  if not ran then
    building[item.Path] = nil
    notify.error(("%s: terminal.nvim failed: %s"):format(item.Repo, tostring(started)))
    return false
  end
  if not started then
    -- terminal.nvim has said why already.
    building[item.Path] = nil
    return false
  end
  if handle and handle.backend and handle.backend ~= "native" then
    -- A tmux or WezTerm pane never reports the end of its command: no lock that nothing would
    -- release, and no promise of a re-check.
    building[item.Path] = nil
    notify.info(
      ("%s: building in a %s pane - its end is not reported here, R re-checks"):format(
        item.Repo,
        handle.backend
      )
    )
  end
  return true
end

---The command `b` puts on the clipboard: go to the repo first, then build.
---
---The script's `Command` (`M.build_hint`), never the prose `Hint`. The folder change comes first
---because the commands are relative (`node scripts/...`, `cmake --build build`) and a terminal that
---sits anywhere else (the config, another repo) would build nothing or the wrong thing.
---@param item MyPlugins.MachineItem
---@return string|nil cmd nil when the line has no build hint
function M.build_command(item)
  local hint = M.build_hint(item)
  if not hint then
    return nil
  end
  if item.Path == nil or item.Path == "" then
    return hint
  end
  -- PowerShell single quotes: the only character to double is the quote itself.
  local path = item.Path:gsub("'", "''")
  return ("Set-Location -LiteralPath '%s'; %s"):format(path, hint)
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
      local cmd = M.build_hint(item)
      return ("nothing to pull, but the build is %s - %s%s"):format(
        item.Build,
        cmd or item.Hint,
        cmd and " (b copies, B runs it)" or ""
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
  local pull, unpushed, dirty, build, up_to_date = 0, 0, 0, 0, 0
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
      up_to_date = up_to_date + 1
    end
  end
  return ("%d pullable | %d unpushed | %d dirty | %d build | %d current"):format(
    pull,
    unpushed,
    dirty,
    build,
    up_to_date
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
    "MyPlugins machine   <CR> pull   P pull all   b build cmd   B build here   a show current   R recheck   ? help",
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
    " B                run that build in a float terminal, in the repo's folder",
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
    " A build starts only on B; b copies the command instead.",
    " On the workstation (NVIM_MACHINE_ROLE) B is blocked (EDR).",
    "",
  }
end

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
    if not it then
      notify.info("No build command for this line.")
      return
    end
    local cmd = M.build_command(it)
    if not cmd then
      notify.info(M.no_command_message(it))
      return
    end
    vim.fn.setreg("+", cmd)
    notify.info("Copied: " .. cmd)
  end, "Copy the build command of the repo under the cursor")
  map("B", function()
    M.build_in_terminal(under_cursor())
  end, "Run the build of the repo under the cursor in a float terminal")
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
      desc = "Machine-switch check over ALL repos in $REPOS_DIR (plugins, vaults, native apps): behind / ahead / dirty and stale native builds in a scratch buffer, sorted by what you can do; <CR> pulls the repo under the cursor, P pulls all that can be, b copies the build command, B runs it in a float terminal in the repo's folder (blocked on the workstation, EDR), a shows the current ones, ? opens the cheat sheet. --pull fast-forwards before the report, --only=a,b limits the run. Runs scripts/sync-machine.ps1",
      run = function(ctx)
        M.run({ pull = ctx.flags.pull == true, only = ctx.flags.only })
      end,
    },
  }
end

return M
