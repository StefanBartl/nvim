---@module 'bindings.usrcmds.bindings_explorer'
--- `:Bindings` — the composer verb + route table over the BINDINGS corpus
--- (extern cheatsheets under docs/NOTES/ExternPlugins/Bindings + each personal
--- plugin's / this config's own `docs/BINDINGS.md`). Full feature docs:
--- `docs/FEATURES.md` in this module, `:help bindings_explorer`.
---
--- Routes and the file that implements each:
---   search  [cat] [plugin] [query]  live-grep picker (live.lua), static
---                                   prompt+list fallback (search.lua/ui.lua)
---   browse  [cat] [scope] [plugin]  picker over parsed table rows (records.lua
---                                   scraper + browse.lua)
---   check   [plugin] [repo]         drift report vs nvim_get_keymap/_commands
---                                   (drift.lua; +repo.lua for the checkout axis)
---   report  [...] [out=<path>]      same drift run, written to Markdown
---   status                          one-screen corpus/live/plugin dashboard
---   path    [personal|extern]       copy the corpus root(s) to the clipboard
---
--- A cheatsheet stem may stand in any `[plugin]` slot as a scope (see
--- `plugin_scope.lua`); `search` only treats a token as a scope when it names
--- a sheet outright, since that slot also holds the query.
---
--- CDX: every user-facing string of `:Bindings` is deliberately German (see
--- status.lua / report.lua). Keep, or switch to English like the rest?

local composer = require("lib.nvim.bindings.usercmd.composer")
local config = require("bindings.usrcmds.bindings_explorer.config")
local search = require("bindings.usrcmds.bindings_explorer.search")
local live = require("bindings.usrcmds.bindings_explorer.live")
local ui = require("bindings.usrcmds.bindings_explorer.ui")
local browse = require("bindings.usrcmds.bindings_explorer.browse")
local drift = require("bindings.usrcmds.bindings_explorer.drift")
local status = require("bindings.usrcmds.bindings_explorer.status")
local plugin_scope = require("bindings.usrcmds.bindings_explorer.plugin_scope")

--- Argument type of the plugin-scope slots. Own name, not `STRING`, so `<Tab>`
--- can offer the typed category's cheatsheet stems (`plugin_scope.argtype`);
--- the composer's type register is process-wide, hence the prefix — same
--- convention as `GH_REPO`, `IMAGE_TARGET` and this config's other plugin types.
local PLUGIN_ARG = "BINDINGS_PLUGIN"

--- The two corpus halves, allowed as a `browse` positional. Deliberately no
--- `enum` on the slot: it holds this value OR a plugin stem, and an `enum`
--- would reject every stem as a typo before the handler sees it.
local SCOPE_VALUES = { "personal", "extern" }

local M = {}

---@return table lib.nvim notify handle
local function notify()
  return require("lib.nvim.notify").create("[bindings]")
end

--- Run a search over `roots`. Tries live-grep first (`live.lua`); only with
--- no picker engine does it fall back to the static prompt+list search (with
--- `kit.input` when `query` is missing).
---@param roots string[]
---@param query string|nil
---@param prompt string
---@return nil
local function search_scoped(roots, query, prompt)
  if live.open(roots, { query = query, prompt = prompt }) then
    return
  end

  if query and query ~= "" then
    ui.pick(search.search(query, roots))
    return
  end

  require("lib.nvim.ui.kit.input").open({
    title = prompt,
    on_submit = function(line)
      if line == "" then
        return
      end
      ui.pick(search.search(line, roots))
    end,
  })
end

---@class Bindings.Selection
---@field plugin Bindings.PluginMatch|nil resolved plugin scope
---@field query string|nil search text (`search` only)
---@field scope ("personal"|"extern")|nil corpus half (`browse` only)

--- Read a `search` route's plugin scope from its two positionals + optional
--- `plugin=`.
---
--- The first positional carries scope OR query, so position doesn't decide it
--- — whether the token names a sheet does: `hover.nvim` is a scope, `redact`
--- is a query, and `hover.nvim redact` / `redact hover.nvim` both mean "redact,
--- scoped to hover.nvim". Two tokens where neither names a sheet is a typo,
--- not a two-word query — search takes one pattern, not two.
---@param ctx table composer ctx
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil
---@return Bindings.Selection|nil sel
---@return string|nil err ready-to-show `notify` message
local function search_selection(ctx, category)
  local opts = { category = category }
  local a, b = ctx.args.plugin, ctx.args.query
  local explicit = ctx.kv and ctx.kv.plugin or nil

  -- `plugin=` is the spelled-out form: it may prefix-resolve, and the
  -- positional is then unambiguously the query.
  if explicit then
    local match, err = plugin_scope.resolve(explicit, { category = category, fuzzy = true })
    if not match then
      return nil, err or plugin_scope.unknown_message(explicit, opts)
    end
    if b then
      return nil, ("zu viele Argumente: '%s' — mit plugin= ist '%s' die Query"):format(b, a)
    end
    return { plugin = match, query = a }
  end

  if not a then
    return {}
  end

  local match = plugin_scope.resolve(a, opts)
  if match then
    return { plugin = match, query = b }
  end
  if not b then
    return { query = a }
  end
  local swapped = plugin_scope.resolve(b, opts)
  if swapped then
    return { plugin = swapped, query = a }
  end
  return nil, plugin_scope.unknown_message(a, opts)
end

--- Same for `browse`, where the slot carries plugin OR corpus half.
---
--- No query here for a token to be confused with, so this slot also
--- prefix-resolves (`doc` → `documentation.nvim`) and reports an unknown token
--- as an error rather than silently reading it another way. Order is free:
--- `keymaps hover.nvim personal` and `keymaps personal hover.nvim` are the same.
---@param ctx table composer ctx
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil
---@return Bindings.Selection|nil sel
---@return string|nil err
local function browse_selection(ctx, category)
  ---@type Bindings.Selection
  local sel = {}
  local token = ctx.kv and ctx.kv.plugin or nil

  for _, raw in ipairs(ctx.pos or {}) do
    local lower = raw:lower()
    if lower == "personal" or lower == "extern" then
      if sel.scope then
        return nil, ("Korpushälfte doppelt: '%s'"):format(raw)
      end
      sel.scope = lower
    elseif token then
      return nil, ("zu viele Argumente: '%s' — ein Plugin-Scope reicht"):format(raw)
    else
      token = raw
    end
  end

  if token then
    local opts = { category = category, scope = sel.scope, fuzzy = true }
    local match, err = plugin_scope.resolve(token, opts)
    if not match then
      return nil, err or plugin_scope.unknown_message(token, opts)
    end
    sel.plugin = match
  end

  return sel
end

--- Reduce a `check`/`report` plugin token to EXACTLY one cheatsheet stem.
---
--- Both axes filter on `rec.plugin == plugin` (see `drift.check`), i.e. one
--- stem; a token naming two sheets (`dap` → `dap.nvim` and `Dap`) is rejected
--- rather than silently narrowed to one. An exactly-typed stem wins over its
--- normalized twin — else `:Bindings check Dap` would be ambiguous even though
--- a file is named that.
---
--- A token naming nothing passes through unchanged (as before plugin scope),
--- just with a warning: the report stays empty, and without a hint that is
--- indistinguishable from "found nothing".
---@param token string|nil
---@return string|nil stem
---@return string|nil err
local function single_stem(token)
  if not token or token == "" then
    return nil, nil
  end

  local match = plugin_scope.resolve(token)
  if not match then
    notify().warn(plugin_scope.unknown_message(token))
    return token, nil
  end
  if #match.stems == 1 then
    return match.stems[1], nil
  end
  if #match.exact == 1 then
    return match.exact[1], nil
  end
  return nil,
    ("'%s' benennt mehrere Cheatsheets: %s — bitte den Stamm ausschreiben"):format(
      token,
      table.concat(match.stems, ", ")
    )
end

--- Search the corpus, optionally scoped to a category and/or a plugin.
---
--- The plugin scope replaces the roots with the plugin's files rather than
--- filtering on top — both backends take files and directories in the same
--- position (`live.lua` passes them to ripgrep, `search.lua` reads them
--- directly), so a scoped search is the same search over fewer paths.
---
--- Without a plugin scope the file list goes through `plugin_scope.all_files`,
--- not `config.roots()`: since `BND-04` the two physical trees alone are no
--- longer the whole corpus — each personal plugin brings its three categories
--- from its own `docs/BINDINGS.md`, which `config.roots()` does not see. A
--- plugin scope is unaffected, because `plugin_scope.resolve` has always read
--- that third source.
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil nil = the whole corpus
---@param sel Bindings.Selection|nil
---@return nil
function M.search(category, sel)
  sel = sel or {}
  local label = sel.plugin and sel.plugin.label or nil

  local roots = sel.plugin and sel.plugin.files or plugin_scope.all_files(category)

  local prompt
  if category and label then
    prompt = ("Bindings: %s — %s"):format(category, label)
  elseif label then
    prompt = "Bindings: " .. label
  elseif category then
    prompt = "Bindings: " .. category
  else
    prompt = "Bindings durchsuchen"
  end

  search_scoped(roots, sel.query, prompt)
end

--- Copy the BINDINGS root(s) to the clipboard.
---@param scope "personal"|"extern"|nil nil = both, newline-separated
---@return nil
function M.path(scope)
  local roots = config.roots()
  local text
  if scope == "personal" then
    text = roots[1]
  elseif scope == "extern" then
    text = roots[2]
  else
    text = table.concat(roots, "\n")
  end
  vim.fn.setreg("+", text)
  notify().info("Pfad(e) kopiert: " .. text)
end

--- Picker over parsed table rows (`records.lua`) instead of full text.
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil nil = all three
---@param sel Bindings.Selection|nil
---@return nil
function M.browse(category, sel)
  sel = sel or {}
  browse.open(category, sel.scope, sel.plugin)
end

--- Show the drift report (`drift.lua`) in a read-only viewer.
---@param plugin string|nil cheatsheet stem; since plugin scope it need not be
---typed exactly (`hover` → `hover.nvim`, see `single_stem`).
---@param opts { repo?: boolean, repo_root?: string, scope?: "personal"|"extern"|"all" }|nil
---`repo` adds the checkout axis (see `drift.lua`'s module doc, "The repo
---axis") — opt-in, since it is the one axis that reads ~20 repos off disk
---instead of querying a running session. `repo_root` aims that axis at a
---collection dir of several Lua projects instead of the lazy-spec resolution
---and implies `repo`. `scope` splits own vs third-party live commands,
---default `"personal"` — see `drift.check`.
---@return nil
function M.check(plugin, opts)
  local stem, stem_err = single_stem(plugin)
  if stem_err then
    notify().error(stem_err)
    return
  end

  local findings, skipped, source_reason, repo_info, scope_info, autocmd_info =
    drift.check(stem, opts)
  -- The scope goes in the title, not just the report: the difference between
  -- 53 and 107 findings is otherwise unexplained without scrolling to the
  -- scope note.
  local label = (scope_info and scope_info.scope ~= "personal")
      and (" [" .. scope_info.scope .. "]")
    or ""
  require("lib.nvim.ui.kit.viewer").open({
    title = ("Bindings — check%s (%d)"):format(label, #findings),
    lines = drift.describe(findings, skipped, source_reason, repo_info, scope_info, autocmd_info),
  })
end

--- Write the same report as a Markdown file (`report.lua`).
---@param plugin string|nil
---@param opts { repo?: boolean, repo_root?: string, out?: string, scope?: "personal"|"extern"|"all" }|nil
---`out` may be a directory or a filename; without `out` the report lands as
---`BINDINGS-DRIFT-<date>.md` in `config.report_dir()`. `scope` as in `M.check`.
---@return nil
function M.report(plugin, opts)
  opts = opts or {}
  local stem, stem_err = single_stem(plugin)
  if stem_err then
    notify().error(stem_err)
    return
  end

  local path, err, count = require("bindings.usrcmds.bindings_explorer.report").write({
    plugin = stem,
    repo = opts.repo,
    repo_root = opts.repo_root,
    out = opts.out,
    scope = opts.scope,
  })
  if not path then
    notify().error("Bericht nicht geschrieben: " .. (err or "unbekannter Fehler"))
    return
  end
  notify().info(("%d Befunde -> %s"):format(count or 0, path))
end

--- Dashboard: eine Seite Zahlen plus die Routenliste (`status.lua`).
---@return nil
function M.status()
  status.open()
end

--- One `search` route. The four differ only in path, category and
--- description — the argument schema (plugin scope, query, `plugin=`) is the
--- same for all, and a copy per route would be four places a later slot can
--- go missing.
---@param path string[]
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil
---@param desc string
---@return Lib.UserCmd.Composer.Route
local function search_route(path, category, desc)
  return {
    path = path,
    args = {
      { name = "plugin", type = PLUGIN_ARG, optional = true },
      { name = "query", type = "STRING", optional = true },
    },
    kv = { { key = "plugin", type = PLUGIN_ARG } },
    desc = desc,
    run = function(ctx)
      local sel, err = search_selection(ctx, category)
      if not sel then
        notify().error(err or "Argumente nicht verstanden")
        return
      end
      M.search(category, sel)
    end,
  }
end

--- One `browse` route, same pattern. Both positionals carry the same type and
--- the same `values`, because both take either the plugin scope or the corpus
--- half — so `<Tab>` offers what is allowed in each of the two positions.
---@param path string[]
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil
---@param desc string
---@return Lib.UserCmd.Composer.Route
local function browse_route(path, category, desc)
  return {
    path = path,
    args = {
      { name = "plugin", type = PLUGIN_ARG, values = SCOPE_VALUES, optional = true },
      { name = "scope", type = PLUGIN_ARG, values = SCOPE_VALUES, optional = true },
    },
    kv = { { key = "plugin", type = PLUGIN_ARG } },
    desc = desc,
    run = function(ctx)
      local sel, err = browse_selection(ctx, category)
      if not sel then
        notify().error(err or "Argumente nicht verstanden")
        return
      end
      M.browse(category, sel)
    end,
  }
end

---@return nil
function M.enable()
  -- Before `composer.verb`, so the routes below may reference the type:
  -- `argtypes.get` falls back silently to STRING for an unknown name, and the
  -- slot would then have completion without cheatsheet stems.
  composer.register_type(PLUGIN_ARG, plugin_scope.argtype())

  composer.verb("Bindings", {
    desc = "Cheatsheets in docs/NOTES/{PersonelPlugins/BINDINGS,ExternPlugins/Bindings} durchsuchen",
    default = function()
      M.search(nil, nil)
    end,
    routes = {
      search_route(
        { "search" },
        nil,
        "Live-Grep über beide BINDINGS-Bäume (Picker-Engine, sonst Prompt+Liste); ein Cheatsheet-Stamm als Argument scopt auf dessen Sheets"
      ),
      search_route(
        { "search", "keymaps" },
        "Keymaps",
        "Live-Grep, nur Keymaps-Cheatsheets; `hover.nvim` als Argument scopt auf dessen Sheet"
      ),
      search_route(
        { "search", "usercmds" },
        "Usercmds",
        "Live-Grep, nur Usercmds-Cheatsheets; `hover.nvim` als Argument scopt auf dessen Sheet"
      ),
      search_route(
        { "search", "autocmds" },
        "Autocmds",
        "Live-Grep, nur Autocmds-Cheatsheets; `hover.nvim` als Argument scopt auf dessen Sheet"
      ),
      {
        path = { "path" },
        args = {
          { name = "scope", type = "STRING", enum = { "personal", "extern" }, optional = true },
        },
        desc = "BINDINGS-Wurzel(n) in die Zwischenablage kopieren",
        run = function(ctx)
          M.path(ctx.args.scope)
        end,
      },
      browse_route(
        { "browse" },
        nil,
        "Picker über alle Tabellenzeilen (Keymaps+Usercmds+Autocmds); `personal`/`extern` oder ein Cheatsheet-Stamm scopen"
      ),
      browse_route(
        { "browse", "keymaps" },
        "Keymaps",
        "Picker über Keymaps-Tabellenzeilen; `personal`/`extern` oder ein Cheatsheet-Stamm scopen"
      ),
      browse_route(
        { "browse", "usercmds" },
        "Usercmds",
        "Picker über Usercmds-Tabellenzeilen; `personal`/`extern` oder ein Cheatsheet-Stamm scopen"
      ),
      browse_route(
        { "browse", "autocmds" },
        "Autocmds",
        "Picker über Autocmds-Tabellenzeilen; `personal`/`extern` oder ein Cheatsheet-Stamm scopen"
      ),
      {
        path = { "check" },
        args = {
          { name = "plugin", type = PLUGIN_ARG, optional = true },
          { name = "axis", type = "STRING", enum = { "repo", "extern", "all" }, optional = true },
        },
        -- `root=` as kv, not a third positional: a path and a plugin name are
        -- both free strings, and the composer binds positionals in order —
        -- `:Bindings check C:/repos` would silently bind the path as the plugin
        -- name. With the key in front the mapping is position-independent, and
        -- `<Tab>` after `root=` completes directories (`type = "DIR"`).
        kv = { { key = "root", type = "DIR" } },
        desc = "Drift-Bericht: dokumentiert-aber-nicht-live / live-aber-undokumentiert (Personal, read-only)",
        run = function(ctx)
          M.check(ctx.args.plugin, {
            repo = ctx.args.axis == "repo",
            repo_root = ctx.kv.root,
            scope = (ctx.args.axis == "extern" or ctx.args.axis == "all") and ctx.args.axis or nil,
          })
        end,
      },
      -- The same axis without a plugin argument. Needed as its own route, not
      -- a mere second positional: `:Bindings check repo` would otherwise bind
      -- "repo" as the plugin name and silently return an empty report. As a
      -- literal child of `check` the tree walk wins (see composer `tree.walk`),
      -- and `<Tab>` suggests it.
      {
        path = { "check", "repo" },
        args = { { name = "plugin", type = PLUGIN_ARG, optional = true } },
        kv = { { key = "root", type = "DIR" } },
        desc = "Drift-Bericht mit der Checkout-Achse: dokumentierte Bindings ungeladener Plugins gegen deren lokalen Quellbaum; `root=<dir>` nimmt jedes Lua-Projekt unter einem Sammelverzeichnis statt der Lazy-Spec-Auflösung",
        run = function(ctx)
          M.check(ctx.args.plugin, { repo = true, repo_root = ctx.kv.root })
        end,
      },
      -- `extern`/`all` need the same literal child route as `repo`, for the
      -- same reason: `:Bindings check extern` would otherwise bind "extern" as
      -- the plugin name and silently return an empty report.
      {
        path = { "check", "extern" },
        args = { { name = "plugin", type = PLUGIN_ARG, optional = true } },
        kv = { { key = "root", type = "DIR" } },
        desc = "Nur die fremden: live registrierte Commands ohne Cheatsheet, deren Plugin dieser Korpus nicht abdeckt",
        run = function(ctx)
          M.check(ctx.args.plugin, { repo_root = ctx.kv.root, scope = "extern" })
        end,
      },
      {
        path = { "check", "all" },
        args = { { name = "plugin", type = PLUGIN_ARG, optional = true } },
        kv = { { key = "root", type = "DIR" } },
        desc = "Eigene und fremde zusammen — das Verhalten vor der Scope-Trennung",
        run = function(ctx)
          M.check(ctx.args.plugin, { repo_root = ctx.kv.root, scope = "all" })
        end,
      },
      -- `report` mirrors `check` including the second route for `repo`, for
      -- the same reason: without a literal child, `:Bindings report repo` would
      -- bind "repo" as the plugin name. `out` is `PATH`, not `FILE` — `FILE`
      -- wants a readable file, and an output file does not exist yet by
      -- definition before the run.
      {
        path = { "report" },
        args = {
          { name = "plugin", type = PLUGIN_ARG, optional = true },
          { name = "axis", type = "STRING", enum = { "repo", "extern", "all" }, optional = true },
        },
        kv = { { key = "root", type = "DIR" }, { key = "out", type = "PATH" } },
        desc = "Drift-Bericht als Markdown-Datei; ohne `out=` nach docs/ROADMAP/personal/All/BINDINGS-DRIFT-<datum>.md",
        run = function(ctx)
          M.report(ctx.args.plugin, {
            repo = ctx.args.axis == "repo",
            repo_root = ctx.kv.root,
            out = ctx.kv.out,
            scope = (ctx.args.axis == "extern" or ctx.args.axis == "all") and ctx.args.axis or nil,
          })
        end,
      },
      -- Dieselben literalen Kinder wie bei `check`, aus demselben Grund.
      {
        path = { "report", "extern" },
        args = { { name = "plugin", type = PLUGIN_ARG, optional = true } },
        kv = { { key = "root", type = "DIR" }, { key = "out", type = "PATH" } },
        desc = "Nur die fremden, als Markdown-Datei",
        run = function(ctx)
          M.report(ctx.args.plugin, { repo_root = ctx.kv.root, out = ctx.kv.out, scope = "extern" })
        end,
      },
      {
        path = { "report", "all" },
        args = { { name = "plugin", type = PLUGIN_ARG, optional = true } },
        kv = { { key = "root", type = "DIR" }, { key = "out", type = "PATH" } },
        desc = "Eigene und fremde zusammen, als Markdown-Datei",
        run = function(ctx)
          M.report(ctx.args.plugin, { repo_root = ctx.kv.root, out = ctx.kv.out, scope = "all" })
        end,
      },
      {
        path = { "report", "repo" },
        args = { { name = "plugin", type = PLUGIN_ARG, optional = true } },
        kv = { { key = "root", type = "DIR" }, { key = "out", type = "PATH" } },
        desc = "Drift-Bericht mit der Checkout-Achse, als Markdown-Datei",
        run = function(ctx)
          M.report(ctx.args.plugin, { repo = true, repo_root = ctx.kv.root, out = ctx.kv.out })
        end,
      },
      {
        path = { "status" },
        desc = "Dashboard: Korpus-, Live- und Plugin-Zahlen plus die Routenliste",
        run = function()
          M.status()
        end,
      },
    },
  })
end

return M
