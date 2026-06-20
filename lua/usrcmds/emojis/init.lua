---@module 'usrcmds.emojis'
---@brief :Emojis [action] [scope]
---
---   action : clear | insert | list | count | replace   (default: clear)
---   scope  : word | line | visual | % | cwd            (default: %)
---
---   :Emojis                   → clear %
---   :Emojis clear %           → strip all emojis from buffer
---   :Emojis clear line        → strip cursor line
---   :Emojis clear visual      → strip last visual selection
---   :Emojis list %            → quickfix list of emoji positions
---   :Emojis count cwd         → async rg count across cwd
---   :Emojis insert            → emoji picker at cursor
---   :Emojis replace %         → emoji → :name: placeholders
---   :'<,'>Emojis clear        → Vim range overrides scope

local api = vim.api
local fn  = vim.fn

-- notify: use lib.notify if available, else plain vim.notify
local ok_n, _n = pcall(require, "lib.notify")
local N = ok_n and _n.create("[usrcmds.emojis]") or {
  info  = function(m) vim.notify("[emojis] "..m, vim.log.levels.INFO)  end,
  warn  = function(m) vim.notify("[emojis] "..m, vim.log.levels.WARN)  end,
  error = function(m) vim.notify("[emojis] "..m, vim.log.levels.ERROR) end,
}

local ops = require("usrcmds.emojis.ops")

---@class usrcmds.emojis
local M = {}
local _done = false

local ACTIONS = { "clear", "insert", "list", "count", "replace" }
local SCOPES  = { "word", "line", "visual", "%", "cwd" }

-- insert picker entries
local PICK = {
  {"✅","check"},{"❌","cross"},{"⚠️","warning"},{"💡","bulb"},
  {"📝","memo"},{"🔥","fire"},{"🚀","rocket"},{"🐛","bug"},
  {"🔧","wrench"},{"🔴","red"},{"🟡","yellow"},{"🟢","green"},
  {"📌","pin"},{"📎","clip"},{"🏁","flag"},{"💬","speech"},
  {"🤔","think"},{"👍","up"},{"👎","down"},{"🎯","dart"},
  {"🔒","lock"},{"🔓","unlock"},{"⭐","star"},{"💯","100"},
  {"✨","sparkle"},{"💥","boom"},{"🛑","stop"},{"🆕","new"},
}

-- ============================================================================
-- Utilities
-- ============================================================================

local function has(list, v)
  for _,x in ipairs(list) do if x==v then return true end end
  return false
end

-- ============================================================================
-- Scope  →  {bufnr, l1, l2}  (0-based, inclusive)
-- ============================================================================

local function resolve(scope, range, line1, line2)
  local buf = api.nvim_get_current_buf()
  assert(api.nvim_buf_is_valid(buf), "buffer not valid")
  local last = api.nvim_buf_line_count(buf)  -- count, 1-based

  -- Vim explicit range always wins (:'<,'>Emojis, :10,20Emojis)
  if range > 0 then
    local l1 = math.max(0, line1 - 1)
    local l2 = math.min(last - 1, line2 - 1)
    return { buf=buf, l1=l1, l2=l2 }
  end

  if scope == "%" then
    return { buf=buf, l1=0, l2=last-1 }

  elseif scope == "line" or scope == "word" then
    local cur = api.nvim_win_get_cursor(0)[1]   -- 1-based
    local l   = math.min(math.max(1, cur), last) - 1  -- 0-based
    return { buf=buf, l1=l, l2=l }

  elseif scope == "visual" then
    local vs = fn.getpos("'<")   -- {bufnum, lnum, col, off}
    local ve = fn.getpos("'>")
    local l1v, l2v = vs[2], ve[2]
    if l1v == 0 then error("no previous visual selection") end
    local l1 = math.min(l1v,l2v) - 1
    local l2 = math.min(math.max(l1v,l2v), last) - 1
    l1 = math.max(0, l1)
    return { buf=buf, l1=l1, l2=l2 }

  elseif scope == "cwd" then
    return { buf=-1, l1=0, l2=0 }   -- sentinel

  else
    error("unknown scope: "..scope)
  end
end

-- ============================================================================
-- Actions
-- ============================================================================

local function do_edit(action, t)
  local lines = api.nvim_buf_get_lines(t.buf, t.l1, t.l2+1, false)
  if #lines == 0 then N.info("range is empty"); return end

  local new_lines, n
  if action == "clear" then
    new_lines, n = ops.clear(lines)
  else
    new_lines, n = ops.replace(lines)
  end

  if n == 0 then N.info("no emojis found in scope"); return end

  api.nvim_buf_set_lines(t.buf, t.l1, t.l2+1, false, new_lines)
  local verb = action == "clear" and "Removed" or "Replaced"
  N.info(("%s %d emoji%s"):format(verb, n, n==1 and "" or "s"))
end

local function do_list(t)
  local lines   = api.nvim_buf_get_lines(t.buf, t.l1, t.l2+1, false)
  local entries = ops.list(lines, t.l1)
  if #entries == 0 then N.info("no emojis found in scope"); return end

  local name = fn.bufname(t.buf)
  local qf = {}
  for _, e in ipairs(entries) do
    qf[#qf+1] = { bufnr=t.buf, filename=name,
                  lnum=e.lnum, col=e.col+1, text="emoji "..e.text }
  end
  fn.setqflist({}, "r", { title="Emojis", items=qf })
  vim.cmd("copen")
  N.info(("Found %d emoji%s → quickfix"):format(#entries, #entries==1 and "" or "s"))
end

local function do_count(t)
  local lines = api.nvim_buf_get_lines(t.buf, t.l1, t.l2+1, false)
  local n     = ops.count(lines)
  local lc    = t.l2 - t.l1 + 1
  if n == 0 then
    N.info(("no emojis in %d line%s"):format(lc, lc==1 and "" or "s"))
  else
    N.info(("Found %d emoji%s in %d line%s"):format(
      n, n==1 and "" or "s", lc, lc==1 and "" or "s"))
  end
end

local function do_insert()
  local items = {}
  for _, e in ipairs(PICK) do items[#items+1] = e[1].."  "..e[2] end
  vim.ui.select(items, { prompt="Insert emoji:" }, function(choice)
    if not choice then return end
    local icon = choice:match("^(.-)%s%s")
    if not icon or icon=="" then return end
    ---@diagnostic disable-next-line: deprecated
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local line = api.nvim_buf_get_lines(0, row-1, row, false)[1] or ""
    api.nvim_buf_set_lines(0, row-1, row, false,
      { line:sub(1,col)..icon..line:sub(col+1) })
    pcall(api.nvim_win_set_cursor, 0, { row, col+#icon })
  end)
end

local function do_cwd(action)
  if action~="list" and action~="count" then
    N.warn("cwd only supports list/count"); return
  end
  local cwd = fn.getcwd()
  N.info("Searching cwd for emojis (async)…")

  -- rg Unicode codepoint range — works without --pcre2
  local rg_pat = [=[[\x{1F000}-\x{1FFFF}\x{2600}-\x{27FF}\x{2B00}-\x{2BFF}]]=]
  local cmd = { "rg", "--no-heading", "--line-number", "--with-filename",
                "--color=never", rg_pat, cwd }

  local out, err_buf = {}, {}

  local function on_done(code)
    if code~=0 and code~=1 then
      N.warn("rg exited "..code..": "..table.concat(err_buf,""))
      return
    end
    M._finish_cwd(action, out, cwd)
  end

  if type(vim.system)=="function" then
    vim.system(cmd, { text=true,
      stdout=function(_,d)
        if not d or d=="" then return end
        for _,l in ipairs(vim.split(d,"\n",{plain=true})) do
          if l~="" then out[#out+1]=l end
        end
      end,
      stderr=function(_,d)
        if d and d~="" then err_buf[#err_buf+1]=d end
      end,
    }, vim.schedule_wrap(function(o) on_done(o.code) end))
  else
    fn.jobstart(cmd, {
      on_stdout=function(_,d)
        for _,l in ipairs(d or {}) do if l~="" then out[#out+1]=l end end
      end,
      on_stderr=function(_,d)
        for _,l in ipairs(d or {}) do if l~="" then err_buf[#err_buf+1]=l end end
      end,
      on_exit=vim.schedule_wrap(function(_,c) on_done(c) end),
    })
  end
end

function M._finish_cwd(action, lines, cwd)
  if #lines==0 then N.info("no emojis found under cwd"); return end
  if action=="count" then
    N.info(("Found %d match%s under %s"):format(
      #lines, #lines==1 and "" or "es", fn.fnamemodify(cwd,":~")))
    return
  end
  local qf = {}
  for _,raw in ipairs(lines) do
    local file, lnum = raw:match("^(.+):(%d+):")
    if file and lnum then
      qf[#qf+1]={ filename=file, lnum=tonumber(lnum), col=1,
                  text=raw:match("^.+:%d+:(.*)$") or "" }
    end
  end
  if #qf==0 then N.warn("rg output could not be parsed"); return end
  fn.setqflist({}, "r", { title="Emojis (cwd)", items=qf })
  vim.cmd("copen")
  N.info(("Found %d match%s → quickfix"):format(#qf, #qf==1 and "" or "es"))
end

-- ============================================================================
-- Dispatch
-- ============================================================================

local function execute(cmd_args, default_scope)
  local action = ((cmd_args.fargs[1] or "clear"):lower())
  local scope  = ((cmd_args.fargs[2] or default_scope):lower())

  if not has(ACTIONS, action) then
    N.error("unknown action '"..action.."'. Valid: "..table.concat(ACTIONS,", "))
    return
  end
  if action~="insert" and not has(SCOPES, scope) then
    N.error("unknown scope '"..scope.."'. Valid: "..table.concat(SCOPES,", "))
    return
  end

  if action=="insert" then do_insert(); return end
  if scope=="cwd"     then do_cwd(action); return end

  local ok, result = pcall(resolve, scope, cmd_args.range, cmd_args.line1, cmd_args.line2)
  if not ok then
    N.error("scope error: "..tostring(result)); return
  end

  if     action=="clear"   then do_edit("clear",   result)
  elseif action=="replace" then do_edit("replace", result)
  elseif action=="list"    then do_list(result)
  elseif action=="count"   then do_count(result)
  end
end

-- ============================================================================
-- Completion
-- ============================================================================

local function complete(_, cmd_line, _)
  local tokens = vim.split(vim.trim(cmd_line), "%s+", { trimempty=true })
  local n      = #tokens - 1          -- args after "Emojis"
  local trail  = cmd_line:sub(-1)==" "
  local arg    = trail and (n+1) or n  -- which arg are we completing?

  local cands = arg<=1 and ACTIONS or (arg==2 and SCOPES or {})
  local partial = (not trail and tokens[#tokens]) or ""
  if partial=="" then return cands end
  local out = {}
  for _,c in ipairs(cands) do
    if vim.startswith(c, partial) then out[#out+1]=c end
  end
  return out
end

-- ============================================================================
-- Setup
-- ============================================================================

---@param opts? usrcmds.emojis.SetupOpts
function M.setup(opts)
  if _done then return end
  opts = opts or {}
  local ds = opts.default_scope or "%"
  if not has(SCOPES, ds) then
    N.warn("invalid default_scope '"..ds.."', using '%'"); ds = "%"
  end

  -- Use the native API directly so cmd_args fields are guaranteed correct
  api.nvim_create_user_command("Emojis", function(cmd_args)
    execute(cmd_args, ds)
  end, {
    desc     = "[emojis] :Emojis [clear|insert|list|count|replace] [word|line|visual|%|cwd]",
    nargs    = "*",
    range    = true,
    complete = complete,
  })

  _done = true
end

return M
