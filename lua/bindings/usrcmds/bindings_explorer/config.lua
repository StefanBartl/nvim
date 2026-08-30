---@module 'bindings.usrcmds.bindings_explorer.config'
--- Wo die BINDINGS-Cheatsheets liegen — und, für `drift.lua`s Repo-Achse,
--- wo die lokalen Plugin-Checkouts liegen. Konzept: docs/ROADMAP/personal/
--- bindings-explorer.nvim.md.

local M = {}

--- Beide BINDINGS-Wurzeln, absolut.
---@return string[]
function M.roots()
  local cfg = vim.fn.stdpath("config")
  return {
    vim.fs.joinpath(cfg, "docs", "NOTES", "PersonelPlugins", "BINDINGS"),
    vim.fs.joinpath(cfg, "docs", "NOTES", "ExternPlugins", "Bindings"),
  }
end

--- Beide Wurzeln, aber nur die `folder`-Unterkategorie (`"Keymaps"`|
--- `"Usercmds"`|`"Autocmds"`) — beide Bäume verwenden dieselben drei
--- Ordnernamen, siehe `M.roots()`.
---@param folder "Keymaps"|"Usercmds"|"Autocmds"
---@return string[]
function M.roots_for(folder)
  local out = {}
  for _, root in ipairs(M.roots()) do
    out[#out + 1] = vim.fs.joinpath(root, folder)
  end
  return out
end

--- Der Lua-Baum dieser Config selbst. `drift.lua`s Repo-Achse nimmt ihn als
--- zweite Suchstelle: ein dokumentiertes Binding eines Personal-Plugins wird
--- oft nicht vom Plugin registriert, sondern hier (lazy `keys`-Spec,
--- `bindings/mappings/*`) — ohne diese Stelle wäre genau das ein
--- systematischer Falschbefund der Achse.
---@return string
function M.config_lua_root()
  return vim.fs.joinpath(vim.fn.stdpath("config"), "lua")
end

---@class Bindings.RepoDir
---@field name string Cheatsheet-Stamm, also `records.lua`s `plugin`-Feld, z.B. "images.nvim".
---@field dir string Absoluter Pfad des lokalen Checkouts.

---@alias Bindings.RepoResolver fun(): Bindings.RepoDir[]|nil, string|nil

--- Default-Auflösung: `plugins.personal.export` liefert bereits genau
--- `{ name, repo, dir }` je aktiviertem Personal-Plugin mit lokalem
--- Checkout, abgeleitet aus dem echten Lazy-Spec statt aus einer
--- handgepflegten Liste (siehe `plugins/personal/list.lua`s Moduldoc dazu,
--- warum die Markdown-Liste als Quelle aufgegeben wurde).
---
--- `nil` + Grund statt einer leeren Liste, wenn die Auflösung selbst nicht
--- möglich war — dieselbe Haltung wie `source.lua`: „nichts gefunden" und
--- „konnte nicht nachsehen" sind verschiedene Aussagen, und ein Report, dem
--- still eine Achse fehlt, liest sich sonst wie einer, in dem sie nichts
--- gefunden hat.
---@type Bindings.RepoResolver
local function default_repo_dirs()
  local ok, export = pcall(require, "plugins.personal.export")
  if not ok then
    return nil, "plugins.personal.export not loadable: " .. tostring(export)
  end

  local projects, err = export.projects()
  if err then
    return nil, err
  end
  if not projects or #projects == 0 then
    return nil, "no enabled personal plugin has a local checkout on this machine"
  end

  local out = {}
  for _, p in ipairs(projects) do
    out[#out + 1] = { name = p.name, dir = p.dir }
  end
  return out, nil
end

---@type Bindings.RepoResolver|nil
local repo_resolver = nil

--- Die Auflösung austauschen (Tests gegen ein Fixture-Repo; ein künftiger
--- Umzug dieses Moduls in ein eigenes Repo, wo `plugins.personal` nicht
--- existiert). `nil` stellt die Default-Auflösung wieder her.
---@param fn Bindings.RepoResolver|nil
---@return nil
function M.set_repo_dirs(fn)
  repo_resolver = fn
end

--- Jedes Plugin mit lokalem Checkout, das `drift.lua`s Repo-Achse
--- durchsuchen kann.
---@return Bindings.RepoDir[]|nil
---@return string|nil reason Warum die Achse nicht befragt werden konnte.
function M.repo_dirs()
  return (repo_resolver or default_repo_dirs)()
end

--- Verzeichnisnamen, die unter einer Sammelwurzel nie ein Projekt sind.
--- Kein Vollständigkeitsanspruch: die Lua-Prüfung unten sortiert das meiste
--- schon aus, das hier spart nur das Scandir bei den häufigen Fällen.
local SKIP_DIRS = { [".git"] = true, node_modules = true, target = true }

--- Ob `dir` wie ein Lua-Projekt aussieht: ein `lua/`-Unterverzeichnis oder
--- mindestens eine `.lua`-Datei obenauf.
---
--- Bewusst nicht `.git` als Kriterium — die Repo-Achse liest Quelltext, nicht
--- Git-Historie, und ein Checkout ohne eigenes `.git` (Submodul, entpacktes
--- Release, Worktree-Kopie) ist genauso greppbar. Umgekehrt wäre ein
--- Git-Repo ohne eine Zeile Lua für diese Achse wertlos.
---@param dir string
---@return boolean
local function looks_like_lua_project(dir)
  if vim.fn.isdirectory(vim.fs.joinpath(dir, "lua")) == 1 then
    return true
  end
  for name, type_ in vim.fs.dir(dir) do
    if type_ == "file" and name:match("%.lua$") then
      return true
    end
  end
  return false
end

--- Jedes Lua-Projekt direkt unter `root`, als `Bindings.RepoDir`-Liste.
---
--- Für den Fall, dass die Checkouts nicht über den Lazy-Spec auffindbar sind,
--- sondern schlicht nebeneinander in einem Sammelverzeichnis liegen
--- (`C:/repos`) — dann ist der Pfad die Auflösung, und die Achse deckt jedes
--- Projekt darunter ab statt nur die als Plugin aktivierten. Der
--- Verzeichnisname IST der `name`, weil `records.lua`s `plugin`-Feld der
--- Cheatsheet-Dateistamm ist und dieser Korpus die Cheatsheets nach den
--- Repos benennt; ein Verzeichnis ohne gleichnamiges Cheatsheet fällt in
--- `drift.lua`s Bericht als undokumentiert auf, statt still zu verschwinden.
---
--- Nur eine Ebene tief. Ein rekursiver Abstieg fände in jedem Checkout dessen
--- eigene Unterverzeichnisse mit `lua/` wieder und meldete `lua`, `tests`,
--- `spec` als eigene „Repos".
---
--- `nil` + Grund statt einer leeren Liste, wenn nicht nachgesehen werden
--- konnte — dieselbe Unterscheidung wie `default_repo_dirs` und `repo.lua`s
--- `M.mentions`: „nichts gefunden" und „konnte nicht nachsehen" sind
--- verschiedene Aussagen.
---@param root string Sammelverzeichnis, absolut oder `~`/`$VAR`-expandiert.
---@return Bindings.RepoDir[]|nil
---@return string|nil reason
function M.repo_dirs_under(root)
  if type(root) ~= "string" or root == "" then
    return nil, "no repo root given"
  end
  -- `:p` hängt einen Trenner an, `normalize` macht aus Windows-Backslashes
  -- Slashes -- danach reicht ein Muster ohne Escape-Sonderfall.
  local abs = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(root), ":p")):gsub("/$", "")
  if vim.fn.isdirectory(abs) ~= 1 then
    return nil, ("repo root is not a directory: %s"):format(abs)
  end

  local out = {}
  for name, type_ in vim.fs.dir(abs) do
    local dir = vim.fs.joinpath(abs, name)
    local is_dir = type_ == "directory" or (type_ == "link" and vim.fn.isdirectory(dir) == 1)
    if is_dir and not SKIP_DIRS[name] and name:sub(1, 1) ~= "." then
      if looks_like_lua_project(dir) then
        out[#out + 1] = { name = name, dir = dir }
      end
    end
  end

  if #out == 0 then
    return nil, ("no Lua project directly under %s"):format(abs)
  end
  table.sort(out, function(a, b)
    return a.name < b.name
  end)
  return out, nil
end

return M
