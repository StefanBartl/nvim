# gitsuite.nvim: eigene Engine als vollständiger lazygit+neogit-Ersatz

Konzept & Implementierungsplan zu Punkt 2 aus der gitsuite.nvim-Aufgabenliste:

> Scope-Entscheidung (geklärt): gitsuite.nvim soll lazygit + neogit vollständig
> ersetzen. Aktuell ruft z. B. `<leader>lg` nur die echte lazygit-UI auf
> (gleicher Look, sogar mit „lazygit" als Überschrift) — es ist also nur ein
> Wrapper. Ziel: eine eigene Engine/UI im Lazygit-Look, die die Funktionen von
> lazygit und neogit vereint, sodass die externen Tools nicht mehr gebraucht
> werden.

Reine Recherche + Planung, kein Code. Alle Repo-Pfade beziehen sich auf
`$REPOS_DIR/gitsuite.nvim` (bzw. `$REPOS_DIR/lib.nvim`) und `stdpath('config')`
für die nvim-Konfiguration, sofern nicht anders angegeben.

---

## 1. Ist-Zustand

### 1.1 Was heute wirklich passiert

- `<leader>lg` → `:Git ui lazygit` → `features/ui/lazygit/init.lua`: spawnt
  den **echten** `lazygit`-Binary per `jobstart(argv, {term=true})` in einem
  Float (90% der Editorfläche, `title = " lazygit "`). Das Neovim-seitige ist
  eigen (Float, `nvr`-Bridge für `O`/`<C-o>`), die eigentliche UI ist
  weiterhin lazygit selbst — daher exakt der im Auftrag beschriebene Eindruck
  ("gleicher Look, sogar mit lazygit als Überschrift").
- `:Git ui neogit` → `adapter/neogit.lua` → `require("neogit").open()`. Ein
  reiner Adapter, keine eigene Logik. neogit ist in
  `lua/plugins/git.lua` als eigenes, separates Plugin installiert
  (`NeogitOrg/neogit`, `cmd = "Neogit"`, Keymap `<leader>gg`) — **nicht** als
  Dependency von gitsuite.nvim.
- `docs/scope.md` listet unter "Does not" explizit: *"No staging UI. neogit
  owns that"* und *"No interactive rebase, no commit editor, no push/pull/fetch
  UI ... lazygit or the terminal is the intended tool for those."*
  `docs/architecture.md` begründet das als bewusste Design-Entscheidung: die
  `ui`-Familie ist einer von genau zwei Fällen (neben `hunk`/`diff`), in denen
  "own implementation" explizit **abgelehnt** wurde, weil lazygit/neogit
  "years of edge-case work" sind.
- Punkt 2 der Aufgabenliste kehrt diese Entscheidung bewusst um. Alle Doku,
  die diese alte Begründung trägt (`scope.md`, `architecture.md`,
  `around-it.md`, `requirements.md`, `commands.md`, `BINDINGS.md`,
  `configuration.md`), muss im Zuge der Umsetzung mitgezogen werden — s.
  [§7](#7-doku-die-mitgezogen-werden-muss).

### 1.2 Bug aus Punkt 1 als Nebenbefund

Punkt 1 der Aufgabenliste ("`:Git ui` listet auch nicht installierte Plugins")
erklärt sich aus dem oben Gesagten: neogit lädt bei diesem Setup erst lazy
über `cmd = "Neogit"`, `package.loaded["neogit"]` ist also bis zum ersten
`:Neogit`-Aufruf `nil`. `adapter.resolve("neogit")` liefert dann korrekt
`nil` — der Fehler muss folglich in der `:Git ui`-Menü-/Completion-Liste
selbst liegen (sie listet vermutlich die drei UI-Namen statisch statt über
`adapter.resolve` zu filtern). Das ist ein separater, kleiner Fix und **nicht**
Teil dieses Konzepts — sollte aber ohnehin obsolet werden, sobald neogit als
Backend entfällt (Phase 9).

### 1.3 Was bereits an Infrastruktur existiert und wiederverwendbar ist

`lib.nvim.git` (`$REPOS_DIR/lib.nvim\lua\lib\nvim\git\init.lua`) ist die
**einzige** Stelle, über die gitsuite.nvim heute git aufruft (Contributing-Regel:
"Every git call goes through `lib.nvim.git`/`lib.nvim.cross.run_argv` — no
`vim.fn.system("git " .. ...)` anywhere"). Vorhanden, alle rein lesend:

| Funktion | Deckt ab |
| --- | --- |
| `status_porcelain` / `_async` | Working-Tree-Status (Dateien, XY-Codes, Rename-Tracking) |
| `show` / `show_async` | Datei-Inhalt zu Rev/Index/Konfliktstufe |
| `blame_porcelain` / `_async` | Blame |
| `refs` | Branches/Remotes/Tags, sortiert für Completion |
| `checkout` | Branch wechseln (einzige **schreibende** Funktion im Modul) |
| `current_branch`, `ahead_behind`, `upstream`, `head_hash`, `describe`, `remote_url`, `in_git_repo`, `repo_root`, `is_dirty`, `is_detached_head`, `is_tracked`, `relative_path`, `current_ref` | Repo-Metadaten |

Alles NUL-getrennt geparst (`-z`), argv-basiert (kein Shell-String), mit
synchronen + async Varianten nach demselben Muster. Das ist exakt das
Fundament, auf dem die neue Engine aufsetzen sollte — nicht neu erfinden.

Ebenfalls wiederverwendbar, unverändert:

- `features/status/*`, `features/branch/*`, `features/blame/*`,
  `features/conflict/*` — die reinen Datenoperationen bleiben, nur die
  Präsentation wandert in die neue Engine-UI bzw. wird von ihr zusätzlich
  aufgerufen.
- `adapter/gitsigns.lua` + `features/hunk/*` — Hunk-Stage/-Reset bleibt über
  gitsigns' Engine laufen (siehe [§5](#5-offene-entscheidungen), Punkt 3).
- `diff.nvim` (hartes Dependency) für Side-by-side-Diffs.
- `features/ui/lazygit/init.lua`s Float-Geometrie/`jobstart`-Pattern als
  Vorlage für die neue Engine-Float (Windows-taugliches `argv`-`jobstart`,
  kein `termopen`).

---

## 2. Zielbild

Eine neue, eigene UI-Engine (Arbeitstitel `gitsuite.engine`, Modul unter
`lua/gitsuite/engine/`), die im Lazygit-Look mehrere Panels in einem Float
oder Split zeigt und dabei sowohl lazygits Tagesgeschäft (Status/Stage/Commit/
Push/Pull/Branches/Stash/Log) als auch neogits Rolle (Staging-UI) abdeckt.
Ergebnis: `<leader>lg` (oder ein neuer Default-Keymap) öffnet **gitsuite
selbst**, nicht mehr den externen `lazygit`-Prozess und nicht mehr `neogit`.

Nicht-Ziel (siehe `docs/scope.md`, bleibt unverändert): kein
Multi-Repo-Dashboard (das ist reposcope.nvim), keine Git-Hosting-API
(Issues/PRs) — Punkt 2 der Aufgabenliste spricht ausdrücklich nur von
"die Funktionen von lazygit und neogit vereinen", nicht von einem größeren
Scope als die beiden bisher abdecken.

### 2.1 Feature-Parität: was die Engine leisten muss

Abgeglichen gegen lazygits Panels und neogits Popups:

| Bereich | lazygit | neogit | Engine-Anforderung |
| --- | --- | --- | --- |
| Status/Files | Panel mit Stage/Unstage (Datei- und Hunk-Ebene), Discard | Status-Buffer mit denselben Aktionen | Files-Panel: stage/unstage/discard je Datei, delegiert Hunk-Ebene an gitsigns |
| Commit | Popup (Message, Amend, `--no-verify`) | Popup | Commit-Panel/Prompt inkl. Amend |
| Branches | Panel: create/delete/rename/checkout/merge | Popup | Branches-Panel, Teile bereits in `features/branch` vorhanden (nur `list`+`switch`, `create`/`delete`/`rename` fehlen) |
| Commits/Log | Panel mit Graph, Diff pro Commit, Reset/Revert/Cherry-pick | Log-Buffer | Log-Panel: `git log` parsen, Commit-Diff über `diff.nvim` |
| Stash | Panel: push/pop/apply/drop/show | Popup | Stash-Panel, komplett neu |
| Push/Pull/Fetch | Popups inkl. force/upstream-Handling | Popups | Aktionen auf Branches-/Status-Panel, keine eigene Panel nötig |
| Rebase/Merge | Interaktives Rebase-Panel, Merge-Konfliktbehandlung | Popup + Rebase-Todo-Editor | Schwierigster Teil — s. [§5](#5-offene-entscheidungen), Punkt 4 |
| Submodules | Panel | — | Nicht in Punkt 2 gefordert, aus Scope raus, außer der User widerspricht |

---

## 3. Architektur-Einordnung

### 3.1 Was sich am bestehenden Muster ändert

`docs/architecture.md` begründet aktuell die "own implementation vs. thin
adapter"-Aufteilung damit, dass gitsigns/`diff.nvim`/lazygit/neogit "years of
edge-case work" sind, deren Reimplementierung "explicitly rejected" wurde.
Für `ui` (lazygit/neogit) wird das mit Punkt 2 bewusst aufgehoben — für
`hunk` (gitsigns) und `diff`/`diffview` bleibt die Begründung unverändert
bestehen (siehe [§5](#5-offene-entscheidungen), Punkt 3: Hunk-Staging bleibt
sinnvollerweise bei gitsigns).

Die Adapter-Registry (`lua/gitsuite/adapter/init.lua`) bleibt als Muster
bestehen, ändert aber die Rolle von `adapter/lazygit.lua` und
`adapter/neogit.lua`: von "das eigentliche Backend" zu "optionaler
Fallback/Escape-Hatch" (falls der User das so will, s. offene Entscheidung 1)
oder sie werden nach Phase 9 ganz entfernt.

### 3.2 Wohin die neuen schreibenden Git-Primitive gehören

`lib.nvim.git` enthält heute nur eine einzige schreibende Funktion
(`checkout`). Für Stage/Commit/Push/Pull/Stash/Branch-Verwaltung/Rebase fehlt
in `lib.nvim.git` fast alles. Die Projekt-Konvention ("every git call goes
through `lib.nvim.git`") spricht dafür, diese Primitive dort zu ergänzen,
statt sie gitsuite-intern zu duplizieren — andere `*.nvim`-Plugins könnten
sie potenziell mitnutzen, und der bestehende Stil (argv, `run_blocking`/
`run_async_captured`, `Lib.Git.Opts` mit `dir`) passt exakt. Das ist aber ein
Eingriff in ein **separates** Repo mit eigenem Test-/Release-Rhythmus — siehe
offene Entscheidung 2.

### 3.3 UI-Rendering

Kein neues UI-Toolkit als Abhängigkeit (nui.nvim o. ä.) vorausgesetzt — das
Projekt baut Floats bisher pur mit `nvim_open_win`/`nvim_create_buf`
(`features/ui/lazygit/init.lua` als Vorlage). Für ein Mehr-Panel-Layout
(Lazygit hat fünf Panels: Status, Files, Branches, Commits, Stash, plus
Haupt-Diff-Bereich) reicht das — mehrere Floats nebeneinander oder ein
Split-Layout in einer Tabpage, analog zu neogits `kind = "split"`. Details
sind Sache der Umsetzung, keine Vorentscheidung nötig, außer der User will
explizit ein Toolkit (offene Entscheidung 5).

Kernprinzip für Testbarkeit: **Engine-Logik von Rendering trennen** — dieselbe
Trennung, die `features/conflict/parser.lua` (reine Logik) von
`features/conflict/highlights.lua` (Rendering) bereits vorlebt. Die
Git-Aufrufe, State-Verwaltung (welche Datei ist selektiert, welches Panel ist
aktiv) und reine Parsing-Funktionen (Log-Zeilen, Stash-Liste) müssen ohne
offenes Fenster testbar sein; nur das tatsächliche Zeichnen braucht ein
laufendes Nvim mit UI.

---

## 4. Phasenplan

Nummerierung schließt an die höchste bestehende `GS-`-Ticket-Nummer im Repo an
(`GS-28`, siehe `features/conflict/parser.lua`/`conflict/init.lua`) — neue
Tickets ab **GS-29**. Jede Phase ist einzeln nutzbar/mergebar, nichts wartet
auf die letzte Phase, um Wert zu liefern.

| # | Titel | Inhalt | Voraussetzung |
| --- | --- | --- | --- |
| GS-29 | Konzept (dieses Dokument) | Ist-Analyse, Architekturentscheidung, Phasenplan | — |
| GS-30 | `lib.nvim.git`: schreibende Primitive | `stage`/`unstage`/`stage_all`/`discard`, `commit` (inkl. amend), `push`/`pull`/`fetch`, `branch_create`/`branch_delete`/`branch_rename`, je mit Tests in lib.nvim | Offene Entscheidung 2 geklärt |
| GS-31 | Engine-Grundgerüst + Files-Panel | `lua/gitsuite/engine/` State-Machine, Float/Split-Layout, Files-Panel (Status lesen, stage/unstage/discard je Datei), neuer Command `:Git ui engine` parallel zu `lazygit`/`neogit` | GS-30 |
| GS-32 | Commit-Panel | Commit-Message-Prompt, Amend, an Files-Panel gekoppelt | GS-31 |
| GS-33 | Branches-Panel | List/Create/Delete/Rename/Checkout — baut auf `features/branch` auf, ergänzt fehlende Schreiboperationen | GS-30, GS-31 |
| GS-34 | Log/Commits-Panel | `git log`-Parsing (Graph, Refs, Subject, Author, Datum), Commit-Diff über `diff.nvim`, Reset/Revert/Cherry-pick | GS-30, GS-31 |
| GS-35 | Stash-Panel | push/pop/apply/drop/show | GS-30 |
| GS-36 | Push/Pull/Fetch + Konfliktpfad | Popups/Prompts für Push (force/force-with-lease/upstream), Pull (rebase/merge), Fetch (prune); Merge-Konflikte nach Pull/Rebase münden in `features/conflict` (Wiederverwendung, kein Neubau) | GS-30, GS-33 |
| GS-37 | Rebase/Merge/Cherry-pick (interaktiv) | Schwierigster Teil — Umfang hängt an offener Entscheidung 4 | GS-34, GS-36 |
| GS-38 | Cutover | `<leader>lg`/Default-Keymap zeigt auf die eigene Engine; `lazygit`/`neogit` werden zu explizitem Opt-in-Fallback (`:Git ui lazygit`/`:Git ui neogit` bleiben, sind aber nicht mehr der Default); **alle** Doku-Seiten aus [§7](#7-doku-die-mitgezogen-werden-muss) aktualisiert; `personal/init.lua` + `plugins/git.lua` ggf. angepasst | GS-31–37 abgeschlossen, Parität erreicht |
| GS-39 | Deprecation | `adapter/neogit.lua` entfernen, neogit-Plugin-Spec aus `plugins/git.lua` entfernen; `adapter/lazygit.lua` behalten oder entfernen je nach offener Entscheidung 1 | GS-38, nach Beobachtungszeit |

---

## 5. Offene Entscheidungen

Diese fünf Punkte sollten vor GS-30 geklärt werden, weil sie den Zuschnitt
mehrerer späterer Phasen verändern:

1. **Bleibt der echte `lazygit`-Binary-Float als Fallback erhalten** (z. B.
   weiterhin unter `:Git ui lazygit` erreichbar), oder wird er komplett
   entfernt, sobald die eigene Engine Parität hat? Ein Fallback kostet wenig
   (Code existiert bereits, `adapter/lazygit.lua` bleibt einfach unverändert
   liegen) und ist ein Sicherheitsnetz für Fälle, die die eigene Engine
   (noch) nicht abdeckt — insbesondere interaktives Rebase (Punkt 4).
2. **Wohin gehören die neuen schreibenden Git-Primitive** — in `lib.nvim.git`
   (geteilt, passt zur bisherigen Konvention, aber Eingriff in ein separates
   Repo mit eigenem Release-Rhythmus) oder gitsuite-intern (`gitsuite.git`,
   schneller iterierbar, aber Konventionsbruch und potenziell für andere
   Plugins nicht wiederverwendbar)?
3. **Hunk-genaues Stage/Unstage** (einzelne Zeilen eines Hunks stagen, wie
   lazygit es per Cursor-Selektion kann): weiterhin über gitsigns delegieren
   (aktuelle `hunk`-Familie, `docs/architecture.md`s eigene Begründung dafür
   bleibt gültig — gitsigns' Hunk-Engine ist genau der Teil, der laut
   bisheriger Doku *nicht* neu gebaut werden sollte), oder eigene
   `git apply --cached`-Implementierung für den Fall, dass gitsigns nicht
   installiert ist? Empfehlung: bei gitsigns-Delegation bleiben, Lücke nur
   für den `native`-Fallback-Fall dokumentieren (wie heute schon bei
   `features/hunk/init.lua`).
4. **Interaktives Rebase**: volle eigene Todo-Editor-UI (lazygits/neogits
   aufwendigster Einzelteil) — eigene Implementierung, oder bewusst als
   letzte Lücke akzeptieren und dafür dauerhaft auf den lazygit-Fallback
   verweisen (hängt an Entscheidung 1)? Empfehlung: als eigene GS-37-Phase
   einplanen, aber explizit als "kann auf Fallback verweisen bleiben" markiert
   akzeptieren, falls der Aufwand den Nutzen übersteigt.
5. **UI-Rendering-Basis**: reiner Eigenbau mit `nvim_open_win`/Extmarks
   (Projektkonvention, keine neue Abhängigkeit) oder ein UI-Toolkit wie
   nui.nvim als neue weiche Abhängigkeit? Empfehlung: Eigenbau, konsistent mit
   dem Rest des Ökosystems (kein anderes `*.nvim`-Plugin des Users bindet
   aktuell ein UI-Toolkit für Floats ein, soweit aus den gelesenen Dateien
   ersichtlich).

---

## 6. Risiken

- **Scope-Explosion**: `docs/architecture.md` begründet den aktuellen Zustand
  damit, dass lazygit/neogit "years of edge-case work" sind. Das ist keine
  überholte Einschätzung, sondern eine bewusst in Kauf genommene Konsequenz
  der Scope-Entscheidung aus Punkt 2 — der Aufwand pro Phase sollte darum
  eher konservativ geschätzt werden, insbesondere GS-37 (Rebase).
- **Testbarkeit**: Eine Mehr-Panel-UI ist schwerer headless mit plenary zu
  testen als die bisherigen reinen Git-Datenfunktionen. Mitigation: Trennung
  Engine-Logik/Rendering wie in [§3.3](#33-ui-rendering) beschrieben — jede
  Phase liefert eine testbare Logikschicht plus eine dünne, nur manuell
  geprüfte Rendering-Schicht (gleiches Verhältnis wie
  `conflict/parser.lua`/`conflict/highlights.lua` heute schon).
- **Windows-Kompatibilität**: Bestehende Regeln aus dem Code
  (`jobstart(argv, {term=true})` statt `termopen()`, kein Shell-String für
  Git-Aufrufe, `nvr`-Bridge-Muster) gelten unverändert für die neue Engine —
  das Projekt läuft laut `.github/workflows/ci.yml` auf Linux/Windows/macOS.
- **Kollision mit Punkt 1**: Der `:Git ui`-Options-Bug (Punkt 1 der
  Aufgabenliste) sollte vor oder spätestens mit GS-38 mit erledigt werden,
  weil er sich nach dem Cutover ohnehin anders darstellt (neogit ggf. gar
  nicht mehr in der Liste).

---

## 7. Doku, die mitgezogen werden muss

Erst ab GS-38 (Cutover) relevant, hier vorgemerkt, damit es nicht vergessen
wird:

- `docs/scope.md` — "Does not"-Absatz zu Staging-UI/Rebase/Commit-Editor/
  Push-Pull-UI entfällt oder wird durch die neuen Fähigkeiten ersetzt.
- `docs/architecture.md` — Abschnitt "Own implementation where it pays off,
  a thin adapter where it doesn't" muss `ui` aus der Adapter-Spalte in die
  Own-Implementation-Spalte verschieben, mit neuer Begründung.
- `docs/around-it.md` — Abschnitte "neogit" und die lazygit-Erwähnung unter
  "vim-fugitive / ... / lazygit.nvim" müssen umgeschrieben werden: neogit
  wechselt von "adapted only" zu "replaced outright".
- `docs/requirements.md` — Zeilen zu `neogit`/`lazygit executable` in der
  Optional-Tabelle entfallen oder wandern zu "nur für den expliziten
  Fallback" (abhängig von offener Entscheidung 1).
- `docs/commands.md`, `docs/BINDINGS.md` — neue `:Git ui engine`-Routen
  (bzw. deren finaler Name nach Cutover), generierte Tabelle neu erzeugen.
- `docs/configuration.md` — neue `keymaps`/`features`-Einträge für die
  Engine.
- `$NVIM_CONFIG_DIR/lua\plugins\personal\init.lua` und
  `lua\plugins\git.lua` — Kommentare, die aktuell erklären, dass neogit
  separat installiert ist bzw. dass `<leader>lg` "still the real lazygit TUI"
  ist, müssen aktualisiert werden; `dependencies`-Eintrag ggf. erweitert.
- `vim.fn.stdpath('config') .. /docs/NOTES/BINDINGS` — falls sich Keymaps
  ändern (neuer Default für `<leader>lg` o. ä.), dort nachziehen (siehe
  allgemeine Arbeitsanweisung des Users).

---

## 8. Nächste Schritte

1. Die fünf offenen Entscheidungen in [§5](#5-offene-entscheidungen) mit dem
   User klären.
2. GS-29 bis GS-39 als Backlog-Tasks anlegen, gleiches Dateiformat wie die
   bestehenden `docs/ROADMAP/Backlog/TASKS/GS-13..28_*.md`.
3. Mit GS-30 (`lib.nvim.git`: schreibende Primitive) beginnen — alle
   folgenden Phasen bauen darauf auf.
