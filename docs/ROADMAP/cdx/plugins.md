# Refactoring: NVIM Custom Moduls

## Table of content

  - [`usrcmds/reload` → **debugging.nvim**](#usrcmdsreload-debuggingnvim)
  - [`usrcmds/compress_dir` → **project-insight.nvim**](#usrcmdscompress_dir-project-insightnvim)
  - [`custom.open` → **Neues Plugin**](#customopen-neues-plugin)
  - [`custom.format`](#customformat)
  - [`/custom/linemarker`](#customlinemarker)
  - [`/custom/mynotes`](#custommynotes)

---

## `usrcmds/reload` → **debugging.nvim**

**Begründung:**
`ReloadCurrentModule` ist ein typisches Neovim-Entwicklungs-/Debugging-Werkzeug. Man benutzt es, wenn man an Plugins oder der eigenen Config arbeitet und schnell iterieren will. `debugging.nvim` hat bereits genau diese Zielgruppe: `:Debug inspect`, `:Debug dump`, `:Debug cursor state` — alles für den Entwickler, der Neovim selbst untersucht und debuggt.

Ein `:Debug reload` (oder `:Debug module reload`) würde sich nahtlos einreihen. Die bestehende `usercmds/`-Schicht in debugging.nvim (`reports.lua`, `neotree_safety.lua`) zeigt, dass das Plugin User-Commands als Leaf-Module organisiert — das Reload-Modul passt strukturell genau da rein.

**Einzige Anpassung:** Der direkte `require("lib.nvim.notify")` bleibt kompatibel, da debugging.nvim lib.nvim sowieso als Dependency hat.

---

## `usrcmds/compress_dir` → **project-insight.nvim**

**Begründung:**
project-insight.nvim hat bereits eine "Projekt-Snapshot"-Ebene: `:ProjectInsight tree` (Dateiliste schreiben), `:ProjectInsight count`, `:ProjectInsight clipboard`. `compress_dir` macht im Grunde dasselbe auf der nächsten Ebene — es erzeugt ein Archiv und eine Dateiliste des aktuellen Projekts. Ein `:ProjectInsight archive` oder `:ProjectInsight compress` würde den "Ich will einen Snapshot meines Projekts" Workflow vervollständigen.

**Einschränkung (wichtig):** `compress_dir` verwendet Shell-Kommandos (`sh -c`, `find`, `tar`) und ist damit **Unix-only**. project-insight.nvim wirbt mit "Linux | macOS | Windows"-Support. Das würde eine Cross-Platform-Lücke aufreißen. Entweder müsste `compress_dir` vor dem Eingliedern mit einem Windows-Fallback (PowerShell `Compress-Archive`) aufgerüstet werden, oder es wird als explizit opt-in/Unix-only markiert.

---

## `custom.open` → **Neues Plugin**

Das Modul ist bereits eine vollständige, eigenständige Architektur:

- Eigene `registry.lua`, `context.lua`, `platform.lua`, `util.lua`, `@types/`
- Handler-System mit Plugin-artiger Erweiterbarkeit (`register_all`)
- Vier Handler-Kategorien: filemanager, browser (6 Browser), notepad, nvim_internal
- Kontext-Erkennung: Tree-Buffer, URL vs. Pfad, cfile/cword/buffer_path
- Vollständiges Cross-Platform (Windows, WSL, macOS, Linux)

**Keiner der bestehenden Repos passt:** `fileops.nvim` arbeitet auf Dateisystem-Ebene (CRUD via libuv), `custom.open` ist ein **Launcher für externe Anwendungen** — semantisch und architektonisch anderes Terrain. Die anderen Repos haben noch weniger Bezug.

**Empfehlung:** Neues Plugin, z.B. `xopen.nvim` oder `opener.nvim`. Das Modul ist bereits "release-ready" — es braucht nur die Umbenennung der require-Pfade.

---

## `custom.format`

Das Modul hat zwei klar trennbare Teile:

### `custom.format.markdown` → **`markdown.nvim`**

`custom.format.markdown` implementiert `headline_separators` (sorgt für `[blank]---[blank]` zwischen H2+-Sections). `markdown.nvim` hat bereits das Feature **`headline_spacing`** mit identischer Beschreibung. Das ist dieselbe Funktionalität — die Logik gehört direkt dort rein, entweder als Merge oder als Alias.

### Der Rest → `buffer-ctx.nvim`

Die verbleibenden Subcommands (column, table, textwidth, filter, clear, enum, trim, sort, unique, case, indent) sind **generische Buffer-/Text-Operationen**. Zu den bestehenden usrcmds `:Copy` und `:Insert` kommt ein neues `:Format` dazu.

---

## `/custom/linemarker`

Gehört meiner Meinung nach nach `/wkdoptions/ui`.

---

## `/custom/mynotes`

**Die Mechanik ist identisch.** pickers.nvim hat bereits genau dasselbe Pattern für zwei Scopes:

- `repos` → `repos_dir` config → `:Pickers repos files/grep` → Compat-Commands `RepoFiles`, `RepoGrep`
- `wkdbooks` → `wkdbooks_dir` config → `:Pickers wkdbooks files/grep` → Compat-Commands `WkdBookFiles`, `WkdBookGrep`

`mynotes.register.register()` tut exakt dasselbe, nur manuell und für beliebig viele benannte Verzeichnisse. Die drei Dateien `core.lua`, `register.lua` und die `specs/` sind im Grunde **die generische Version** von dem, was pickers.nvim für repos und wkdbooks bereits fest verdrahtet hat.

**Wie die Integration aussehen könnte:**

```lua
require("pickers").setup({
  collections = {
    { name = "notes",      dir = vim.env.REPOS_DIR .. "/Notes",      keys = { files = "<leader>mnf", grep = "<leader>mng" } },
    { name = "notes_lua",  dir = vim.env.REPOS_DIR .. "/Notes/Lua",  keys = { files = "<leader>mlf", grep = "<leader>mlg" } },
    { name = "checklists", dir = vim.env.REPOS_DIR .. "/Checklists" },
    -- ...
  },
})
```

pickers.nvim generiert daraus automatisch `:Pickers notes files/grep` als neue Scopes plus Compat-Commands `NotesFiles`, `NotesGrep` — genau wie heute, nur ohne den spec-Code.

**Ein echter Mehrwert entsteht zusätzlich:** Die aktuellen `wkdbooks`- und `repos`-Scopes könnten intern dasselbe `collections`-System nutzen — sie wären dann nur built-in Collections mit Sonderlogik (wkdbook-Prefix-Filterung). Die Architektur wird einheitlicher statt doppelt.

**Der einzige Unterschied** zwischen heute und nach der Integration ist UI-seitig: heute sind es isolierte Top-Level-Commands, danach gehen sie durch `:Pickers`. Aber weil pickers.nvim das Compat-Command-System hat, bleibt `NotesFiles` etc. trotzdem direkt aufrufbar.

**Fazit:** Integrieren macht Sinn. Die `register.lua` + `core.lua` lösen sich auf, `specs/*.lua` werden zu Config-Einträgen in deinem pickers.nvim-Setup.

Es muss nur sichergestelt werden, dass alle in mynotes und pickers registrieren pickers danach auch registriert sind. Dass ich danach nicht zb `:NvimNotes` sondern `:Pickers notes file/grep` gefält mir gut. Jedenfalls soll es eine `CHEATSHEET.md` mit allen usrcmds geben sowie eine README.m d auif deutsch, der den unterschied zwischen dem fest verdrahtenten und normalen  specs macht. Außerdem: Idealerweiße würde das mit wkdbooks so gestalltet sein, dasss man das gleiche auch mit anderen projekordnern machen kan, also dass der root Ordner genommen wird und dann alle Ordner darin die ein bestimmtes präfix haben, aufgelistet werden für grep/files, Das sollte einfach machbar sein auch mit anderen ordnern, und die WLKDBooks implemntierung ist daann sozusagen "userconfig", denn wenn andere Developer das Plugin nutzen wollen, wollen sie eventuell das gleiche Feature nutzen, aber nicht mit `wkdbooks-` als Präfix.

---
