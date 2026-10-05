# Implementierungsplan: `:MyPlugins sync` — alle Plugin-Repos auf den aktuellen Stand, Problemfälle als Triage-Liste

Stand: 2026-10-05. Status: **Plan, noch nichts implementiert.**

## 1. Auftrag (bereinigt)

Eine Option unter `:MyPlugins`, die

1. zuerst **alle** Plugin-Repos `fetch`t,
2. danach bei jedem Repo, das Commits zu ziehen hat, **pullt**,
3. Repos, bei denen das nicht klappt (z. B. uncommittete Änderungen, nicht
   fast-forwardbar), **nicht sofort abbricht**, sondern **sammelt** und am Ende
   in einer **Liste/Dashboard** anzeigt,
4. aus dieser Liste erlaubt, **in jedes einzelne Repo hineinzugehen** und das
   Problem entweder zu **lösen** oder das Repo zu **überspringen**,
5. am Ende Gewissheit gibt: *alle* Repos sind aktuell, **außer** die, die ich
   bewusst übersprungen habe.

Ziel ist der Zwei-Maschinen-Workflow (`dir`-Modus, siehe
[`plugin_repos/README.md`](../../../lua/bindings/usrcmds/plugin_repos/README.md),
Abschnitt "The two-machine `dir`-mode sync case"): auf Maschine B in einem Rutsch
alles nachziehen, was auf Maschine A gepusht wurde.

## 2. Ist-Zustand (was es schon gibt, was fehlt)

`:MyPlugins update` (`init.lua`, `update_all` → `run_listed_op`) macht bereits
fetch + `pull --ff-only` pro Repo, sequentiell, mit Progress und einer
Abschluss-Notify. Es fehlt genau das, was der Auftrag verlangt:

| Baustein | Vorhanden | Lücke |
|---|---|---|
| Fetch + ff-only-Pull je Repo | `ops.update_one` → `lib.nvim.git.update_async` | Fetch und Pull sind **pro Repo verschränkt**, nicht "erst alle fetchen, dann pullen" |
| Fehler sammeln | `ops.run_sequential` liefert `failed = {item, err}` | Nur ein Text in einer `notify.warn`; **keine Klassifizierung**, kein Weiterarbeiten damit |
| "Warum nicht?" | rohes `stderr` von git | Kein Unterschied zwischen *dirty*, *diverged*, *kein Upstream*, *Netzfehler* |
| Interaktive Liste | `picker.lua` (Aktionen vorab zuweisen), `tasks_dash.lua` (Snacks-Picker mit Preview + Keys) | Kein Triage-View für Sync-Probleme |
| In ein Repo springen | gitsuite `:Git dashboard`: Taste `L` → `features.ui.lazygit(path)`, `S` → Detailstatus | Nicht an eine Problemliste gekoppelt; kein "danach erneut prüfen" |
| Skip-Konzept | — | Gibt es nicht |
| Endzustand "alle aktuell außer ..." | — | Gibt es nicht |

Wiederverwendbar ohne neue Git-Logik: `lib.nvim.git` (`fetch_async`, `pull_async`,
`status_porcelain_async`, `parse_status`, `ahead_behind`, `upstream`,
`is_detached_head`), `ops.run_sequential`, `ops.resolve_base_dir`,
`plugins.personal.core.list` (die maßgebliche Repo-Liste), `confirm.yesno`,
`new_progress` (Statusline).

## 3. Design

### 3.1 Aufruf

```
:MyPlugins sync [dir] [--only=<name>] [--check] [--no-fetch] [--jobs=<n>]
:MyPlugins sync issues            " letzte Problemliste erneut öffnen
```

- `--check`: Trockenlauf. Fetch + Klassifizierung, **kein Pull**; zeigt, was
  passieren würde (analog `--dry-run` bei `clone`/`reclone`; Flag-Name `dry-run`
  beibehalten, damit es zur Umgebung passt — `--check` nur als Alias, falls gewünscht).
- `--no-fetch`: nur klassifizieren und pullen mit dem, was lokal schon gefetcht ist.
- `--jobs=<n>`: Parallelität der Fetch-Phase, Default **2** (siehe 3.5).
- Scope wie bei allen Subcommands: nur Repos aus `plugins.personal.core.list`,
  nie ein Verzeichnis-Scan (`$REPOS_DIR` enthält auch Notes, WKDBooks, ...).

### 3.2 Phasen

```
Phase 0  Auflösen        Liste lesen, base_dir bestimmen, vorhandene Git-Repos filtern
Phase 1  Fetch alle      git fetch --all --prune, Fehler pro Repo merken (Netz, Auth)
Phase 2  Klassifizieren  git status --porcelain=v2 --branch → Zustand je Repo
Phase 3  Pull            nur Repos mit behind > 0: git pull --ff-only
Phase 4  Re-Klassifizieren der fehlgeschlagenen Pulls (Ursache bestimmen)
Phase 5  Ergebnis        Zusammenfassung + Triage-Dashboard, falls Probleme existieren
```

Phase 1 vor Phase 2/3 ist der entscheidende Unterschied zu `update`: Erst wenn
**alle** Remotes bekannt sind, steht fest, welche Repos überhaupt etwas zu
ziehen haben, und die Zusammenfassung ("12 zu ziehen, 3 Probleme") ist vollständig
bevor der erste Pull startet.

### 3.3 Klassifizierung (der Kern)

Eine **reine Funktion** `classify(record) -> state, detail` auf Basis der
Status-Daten (`# branch.head`, `# branch.upstream`, `# branch.ab +A -B`, geänderte
Einträge) — **keine** Auswertung von git-Meldungstexten (die sind lokalisierbar;
`lib.nvim.git.pull_async` begründet dasselbe ausführlich). Fehlerursachen nach
einem gescheiterten Pull werden ebenfalls strukturell aus einem erneuten Status
abgeleitet, nicht aus `stderr`.

| Zustand | Bedingung | Aktion | Zählt als Problem |
|---|---|---|---|
| `current` | behind = 0, ahead = 0, sauber | nichts | nein |
| `pulled` | behind > 0, Pull erfolgreich | — | nein |
| `fetch_failed` | Fetch schlug fehl | übersprungen, Ursache = stderr | **ja** |
| `no_upstream` | kein `branch.upstream` | nichts pullbar | **ja** |
| `detached` | HEAD detached | nichts pullbar | **ja** |
| `diverged` | ahead > 0 und behind > 0 | kein ff möglich | **ja** |
| `dirty_blocked` | behind > 0, Pull scheitert, Arbeitsbaum dreckig | nicht ff-bar wegen lokaler Änderungen | **ja** |
| `pull_failed` | behind > 0, Pull scheitert, Ursache sonst unklar | stderr als Detail | **ja** |
| `ahead` | ahead > 0, behind = 0 | nichts zu ziehen; unpushed Commits | Hinweis |
| `dirty` | behind = 0, Änderungen vorhanden | nichts zu ziehen | Hinweis |
| `not_git` / `missing` | Ordner da aber kein Repo / fehlt | — | Hinweis (`missing`: "clone" empfehlen) |

**Wichtige Designentscheidung:** Auch `behind > 0` + dreckiger Arbeitsbaum wird
**trotzdem versucht** zu pullen. `git pull --ff-only` funktioniert bei dreckigem
Baum, solange die Änderungen die einzuziehenden Dateien nicht berühren — das
spart unnötige Probleme. Scheitert er, entscheidet git (nicht wir) und das
Ergebnis landet als `dirty_blocked`.

`ahead` und `dirty` (ohne behind) sind **keine Blocker** für "alle aktuell":
das Repo hat alles, was das Remote hat. Sie erscheinen als Hinweise im Dashboard
(Umschalter, Default: ausgeblendet), damit man sie nicht vergisst, aber sie
verhindern nicht das grüne Endergebnis. → offene Frage Q1.

### 3.4 Triage-Dashboard

Snacks-Picker nach dem Muster von `tasks_dash.lua` (inkl. Fallback auf
`vim.ui.select` ohne snacks.nvim, dann ohne Batch). Eine Zeile pro Problem-Repo:

```
 ✗ diverged       ai.nvim           main  ↑2 ↓3        ...
 ✗ dirty_blocked  filetree.nvim     main  ↓1  ~4 Dateien
 ✗ no_upstream    sandbox.nvim      feat/x
 ⏭ skipped        cmdlog.nvim       (übersprungen)
```

Preview-Pane je Repo: `git status -sb`, `git log --oneline HEAD..@{u}` (was
käme rein), `git log --oneline @{u}..HEAD` (was ginge raus), bei `dirty_blocked`
die Schnittmenge aus lokal geänderten Dateien und `git diff --name-only HEAD..@{u}`
(= genau die Dateien, die den Pull blockieren).

Tasten:

| Taste | Aktion |
|---|---|
| `<CR>` / `L` | **ins Repo gehen**: lazygit für diesen Pfad (`gitsuite.features.ui.lazygit(path)`), nach dem Schließen **automatisch erneut prüfen + Pull erneut versuchen** — gelöste Repos verschwinden aus der Liste |
| `t` | Terminal im Repo-Verzeichnis (Split), ebenfalls mit Re-Check beim Schließen |
| `s` | **Überspringen** (markierte, sonst Zeile unter dem Cursor); Repo bleibt sichtbar als `skipped` |
| `u` | Skip aufheben |
| `r` | Pull für markierte/aktuelle Zeile erneut versuchen (ohne Fetch) |
| `R` | Gesamtlauf erneut (Phase 1–5) |
| `a` | Hinweise (`ahead`/`dirty`) ein-/ausblenden |
| `<Tab>`/`<S-Tab>` | markieren (Snacks-Multiselect) |
| `y` | Pfad yanken |
| `g?` | Hilfe |

Optionale Assist-Aktionen (erst in M5, jeweils mit `confirm.yesno`, die den
exakten Befehl nennt): `diverged` → "rebase auf Upstream" / "merge";
`dirty_blocked` → "stash, pull, stash pop". Standard bleibt: lazygit, weil der
Nutzer ohnehin selbst entscheiden will.

### 3.5 Windows / EDR / Netz

Das Repo dokumentiert, dass der Firmen-EDR jeden `git.exe`-Start scannt und
~116 Fetches das UI 60–90 s einfrieren ließen (siehe `lua/config/lazy/init.lua`,
Kommentar am Checker). Daraus folgt:

- alle Git-Aufrufe **asynchron** über `lib.nvim.git`/`run_argv` (nie
  `run_blocking_*` in der Schleife), UI bleibt bedienbar;
- Fetch-Parallelität begrenzt (`--jobs`, Default 2, Maximum 6), Pull und Status
  sequentiell oder ebenfalls begrenzt;
- `GIT_TERMINAL_PROMPT=0` für alle Aufrufe, sonst hängt ein privates Repo
  (z. B. `my.nvim`) an einer Credential-Abfrage, die in einem Hintergrundjob
  niemand sieht → wird als `fetch_failed` mit Hinweis "Auth" gemeldet;
- Timeout pro Repo (Default 60 s) → `fetch_failed`/`pull_failed` statt Hängen;
- Abbruch: `stop()`-Handles aller laufenden Jobs werden gesammelt; `:MyPlugins
  sync` ein zweites Mal aufrufen während ein Lauf aktiv ist → Nachfrage
  "abbrechen/neu starten" statt zweiter paralleler Lauf.

### 3.6 Zustand & Endmeldung

`stdpath("state")/myplugins_sync.json`: Ergebnis des letzten Laufs (Repo →
Zustand, Detail, `skipped`, Zeitstempel). Zweck:

- `:MyPlugins sync issues` öffnet die Triage-Liste auch nach einem Neustart;
- Skips überleben das Schließen des Dashboards, **aber nicht** den nächsten
  vollständigen Lauf, der sie wieder zur Prüfung stellt (ein Skip gilt für
  *diese* Synchronisation, nicht dauerhaft). Dauerhaftes Ignorieren gehört in
  die Plugin-Liste/`modes`, nicht hierher. → offene Frage Q2.

Beim Schließen des Dashboards (oder wenn keine Probleme existieren) genau
**eine** Abschluss-Notification:

```
Sync: 41 aktuell (7 gepullt), 2 übersprungen: cmdlog.nvim, ai.nvim, 0 ungelöst
```

Ist `ungelöst = 0`, steht dort ausdrücklich "alle Repos aktuell außer den
übersprungenen" — das ist die vom Auftrag verlangte Gewissheit. Ungelöste
Repos bleiben im State und in der Statusline-Anzeige (`new_progress`-Kanal nicht
dafür missbrauchen; stattdessen `:MyPlugins sync issues`-Hinweis in der Notify).

### 3.7 Abgrenzung

- **Remote-Modus** (`OVERRIDE = "remote"` bzw. Rolle `workstation`, siehe
  `plugins/personal/core/source.lua`): es gibt keine lokalen Checkouts, lazy
  verwaltet die Repos über `:Lazy update`. `sync` meldet dann "keine lokalen
  Checkouts im Scope" und beendet sich; es versucht nicht, lazy zu ersetzen.
- **Drittanbieter-Plugins** (lazy-Checkouts unter `stdpath("data")/lazy`): nicht
  im Scope, `sync` arbeitet nur auf `plugins.personal.core.list`.
- **`:MyPlugins update`** bleibt unverändert (schnell, ohne Dashboard);
  `sync` ist die gründliche Variante. Intern teilen beide die Primitive in `ops.lua`.
- **`picker.lua`** bekommt später optional eine Aktion `sync` (M5), keine Änderung am Kern.

## 4. Modul-Layout

Neue Dateien in `lua/bindings/usrcmds/plugin_repos/` (Präfix `sync_`, wie `tasks_*`
für die Task-Routen), `init.lua` bekommt nur die Route:

| Datei | Verantwortung |
|---|---|
| `sync.lua` | Orchestrator Phase 0–5, Progress, Abbruch, Endmeldung |
| `sync_classify.lua` | **reine** Funktionen: `classify(status_record, ctx)`, Sortierung, Zusammenfassung — vollständig testbar ohne Git |
| `sync_state.lua` | Lesen/Schreiben des JSON-State, Skip-Verwaltung |
| `sync_dash.lua` | Triage-Picker (Snacks) + `vim.ui.select`-Fallback, Preview, Keymaps |
| `sync_routes.lua` | Route-Definition (`path = {"sync"}`, `{"sync","issues"}`), Flags/Typen; wird in `init.lua` wie `tasks_routes` per `pcall(require)` geladen, damit ein älteres `lib.nvim` auf der anderen Maschine nur diese Route verliert, nicht ganz `:MyPlugins` |

Erweiterungen an `ops.lua` (nur Primitive, weiterhin ohne notify/progress):
`status_one(path, cb)` (Status-Record via `lib.nvim.git`, Fallback auf
`git status --porcelain=v2 --branch`, falls eine benötigte Funktion in einer
älteren `lib.nvim`-Version fehlt), `changed_files_incoming(path, cb)`,
`fetch_one` mit Timeout/`GIT_TERMINAL_PROMPT=0`-Option.

Typen kommen nach `lua/@types/` bzw. neben die bestehenden `---@class`-Blöcke:
`MyPlugins.SyncRecord { name, path, branch, ahead, behind, dirty, state, detail, skipped }`.

## 5. Meilensteine

**M1 — Klassifizierung (Kern, ohne UI)**
- `sync_classify.lua` mit der Zustandstabelle aus 3.3, `ops.status_one`.
- Unit-Tests der reinen Funktion (Tabellentests für jede Zeile der Zustandstabelle, inkl. Randfälle: kein Upstream + dirty, detached + behind).
- Abnahme: `classify` liefert für alle Tabellenzeilen den erwarteten Zustand; keine Abhängigkeit von git-Meldungstexten.

**M2 — Orchestrator + Endmeldung**
- `sync.lua`: Phasen 0–5, Fetch-Phase mit `--jobs`, Pull nur bei `behind > 0`, Re-Klassifizierung nach Pull-Fehler, eine Abschlussmeldung, `--check`/`--no-fetch`/`--only`.
- Route `:MyPlugins sync` in `init.lua` (guarded über `sync_routes.lua`).
- Abnahme: Lauf über die echte Liste (~45 Repos in `C:\repos`) bleibt bedienbar (UI nicht eingefroren), Summary stimmt mit `git status` je Repo überein; Fehler eines Repos stoppt den Lauf nicht.

**M3 — Integrationstests mit Wegwerf-Repos**
- Fixture-Skript: bare Remote + zwei Klone, erzeugt je einen Fall (behind, ahead, diverged, dirty-aber-pullbar, dirty-blockiert, kein Upstream, detached, nicht erreichbares Remote).
- Test, dass `sync` jeden Fall korrekt einordnet und die ff-bare Teilmenge wirklich zieht.
- Abnahme: alle Fälle grün; läuft unter Windows (Pfade, `git.exe`).

**M4 — Triage-Dashboard + State**
- `sync_dash.lua` (Liste, Preview, Tasten aus 3.4 außer Assist-Aktionen), `sync_state.lua`, `:MyPlugins sync issues`.
- Lazygit/Terminal mit automatischem Re-Check beim Schließen; Skip/Unskip; Endmeldung beim Schließen.
- Abnahme: Problemrepo lösen in lazygit → Zeile verschwindet ohne Neustart des Laufs; Skip → Endmeldung nennt es namentlich; Neustart + `sync issues` stellt die Liste wieder her.

**M5 — Politur & Assist**
- Optionale Aktionen (rebase/merge/stash-pull-pop) mit Bestätigungsdialog, Picker-Aktion `sync`, Statusline-Hinweis bei ungelösten Repos.
- Docs: Abschnitt `:MyPlugins sync` in `plugin_repos/README.md` (inkl. Zustandstabelle und Tastenübersicht), `:help`-Datei falls vorhanden, Hinweis auf den Zwei-Maschinen-Workflow.
- Abnahme: README/Help vollständig, `:MyPlugins` Completion kennt `sync`, `sync issues` und alle Flags.

## 6. Risiken & Gegenmaßnahmen

| Risiko | Gegenmaßnahme |
|---|---|
| EDR bremst viele `git.exe`-Starts, UI wirkt hängend | async, begrenzte Parallelität, Progress in der Statusline, Timeout (3.5) |
| Credential-Prompt hängt unsichtbar (privates `my.nvim`) | `GIT_TERMINAL_PROMPT=0`, Klassifizierung als `fetch_failed` mit Auth-Hinweis |
| Pull verändert ein Repo, in dem gerade ein Buffer offen ist | Nach erfolgreichem Pull `:checktime` für betroffene Buffer; Hinweis in der Summary |
| Meldungs-Parsing bricht bei anderem `LANGUAGE`/Git-Version | Nur strukturelle Auswertung (Status-Record, HEAD vorher/nachher), nie `stderr`-Text |
| Eine ältere `lib.nvim`-Version auf der anderen Maschine hat die benötigten Status-Funktionen nicht | `pcall(require)`-Guard wie bei `tasks_routes`, Fallback in `ops.status_one`, sonst klare Meldung "lib.nvim aktualisieren" (`:MyPlugins update` reicht dafür) |
| Doppelstart von `sync` | Laufzustand im Modul, zweiter Aufruf fragt nach (3.5) |
| Assist-Aktionen zerstören lokale Arbeit | Standard ist lazygit; Assist nur mit Bestätigung, die den exakten Befehl zeigt, und nie `reset --hard`/`clean` |

## 7. Offene Fragen an dich

- **Q1:** Soll `ahead` (nur lokale, ungepushte Commits) und `dirty` (nur
  uncommittete Änderungen, nichts einzuziehen) als **Problem** gelten oder nur
  als Hinweis? Vorschlag: Hinweis — "aktuell" heißt "hat alles, was das Remote
  hat". Das ändert nur die Endaussage, nicht die Mechanik.
- **Q2:** Soll ein **Skip dauerhaft** (bis du ihn aufhebst) oder nur für die
  laufende Synchronisation gelten? Vorschlag: nur für den Lauf, beim nächsten
  `sync` kommt das Repo wieder zur Prüfung.
- **Q3:** Reicht lazygit als "ins Repo hineingehen", oder willst du zusätzlich
  einen schlanken eingebauten Weg (z. B. `:Git`-Status-Buffer von gitsuite)?
  Vorschlag: lazygit + Terminal-Split.
- **Q4:** Fetch-Parallelität Default 2 — ok, oder lieber strikt sequentiell wie
  `update` heute?
- **Q5:** `--check` als eigener Flag, oder reicht `--dry-run` für Konsistenz mit
  `clone`/`reclone`? Vorschlag: nur `--dry-run`.

## 8. Reihenfolge-Empfehlung

M1 → M2 liefert bereits den größten Teil des Nutzens (vollständiger Lauf,
Klassifizierung, eine klare Endmeldung mit den Problemfällen als Liste in der
Notification). M3 sichert das ab, M4 macht daraus das gewünschte Dashboard,
M5 ist Komfort. Schätzung grob: M1–M2 ein Arbeitsblock, M3 halber, M4 ein
bis anderthalb, M5 nach Bedarf.
