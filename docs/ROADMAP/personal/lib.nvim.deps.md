I'll look at the roadmap doc and check what's actually implemented in the lib.

`lua/lib/nvim/deps/` exists — let me look at both it and the roadmap doc.

## Kurzantwort

Der Punkt ist **umgesetzt** — und zwar vollständiger, als die Notiz vermuten lässt. Du findest nichts dazu, weil **das Roadmap-Dokument selbst nicht mehr existiert**: Commit `85674ec` („docs: move the roadmap documents out of the repository") hat `docs/ROADMAP/` aus dem Repo entfernt, und `dependency-installer.md` ist auch nicht in `AppData/Local/nvim/docs/ROADMAP/personal/` gelandet — der Ordner `lib_nvim.nvim/` existiert dort nicht mehr. Die Datei lebt nur noch in der History:

```bash
git show 85674ec^:docs/ROADMAP/dependency-installer.md
```

Der Code ist da: [lua/lib/nvim/deps/](./lua/lib/nvim/deps/), 1813 Zeilen in 8 Submodulen, plus 11 konsumierende Plugins.

---

## Die 4 offenen Punkte — Status heute

| Punkt (aus dem Doc) | Status jetzt |
|---|---|
| **Phasing 5:** „no plugin ships a spec yet" | **erledigt.** 11 Plugins mit `docs/install.json`: filetree, gopath, images, insights, language, mdview, migrate, pdfport, pickers, replacer, runtime-analysis |
| **Still worth doing:** `deps.health`-Migrationen in Plugins, die noch `check_exe` handrollen | **erledigt.** Alle 11 `health.lua` rufen `deps.health.report_for(...)`; die verbliebenen `executable()`-Treffer sind Kapabilitäts-Checks, keine Tool-Listen |
| **Still worth doing:** Windows-Elevation ungetestet (`choco` will elevated shell, `winget` eigenen UAC-Prompt) | **weiterhin offen** — nur durchdacht, nie auf einer Maschine ausprobiert, die wirklich Elevation braucht |
| **Phasing 6:** `documentation.nvim` Deps-Tab | **weiterhin offen** — Fremdrepo, hängt an einem stabilen Spec-Schema (das jetzt existiert) |

Dazu bewusst *nicht* gebaut: pro-Plugin `setup({ deps_popup = false })` — der `vim.g`-Toggle deckt es ab, ein zweiter Knopf pro Plugin wäre Redundanz. Die „Open questions" 1–5 sind alle beantwortet und im Doc durchgestrichen.

Also real offen: **Windows-Elevation** und der **documentation.nvim-Tab**. Beides nichts, was in lib.nvim noch fehlt.

---

## Wie der Checker genau funktioniert

**Deklaration (im jeweiligen Plugin, nicht in lib.nvim):** `docs/install.json` oder `docs/INSTALL.md` mit einem Eintrag pro Tool — `bin`, `why` (Pflicht, nicht-leer, sonst Validierungsfehler), `pkg`-Map pro Paketmanager, optional `required` / `bin_alternatives` / `see`.

**Auflösung:** `spec.find(name)` sucht erst `runtimepath` (managerunabhängig), dann per `pcall` lazy.nvims Registry — nötig, weil lazy ein Plugin erst beim Laden auf den rtp legt (gemessen: 120 konfiguriert, 44 geladen, 76 pending).

**Prüfung:** `deps.detect` fragt „ist es da", über alle Schreibweisen; `deps.pm` erkennt den Paketmanager und komponiert das Kommando; `deps.install.plan()` ist rein und teilt `missing` in `installable` / `unsupported`.

**Drei Einstiegspunkte, alle opt-in:**

1. `:Lib deps show|install <plugin>` — Popup mit `i` (ein Tool), `I` (alles fehlende), `<CR>` (Output auf-/zuklappen). Ohne Root installiert es inline und streamt; mit Root übergibt es an ein echtes Terminal mit vorgetipptem, **nicht abgeschicktem** Kommando.
2. `deps.health.report_for("plugin.nvim")` — eine Zeile in `health.lua`.
3. `require("lib.nvim.deps").show_once("plugin.nvim")` — im `setup()` des Plugins.

---

## Deine beiden Ziele

**„Neues Plugin installiert → wird gecheckt, ob CLI-Tools fehlen, und vorgeschlagen"** — **erfüllt, über `show_once`.** Beim ersten `setup()` nach der Installation kommt das Popup mit Tools + `why` + Install-Keymaps; „gesehen" liegt persistent in `cache.disk`, überlebt Neustarts. Abschaltbar über `vim.g.lib_nvim_deps_disable_first_run` bzw. `vim.g.lib_nvim_deps_disabled_plugins`.

Die Einschränkung: Trigger ist das `setup()` des Plugins, **nicht** ein lazy.nvim-Install-Hook. Ein Plugin, das die Zeile nicht hat, bleibt stumm — bewusst so, weil `require` in diesem Modul nie den Editor anfassen darf. Deine 11 eigenen Plugins haben die Zeile alle.

**„Scope cwd/path/pluginname"** — **das ist die echte Lücke.** Heute geht nur der Plugin-Name:

- `:Lib deps show <plugin>` — Name, aufgelöst über rtp/lazy
- `:Lib deps show` ohne Argument — listet nur *welche* Plugins eine Spec haben, **kein Sammelreport** über deren Tool-Status
- kein cwd-Scope („das Plugin, an dem ich gerade arbeite")
- kein Pfad-Scope — obwohl `spec.load(path)` das intern längst kann; es fehlt nur die Route, `M.show`/`resolve` gehen ausschließlich über `spec.find(name)`

Das wäre die naheliegendste offene Arbeit: `resolve()` so erweitern, dass ein Argument, das wie ein Pfad aussieht, direkt geladen wird, ein leeres Argument den cwd probiert, und `:Lib deps show` ohne Argument einen aggregierten Report über alle Plugins mit Spec rendert statt einer Namensliste. Sag Bescheid, wenn ich das bauen soll.
