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
- [Folgesession 2026-09-15: Phase 2 + 3 + 4 in einem Rutsch](#folgesession-2026-09-15-phase-2--3--4-in-einem-rutsch)
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

Noch nicht begonnen — einzige offene Phase. Details:
`wkdbook-myplugins/data.nvim/ROADMAP/ROADMAP.md`.

### Phase 2 — YAML ✅ 2026-09-15 (Folgesession)

`:YAML pretty/lines/keys/sort` (kein `compact`). `lib.lua.yaml.encode` +
gemeinsamer Null-Sentinel `lib.lua.null` neu in `lib.nvim` (`836c6ca`).
`data.nvim` Commit `5bb2e39`.

### Phase 3 — XML ✅ 2026-09-15 (Folgesession)

`:XML` mit allen fünf Actions. `lib.lua.xml` (Decode+Encode, reiner Baum
`{tag,attrs,children}`) neu in `lib.nvim` (`23b606c`). `data.nvim` Commit
`27b31e3`.

### Phase 4 — Ökosystem ✅ 2026-09-15 (Folgesession, mit 2 Abweichungen)

`:JSON ndjson`, `:JSON to yaml`/`:YAML to json`, Fenced-Scope-Integration —
letztere über `color_my_ascii.fences` statt `markdown.nvim` (robuster,
Language-agnostisch). `diff.nvim`-Vorher/Nachher **nicht** umgesetzt, hängt
an Phase 1s `filter`. `data.nvim` Commit `32ad422`.

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

## Folgesession 2026-09-15: Phase 2 + 3 + 4 in einem Rutsch

Nutzerwunsch: alle drei verbleibenden Phasen außer Phase 1 (Register-Scope +
Filter, bewusst abgewählt) in einer Session, hintereinander, mit
Kurzmeldung nach jeder Phase.

**lib.nvim-Erweiterungen (alle mit Tests, luacheck/stylua grün, headless
`TESTS/run.lua` grün):**

- `lib.lua.null` (neu) — ein gemeinsamer Null-Sentinel für alle
  `lib.lua.*`-Formatmodule, weil echtes Lua-`nil` nicht als Tabellenwert
  gespeichert werden kann. `lib.nvim.json.decode` normalisiert
  `vim.json.decode`s eigenes `vim.NIL` jetzt rekursiv darauf.
- **Echter Bug gefunden und gefixt (nicht nur diese Session betreffend,
  sondern ein Phase-0-Altfehler):** `lib.lua.json.encode` konnte einen
  dekodierten JSON-`null`-Wert nicht zurück-encodieren (Fehler „cannot
  encode value of type 'userdata'"), weil `vim.NIL` (userdata) nie
  behandelt wurde. Durch die `lib.lua.null`-Normalisierung behoben —
  betraf potenziell auch `:JSON pretty`/`compact`/`sort` auf jedem Input
  mit `null`-Werten, nicht nur die neuen Phasen.
- `lib.lua.yaml.encode` (neu) — Gegenstück zu `simple_parse`, gegen den
  Decoder zurück-geprüft (encode→decode-Round-Trip in den Tests, nicht nur
  Sichtprüfung). Mehrschlüssel-Listeneinträge über die
  bare-`-`-plus-Block-Form (Decoder-Limit: `- a: 1` liest nur einen Key).
- `lib.lua.xml` (neu, Decode+Encode) — reiner Baum
  `{tag, attrs, children}`, bewusst keine JSON-artige Objektifizierung
  (mehrdeutig ohne Schema). Deckt Attribute, Self-Closing-Tags,
  verschachtelte Elemente, CDATA (literal), Kommentare (verworfen), die
  fünf vordefinierten Entities + numerische/hex Zeichenreferenzen, sowie
  eine führende `<?xml ...?>`-Deklaration ab. `encode` ist wie
  `lib.lua.json.encode` standardmäßig kompakt (einzeilig), `.pretty`/
  `opts.indent` für mehrzeilig.
- Commits: `379fa81` (Phase 0, `path_flatten`), `836c6ca` (`null`+
  `yaml.encode`+JSON-Null-Fix), `23b606c` (`xml`).

**data.nvim:**

- **Phase 2:** `data/format/yaml.lua`, `:YAML`-Verb (ohne `compact`).
  `bindings/usrcmds.lua` auf eine gemeinsame Routen-Fabrik (`make_routes`/
  `make_verb`) umgebaut statt Routen-Tabellen zu duplizieren.
  **Nebenbei ein zweiter echter Bug gefixt:** `config.json.indent`/`sep`
  wurden gemerged und typisiert, aber von `data.run()` nie tatsächlich
  gelesen — ein gesetztes `json.indent` hatte still keine Wirkung, außer
  bei jedem Aufruf explizit wiederholt. `data.run()` fällt jetzt auf
  `config.get(fmt)` zurück, wenn ein Args/Flag-Wert fehlt.
- **Phase 3:** `data/format/xml.lua`, `:XML`-Verb (alle fünf Actions,
  `compact` inklusive — anders als YAML hat XML kein Flow-Style-Problem).
  `lines`/`keys` flatten den rohen Elementbaum (`children.1.attrs.id`),
  keine JSON-artige Zusammenfassung — bewusst dokumentiert in
  `docs/architecture.md`.
- **Phase 4:**
  - `:JSON ndjson [indent]` — jede Zeile einzeln dekodiert/pretty-printet,
    eine nicht dekodierbare Zeile bleibt unverändert (keine
    Abbruch-Semantik übers ganze Scope), eine einzelne Sammel-Warnung am
    Ende.
  - `:JSON to yaml` / `:YAML to json` (`data.convert`) — dekodiert mit dem
    einen Format, rendert mit dem anderen. **Bewusst nicht** für XML
    verdrahtet (siehe `docs/architecture.md`: kein eindeutiges Mapping
    XML↔Objekt ohne Schema).
  - Fenced-Scope: `data/scope/resolve.lua` fragt (per `pcall`) nach, ob
    `color_my_ascii.fences.block_at(bufnr, row, {lang=...})` einen
    passenden ` ```json `/` ```yaml `/` ```xml `-Block um den Cursor kennt,
    wenn kein Range gegeben ist — **Abweichung vom Plan:** ursprünglich war
    `markdown.nvim`s Fenced-Scope-Feature vorgesehen, das aber nur
    verschachtelte *Markdown*-Blöcke behandelt; `color_my_ascii.fences` ist
    die tatsächliche, sprachagnostische Quelle (die `markdown.nvim` intern
    selbst nutzt). Rein additiv: kein `color_my_ascii`, kein passender
    Fence, oder `fenced_scope.enable = false` fallen alle auf das
    bisherige Ganzer-Buffer-Verhalten zurück.
  - `diff.nvim`-Vorher/Nachher **nicht** umgesetzt — hängt an `:JSON
    filter` aus Phase 1, die nicht Teil dieser Runde war.
- Commits: `5bb2e39` (Phase 2), `27b31e3` (Phase 3), `32ad422` (Phase 4).
- Tests: von 23 auf 76 Specs gewachsen (`format_yaml_spec.lua`,
  `format_xml_spec.lua`, erweiterte `usrcmds_spec.lua`/
  `scope_resolve_spec.lua`/`config_spec.lua`), alle grün über
  `scripts/test.sh`. Die Fenced-Scope-Tests erkennen `color_my_ascii`
  automatisch als Sibling-Checkout (`E:\repos\color_my_ascii.nvim`) und
  überspringen sich selbst (0 `it`s registriert), wenn es fehlt — kein
  Hard-Fail bei fehlender optionaler Abhängigkeit.
- Doku: README, alle `docs/*.md`, `doc/data.txt`, `docs/BINDINGS.md` nach
  jeder Phase synchron mitgezogen (inkl. neuer `docs/integrations.md` für
  die color_my_ascii-Integration).
- Wkdbook-ROADMAP aktualisiert (`WKDBooks` Commit `3a9ca95`): Phase 2/3/4
  als erledigt ersatzlos entfernt, Phase 1 + offene Fragen bleiben.

## Offene Punkte / nächste Schritte

1. Phase 1 (Register-Scope + Filter) ist die einzige verbleibende Phase,
   siehe `wkdbook-myplugins/data.nvim/ROADMAP/ROADMAP.md`. `diff.nvim`s
   Vorher/Nachher-Integration hängt direkt daran.
2. Kein CI-Workflow angelegt (kein `NEW-*`-Zwang dafür) — bei Bedarf
   `ci-fleet-conventions` (stylua v2.5.2, luacheck 1.2.0, `checkout@v5`)
   übernehmen, wenn das Repo eines bekommen soll.
