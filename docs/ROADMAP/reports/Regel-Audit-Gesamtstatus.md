# Regel-Audit — Gesamtstatus

> Stand: 2026-09-19. Dieses Dokument ersetzt die drei separaten Reports
> `Regel-Audit-rules-nvim.md` (ursprünglicher Audit, 2026-09-18),
> `Regel-Audit-Befunde.md` (vollständige 497-Befundliste samt zwei
> Regressions-Nachträgen) und `Regel-Audit-Offene-Punkte.md`
> (Bearbeitungsstand nach der ersten Fix-Runde) — als eine kondensierte
> Zusammenfassung statt drei wachsender Einzeldokumente. Die 497
> Einzelbefunde selbst (Datei, Zeile, Befund-/Regelbezug-/Auswirkungstext,
> Status) sind hier NICHT wortwörtlich übernommen, nur zu Tabellen und
> Mustern verdichtet — wer einen einzelnen historischen Befund im Volltext
> braucht, findet ihn nur noch in der Git-Historie dieses Verzeichnisses.

## Table of content

  - [Kurzfassung](#kurzfassung)
  - [Teil 1 — Ursprünglicher Audit (2026-09-18): Methode und automatische Regeln](#teil-1--ursprnglicher-audit-2026-09-18-methode-und-automatische-regeln)
  - [Teil 2 — Die 497-Befund-Kampagne](#teil-2--die-497-befund-kampagne)
  - [Teil 3 — Zwei Regressions-Nachträge](#teil-3--zwei-regressions-nachtrge)
  - [Teil 4 — Bemerkenswerte Einzelbefunde](#teil-4--bemerkenswerte-einzelbefunde)
  - [Teil 5 — Aktueller Stand der vier offenen Baustellen](#teil-5--aktueller-stand-der-vier-offenen-baustellen)
  - [Empfehlung für die nächste Runde](#empfehlung-fr-die-nchste-runde)

---

## Kurzfassung

Ein Audit aller 38 `.nvim`-Repos gegen den vollständigen `rules.nvim`-Regelkatalog
(421 Regeln, 13 Familien) lief am 2026-09-18/19 in mehreren Runden:

1. **Automatische Regeln** (32 von 421, alle 38 Repos): 66 Rohtreffer, davon nur
   **10 echt** — der Rest waren sechs konkrete Defekte in den Checks selbst
   (mittlerweile alle gefixt) plus ein `rules.nvim`-eigener Bug (Worktrees wurden
   mitgescannt, ebenfalls gefixt).
2. **Manuelle `critical`-Regeln** (76 von 111, alle 38 Repos): 541 Rohbefunde,
   **497 bestätigt** nach adversarialer Gegenprüfung, **alle 497 gefixt** (davon
   483 mit Commit, 14 beim Nachlesen bereits sauber, 0 bewusst offen gelassen —
   die anfänglich 8 zurückgestellten Architekturentscheidungen wurden noch am
   selben Tag in einer zweiten Runde entschieden und umgesetzt).
3. **Zwei Regressions-Nachträge**: eine erste Runde prüfte die ersten fünf
   Fix-Batches auf selbst eingeführte Bugs (6 gefunden, alle gefixt); eine
   zweite, größere Runde prüfte **jeden Commit der gesamten Session** über alle
   38 Repos (34 Kandidaten, 31 bestätigt, **23 Repos** betroffen, alle gefixt).
4. **Vier Baustellen aus dem ursprünglichen Audit** sind danach separat
   angegangen worden — Stand siehe [Teil 5](#teil-5--aktueller-stand-der-vier-offenen-baustellen):
   `ERR-11` (fast fertig), `LUA-01` (fertig, drei kleine Nacharbeiten aus dem
   adversarialen Verify), `ERR-50`/`ERR-22` (noch nicht begonnen), die 313
   ungeprüften `recommended`/`nice-to-have`-Regeln (noch nicht begonnen).

Zahlenbasis des Gesamt-Audits: 421 Regeln, 38 Repos, ~390.000 LOC Lua.

---

## Teil 1 — Ursprünglicher Audit (2026-09-18): Methode und automatische Regeln

Lauf über alle 38 Repos gegen den vollständigen Regelkatalog aus
`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists`, über die programmatische
API von `rules.nvim` (`check_family_json`) für automatisierbare Regeln, plus eine
Agent-Runde für den Rest.

### Regelkatalog nach Familie

| Familie | gesamt | automatisiert | manuell | davon critical |
|---|---:|---:|---:|---:|
| PERF | 64 | 0 | 64 | 10 |
| LUA | 59 | 1 | 58 | 14 |
| NEW | 50 | 14 | 36 | 18 |
| UI | 41 | 1 | 40 | 4 |
| LLS | 37 | 0 | 37 | 1 |
| PRIN | 37 | 0 | 37 | 6 |
| ERR | 35 | 0 | 35 | 16 |
| REL | 34 | 8 | 26 | 15 |
| SEC | 29 | 2 | 27 | 18 |
| CMT | 16 | 0 | 16 | 1 |
| DEP | 7 | 6 | 1 | 0 |
| XP | 7 | 0 | 7 | 7 |
| TS | 5 | 0 | 5 | 1 |
| **Summe** | **421** | **32** | **389** | **111** |

389 der 421 Regeln haben per Design keinen automatischen Verdict — der Katalog
ist zum ganz überwiegenden Teil Handarbeit.

### Automatische Regeln: 66 Treffer, 10 echte

| Regel | Severity | Repos | echt | Rauschen |
|---|---|---:|---:|---:|
| `NEW-49` | recommended | 26 | 0 | 26 |
| `NEW-08` | recommended | 15 | 8 | 7 |
| `NEW-45` | recommended | 7 | 0 | 7 |
| `DEP-01` | recommended | 6 | 0 | 6 |
| `SEC-01` | critical | 5 | 0 | 5 |
| `DEP-02` | recommended | 3 | 0 | 3 |
| `REL-29` | critical | 2 | 2 | 0 |
| `NEW-48` | critical | 2 | 0 | 2 |
| **Summe** | | **66** | **10** | **56** |

Bemerkenswert: jeder einzelne `critical`-Treffer außer `REL-29` war ein
Fehlalarm. Ursache: sechs konkrete Defekte im Ruleset selbst (`NEW-49` prüfte
nicht, ob ein Repo überhaupt busted-Syntax nutzt; `NEW-45` kannte nur
`stylua.toml`, nicht `.stylua.toml`; `NEW-08` übersah die Verzeichnisform und
`usercmds.lua`; `NEW-48` prüfte den Dateinamen statt den Inhalt; `DEP-01`s
`unless`-Klausel matchte nur wörtlich; `SEC-01`/`DEP-02` fehlte jeder Kontext
für Testcode/Fixtures/gegatete Fallbacks). **Alle sechs sind inzwischen
gefixt** (siehe rules.nvim-Commits vom 2026-09-18/19: neue Engine-Primitiven
`excludes`/`paths`, vier `.rules-waivers.json`-Dateien für die Fälle, die kein
Check je richtig erkennen kann).

Separat gefunden und gefixt: `rules.nvim`s `fswalk.lua` scannte
`.claude/worktrees/` mit (`SKIP_DIRS` kannte nur `.git`/`.deps`) — bei
`documentation.nvim` machte das aus 17 echten `SEC-01`-Treffern 68 gemeldete.
Eine Zeile Fix, seither behoben.

### Die fünf systematischen Muster des Original-Audits

Fünf Regeln erklärten 173 der ursprünglich identifizierten Befunde — keine 173
Einzelfehler, sondern fünf sich fleet-weit wiederholende Gewohnheiten:

1. **`SEC-34`** (21 Repos, 37 Stellen) — `vim.fn.expand()` auf Nutzertext wertet
   Backtick-Spans über `&shell` aus. Ersatz `lib.nvim.cross.fs.expand_path`
   existierte schon und wurde von 15/38 Repos bereits genutzt — reiner
   Rollout-Rückstand. **Inzwischen in 7+ weiteren Repos nachgezogen.**
2. **`ERR-11`** (30 Repos, 52 Stellen) — „leer, weil nichts da" ≠ „leer, weil
   kaputt". Dieselbe Denkfigur wie beim 32-Repo-Sweep vom 2026-09-07. **Siehe
   Teil 5** für den aktuellen Fix-Stand.
3. **`LUA-01`/`ERR-50`/`ERR-22`** (21/24/22 Repos) — optionale Abhängigkeiten
   und Config-Validierung. **Siehe Teil 5.**
4. **`ERR-01`/`ERR-03`** (20/17 Repos) — fehlende `pcall`s an Systemgrenzen,
   nicht geprüfte Exit-Codes. Größtenteils im Rahmen der 497er-Kampagne
   mitgefixt (siehe Teil 2).
5. **`XP-01`** (9 Repos, 12 Stellen) — roher Pfad als Glob-Pattern. Ersatz
   `lib.nvim.fs.globbable` existierte schon.

---

## Teil 2 — Die 497-Befund-Kampagne

Für die 389 Regeln ohne automatischen Verdict: pro Plugin ein Agent, der jeden
Befund mit Datei und Zeile belegt, danach ein zweiter Agent, der jeden Befund
zu **widerlegen** versucht (typischerweise durch empirisches Nachstellen in
headless Neovim). Workflow mit 76 Agents (38 Audits, 38 Gegenprüfungen).

- **541 Rohbefunde → 497 bestätigt** (44 widerlegt, 8%).
- 252 `confidence: high`, 233 `medium`, 12 `low`. 486 Produktionscode, 11 Testcode.
- 38 von 38 Plugins hatten mindestens einen Befund — keines war sauber.
- **Umsetzung: 497/497 abgeschlossen** (2026-09-19) — 483 gefixt mit Commit, 14
  beim Nachlesen bereits sauber vorgefunden, 0 bewusst offen gelassen (die
  anfänglich 8 zurückgestellten Architekturentscheidungen wurden noch am
  selben Tag in einer zweiten, zweistufigen Runde entschieden und umgesetzt —
  siehe zwei Beispiele am Ende dieses Teils).

### Verteilung nach Familie

| Familie | Befunde | Anteil |
|---|---:|---:|
| ERR — Fehlerbehandlung & Rückgabewerte | 259 | 52% |
| SEC — Sicherheit | 77 | 15% |
| LUA — Lua/Neovim-Fallstricke | 61 | 12% |
| PERF — Performance | 36 | 7% |
| PRIN — Prinzipien | 21 | 4% |
| LLS — LuaLS-Diagnosen | 21 | 4% |
| XP — Cross-Platform | 15 | 3% |
| UI — Oberfläche | 7 | 1% |

### Häufigste Regel-IDs (Top 15 von 497 Einzelbefunden)

| Regel | Anzahl | Typisches Fehlermuster |
|---|---:|---|
| `ERR-11` | 52 | „Nichts zu melden" kollabiert mit „Fehler beim Ermitteln" — Rückgabe `""`/`{}`/`nil` für beide Fälle. |
| `SEC-34` | 37 | Buffer-/Nutzertext direkt in `vim.fn.expand()`. |
| `ERR-01` | 32 | Fehlendes `pcall()` um eine Systemgrenze (Subprozess, Dateisystem), die werfen kann. |
| `ERR-03` | 27 | „Äußerer Call warf nicht" wird mit „Operation erfolgreich" verwechselt, ohne Exit-Code/Rückgabewert zu prüfen. |
| `ERR-22` | 26 | Ein ungültiger einzelner Config-Wert wird unverändert verwendet statt auf den Default zu degradieren. |
| `LUA-01` | 25 | Harte Abhängigkeit wird als optional dokumentiert/gemeldet oder umgekehrt. |
| `ERR-50` | 24 | Config-Validierung (unbekannte Keys) passiert nach oder gar nicht vor dem Merge. |
| `LLS-31` | 21 | Ein `pcall`/Erfolgs-Return basiert auf geplanter statt verifizierter Arbeit. |
| `ERR-10` | 21 | „Kein Argument" und „ungültiges Argument" werden verwechselt. |
| `ERR-02` | 20 | Fehlende Typ-/Nil-Prüfung vor Nutzung eines Werts. |
| `ERR-30` | 15 | Ein Plan (Rename, Edit) wird ohne erneute Prüfung des aktuellen Zustands zurückgeschrieben — Risiko stillen Datenverlusts. |
| `PERF-46` | 13 | Ein Cache-Key lässt einen ergebnisrelevanten Parameter aus. |
| `ERR-54` | 13 | Ein öffentlicher Getter gibt geteilten State per Referenz zurück, ohne Mutations-Vertrag. |
| `XP-01` | 12 | `vim.fn.glob`/`globpath` behandeln ihr Argument als Pattern statt als Literal. |
| `SEC-33` | 12 | Eine persistierte JSON-Datei wird beim Laden ungeprüft als vertrauenswürdig behandelt. |

(Längerer Schwanz mit abnehmender Häufigkeit: `LUA-87`=12, `PRIN-25`=9,
`LUA-16`=9, `PRIN-20`=8, `PERF-42`=8, `ERR-60`=7, `ERR-33`=7, `PERF-93`=6,
`ERR-51`=6, `SEC-30`=5, danach Einzelfälle bis hinunter zu `XP-04`, `UI-53`,
`SEC-45`, `LUA-02`, `ERR-62` u. a.)

### Befunde je Plugin

| Plugin | Befunde | Status | Plugin | Befunde | Status |
|---|---:|---|---|---:|---|
| dap.nvim | 21 | fertig | pickers.nvim | 12 | fertig |
| mdview.nvim | 18 | fertig | runtime-analysis.nvim | 12 | fertig |
| lib.nvim | 17 | fertig | diff.nvim | 11 | fertig |
| replacer.nvim | 17 | fertig | documentation.nvim | 11 | fertig |
| buffer-ctx.nvim | 16 | fertig | emojis.nvim | 11 | fertig |
| insights.nvim | 16 | fertig | fileops.nvim | 11 | fertig |
| language.nvim | 16 | fertig | hover.nvim | 11 | fertig |
| debugging.nvim | 15 | fertig | markdown.nvim | 11 | fertig |
| pdfport.nvim | 15 | fertig | recommender.nvim | 10 | fertig |
| reposcope.nvim | 15 | fertig | rules.nvim | 10 | fertig |
| sandbox.nvim | 15 | fertig | spotlight.nvim | 9 | fertig |
| cascade.nvim | 14 | fertig | my.nvim | 7 | fertig |
| casedesk.nvim | 14 | fertig | data.nvim | 5 | fertig |
| cmdlog.nvim | 14 | fertig | ai.nvim | 13 | fertig |
| color_my_ascii.nvim | 14 | fertig | github_stats.nvim | 13 | fertig |
| media.nvim | 14 | fertig | gopath.nvim | 13 | fertig |
| lsp.nvim | 13 | fertig | open.nvim | 13 | fertig |
| sessions.nvim | 13 | fertig | ui.nvim | 13 | fertig |
| filetree.nvim | 12 | fertig | images.nvim | 12 | fertig |

**Summe: 497 Befunde, 497 fertig (0 offen).**

### Die 8 anfänglich zurückgestellten Architekturentscheidungen

Alle 8 wurden am selben Tag in einer zweiten, zweistufigen Runde (Entscheiden +
Umsetzen, dann unabhängige Gegenprüfung vor dem Push) entschieden. Zwei davon
mit expliziter Begründung im Commit:

- **`dap.nvim`** `adapters/init.lua`: die `adapters`-Config-Option wurde nach
  nvim-dap-Adapternamen statt nach Sprache verschlüsselt — Sprach-Keys wären
  ein separates Follow-up, nicht Teil dieses Audits (`0f7c4ba`).
- **`reposcope.nvim`** `remote.lua`s `SEC-21`-Fix: `max_bytes`/`timeout_ms`
  wurden ergänzt, der zusätzlich implizierte URL-gehashte Re-Fetch-Cache
  bewusst nicht gebaut — eigene Schicht mit eigenen API-Entscheidungen, kein
  Audit-Fix (`8e9a608`).

---

## Teil 3 — Zwei Regressions-Nachträge

**Nachtrag 1** — Regressions-Review der ersten fünf Fix-Runden (`lib.nvim`,
`dap.nvim`, `mdview.nvim`, `replacer.nvim`, `buffer-ctx.nvim`): separate
Multi-Agent-Prüfung (Bugs/Security/Performance, adversarial gegengeprüft) nur
gegen die neuen Diffs. **6 echte Regressionen gefunden, alle gefixt:**

- `lib.nvim` `frecency/init.lua` — ein Leseerfehler beim ersten Laden blockierte
  `flush()` dauerhaft, auch nachdem die Datei wieder lesbar war (`fe1c746`).
- `lib.nvim` `telemetry/fingerprint.lua` — ein dokumentiertes 512-Byte-Digest-
  Fenster war versehentlich auf 64 Byte reduziert (`3050594`).
- `dap.nvim` `configurations/init.lua` — `load_all()` deduplizierte nicht nach
  Alias-Ziel, `javascript`/`typescript` luden dasselbe Modul doppelt (`b6fe1be`).
- `mdview.nvim` `launcher.lua` — ein `%d`-Format auf einem jetzt legitim `nil`en
  Timeout crashte statt zu warnen (`d5bb8b1`).
- `replacer.nvim` `fnames.lua` — der neue `ERR-30`-Check hielt einen reinen
  Case-Rename auf NTFS/APFS für eine echte Kollision (`264cbec`).
- `buffer-ctx.nvim` `templates/guard.lua` — der `vim.fn.input`-Fallback lief
  nach einem abgebrochenen ersten Prompt trotzdem weiter zum zweiten (`9191fbe`).

**Nachtrag 2** — Regressions-Audit über die gesamte Session: nach Abschluss der
497er-Kampagne lief eine zweite, größere Prüfung gegen **jeden Commit dieser
Session, über alle 38 Repos** — Bugs/Security/Performance in einem Durchgang,
jeder Kandidat von 3 unabhängigen Agenten per Mehrheitsentscheid geprüft.
**34 Kandidaten → 31 bestätigt, 23 Repos betroffen, alle gefixt** (zweistufig:
Fix-Agent, dann ein unabhängiger zweiter Agent, der den Diff selbst liest, die
Gates neu laufen lässt und erst danach pusht). 15 Repos ohne überlebenden Fund.
Auswahl bemerkenswerter Funde in [Teil 4](#teil-4--bemerkenswerte-einzelbefunde).

---

## Teil 4 — Bemerkenswerte Einzelbefunde

Eine Auswahl der Funde mit dem größten Impact oder der interessantesten Ursache
(vollständige Liste nur noch in der Git-Historie):

1. **`dap.nvim`** `adapters/init.lua` — die dokumentierte `adapters`-Config-
   Override wurde komplett verworfen; `setup()` gab trotzdem `true` zurück (`0f7c4ba`).
2. **`dap.nvim`** `languages/python.lua` — der Python-DAP-Adapter rief
   `python -m debugpy -m debugpy.adapter` auf (ein Python-Flag an das debugpy-
   CLI verfüttert) — crasht bei jeder echten Mason-Installation; Healthcheck
   meldete trotzdem grün (`cc38a8c`).
3. **`dap.nvim`** `languages/javascript.lua`+`browser.lua` — Adapterpfad prüfte
   die Existenz einer Binary als Gate, verkabelte dann aber einen anderen,
   hartkodierten, ungeprüften Mason-Pfad (`5f94631`).
4. **`dap.nvim`** `utils/validation.lua` `pick_process` — spawnte `ps`
   ungeschützt; ohne `ps` im PATH (z. B. Windows) hängt die gesamte
   Config-Resolution-Coroutine dauerhaft, ohne jeden Fehler (`5f3f359`).
5. **`dap.nvim`** `core/setup.lua` — die `log_level`-Config-Option war komplett
   wirkungslos: akzeptiert, typisiert, dokumentiert, aber nie an
   `dap.set_log_level()` verkabelt (`beeaa34`).
6. **`lib.nvim`** `fs/scan_cached`/`fs/scan_roots` — Cache-Keys ließen
   ergebnisrelevante Parameter aus (`ignore`-Prädikat, `roots`/`kind`) —
   servierte fleet-weit stille Falschantworten.
7. **`lib.nvim`** `disk.lua` (Nachtrag 2) — eine Fehlermeldung behauptete ein
   `.corrupt`-Backup geschrieben zu haben, das nie geschrieben wurde — untergrub
   fleet-weit das Vertrauen in die Datenwiederherstellung (`98ddf12`).
8. **`lib.nvim`** `cache/memory.lua` (Nachtrag 2) — unbegrenztes Wachstum des
   Cache-Namespace für Einweg-Closure-Keys einer fleet-weit genutzten API (`4cd7793`).
9. **`replacer.nvim`** `fnames.lua` — Bulk-Renames wurden ohne erneute Prüfung
   geschrieben, ob das Ziel noch frei ist; `rename()`/`MoveFileEx` überschreibt
   ein existierendes Ziel still (potenzieller stiller Datenverlust).
10. **`language.nvim`** `translate/init.lua` `M.run_region` — übersetzter Text
    wurde ohne erneute Prüfung, ob die erfasste Buffer-Spanne noch den
    Originaltext enthält, zurückgeschrieben; ein `pcall` verschluckte einen
    Out-of-Range-Write zusätzlich stillschweigend.
11. **`insights.nvim`** `ui/scratch.lua` (Nachtrag 2) — ein UI-Fallback zerstörte
    genau den Report-Buffer, aus dem heraus er geöffnet worden war (`0eb88b0`).
12. **`filetree.nvim`** `size_info` (Nachtrag 2) — Cache-Key-Format passte unter
    Windows nie zum eigenen Invalidierungs-Hook, erzwang wiederholte
    Subprozess-Spawns beim normalen Tree-Browsen (`a59c5e5`).
13. **`documentation.nvim`** `standalone/docmap.lua` (Nachtrag 2) — ein früherer
    `SEC-46`-Fix für Windows-Shell-Quoting war für Pfade mit einem einzelnen
    abschließenden Backslash immer noch kaputt (`941ccfd`).
14. **`data.nvim`** `config/init.lua` (Nachtrag 2) — `setup()`s „tiefer" Merge
    war tatsächlich flach und aliasierte unberührte DEFAULTS-Subtabellen bei
    jedem echten `setup()`-Aufruf neu (`cc7664e`).
15. **`reposcope.nvim`** (Nachtrag 2) — einziges Repo der gesamten Kampagne, das
    einen `git push --force-with-lease` brauchte, um 2 Commits mit gebrochener
    Bisektierbarkeit neu zu schneiden — nur nach expliziter Nutzer-Rückfrage.
16. **`rules.nvim`** `checks/init.lua`+`json_key.lua` (Nachtrag 2) — rohe
    mehrzeilige `debug.traceback()`-Strings in `Rules.Finding.text` crashten den
    Report-Renderer — ein Meta-Bug im Tool, das Reports wie diesen erzeugt (`91d238a`).

---

## Teil 5 — Aktueller Stand der vier offenen Baustellen

Nach Abschluss der 497er-Kampagne und beider Regressions-Nachträge blieben aus
dem ursprünglichen Audit vier Baustellen, die bewusst als eigene Runden
zurückgestellt wurden (Verhaltensänderungen mit echtem Urteilsbedarf, keine
mechanische Textersetzung). Stand hier ist live, nicht der vom 2026-09-18.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln" — **24 von 30 Repos geprüft**

Durchgeführt am 2026-09-19 als Multi-Agent-Workflow: pro Repo ein Fix-Agent
(frischer Audit gegen aktuellen Code, dann Fix + lokaler Lint/Test + Push),
danach ein adversarialer Verify-Agent pro Repo. 48 Agents, 0 Fehler, 0
Refutationen.

- **14 Repos mit echten Verstößen**, gefunden/gefixt/gepusht: `ai`,
  `buffer-ctx` (2 Stellen), `cascade`, `casedesk`, `cmdlog`, `insights`, `lib`,
  `markdown`, `my`, `pdfport`, `recommender`, `reposcope` (2 Stellen),
  `runtime-analysis`, `spotlight`.
- **10 Repos bereits sauber**: `dap`, `debugging`, `diff`, `documentation`,
  `github_stats`, `images`, `language`, `lsp`, `replacer`, `rules`.
- **6 Repos noch nicht geprüft** (`fileops`, `filetree`, `hover`, `media`,
  `pickers`, `ui`) — waren beim Start aktiv von einer parallelen Session
  belegt, wurden bewusst ausgeklammert. **Nachtrag empfohlen**, sobald Zeit da
  ist — reine Formsache, dieselbe Methode wie oben.

### `LUA-01` — Hart oder weich, aber konsistent — **21 von 21 Repos geprüft, fertig**

Gleiches Muster wie `ERR-11`, per direktem Agent-Tool-Fan-out (Workflow-Tool
war für diesen Task nicht freigegeben). Alle 21 ursprünglich betroffenen Repos
geprüft, alle 6 echten Funde und alle 15 "nichts gefunden"-Verdikte
adversarial **CONFIRMED** (0 Refutationen).

- **6 echte Funde, gefixt und gepusht**: `cascade` (`c008fff`), `cmdlog`
  (`9450f27`), `color_my_ascii` (`4f95f5f`), `dap` (`c33cb4b` + `c5143e9`
  Nachtrag), `reposcope` (`9d5ca02`), `sessions` (`c110005`).
- **15 Repos bereits sauber**: `buffer-ctx`, `media`, `open`, `pickers`,
  `recommender`, `spotlight`, `emojis`, `fileops`, `filetree`*, `github_stats`,
  `gopath`, `insights`, `markdown`, `pdfport`, `sandbox`*.
- \* Zwei der zunächst als „sauber" gemeldeten Repos hatte der adversariale
  Verify-Durchgang bemängelt (echte, wenn auch kleine Inkonsistenzen
  übersehen) — beide Nachfixes sind inzwischen gelandet: `filetree.nvim`
  (`eae0df5`, `0d1b801` — zwei verbliebene weiche `ui.kit`/`ui.winbar`-Stellen
  trotz sonst fleet-weit hart deklariertem `ui.nvim`; für `ui.winbar` eigens
  gegen ui.nvims Commit-Historie verifiziert, dass keine Versions-Schiefe
  vorliegt) und `sandbox.nvim` (`0d77fe4` — Doku/Code-Widerspruch: `nvzone/menu`
  fällt in Wahrheit auf `ui.kit.menu` zurück statt „auszugehen", Kommentare und
  Vimdoc sagten das Gegenteil, gegen ui.nvims Quellcode nachverifiziert).
  Außerdem ein reiner Vimdoc-Nachtrag bei `fileops.nvim` (`122651e`) — `:help
  fileops` beschrieb noch die alte `vim.ui.select`-Vorabversion. **Damit ist
  `LUA-01` inklusive aller adversarial aufgedeckten Nachfixes vollständig
  abgeschlossen.**

### `ERR-50`/`ERR-22` — Config-Validierung und -Degradierung — **noch nicht begonnen**

`ERR-50` (Validierung unbekannter Keys vor dem Merge) betrifft 24 Repos,
`ERR-22` (Degradierung ungültiger Werte auf den Default) 22 Repos, oft im
selben `config/init.lua`. Bekannte Abweichung von den 2026-09-18-Zahlen:
`ai.nvim`s `ERR-50`-Fund (`DEFAULTS.lua:64`) ist bereits durch eine parallele
Session behoben — die Zahl „24" ist entsprechend mindestens um eins veraltet,
wie bei `ERR-11`/`LUA-01` zu erwarten.

### Die 313 ungeprüften `recommended`/`nice-to-have`-Regeln — **noch nicht begonnen**

Der Katalog hat 421 Regeln, geprüft (manuell) sind bisher nur die 76
`critical`-Regeln der review-relevanten Familien. Die übrigen 313 —
`recommended`/`nice-to-have` plus die `critical`-Regeln der Gate-Familien
NEW/REL außerhalb ihres automatisierten Teils — sind komplett offen.
Größenordnung: `PERF` allein hat 64 Regeln, `LUA` 59, `UI` 41 — jede zu 95%+
ungeprüft.

---

## Empfehlung für die nächste Runde

1. **Vor jeder Gruppe den aktuellen Stand neu erheben** — die Zahlen aus dem
   2026-09-18-Audit sind eine Startliste, kein verlässlicher Live-Stand. Bei
   `ERR-11` war das fast die Hälfte, bei `LUA-01` ein Drittel der geprüften
   Repos bereits anderweitig sauber.
2. **Vorher kurz per `ListAgents` prüfen**, ob eine parallele Session gerade in
   denselben Repos arbeitet, und betroffene Repos für diese Runde ausklammern.
3. **Eine Gruppe nach der anderen**, nicht gemischt — jede hat ihr eigenes
   Urteilsmuster.
4. **Dieselbe zweistufige Struktur** wie `ERR-11`/`LUA-01`: ein Agent pro Repo
   (frisch auditieren, fixen, lokal verifizieren, pushen), danach ein
   adversarialer Verify-Agent pro Repo gegen den echten Diff, nicht gegen die
   Prosa-Zusammenfassung — bei `LUA-01` hat genau dieser zweite Schritt zwei
   echte, sonst übersehene Restfunde aufgedeckt.
5. **Reihenfolge**: `ERR-11`-Nachtrag für die 6 verbliebenen Repos zuerst
   (kleinster Aufwand, Methode bereits etabliert), dann `ERR-50`/`ERR-22`
   zusammen (oft dieselbe `config/init.lua`-Stelle), die 313 ungeprüften
   Regeln als eigenes, deutlich größeres Vorhaben zuletzt.
