---@module 'bindings.usrcmds.bindings_explorer.report'
--- `:Bindings report` — the same drift run `:Bindings check` shows in a
--- viewer, written to a Markdown file instead.
---
--- Why it exists: the 2026-09-02 drift report was assembled by hand out of a
--- headless run (`nvim --headless -c "lua ... drift.check"`, output
--- redirected, run header and counts typed in front of it). That hand work is
--- what this module does — run header, counts by finding kind, and
--- `drift.describe`'s unchanged text as an appendix.
---
--- What it deliberately does NOT do is judge the findings. Which of them is a
--- real documentation gap and which is a tool defect or an expected effect
--- (a buffer-local UI that is not open, a lazy trigger that never fired) is a
--- reading, and that reading is the part a handwritten report is worth
--- writing for. This file produces the measured half so the person only has
--- to add the other one.
---
--- The appendix is a ```text block rather than Markdown tables on purpose:
--- `drift.describe` aligns its columns with `%-22s`, and that alignment is
--- the only structure the raw report has. Re-cast as tables it would be
--- longer and read worse.
---
--- Output language is German, like every other user-visible string of
--- `:Bindings`.
---
---@see bindings.usrcmds.bindings_explorer.drift

local config = require("bindings.usrcmds.bindings_explorer.config")
local drift = require("bindings.usrcmds.bindings_explorer.drift")

local M = {}

--- Row order of the counts table. Same ranking as `drift.lua`'s `SECTIONS`:
--- whatever is most likely worth acting on comes first.
local KIND_ORDER = {
  "usercmd-not-live",
  "keymap-not-live",
  "keymap-not-in-repo",
  "usercmd-not-in-repo",
  "keymap-undocumented",
  "usercmd-undocumented-source",
  "usercmd-undocumented",
}

local KIND_NOTE = {
  ["usercmd-not-live"] = "dokumentiert, in dieser Session nicht registriert",
  ["keymap-not-live"] = "dokumentiert, in dieser Session nicht gebunden",
  ["keymap-not-in-repo"] = "dokumentiert, im Checkout des Plugins nicht gefunden (Grep-Achse)",
  ["usercmd-not-in-repo"] = "dokumentiert, im Checkout des Plugins nicht gefunden (Grep-Achse)",
  ["keymap-undocumented"] = "im Quelltext dieser Config registriert, nirgends dokumentiert",
  ["usercmd-undocumented-source"] = "im Quelltext dieser Config registriert, nirgends dokumentiert",
  ["usercmd-undocumented"] = "live, im Korpus weder als Tabellenzeile noch als Erwähnung",
}

--- Where the report is written.
---
--- `out` may name a directory (then `BINDINGS-DRIFT-<date>.md` is created in
--- it) or a file. Without `out`, `config.report_dir()` applies. A file name
--- without an extension gets `.md` — the report is Markdown, and an
--- extensionless file in that folder is the odd one out.
---@param out string|nil
---@return string absolute path
function M.resolve_path(out)
  local dir_or_file = (out and out ~= "") and out or config.report_dir()
  local abs = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(dir_or_file), ":p"))

  if vim.fn.isdirectory(abs) == 1 then
    abs =
      vim.fs.joinpath((abs:gsub("/$", "")), ("BINDINGS-DRIFT-%s.md"):format(os.date("%Y-%m-%d")))
  elseif not abs:match("%.%w+$") then
    abs = abs .. ".md"
  end

  return abs
end

---@param findings Bindings.DriftFinding[]
---@return table<string, integer>
local function count_kinds(findings)
  local out = {}
  for _, f in ipairs(findings) do
    out[f.kind] = (out[f.kind] or 0) + 1
  end
  return out
end

--- Render the report as Markdown lines.
---@param findings Bindings.DriftFinding[]
---@param skipped string[]|nil `drift.check`'s second return value
---@param source_reason string|nil its third
---@param repo_info Bindings.RepoInfo|nil its fourth
---@param meta { plugin?: string, duration_ms?: number }|nil
---@return string[]
function M.render(findings, skipped, source_reason, repo_info, meta)
  meta = meta or {}
  local counts = count_kinds(findings)

  local lines = {
    ("# BINDINGS-Driftreport — %s"):format(os.date("%Y-%m-%d")),
    "",
    "Erzeugt von `:Bindings report`. Die Cheatsheets unter `docs/NOTES/` gegen",
    "die Bindings geprüft, die diese Neovim-Instanz tatsächlich registriert hat.",
    "",
    "## Lauf",
    "",
    "| | |",
    "| --- | --- |",
    ("| Erzeugt | %s |"):format(os.date("%Y-%m-%d %H:%M")),
    -- Fields, not `tostring(vim.version())`: that renders "0.12.2+v0.12.2"
    -- on a tagged build, because the build string repeats the version.
    ("| Neovim | %d.%d.%d |"):format(vim.version().major, vim.version().minor, vim.version().patch),
    ("| Umfang | %s |"):format(meta.plugin and ("nur `" .. meta.plugin .. "`") or "alle Plugins"),
    ("| Repo-Achse | %s |"):format(
      (repo_info and repo_info.ran) and "an" or "aus (`:Bindings report repo` schaltet sie zu)"
    ),
  }

  if meta.duration_ms then
    lines[#lines + 1] = ("| Laufzeit der Prüfung | %d ms |"):format(math.floor(meta.duration_ms))
  end
  if repo_info and repo_info.ran then
    lines[#lines + 1] = ("| Aufgelöste Checkouts | %d |"):format(#(repo_info.resolved or {}))
    lines[#lines + 1] = ("| davon beantwortet | %d |"):format(#(repo_info.checked or {}))
    if repo_info.reason then
      lines[#lines + 1] = ("| Repo-Achse nicht befragbar | %s |"):format(repo_info.reason)
    end
  end
  lines[#lines + 1] = ("| Übersprungen (gar nicht geprüft) | %d |"):format(#(skipped or {}))
  lines[#lines + 1] = ("| Befunde | %d |"):format(#findings)
  lines[#lines + 1] = ""

  lines[#lines + 1] = "## Befunde nach Art"
  lines[#lines + 1] = ""
  lines[#lines + 1] = "| Befundart | n | Was es ist |"
  lines[#lines + 1] = "| --- | ---: | --- |"
  local any = false
  for _, kind in ipairs(KIND_ORDER) do
    local n = counts[kind]
    if n then
      any = true
      lines[#lines + 1] = ("| `%s` | %d | %s |"):format(kind, n, KIND_NOTE[kind] or "")
    end
  end
  if not any then
    lines[#lines + 1] = "| — | 0 | keine Befunde |"
  end
  lines[#lines + 1] = ""

  -- The sentence the handwritten 2026-09-02 report sets in bold, because it
  -- is the actual reading aid. It belongs in every run, not just that one.
  lines[#lines + 1] = "**Eine Zahl hier ist ein Befund, kein Problem.** Welcher davon eine echte"
  lines[#lines + 1] = "Doku-Lücke ist und welcher ein Werkzeugfehler oder ein erwartbarer Effekt"
  lines[#lines + 1] = "(buffer-lokale UI nicht offen, lazy nicht ausgelöst), entscheidet die"
  lines[#lines + 1] = "Durchsicht — die Notiz unter jeder Überschrift im Anhang sagt, welche"
  lines[#lines + 1] = "Unschärfe der jeweilige Abschnitt hat."
  lines[#lines + 1] = ""

  lines[#lines + 1] = "## Anhang: der Bericht im Original"
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Unverändert die Ausgabe von `drift.describe`, wie sie `:Bindings check`"
  lines[#lines + 1] = "in den Viewer schreibt."
  lines[#lines + 1] = ""
  lines[#lines + 1] = "```text"
  vim.list_extend(lines, drift.describe(findings, skipped, source_reason, repo_info))
  lines[#lines + 1] = "```"

  return lines
end

--- Run, render and write in one go.
---@param opts { plugin?: string, repo?: boolean, repo_root?: string, out?: string }|nil
---@return string|nil path, string|nil err, integer|nil findings
function M.write(opts)
  opts = opts or {}
  local path = M.resolve_path(opts.out)

  local dir = vim.fs.dirname(path)
  if vim.fn.isdirectory(dir) ~= 1 and vim.fn.mkdir(dir, "p") ~= 1 then
    return nil, ("Verzeichnis nicht anlegbar: %s"):format(dir), nil
  end

  local t0 = vim.uv.hrtime()
  local findings, skipped, source_reason, repo_info =
    drift.check(opts.plugin, { repo = opts.repo, repo_root = opts.repo_root })
  local ms = (vim.uv.hrtime() - t0) / 1e6

  local lines = M.render(findings, skipped, source_reason, repo_info, {
    plugin = opts.plugin,
    duration_ms = ms,
  })

  -- `writefile` returns 0 on success and -1 on failure, and throws for an
  -- unwritable path -- both have to be caught, or a failed report reads as a
  -- written one.
  local ok, res = pcall(vim.fn.writefile, lines, path)
  if not ok then
    return nil, tostring(res), nil
  end
  if res ~= 0 then
    return nil, ("konnte nicht schreiben: %s"):format(path), nil
  end

  return path, nil, #findings
end

return M
