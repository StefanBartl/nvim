# gitsuite.nvim: Multi-Repo-Dashboard aus reposcope.nvim übernehmen, `:MyPlugins` teilkonsolidieren

Konzept & Implementierungsplan zum Auftrag: `:Reposcope dashboard` (reposcope.nvim)
und die dazu passenden Teile von `:MyPlugins` (nvim-config) nach gitsuite.nvim
verschieben; Doku beidseitig nachziehen; weitere Features aufnehmen, die dabei
mit anfallen.

Reine Recherche + Planung, kein Code — gleiches Format wie
[`gitsuite.nvim-eigene-engine-lazygit-neogit-ersatz.md`](gitsuite.nvim-eigene-engine-lazygit-neogit-ersatz.md).
Repo-Pfade: `$REPOS_DIR/{reposcope,gitsuite,lib}.nvim` und `stdpath('config')`
für die nvim-Config, sofern nicht anders angegeben.

---

## 1. Ist-Zustand

### 1.1 `:Reposcope dashboard` / `:Reposcope update` — was heute dort liegt

Reines Multi-Repo-Git-Werkzeug, entstanden bevor es gitsuite.nvim gab:

| Datei | Rolle |
| --- | --- |
| `lua/reposcope/utils/repos.lua` | Verzeichnis-Scan: `resolve_base_dir` (Override > `config.options.clone.std_dir`), `collect_repos`, `is_git_repo` |
| `lua/reposcope/utils/repo_dashboard.lua` | Liest `git status --porcelain=v2 --branch` + `git log -1` für jedes gefundene Repo, parallelisiert (`MAX_PARALLEL = 8`), inkl. `dashboard.extra_paths` |
| `lua/reposcope/utils/repo_actions.lua` | Einzel-Repo `push`/`pull --ff-only`/`fetch --prune`/`update` — eigener `vim.system`-Aufruf, **nicht** über `lib.nvim.git` |
| `lua/reposcope/utils/repo_updater.lua` | Headless Verzeichnis-weites fetch+pull (`:Reposcope update`) |
| `lua/reposcope/ui/actions/dashboard_view.lua` | Popup/Buffer/Split-Ansicht über `ui.kit` (→ hartes `ui.nvim`-Dependency), Zeilen-/Mark-/Bulk-Aktionen `p`/`P`/`f`/`gp`/`gP`/`gf`/`gu` |
| `lua/reposcope/bindings/usrcmds.lua` | Routen `dashboard [dir] [--out] [--to]` und `update [dir]` |
| `config/DEFAULTS.lua` | `dashboard.extra_paths`, `clone.std_dir` (Scan-Basis) |
| `TESTS/dashboard_view_spec.lua`, `TESTS/repos_util_spec.lua` | Testabdeckung |

Dazu Docs an ca. 15 Stellen (siehe [§7](#7-doku-die-mitgezogen-werden-muss)).

**Abhängigkeit:** `dashboard_view.lua:58` zieht `require("ui.kit")` — reposcope
hängt dafür schon hart an `ui.nvim` (auch für Prompt/Filter/Favorites), das
ändert sich durch den Umzug nicht für reposcope, aber es ist die Abhängigkeit,
die mit dem Feature nach gitsuite mitwandert (s. [§3.3](#33-neue-abhängigkeit-gitsuite--uinvim)).

### 1.2 `:MyPlugins` (nvim-config) — was davon generisch ist und was nicht

`lua/bindings/usrcmds/plugin_repos/{init,ops,picker,confirm}.lua`, Befehle
`clone|remove|fetch|pull|update|reclone|dashboard|mode|list|picker`.

- **Config-spezifisch, bleibt in nvim-config:** `clone`/`remove`/`reclone`/`list`/
  `mode`/`picker` — alle hängen an `plugins.personal.list` (die konkrete
  Plugin-Liste dieser Config) bzw. `source.lua`s `OVERRIDE`-Switch
  (dir/remote/auto/disabled-Ladeverhalten). Das ist Config-Architektur, kein
  wiederverwendbares Git-Feature — nichts davon sollte nach gitsuite wandern.
- **Bereits reine Delegation:** `dashboard` ruft nur `:Reposcope dashboard`
  (`open_dashboard()`, `plugin_repos/init.lua:525`) — nach dem Umzug zeigt das
  einfach auf `:Git dashboard` statt `:Reposcope dashboard`. Kein Datenverlust,
  eine Zeile geändert plus die `--fetch`/`--fetch-this`-Vorstufe, die weiterhin
  `:MyPlugins fetch` (config-eigen) aufruft.
- **Duplizierte Git-Primitive:** `ops.lua`s `fetch_one`/`pull_one`/`update_one`
  sind inhaltlich **dieselben** drei Befehle wie `reposcope.utils.repo_actions`
  (`git fetch --all --prune`, `git pull --ff-only`) — nur nochmal eigenständig
  gegen `vim.system` geschrieben, dritte Kopie neben reposcope und dem, was
  gitsuite gleich bekommt. Das ist der Teil von `:MyPlugins`, der nicht
  *umzieht*, aber von der Konsolidierung **profitiert** (s. [§4](#4-zusätzliches-feature-schreibende-git-primitive-in-libnvimgit)).

### 1.3 gitsuite.nvim heute

Laut [`ROADMAP/IMPLEMENTATION-PLAN.md`](../../../../../../E/repos/WKDBooks/Development/wkdbook-myplugins/gitsuite.nvim/ROADMAP/IMPLEMENTATION-PLAN.md)
(Stand 2026-09-22): Wellen 0–5 komplett (`GS-00`…`GS-28`), nur `GS-30`
(manuelle Verifikation) offen. Acht `:Git`-Familien (`conflict`, `hunk`,
`blame`, `diff`, `branch`, `browse`, `ui`, `status`) — **alle Single-Repo**.

Explizite bestehende Abgrenzung, die dieser Auftrag aufhebt (Plan, Abschnitt
„Bewusst geparkt oder verworfen"):

> Nicht gebaut, weil sie das Konzept ausdrücklich ausschließt (Schicht 3):
> gitsigns' Hunk-Engine, neogits Staging-UI; **gitsuite ist ein Repo,
> reposcope ist viele — die Grenze bleibt.**

Diese Zeile muss beim Umsetzen korrigiert werden (s. [§7](#7-doku-die-mitgezogen-werden-muss)) —
sie beschreibt eine Entscheidung, die mit diesem Konzept bewusst revidiert
wird, nicht mehr den Ist-Zustand.

`lib.nvim.git` hat wie im Engine-Report (§1.3 dort) bereits festgehalten nur
**eine** schreibende Funktion (`checkout`). Push/Pull/Fetch existieren dort
nicht — jeder der drei Orte (reposcope, `:MyPlugins`, künftig gitsuite) müsste
sie sonst ein drittes/viertes Mal selbst schreiben.

---

## 2. Zielbild

```
reposcope.nvim   -- bleibt: Suche/Filter/Provider(GitHub,GitLab,Codeberg)/
                    Clone-aus-Suchergebnis/Favorites/Queries/Sessions/Hover.
                    Verliert: dashboard, update, repo_actions, repo_updater,
                    repos.lua, dashboard.extra_paths, clone.std_dir bleibt
                    (wird weiter für den Clone-aus-Suche-Workflow gebraucht).

gitsuite.nvim    -- bekommt: :Git dashboard [dir] [--out] [--to] als neue
                    Familie, Single- UND Multi-Repo (der einzige Bruch mit
                    "ein Repo" -- s. §3), Config dashboard.base_dir/extra_paths,
                    neue Dependency auf ui.nvim (ui.kit).

lib.nvim.git     -- bekommt: push/pull/fetch/update als schreibende Primitive
                    (heute nur checkout) -- gemeinsames Fundament für
                    gitsuite.dashboard UND :MyPlugins/ops.lua.

nvim-config      -- :MyPlugins dashboard zeigt neu auf :Git dashboard statt
                    :Reposcope dashboard. clone/remove/reclone/list/mode/
                    picker bleiben unverändert (config-spezifisch). ops.lua
                    optional auf lib.nvim.git umgestellt (Duplikation weg).
```

reposcope bleibt danach exakt das, was sein Name sagt — Repos *scopen*
(finden/filtern/anschauen), nicht *pflegen*. Pflege (Status, Push, Pull,
Fetch, egal ob ein Repo oder ein ganzer Ordner) ist gitsuite.nvim.

---

## 3. Architektur-Einordnung

### 3.1 Warum jetzt, warum dorthin

Als reposcope.nvims Dashboard gebaut wurde, gab es gitsuite.nvim nicht —
Multi-Repo-Git-Status war die einzige verfügbare Git-UI im Ökosystem und
landete deshalb im nächstbesten Plugin. Jetzt gibt es eine Git-Domäne mit
eigenem Namen, eigenem Adapter-Muster und eigenem `:Git`-Dispatch-Nadelöhr;
ein Multi-Repo-Status- und Aktions-Panel ist inhaltlich Git-Tooling, nicht
Repo-*Discovery*. Der Umzug behebt eine Fehlplatzierung, keine Design-Änderung
an reposcope selbst — reposcopes übrige acht Bereiche (Suche, Filter, Provider,
Cache, Favorites, Queries, Sessions, Hover) bleiben unberührt.

### 3.2 Der einzige echte Bruch: "gitsuite ist ein Repo"

Der bisherige Plan begründet die Adapter-vs-Eigenbau-Aufteilung *und* die
Multi-Repo-Abgrenzung mit derselben Prämisse: gitsuite arbeitet auf **dem
aktuellen Buffer/Repo**. `:Git dashboard` durchbricht das bewusst — es braucht
einen `dir`-Parameter und scannt Subverzeichnisse, wie `reposcope.utils.repos`
es heute tut. Das ist kein Widerspruch, wenn man ihn explizit macht: gitsuite
bekommt eine **einzige** Multi-Repo-Familie (`dashboard`) neben sieben
Single-Repo-Familien, mit klar benanntem Scope-Sprung in der Doku (s.
`docs/scope.md`-Eintrag unten) statt eines stillschweigenden Bruchs.

### 3.3 Neue Abhängigkeit: gitsuite → ui.nvim

`dashboard_view.lua` hängt an `ui.kit` (Popup, scrollbare Ansicht,
Confirm-Dialog). gitsuite hat bisher **keine** ui.nvim-Abhängigkeit (nur
`lib.nvim` hart, `diff.nvim` hart) und baut Floats bisher pur mit
`nvim_open_win`. Zwei Optionen:

1. **`ui.kit` übernehmen** (empfohlen): Code wandert weitgehend unverändert,
   kein Neubau der Popup-/Confirm-Maschinerie. Kosten: gitsuite bekommt eine
   neue harte Dependency auf `ui.nvim`.
2. **Eigenbau**, konsistent mit gitsuites bisherigem "kein UI-Toolkit"-Stil
   (`features/ui/lazygit/init.lua` als reines `nvim_open_win`-Beispiel).
   Kosten: die Popup-/Scroll-/Confirm-Logik aus `ui.kit` müsste neu entstehen.

Kollisionscheck gegen K-5 (Plan, „Korrekturen und Befunde"): `ui.nvim` ↔
gitsuite ist heute **beidseitig weich** (`GS-09`: gitsuite → `ui.contextmenu`
via `lib.nvim.contextmenu`-Kopie, nicht `ui.nvim` selbst; `GS-15`: `ui.nvim` →
`gitsuite.branch` nur via `pcall`). Eine **harte** Kante gitsuite → `ui.nvim`
für `ui.kit` erzeugt keinen Zyklus, solange `ui.nvim` nicht zurück auf
gitsuite hart zeigt (tut es laut `GS-15` nicht) — architektonisch sauber,
aber eine neue Art Kante, die es bisher nicht gab und explizit entschieden
werden sollte (s. [§6, Entscheidung E-2](#6-offene-entscheidungen)).

### 3.4 Wohin die Dateien wandern (Modul-Ebene)

| Reposcope heute | gitsuite künftig (Vorschlag) |
| --- | --- |
| `utils/repos.lua` | `features/dashboard/repos.lua` (oder direkt in `lib.nvim`, falls E-1 das so entscheidet) |
| `utils/repo_dashboard.lua` | `features/dashboard/status.lua` |
| `utils/repo_actions.lua` | entfällt — ersetzt durch `lib.nvim.git.push/pull/fetch` (s. [§4](#4-zusätzliches-feature-schreibende-git-primitive-in-libnvimgit)) |
| `utils/repo_updater.lua` | `features/dashboard/bulk.lua` (nutzt dieselben `lib.nvim.git`-Primitive) |
| `ui/actions/dashboard_view.lua` | `features/dashboard/view.lua` |
| `bindings/usrcmds.lua` (Routen `dashboard`, `update`) | neue Routen `{ "dashboard" }` (Status/UI) und `{ "dashboard", "update" }` (headless Bulk) im bestehenden `build_routes()` von `gitsuite/bindings/usrcmds.lua` |
| `config/DEFAULTS.lua` (`dashboard.extra_paths`) | `gitsuite/config/DEFAULTS.lua`: `dashboard = { base_dir = "", extra_paths = {} }` |

Command-Namensgebung folgt gitsuites bestehendem `<Verb> <Scope> <Aktion>`-Muster
(`:Git status repo`, `:Git branch list`) — Vorschlag: `:Git dashboard [dir]`
als Scope-loser Sonderfall (wie `:Git dashboard` selbst schon der Verb+Scope
ohne dritte Ebene ist), `:Git dashboard update [dir]` für den bisherigen
headless `:Reposcope update`.

---

## 4. Zusätzliches Feature: schreibende Git-Primitive in `lib.nvim.git`

Passt direkt in den Umzug, weil sonst eine **dritte** Kopie derselben drei
Befehle entstünde (gitsuite bräuchte push/pull/fetch für die
Dashboard-Aktionen — reposcope hat sie in `repo_actions.lua`, `:MyPlugins` in
`ops.lua`, jeweils eigenständig gegen `vim.system`). Das ist exakt die K-5-Regel
aus dem gitsuite-Plan („eine Abhängigkeit, die ≥ 2 Plugins teilen, gehört nach
`lib.nvim`") und war bereits im Engine-Report als Idee notiert (dort als
Phasenvorschlag „GS-30: `lib.nvim.git`: schreibende Primitive" — nie mit dieser
Nummer umgesetzt, siehe unten zur Nummerierung).

**Vorschlag für `lib.nvim.git`:**

| Funktion | Deckt ab | Ersetzt |
| --- | --- | --- |
| `push(opts, git_cmd)` | `git push` | `reposcope.repo_actions.push`, künftiges gitsuite-Dashboard |
| `pull(opts, git_cmd)` (ff-only) | `git pull --ff-only` | `repo_actions.pull`, `ops.pull_one`, gitsuite |
| `fetch(opts, git_cmd)` | `git fetch --all --prune` | `repo_actions.fetch`, `ops.fetch_one`, gitsuite |
| `update(opts, git_cmd)` | fetch dann ff-only pull | `repo_actions.update`, `ops.update_one`, `repo_updater.lua`, gitsuite |

Signatur nach bestehendem `lib.nvim.git`-Muster (`opts.dir`, `git_cmd`-Override,
argv-basiert über `lib.nvim.cross.run_argv`, sync **und** async-Variante wie
`status_porcelain`/`status_porcelain_async`). `:MyPlugins`s `ops.lua` auf diese
Primitive umzustellen ist optional (s. [§6, E-4](#6-offene-entscheidungen)) —
schon allein für gitsuite lohnt sich die Konsolidierung, weil sonst niemand
sie hätte.

Damit deckt `lib.nvim.git` künftig die Basis, die der Engine-Report (Phase
GS-30/§3.2 dort) für die *volle* lazygit/neogit-Ersatz-Engine sowieso brauchen
würde — dieser Umzug liefert also einen Teil der Vorarbeit für das größere,
noch nicht begonnene Engine-Vorhaben mit, ohne dass beide Vorhaben sich
gegenseitig blockieren.

---

## 5. Phasenplan

**Zur Nummerierung:** Der Engine-Report reservierte `GS-29`–`GS-39`, davon
wurde nichts umgesetzt — das aktuelle `IMPLEMENTATION-PLAN.md` führt seither
eigenständig weiter und hat `GS-30` bereits für „Manuelle Verifikation" (Welle 6)
belegt; `GS-31` ist im Backlog als `rules-nvim-ruleset-sweep` (Task) vergeben.
Die Buchstaben unten (**A**–**G**) sind Platzhalter — die echten `GS-NN` werden
erst beim Eintragen in die Master-Tabelle von `IMPLEMENTATION-PLAN.md`
vergeben (nächste freie Nummer zu diesem Zeitpunkt prüfen, nicht diesem
Dokument entnehmen).

| # | Titel | Repo | Inhalt | Voraussetzung |
| --- | --- | --- | --- | --- |
| A | `lib.nvim.git`: push/pull/fetch/update | lib.nvim | Primitive + Tests, 3-OS-CI | E-1 geklärt |
| B | gitsuite: Dashboard-Grundgerüst (read-only) | gitsuite.nvim | `repos.lua`+`repo_dashboard.lua`-Äquivalent, `:Git dashboard [dir]` zeigt Status ohne Aktionen, Config `dashboard.base_dir`/`extra_paths` | A (CI grün) |
| C | gitsuite: Dashboard-UI + Aktionen | gitsuite.nvim | `dashboard_view.lua`-Äquivalent (Popup/Buffer/Split, Zeilen-/Mark-/Bulk-Push/Pull/Fetch über die neuen `lib.nvim.git`-Primitive), neue `ui.nvim`-Dependency | B, E-2 geklärt |
| D | gitsuite: headless Bulk-Update | gitsuite.nvim | `:Git dashboard update [dir]` als Äquivalent zu `:Reposcope update`, nutzt A | A, B |
| E | reposcope: Abbau | reposcope.nvim | `dashboard`/`update`-Routen, `repos.lua`/`repo_dashboard.lua`/`repo_actions.lua`/`repo_updater.lua`/`dashboard_view.lua` entfernen, `dashboard.extra_paths`-Config entfernen, Tests entfernen/migrieren | C, D fertig+gepusht |
| F | nvim-config: `:MyPlugins` anpassen | nvim-config | `open_dashboard()` auf `:Git dashboard` umstellen; optional `ops.lua` auf `lib.nvim.git` umstellen (E-4) | C fertig+gepusht |
| G | Doku-Sweep | reposcope.nvim, gitsuite.nvim, nvim-config, ggf. WKDBooks-Plan | alle Stellen aus [§7](#7-doku-die-mitgezogen-werden-muss) | E, F |

Reihenfolge zwingend wegen K-6 (Plan): `lib.nvim` pushen → 3-OS-CI grün
(`ci-verified` zieht nach) → erst dann gitsuite. reposcope darf erst nach C+D
demontiert werden (sonst reißt `:MyPlugins dashboard`s bisherige Delegation
eine Lücke, bevor der Ersatz steht).

---

## 6. Offene Entscheidungen

1. **E-1 — Wohin `resolve_base_dir`/`collect_repos`/`is_git_repo`?** Reines
   `gitsuite.features.dashboard.repos`-Modul (schneller, aber nicht von
   `lib.nvim` aus wiederverwendbar) oder gleich nach `lib.nvim.fs` (geteilter
   Baustein, aber Eingriff in ein drittes Repo für ein Detail, das aktuell nur
   ein Konsument braucht). *Empfehlung:* vorerst gitsuite-intern, K-5 zieht
   erst, wenn ein zweiter Konsument auftaucht (gleiches Prinzip wie beim
   Terminal-Spawn-Helfer im Haupt-Plan, „Bewusst geparkt").
2. **E-2 — `ui.kit` übernehmen oder Eigenbau?** Siehe [§3.3](#33-neue-abhängigkeit-gitsuite--uinvim).
   *Empfehlung:* `ui.kit` übernehmen — spart den Neubau von Popup/Scroll/Confirm,
   die neue Kante ist unidirektional und kollidiert mit keiner bestehenden
   Regel.
3. **E-3 — Bleibt `:Reposcope update`/`dashboard` als deprecated Alias
   bestehen** (kurze Übergangszeit, notify „moved to :Git dashboard", dann
   entfernen) **oder harter Schnitt** in Phase E? *Empfehlung:* harter Schnitt
   — der Plan des Haupt-Vorhabens wählt bei jeder ähnlichen Frage (`D-1` im
   IMPLEMENTATION-PLAN.md) explizit den harten Schnitt, es gibt nur einen
   bekannten Aufrufer (`:MyPlugins`, wird in Phase F mitgezogen).
4. **E-4 — `:MyPlugins`s `ops.lua` jetzt auch auf `lib.nvim.git` umstellen?**
   Kann als Teil von Phase F laufen oder als eigene, spätere Aufräumkarte
   (Duplikation besteht dann zwar weiter, aber unverändert zum heutigen
   Zustand — kein neuer Schaden). *Empfehlung:* mitziehen, wenn A ohnehin
   fertig ist — der Zusatzaufwand ist vor allem Testen, keine neue Logik.
5. **E-5 — Config-Key-Name in gitsuite:** `dashboard.base_dir` (neu, analog zu
   reposcopes `clone.std_dir`) oder direkt ungefiltert `$REPOS_DIR` lesen ohne
   eigenen Override? *Empfehlung:* `base_dir`-Override behalten (reposcopes
   eigene Begründung dafür — Test-/CI-Repos, die nicht unter `$REPOS_DIR`
   liegen — gilt unverändert).

---

## 7. Doku, die mitgezogen werden muss

### reposcope.nvim (entfernen/kürzen)

`docs/commands.md`, `docs/BINDINGS.md`, `docs/configuration.md`
(`dashboard.extra_paths`-Abschnitt), `docs/FEATURES/README.md` (Zeile
„Maintenance"), `docs/FEATURES/WORKFLOW.md` (Dashboard/Update-Abschnitte),
`docs/quickstart.md`, `docs/what-you-get.md`, `docs/troubleshooting.md`,
`docs/requirements.md`, Root-`README.md`, `doc/reposcope.txt`,
`TESTS/README.md` (Testliste ohne `dashboard_view_spec.lua`/`repos_util_spec.lua`).

### gitsuite.nvim (ergänzen)

`docs/commands.md`, `docs/BINDINGS.md` (aus dem Route-Baum neu erzeugen, wie
bei jeder Karte laut „Definition of Done"), `docs/configuration.md` (neue
`dashboard`-Optionen), `docs/what-you-get.md`, **`docs/scope.md`** (den
Multi-Repo-Sprung explizit als bewussten Sonderfall dokumentieren, nicht als
Non-Goal), `docs/architecture.md` (neue `ui.nvim`-Dependency erklären, falls
E-2 = `ui.kit`), Root-`README.md`, `doc/gitsuite.txt`.

### nvim-config

`docs/BINDINGS.md` (`:MyPlugins dashboard`-Zeile: Ziel `:Reposcope dashboard`
→ `:Git dashboard`), `lua/bindings/usrcmds/plugin_repos/README.md`
(Abschnitt „Dashboard (delegates to reposcope.nvim's own git-status overview)"
umbenennen/umschreiben auf gitsuite), `lua/plugins/personal/init.lua`
(`dashboard.extra_paths`-`opts` von der `reposcope`-Spec zur `gitsuite`-Spec
verschieben), `docs/NOTES/BINDINGS-FORMAT.md`/`docs/NOTES/ExternPlugins/Bindings/`
falls sich Keymaps ändern.

### Der Plan selbst

`ROADMAP/IMPLEMENTATION-PLAN.md` (WKDBooks-Original, s.
[§1.3](#13-gitsuitenvim-heute)): die Zeile „gitsuite ist ein Repo, reposcope
ist viele — die Grenze bleibt" unter „Bewusst geparkt oder verworfen" muss auf
diesen revidierten Stand aktualisiert werden, sobald Phase C/D stehen —
sonst widerspricht der eigene Plan dem, was im Repo tatsächlich existiert.

### lib.nvim (falls A umgesetzt wird)

README/`CONTRIBUTING.md`, dort wo `lib.nvim.git`s Funktionsliste dokumentiert
ist (Tabelle analog zu der im Engine-Report, §1.3 dort).

---

## 8. Risiken

- **Vier Repos, eine Kette:** `lib.nvim` → (CI grün) → `gitsuite.nvim` →
  (E, F erst danach) → `reposcope.nvim` + `nvim-config`. Kein Schritt darf vor
  dem grünen CI-Stand des vorherigen gepusht werden (K-6).
- **Testabdeckung darf nicht verloren gehen:** `dashboard_view_spec.lua` und
  `repos_util_spec.lua` testen genau die Logik, die umzieht — sie müssen nach
  gitsuite migriert (nicht einfach gelöscht) werden, bevor sie in reposcope
  entfernt werden.
- **Doku-Drift:** ca. 15 Dateien in reposcope, mindestens 6 in gitsuite, 3 in
  nvim-config — siehe die Checkliste in [§7](#7-doku-die-mitgezogen-werden-muss)
  als Abhak-Liste, um nichts zu vergessen.
- **Workflow-Bruch für den Nutzer:** `:Reposcope dashboard`/`<leader>rs`
  gefolgt von der Dashboard-Nutzung ändert sich auf `:Git dashboard`. Da E-3
  einen harten Schnitt empfiehlt, sollte die letzte reposcope-Version vor dem
  Cutover kurz kommuniziert/im Changelog stehen.
- **Scope-Aufweichung bei gitsuite:** die neue Multi-Repo-Familie ist eine
  bewusste Ausnahme (s. [§3.2](#32-der-einzige-echte-bruch-gitsuite-ist-ein-repo));
  ohne den `docs/scope.md`-Zusatz aus §7 wirkt sie wie ein Bruch der eigenen
  Regeln statt wie eine benannte Entscheidung.

---

## 9. Erweiterung (Zusatzwunsch): gruppierte Dashboards + interaktive Pfadverwaltung

Nachtrag aus der Chat-Rückfrage nach dem Basis-Umzug — sinnvoll, aber ein
eigener Ausbauschritt **nach** Phase C, kein Teil davon (Phase C liefert erst
die flache Ein-Dashboard-Ansicht, die reposcope heute schon hat).

### 9.1 Config-Form

Bare-String- und Listen-Gruppen gemischt (wie ursprünglich vorgeschlagen) sind
inkonsistent typisiert. Da die bestehende Auflösung ohnehin pro Eintrag prüft
„ist das selbst ein Repo oder ein Scan-Ordner"
(`is_git_repo(path) and {path} or collect_repos(path)`, aus
`repos.lua`/`resolve_base_dir` übernommen), reicht eine einheitliche
Listenform pro Gruppe:

```lua
dashboard = {
  groups = {
    ["files & navigation"] = { "E:/repos/reposcope.nvim", "E:/repos/lib.nvim" },
    ["repos dir"]          = { "$REPOS_DIR" },
  },
}
```

Jede Gruppe ist intern nur ein weiterer Aufruf von `dashboard_all(paths)` mit
genau den Pfaden dieser Gruppe statt eines einzelnen Scan-Verzeichnisses —
kein neuer Auflösungspfad nötig, nur eine Schleife über `groups` statt über
einen einzelnen `dir`.

### 9.2 Navigation zwischen Gruppen

Neue Dashboard-Keymaps (Vorschlag, neben den bestehenden `p`/`P`/`f`/`gp`/`gP`/
`gf`/`gu`): `]d`/`[d` (oder `<Tab>`/`<S-Tab>`) wechselt zur nächsten/vorigen
Gruppe, Gruppenname im Winbar/Titel statt (oder neben) dem bisherigen
„N repositories in <dir>"-Header. Eine kombinierte „alle Gruppen"-Ansicht als
zusätzliche Seite ist denkbar, aber nicht zwingend für den ersten Wurf.

### 9.3 Interaktives Hinzufügen/Entfernen

Neue Keymaps (Vorschlag: `a` fügt einen Pfad zur aktuellen Gruppe hinzu, per
`vim.ui.input`; `d`/`x` entfernt den Pfad unter dem Cursor aus seiner Gruppe).

**Persistenz darf nicht die Lua-Config umschreiben** — das tut im ganzen
Ökosystem heute bewusst nur `:MyPlugins mode` (eine einzelne, trivial
ersetzbare `OVERRIDE = "..."`-Zeile in `source.lua`), kein Präzedenzfall für
beliebige Listen-Mutation. Stattdessen ein kleiner persistierter State nach
dem Muster von `reposcope.state.favorites_state`/`session_state` (JSON/Lua
unter `stdpath('data')/gitsuite/dashboard_groups.json`), der sich zur
Laufzeit über die statisch in `setup()` deklarierten `dashboard.groups` legt:
statische Gruppen bleiben Quelltext-Wahrheit, interaktive Änderungen bleiben
lokal auf der Maschine und überleben Config-Änderungen unabhängig davon.

### 9.4 Offene Entscheidungen dieser Erweiterung

- **E-6:** Persistierter State additiv zu `setup()`-Gruppen (Vorschlag oben)
  oder komplett ersetzend, sobald einmal interaktiv verändert wurde?
  *Empfehlung:* additiv — sonst verschwinden statisch konfigurierte Pfade,
  sobald der State einmal existiert.
- **E-7:** Entfernen aus einer Gruppe per Keymap wirkt nur auf die
  *Anzeige-Zuordnung* (welche Gruppe zeigt den Pfad), nie auf das Repo selbst
  — sollte im Confirm-Text (falls `E-2` = `ui.kit`-Confirm übernommen wird)
  explizit stehen, um es nicht mit `remove`/`reclone` aus `:MyPlugins` zu
  verwechseln.
- **E-8:** Eine gruppenlose Vorbelegung („default"-Gruppe für schnelles `a`
  ohne vorher eine Gruppe auszuwählen) — nötig, oder muss jede Gruppe explizit
  benannt existieren, bevor man ihr per Keymap etwas hinzufügt?

Als eigene Phase (Platzhalter **H**, nach **G**) in den Phasenplan aus
[§5](#5-phasenplan) einzuordnen — abhängig von C (Dashboard-UI muss stehen,
bevor sie Gruppen-Navigation bekommt).

---

## 10. Nächste Schritte

1. Die fünf offenen Entscheidungen in [§6](#6-offene-entscheidungen) klären,
   plus E-6–E-8 aus [§9.4](#94-offene-entscheidungen-dieser-erweiterung) falls
   die Erweiterung mitgeplant werden soll.
2. Phasen A–G (und optional H) als Backlog-Karten mit echten `GS-NN`-Nummern
   anlegen (nächste freie Nummer zum Zeitpunkt der Eintragung in
   `IMPLEMENTATION-PLAN.md` prüfen — nicht die Platzhalter aus diesem Dokument
   übernehmen).
3. Mit Phase A (`lib.nvim.git`: push/pull/fetch/update) beginnen — B–D bauen
   darauf auf, E/F erst nach deren Cutover, H frühestens nach C.
