---@module 'bindings.usrcmds.autocmd_docs'
---@brief `:LibAutocmdDocs[Check|All]` and `:LibUsercmdDocs[Check]` — generate
---`bindings/autocmd/` and `bindings/usercmd/` markdown
---from what `lib.nvim.bindings.autocmd` actually registered this session.
---@description
--- `lib.nvim.bindings.autocmd` keeps a record of every autocmd created
--- through it — event, group, pattern, desc, file:line — and
--- `lib.nvim.bindings.autocmd.docs` renders that record as markdown, one file
--- per event family, into a plugin's `bindings/autocmd/`. That answers "what
--- fires when" from what exists rather than from a hand-kept list.
---
--- The single-repo commands come straight from lib (`create_usercmd`). They
--- live *here*, in the config, and not in each plugin on purpose: this is a
--- tool for whoever is editing the repos, and a plugin shipping its own copy
--- would put an identical command in every user's editor.
---
--- `:LibAutocmdDocsAll [dir]` is the config's own addition, in the same shape
--- as every other `*All` command here: no argument means `$REPOS_DIR`.
---
--- **What it can and cannot see.** The set of repositories is derived from the
--- records, not from scanning `dir` — each record knows the file it came
--- from. A scan would find plugins that are installed but never loaded, and
--- writing their docs would put an empty file over a correct one. So a plugin
--- that did not load simply does not appear in the report, and a lazy-loaded
--- plugin whose trigger has not fired yet has registered nothing. Load what
--- you want documented before running this.
---
--- Autocmds created straight from `vim.api.nvim_create_autocmd` leave no
--- record at all. lib counts those call sites statically and prints the
--- warning into the generated file; the report below repeats the count, so
--- "this doc is incomplete" is visible without opening it.

local usercmd = require("lib.nvim.bindings.usercmd")
local notify = require("lib.nvim.notify").create("[autocmd-docs]")
local docs = require("lib.nvim.bindings.autocmd").docs
local resolve_base_dir = require("bindings.usrcmds.plugin_repos.ops").resolve_base_dir

local M = {}

---@param results Lib.Autocmd.Docs.AllResult[]
---@param dry_run boolean
---@return nil
local function report(results, dry_run)
  local lines = {}
  local failed, incomplete = 0, 0

  for _, r in ipairs(results) do
    if r.err then
      failed = failed + 1
      lines[#lines + 1] = ("  %-24s FEHLER: %s"):format(r.plugin, r.err)
    else
      local warn = ""
      if r.unregistered > 0 then
        incomplete = incomplete + 1
        warn = (" — unvollständig: %d× nvim_create_autocmd direkt"):format(r.unregistered)
      end
      lines[#lines + 1] = ("  %-24s %2d autocmds, %d Datei(en)%s"):format(
        r.plugin,
        r.records,
        #r.written,
        warn
      )
    end
  end

  table.sort(lines)
  local head = ("%s%d Repo(s)"):format(dry_run and "[dry-run] " or "", #results)
  if failed > 0 then
    head = head .. (", %d fehlgeschlagen"):format(failed)
  end
  if incomplete > 0 then
    head = head .. (", %d unvollständig"):format(incomplete)
  end

  table.insert(lines, 1, head)
  if #results == 0 then
    lines[#lines + 1] = "  Nichts registriert. Sind die Plugins geladen?"
  end

  if failed > 0 then
    notify.warn(table.concat(lines, "\n"))
  else
    notify.info(table.concat(lines, "\n"))
  end
end

---Register `:LibAutocmdDocs`, `:LibAutocmdDocsCheck` and `:LibAutocmdDocsAll`,
---plus the user-command equivalents.
---@return nil
function M.enable()
  docs.create_usercmd()

  -- `:LibUsercmdDocs` / `:LibUsercmdDocsCheck`, the same pair for the user
  -- commands this config defines. They live here rather than in their own
  -- module for the reason the header gives about the autocmd ones: this is
  -- tooling for whoever edits the repos, and the two generators are the same
  -- tool pointed at two registries.
  --
  -- No `…All` counterpart: lib has no `write_all` for user commands, and the
  -- autocmd one derives its repository set from records that carry a source
  -- path -- which these now do, so it is a small addition if it is ever
  -- wanted, not a missing capability.
  require("lib.nvim.bindings.usercmd").docs.create_usercmd()

  usercmd.create("LibAutocmdDocsAll", function(opts)
    local args = vim.split(opts.args or "", "%s+", { trimempty = true })
    local dry_run, dir = false, nil
    for _, a in ipairs(args) do
      if a == "--dry-run" then
        dry_run = true
      else
        dir = a
      end
    end

    local base = resolve_base_dir(dir)
    if not base then
      notify.error("Kein Verzeichnis angegeben und $REPOS_DIR ist nicht gesetzt")
      return
    end

    report(docs.write_all({ under = base, dry_run = dry_run }), dry_run)
  end, {
    nargs = "*",
    complete = function(arg_lead)
      local out = {}
      if ("--dry-run"):sub(1, #arg_lead) == arg_lead then
        out[#out + 1] = "--dry-run"
      end
      if
        vim.env.REPOS_DIR
        and vim.env.REPOS_DIR ~= ""
        and ("$REPOS_DIR"):sub(1, #arg_lead) == arg_lead
      then
        out[#out + 1] = "$REPOS_DIR"
      end
      vim.list_extend(out, vim.fn.getcompletion(arg_lead, "dir"))
      return out
    end,
    desc = "bindings/autocmd für jedes Repo unter dir/$REPOS_DIR schreiben, das diese Session etwas registriert hat",
  })
end

return M
