---@module 'lsp.lspdoctor'
---@brief On-demand LSP health checks with quick/deep modes, formatter policy, and scratch export.
---@description
--- LSP Doctor inspects the LSP state for the current buffer and the session.
--- It offers a "quick" summary, a "deep" report, a scratch-buffer exporter,
--- and a ":LspDoctor health" subcommand that mimics Neovim's :checkhealth style.
---
--- Key features:
--- - Safety: API guards, pcall for optional deps, pure core collection
--- - Extensibility: modular checks, formatter policy, offset-encoding mismatch
--- - Observability: optional semantic-tokens probe, CodeLens/InlayHints status
--- - UI: print/notify renderers, scratch-buffer export with handy keymaps
---
--- Commands:
---   :LspDoctor          -> quick
---   :LspDoctor!         -> deep
---   :LspDoctor export   -> quick report into a scratch buffer
---   :LspDoctor! export  -> deep report into a scratch buffer
---   :LspDoctor health   -> health-style output (prints to message area)
--- Programmatic:
---   require('usrcmds.lspdoctor').run('deep')               -- returns report
---   require('usrcmds.lspdoctor').export('quick', 0)        -- opens scratch
---   require('usrcmds.lspdoctor').health()                  -- prints health

local M = {}

-- Local aliases (cheap and clear)
local api, lsp, diag = vim.api, vim.lsp, vim.diagnostic
local uv = vim.uv or vim.loop
local fn = vim.fn

-- Defaults --------------------------------------------------------------------

local Defaults = {
  use_notify = false,
  list_limit = 10,
  show_capabilities = true,
  show_workspace = true,
  show_tools = true,
  show_conflicts = true,
  formatter_priority = {},       -- e.g. { "null-ls", "eslint", "lua_ls" }
  semantic_tokens_timeout = 300, -- ms
  scratch_filetype = "markdown",
}

---@type LspDoctorOptions
local Opts = vim.deepcopy(Defaults)

-- Utils -----------------------------------------------------------------------

---@param mod string
---@return boolean, any
local function safe_require(mod)
  local ok, res = pcall(require, mod)
  return ok, res
end

---@param b boolean|nil
---@return string
local function yesno(b)
  return b and "yes" or "no"
end

---@param t string[]
---@param n integer
---@return string[]
local function take(t, n)
  local out = {}
  local len = math.min(#t, n)
  for i = 1, len do out[i] = t[i] end
  if #t > n then out[#out + 1] = ("…(+%d more)"):format(#t - n) end
  return out
end

---@param list string[]
---@param value string
---@return boolean
local function contains(list, value)
  for _, v in ipairs(list) do if v == value then return true end end
  return false
end

-- Collection ------------------------------------------------------------------

---@param bufnr integer
---@return table<string, lsp.Client> clients_by_name, string[] names
local function collect_clients(bufnr)
  if type(bufnr) ~= "number" or not api.nvim_buf_is_valid(bufnr) then
    return {}, {}
  end
  local by_name, names = {}, {}
  local clients = lsp.get_clients({ bufnr = bufnr }) or {}
  for _, c in ipairs(clients) do
    local name = c.name or ("client#" .. tostring(c.id or "?"))
    by_name[name] = c
    names[#names + 1] = name
  end
  table.sort(names)
  return by_name, names
end

---@param bufnr integer
---@return table<string, integer> counts_by_sev, integer total
local function collect_diagnostics(bufnr)
  local counts = { ERROR = 0, WARN = 0, INFO = 0, HINT = 0 }
  if type(bufnr) ~= "number" or not api.nvim_buf_is_valid(bufnr) then
    return counts, 0
  end
  local items = diag.get(bufnr) or {}
  for _, d in ipairs(items) do
    local s = d.severity
    if s == vim.diagnostic.severity.ERROR then counts.ERROR = counts.ERROR + 1
    elseif s == vim.diagnostic.severity.WARN then counts.WARN = counts.WARN + 1
    elseif s == vim.diagnostic.severity.INFO then counts.INFO = counts.INFO + 1
    elseif s == vim.diagnostic.severity.HINT then counts.HINT = counts.HINT + 1
    end
  end
  return counts, #items
end

-- Extended checks -------------------------------------------------------------

-- Offset-encoding mismatch across clients (e.g., "utf-8" vs "utf-16")
---@param clients_by_name table<string, vim.lsp.Client>
---@return string[] unique_encs, string[] mismatches
local function check_offset_encoding(clients_by_name)
  local set, order = {}, {}
  for name, c in pairs(clients_by_name) do
    local enc = (c.offset_encoding or "utf-16") -- server default in upstream; be explicit
    if not set[enc] then set[enc] = {} end
    table.insert(set[enc], name)
  end
  for enc, _ in pairs(set) do order[#order + 1] = enc end
  table.sort(order)
  local mismatches = {}
  if #order > 1 then
    for _, enc in ipairs(order) do
      table.insert(mismatches, ("%s: %s"):format(enc, table.concat(set[enc], ", ")))
    end
  end
  return order, mismatches
end

-- CodeLens/InlayHints status (supported + enabled)
---@param bufnr integer
---@param clients_by_name table<string, lsp.Client>
---@return string[] lines
local function check_lens_inlay(bufnr, clients_by_name)
  local lines = {}
  local any_lens = false
  local any_inlay = false

  for name, c in pairs(clients_by_name) do
    local caps = c.server_capabilities or {}
    local cl = yesno(caps.codeLensProvider ~= nil)
    local ih = yesno(caps.inlayHintProvider ~= nil)
    table.insert(lines, ("  %s: codeLens=%s, inlayHints=%s"):format(name, cl, ih))
    any_lens = any_lens or (caps.codeLensProvider ~= nil)
    any_inlay = any_inlay or (caps.inlayHintProvider ~= nil)
  end

  -- Enabled/active check (best-effort, works on 0.10+)
  local has_inlay_api = (vim.lsp.inlay_hint ~= nil) and (vim.lsp.inlay_hint.enable ~= nil)
  local inlay_enabled
  if has_inlay_api then
    local ok_enabled, enabled = pcall(function()
      -- 0.10: vim.lsp.inlay_hint.is_enabled({ bufnr = ... }) or .get
      if vim.lsp.inlay_hint.is_enabled then
        return vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
      end
      if vim.lsp.inlay_hint.is_enabled == nil and vim.lsp.inlay_hint.get ~= nil then
        -- some nightlies had .get() returning boolean for buffer
        return vim.lsp.inlay_hint.get({ bufnr = bufnr })
      end
      return nil
    end)
    inlay_enabled = ok_enabled and (enabled == true)
  end

  table.insert(lines, ("  inlay_hint API available: %s; enabled_now: %s")
    :format(yesno(has_inlay_api), yesno(inlay_enabled == true)))
  return lines
end

-- Semantic tokens refresh probe (non-blocking, short timeout)
---@param bufnr integer
---@param clients_by_name table<string, vim.lsp.Client>
---@return string[] lines
local function probe_semantic_tokens(bufnr, clients_by_name)
  local lines = {}
  local method = "textDocument/semanticTokens/full"
  local params = lsp.util.make_text_document_params(bufnr)
  local deadline = uv.now() + (Opts.semantic_tokens_timeout or 300)

  -- Iterate all clients that support semanticTokens
  for name, c in pairs(clients_by_name) do
    local caps = c.server_capabilities or {}
    if caps.semanticTokensProvider ~= nil then
      local ok_sent = false
      local responded = false
      local msg = ("  %s: sent=%s responded=%s"):format(name, "no", "no")

      -- Protect request sending
      local ok_req, _ = pcall(function()
        c.request(method, params, function(err, _)
          responded = true
          if err then
            msg = ("  %s: sent=yes responded=error (%s)"):format(name, tostring(err.message or err))
          else
            msg = ("  %s: sent=yes responded=ok"):format(name)
          end
        end, bufnr)
        ok_sent = true
      end)

      if not ok_req then
        msg = ("  %s: sent=error (request failed to start)"):format(name)
      else
        -- Lightweight wait loop up to timeout (does not block UI events)
        -- Note: we yield to the loop by scheduling and sleeping minimally.
        while not responded and uv.now() < deadline do
          -- Let the loop progress; tiny sleep to avoid busy loop
          uv.sleep(5)
        end
        if ok_sent and not responded then
          msg = ("  %s: sent=yes responded=timeout (%dms)"):format(name, Opts.semantic_tokens_timeout or 300)
        end
      end
      table.insert(lines, msg)
    end
  end

  if #lines == 0 then
    table.insert(lines, "  No client provides semanticTokens.")
  end
  return lines
end

-- Provider conflicts (formatting/diagnostics)
---@param clients_by_name table<string, lsp.Client>
---@return string[] conflicts
local function detect_conflicts(clients_by_name)
  local conflicts = {}
  local fmt, diagp = {}, {}
  for name, c in pairs(clients_by_name) do
    local caps = c.server_capabilities or {}
    if caps.documentFormattingProvider == true then fmt[#fmt + 1] = name end
    if caps.diagnosticProvider or caps.publishDiagnosticsProvider then
      diagp[#diagp + 1] = name
    end
  end
  if #fmt > 1 then
    table.sort(fmt)
    conflicts[#conflicts + 1] = "Formatting providers overlap: " .. table.concat(fmt, ", ")
  end
  if #diagp > 1 then
    table.sort(diagp)
    conflicts[#conflicts + 1] = "Diagnostics providers overlap: " .. table.concat(diagp, ", ")
  end
  return conflicts
end

-- Formatter policy winner -----------------------------------------------------

---@param clients_by_name table<string, lsp.Client>
---@return string|nil winner, string[] candidates_sorted, string reason
local function pick_formatter(clients_by_name)
  local candidates = {}
  for name, c in pairs(clients_by_name) do
    local caps = c.server_capabilities or {}
    if caps.documentFormattingProvider == true then
      candidates[#candidates + 1] = name
    end
  end
  table.sort(candidates)

  if #candidates == 0 then
    return nil, candidates, "no formatting provider"
  end

  -- Priority list (first hit wins)
  for _, prefer in ipairs(Opts.formatter_priority or {}) do
    if contains(candidates, prefer) then
      return prefer, candidates, "priority list"
    end
  end

  -- Fallback: first alphabetically
  return candidates[1], candidates, "alphabetical fallback"
end

-- Tools check (non-fatal) -----------------------------------------------------

---@return string[] lines
local function check_tools()
  local tools = {
    "rg", "fd", "jq", "eslint", "prettier", "stylua", "lua-language-server",
  }
  local missing = {}
  for _, t in ipairs(tools) do
    local ok = uv.fs_stat(fn.exepath(t))
    if not ok then missing[#missing + 1] = t end
  end
  if #missing == 0 then
    return { "All common tools present" }
  else
    return { "Missing tools: " .. table.concat(missing, ", ") }
  end
end

-- Report assembly -------------------------------------------------------------

---@param mode '"quick"'|'"deep"'
---@param bufnr integer
---@return LspDoctorReport
local function collect(mode, bufnr)
  local rep = { mode = mode, ok = true, summary = "", sections = {}, extras = {} }

  local clients_by_name, names = collect_clients(bufnr)
  local counts, total = collect_diagnostics(bufnr)

  local s_clients = { title = "LSP clients (current buffer)", lines = {} }
  if #names == 0 then
    s_clients.lines = { "No LSP client attached to the current buffer." }
  else
    for _, n in ipairs(mode == "quick" and take(names, Opts.list_limit) or names) do
      s_clients.lines[#s_clients.lines + 1] = ("- %s"):format(n)
    end
  end

  local s_diags = {
    title = "Diagnostics (current buffer)",
    lines = { ("Total=%d  [ERROR=%d, WARN=%d, INFO=%d, HINT=%d]"):format(
      total, counts.ERROR, counts.WARN, counts.INFO, counts.HINT
    ) },
  }

  table.insert(rep.sections, s_clients)
  table.insert(rep.sections, s_diags)

  -- Conflicts
  if Opts.show_conflicts and #names > 1 then
    local conf = detect_conflicts(clients_by_name)
    table.insert(rep.sections, {
      title = "Provider conflicts",
      lines = (#conf > 0) and conf or { "No obvious overlaps detected." },
    })
  end

  -- Offset-encoding mismatch
  do
    local encs, mismatches = check_offset_encoding(clients_by_name)
    rep.extras.offset_encodings = encs
    if #encs > 0 then
      local lines = (#mismatches > 0)
        and vim.list_extend({ "Mismatch detected across clients:" }, mismatches)
         or { "All clients share the same offset encoding: " .. encs[1] }
      table.insert(rep.sections, { title = "Offset encodings", lines = lines })
      if #encs > 1 then rep.ok = false end
    end
  end

  -- Formatter policy winner
  do
    local winner, all, reason = pick_formatter(clients_by_name)
    rep.extras.formatter_winner = winner
    rep.extras.formatter_candidates = all
    table.insert(rep.sections, {
      title = "Formatter policy",
      lines = {
        "Candidates: " .. (#all == 0 and "(none)" or table.concat(all, ", ")),
        "Winner: " .. (winner or "(none)"),
        "Policy: " .. reason .. (#(Opts.formatter_priority or {}) > 0
            and (" (" .. table.concat(Opts.formatter_priority, " > ") .. ")") or ""),
      },
    })
  end

  if mode == "deep" then
    -- Workspace/root
    if Opts.show_workspace and #names > 0 then
      for _, n in ipairs(names) do
        local c = clients_by_name[n]
        local lines = {}
        local root = (c.config and c.config.root_dir) or c.root_dir
        table.insert(lines, ("  root_dir: %s"):format(tostring(root)))
        local ws = {}
        if c.workspace_folders and type(c.workspace_folders) == "table" then
          for _, f in ipairs(c.workspace_folders) do
            ws[#ws + 1] = (f.name or f.uri or "?")
          end
        end
        if #ws > 0 then
          table.insert(lines, "  workspace_folders:")
          for _, w in ipairs(ws) do table.insert(lines, ("    - %s"):format(w)) end
        else
          table.insert(lines, "  workspace_folders: (none)")
        end
        local bufname = api.nvim_buf_get_name(bufnr)
        if root and type(bufname) == "string" and #bufname > 0 then
          local ok_prefix = bufname:sub(1, #root) == root
          table.insert(lines, ("  buffer_under_root: %s"):format(yesno(ok_prefix)))
        end
        table.insert(rep.sections, { title = ("Workspace: %s"):format(n), lines = lines })
      end
    end

    -- Capabilities (subset)
    if Opts.show_capabilities and #names > 0 then
      for _, n in ipairs(names) do
        local c = clients_by_name[n]
        local caps = c.server_capabilities or {}
        local lines = {
          ("  offsetEncoding: %s"):format(tostring(c.offset_encoding or "nil")),
          ("  positionEncoding: %s"):format(tostring(caps.positionEncoding or "nil")),
          ("  textDocumentSync: %s"):format(type(caps.textDocumentSync)),
          ("  completionProvider: %s"):format(yesno(caps.completionProvider ~= nil)),
          ("  definitionProvider: %s"):format(yesno(caps.definitionProvider ~= nil)),
          ("  documentFormattingProvider: %s"):format(yesno(caps.documentFormattingProvider == true)),
          ("  rangeFormattingProvider: %s"):format(yesno(caps.documentRangeFormattingProvider == true)),
          ("  codeActionProvider: %s"):format(yesno(caps.codeActionProvider ~= nil)),
          ("  semanticTokensProvider: %s"):format(yesno(caps.semanticTokensProvider ~= nil)),
          ("  inlayHintProvider: %s"):format(yesno(caps.inlayHintProvider ~= nil)),
          ("  codeLensProvider: %s"):format(yesno(caps.codeLensProvider ~= nil)),
        }
        table.insert(rep.sections, { title = ("Capabilities: %s"):format(n), lines = lines })
      end
    end

    -- CodeLens/InlayHints
    if #names > 0 then
      table.insert(rep.sections, {
        title = "CodeLens & InlayHints",
        lines = check_lens_inlay(bufnr, clients_by_name),
      })
    end

    -- Semantic tokens probe
    table.insert(rep.sections, {
      title = "Semantic tokens probe",
      lines = probe_semantic_tokens(bufnr, clients_by_name),
    })

    -- Tools/integrations
    if Opts.show_tools then
      table.insert(rep.sections, { title = "External tools", lines = check_tools() })
    end
    do
      local ok_trouble = safe_require("trouble")
      local ok_fidget = safe_require("fidget")
      local ok_navic = safe_require("nvim-navic")
      table.insert(rep.sections, {
        title = "Optional integrations",
        lines = {
          ("trouble.nvim: %s"):format(yesno(ok_trouble)),
          ("fidget.nvim: %s"):format(yesno(ok_fidget)),
          ("nvim-navic: %s"):format(yesno(ok_navic)),
        },
      })
    end
  end

  -- Summary
  if #names == 0 then
    rep.ok = false
    rep.summary = "No LSP client attached; diagnostics empty."
  else
    rep.summary = ("Clients=%d; Diagnostics=%d (E=%d W=%d I=%d H=%d)")
      :format(#names, total, counts.ERROR, counts.WARN, counts.INFO, counts.HINT)
  end

  return rep
end

-- Rendering -------------------------------------------------------------------

---@param rep LspDoctorReport
---@return nil
local function render(rep)
  local function out(line, level)
    if Opts.use_notify then
      vim.notify(line, level or vim.log.levels.INFO, { title = "LSP Doctor" })
    else
      print(line)
    end
  end
  out(("LSP Doctor (%s) – %s"):format(rep.mode, rep.ok and "ok" or "issues"))
  out(rep.summary)
  for _, sec in ipairs(rep.sections) do
    out(("== %s =="%sec))
    for _, l in ipairs(sec.lines) do out(l) end
  end
end

-- Scratch export renderer ------------------------------------------------------

---@param rep LspDoctorReport
---@return integer bufnr
local function render_to_scratch(rep)
  -- Create a scratch buffer in a new split; non-file, no swap, read-only
  vim.cmd("botright new")
  local scratch = api.nvim_get_current_buf()
  api.nvim_buf_set_name(scratch, "LSP Doctor Report")
  api.nvim_set_option_value("buftype", "nofile", { buf = scratch })
  api.nvim_set_option_value("bufhidden", "wipe", { buf = scratch })
  api.nvim_set_option_value("swapfile", false, { buf = scratch })
  api.nvim_set_option_value("modifiable", true, { buf = scratch })
  api.nvim_set_option_value("filetype", Opts.scratch_filetype or "markdown", { buf = scratch })

  local lines = {}
  lines[#lines + 1] = ("# LSP Doctor (%s) – %s"):format(rep.mode, rep.ok and "ok" or "issues")
  lines[#lines + 1] = rep.summary
  lines[#lines + 1] = ""
  for _, sec in ipairs(rep.sections) do
    lines[#lines + 1] = ("## %s"):format(sec.title)
    for _, l in ipairs(sec.lines) do lines[#lines + 1] = l end
    lines[#lines + 1] = ""
  end

  api.nvim_buf_set_lines(scratch, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = scratch })

  -- Minimal helpful mappings (buffer-local)
  local opts = { nowait = true, noremap = true, silent = true, buffer = scratch }
  vim.keymap.set("n", "q", "<cmd>bd!<CR>", opts)               -- close
  vim.keymap.set("n", "y", "ggyG", opts)                       -- yank all
  vim.keymap.set("n", "gw", function()                         -- write to a timestamped file under :echo stdpath('cache')
    local path = fn.stdpath("cache") .. "/lspdoctor_" .. os.date("%Y%m%d_%H%M%S") .. ".md"
    api.nvim_command("silent keepalt keepjumps write! " .. fn.fnameescape(path))
    vim.notify("Wrote report to: " .. path, vim.log.levels.INFO, { title = "LSP Doctor" })
  end, opts)

  return scratch
end

-- Health-style output ---------------------------------------------------------

---@return nil
local function render_health()
  -- Minimal health-like style, no hard coupling to :checkhealth
  local function health_hdr(name) print(("\nhealth#%s#check"):format(name)) end
  local function health_ok(msg) print("OK: " .. msg) end
  local function health_warn(msg) print("WARNING: " .. msg) end
  local function health_err(msg) print("ERROR: " .. msg) end

  local bufnr = 0
  local clients_by_name, names = collect_clients(bufnr)
  local encs, mismatch_lines = check_offset_encoding(clients_by_name)
  local _, total = collect_diagnostics(bufnr)

  health_hdr("lspdoctor")

  if #names == 0 then
    health_err("No LSP client attached to current buffer.")
  else
    health_ok(("LSP clients attached: %d"):format(#names))
  end

  if total == 0 then
    health_ok("No diagnostics in current buffer.")
  else
    health_warn(("Diagnostics present: %d"):format(total))
  end

  if #encs <= 1 then
    health_ok(("Offset encoding unified: %s"):format(encs[1] or "n/a"))
  else
    health_warn("Offset encoding mismatch across clients:")
    for _, l in ipairs(mismatch_lines) do print("  - " .. l) end
  end

  local winner, candidates = pick_formatter(clients_by_name)
  if not winner then
    health_warn("No formatting provider detected.")
  else
    health_ok(("Formatting winner: %s (candidates: %s)"):format(winner, table.concat(candidates, ", ")))
  end

  local tools = check_tools()
  if #tools == 1 and tools[1]:find("^All common tools present") then
    health_ok("Toolchain: " .. tools[1])
  else
    health_warn(tools[1])
  end
end

-- Public API ------------------------------------------------------------------

---Configure behavior. Call once in your setup code.
---@param opts LspDoctorOptions|nil
---@return nil
function M.setup(opts)
  if opts ~= nil then
    for k, v in pairs(opts) do
      if Defaults[k] ~= nil then Opts[k] = v end
    end
  end
end

---Run the doctor in the given mode and render to message area (print/notify).
---@param mode '"quick"'|'"deep"'|nil
---@param bufnr integer|nil
---@return LspDoctorReport
function M.run(mode, bufnr)
  local m = (mode == "deep") and "deep" or "quick"
  local b = (type(bufnr) == "number") and bufnr or 0
  local rep = collect(m, b)
  render(rep)
  return rep
end

---Export the report into a scratch buffer.
---@param mode '"quick"'|'"deep"'|nil
---@param bufnr integer|nil
---@return integer bufnr
function M.export(mode, bufnr)
  local m = (mode == "deep") and "deep" or "quick"
  local b = (type(bufnr) == "number") and bufnr or 0
  local rep = collect(m, b)
  return render_to_scratch(rep)
end

---Print a health-style summary (like :checkhealth output).
---@return nil
function M.health()
  render_health()
end

---Define the :LspDoctor user command with subcommands and bang for deep mode.
---@return nil
function M.enable_usercmd()
  api.nvim_create_user_command("LspDoctor", function(ctx)
    local arg = (ctx.args or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local mode = ctx.bang and "deep" or "quick"
    if arg == "" then
      M.run(mode, 0)
    elseif arg == "export" then
      M.export(mode, 0)
    elseif arg == "health" then
      M.health()
    else
      vim.notify("Unknown argument: " .. arg .. " (use: export|health)", vim.log.levels.WARN, { title = "LSP Doctor" })
    end
  end, {
    bang = true,    -- :LspDoctor! => deep
    nargs = "?",    -- optional subcommand
    complete = function() return { "export", "health" } end,
    desc = "LSP Doctor (add ! for deep, subcommands: export|health)",
  })
end

return M
