# data.nvim — Implementierungsplan & Handover

> Ausnahme-Standort: normalerweise leben Plugin-Roadmaps im Wkdbook
> (`wkdbook-myplugins/<plugin>/ROADMAP/ROADMAP.md`, siehe `NEW-14`). Diese
> Datei hier ist explizit angefordert als laufende Handover-Akte für die
> *Neuanlage* von `data.nvim` und bleibt an diesem Ort
> (`nvim/docs/ROADMAP/handovers/`), nicht im Wkdbook. Der reguläre
> Aufgaben-Backlog liegt trotzdem zusätzlich in
> `wkdbook-myplugins/data.nvim/ROADMAP/ROADMAP.md` (Phase 1–4) — diese Datei
> hier ist die Session-Chronik, jene der Backlog.

## Table of content

- [Regeln für diese Session](#regeln-für-diese-session)
- [Orte](#orte)
- [Konzept-Quelle](#konzept-quelle)
- [Phasenplan](#phasenplan)
  - [Phase 0 — MVP (JSON only) ✅ 2026-09-15](#phase-0--mvp-json-only--2026-09-15)
  - [Phase 1 — Register-Scope + Filter](#phase-1--register-scope--filter)
  - [Phase 2 — YAML](#phase-2--yaml)
  - [Phase 3 — XML](#phase-3--xml)
  - [Phase 4 — Ökosystem](#phase-4--ökosystem)
- [Was real gebaut wurde (Phase 0, verifiziert, nicht nur behauptet)](#was-real-gebaut-wurde-phase-0-verifiziert-nicht-nur-behauptet)
- [Ein echter Bug unterwegs gefunden + gefixt](#ein-echter-bug-unterwegs-gefunden--gefixt)
- [Offene Punkte / nächste Schritte](#offene-punkte--nächste-schritte)

---

## Regeln für diese Session

- Nie mehr als 1 Agent gleichzeitig; bei Bedarf mehrere Runden á 1 Agent, repo-für-repo.
- Antworten Deutsch, Quellcode (inkl. Kommentare) Englisch.
- Keine Co-Autorenschaft von Claude in Commits.
- Nach jedem fertigen Schritt: committen/pushen, main bleibt aktuell.
- `TOOL-PLACEMENT.md` / `HEREDOC.md` beachten, falls Nebenbei-Tooling entsteht.
- Code muss luacheck/stylua-grün sein.
- `gates/NEW_PROJECT.md` (`NEW-01`…`NEW-50`) ist die Checkliste für den
  Erstaufbau, `regeln/PRINCIPLES.md` §1 für den Zuschnitt — beide vor dem
  ersten Commit gelesen.
- `lib.nvim` ist Pflicht-Dependency (`NEW-16`), Eigenbauten werden nach
  Möglichkeit nach `lib.nvim` verschoben statt lokal dupliziert (`NEW-17`,
  `NEW-18`).
- Plugin-Installations-Specs: `vim.fn.stdpath('config')/lua/plugins/personal/init.lua`.

## Orte

| Was | Wo |
| --- | --- |
| Öffentliches Repo | `E:\repos\data.nvim`, GitHub `stefanbartl/data.nvim`, Branch `main` |
| Backlog (Phase 1–4, offene Fragen) | `wkdbook-myplugins/data.nvim/ROADMAP/ROADMAP.md` |
| Ursprüngliches Konzept | `nvim/docs/ROADMAP/LONG_RUN/IDEAS/data.nvim.md` (bleibt dort, kein Duplikat) |
| Neue lib.nvim-Erweiterung | `lib.nvim/lua/lib/lua/tables/paths.lua` → `tables.path_flatten` |
| Diese Handover-Datei | `nvim/docs/ROADMAP/handovers/data/data.nvim.md` |

## Konzept-Quelle

Die vollständige Problem-/Architektur-Analyse (Ist-Zustand, Modulbaum, IR,
Feature-Brainstorm, Phasen, Risiken) steht in
`nvim/docs/ROADMAP/LONG_RUN/IDEAS/data.nvim.md` und wird hier nicht
dupliziert — diese Datei verweist nur darauf und protokolliert, was daraus
real umgesetzt wurde.

## Phasenplan

### Phase 0 — MVP (JSON only) ✅ 2026-09-15

- `lib.lua.tables.flatten` als **`lib.lua.tables.path_flatten`** gebaut
  (Kollision mit dem bestehenden `tables.flatten` = Array-Flatten vermieden,
  siehe `lib.nvim`s eigenes `README.md`-Update). Neue Datei
  `lib.nvim/lua/lib/lua/tables/paths.lua`, Tests in `TESTS/lua_helpers_spec.lua`
  ergänzt, `lib.nvim` Commit `379fa81`.
- `data.nvim`-Repo angelegt (öffentlich, GitHub `stefanbartl/data.nvim`,
  Default-Branch `main`).
- `:JSON pretty/compact/lines/keys/sort`, Scope Buffer + Selektion
  (`data/scope/resolve.lua`), `:checkhealth data`, README/vimdoc/`BINDINGS.md`.
- `data.nvim` Commit `f4de1de` (root commit, 39 Dateien).

### Phase 1 — Register-Scope + Filter

Noch nicht begonnen. Details: `wkdbook-myplugins/data.nvim/ROADMAP/ROADMAP.md`.

### Phase 2 — YAML

Noch nicht begonnen — braucht zuerst `lib.lua.yaml.encode` in `lib.nvim`.

### Phase 3 — XML

Noch nicht begonnen — braucht `lib.lua.xml` (Decode + Encode) in `lib.nvim`,
existiert aktuell gar nicht.

### Phase 4 — Ökosystem

Noch nicht begonnen.

## Was real gebaut wurde (Phase 0, verifiziert, nicht nur behauptet)

- **lib.nvim:** `lua/lib/lua/tables/paths.lua` (`M.flatten`), aggregiert als
  `tables.path_flatten` in `tables/init.lua`, Typen in `@types/paths.lua` +
  `@types/init.lua`, README-Abschnitt ergänzt. Tests in
  `TESTS/lua_helpers_spec.lua` (sortierte Keys, Array-Indizes, custom `sep`,
  leere verschachtelte Tabelle als eigenes Blatt, `max_depth`-Guard) —
  headless mit `nvim --headless -u NONE -c "set rtp+=." -c "luafile TESTS/run.lua"`
  laufen lassen, alle grün (`LIB_TESTS_OK`). `luacheck`/`stylua --check` grün.
- **data.nvim:** Module `config` (DEFAULTS/init, `lib.lua.config`-basiert),
  `scope.resolve` (Range→0-based Zeilenspanne), `format.json` (dünner Adapter
  auf `lib.nvim.json` + `lib.lua.json.encode` + `tables.path_flatten`),
  `format` (Registry), `init` (Facade `run()`/`setup()`), `bindings.usrcmds`
  (`:JSON`-Verb über `composer`), `bindings.keymaps`/`autocmds` (bewusst leer,
  `NEW-08` erfüllt), `health`.
- **Tests:** `TESTS/config_spec.lua`, `scope_resolve_spec.lua`,
  `format_json_spec.lua`, `usrcmds_spec.lua` — 23 Specs, alle grün via
  `scripts/test.sh` (Plenary, `LIB_NVIM_DIR`/`PLENARY_DIR` auf lokale
  Checkouts gesetzt). `luacheck lua TESTS` und `stylua --check` beide grün.
- **Doku:** `README.md` (Fassung-3-Konvention: nur Documentation+License),
  `docs/{README,requirements,installation,quickstart,what-you-get,
  configuration,commands,scope,architecture,health,CONTRIBUTING,BINDINGS}.md`,
  `doc/data.txt` (vimdoc, `:helptags` fehlerfrei geprüft).

## Ein echter Bug unterwegs gefunden + gefixt

`data.run()`s eigene `notify.error(...)`-Aufrufe liefen **synchron** im
Callback des `:JSON`-Usercommands. Das ist exakt die Falle, die
`lib.nvim.bindings.usercmd.composer`s eigener Code schon dokumentiert
(`make_deferred_notify`): `vim.notify` auf ERROR-Level landet letztlich bei
`nvim_err_writeln`, und synchron aus einem per `vim.cmd()`/`nvim_exec2()`
aufgerufenen Usercommand-Handler heraus schlägt das als roher `Vim:...`-Fehler
beim *Aufrufer* durch statt als saubere Notification anzukommen — sichtbar
geworden durch einen fehlschlagenden Test (`usrcmds_spec.lua`, "malformed
JSON leaves the buffer untouched"). Fix: `data/init.lua`s eigener
`notify`-Wrapper deferred `error`/`warn` jetzt genauso über `vim.schedule`,
mit Kommentar, der auf die Composer-Vorlage verweist. Nach dem Fix: 23/23
Tests grün.

## Offene Punkte / nächste Schritte

1. `nvim-config/lua/plugins/personal/init.lua`: `data.nvim`-Spec ergänzen
   (Nutzerwunsch, mitten in dieser Session gestellt) — als eigener
   Arbeitsschritt direkt im Anschluss an diese Handover-Notiz.
2. Phase 1 (Register-Scope + Filter) ist der nächste inhaltliche Schritt,
   siehe `wkdbook-myplugins/data.nvim/ROADMAP/ROADMAP.md`.
3. Kein CI-Workflow angelegt (kein `NEW-*`-Zwang dafür) — bei Bedarf
   `ci-fleet-conventions` (stylua v2.5.2, luacheck 1.2.0, `checkout@v5`)
   übernehmen, wenn das Repo eines bekommen soll.
