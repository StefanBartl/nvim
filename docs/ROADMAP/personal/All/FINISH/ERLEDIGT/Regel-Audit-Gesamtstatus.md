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
  - [Teil 1 — Ursprünglicher Audit (2026-09-18): Methode und automatische Regeln](#teil-1-ursprnglicher-audit-2026-09-18-methode-und-automatische-regeln)
    - [Regelkatalog nach Familie](#regelkatalog-nach-familie)
    - [Automatische Regeln: 66 Treffer, 10 echte](#automatische-regeln-66-treffer-10-echte)
    - [Die fünf systematischen Muster des Original-Audits](#die-fnf-systematischen-muster-des-original-audits)
  - [Teil 2 — Die 497-Befund-Kampagne](#teil-2-die-497-befund-kampagne)
    - [Verteilung nach Familie](#verteilung-nach-familie)
    - [Häufigste Regel-IDs (Top 15 von 497 Einzelbefunden)](#hufigste-regel-ids-top-15-von-497-einzelbefunden)
    - [Befunde je Plugin](#befunde-je-plugin)
    - [Die 8 anfänglich zurückgestellten Architekturentscheidungen](#die-8-anfnglich-zurckgestellten-architekturentscheidungen)
  - [Teil 3 — Zwei Regressions-Nachträge](#teil-3-zwei-regressions-nachtrge)
  - [Teil 4 — Bemerkenswerte Einzelbefunde](#teil-4-bemerkenswerte-einzelbefunde)
  - [Teil 5 — Aktueller Stand der vier offenen Baustellen](#teil-5-aktueller-stand-der-vier-offenen-baustellen)
    - [`ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln" — **30 von 30 Repos geprüft, fertig**](#err-11-nichts-zu-melden-fehler-beim-ermitteln-30-von-30-repos-geprft-fertig)
    - [`LUA-01` — Hart oder weich, aber konsistent — **21 von 21 Repos geprüft, fertig**](#lua-01-hart-oder-weich-aber-konsistent-21-von-21-repos-geprft-fertig)
    - [`ERR-50`/`ERR-22` — Config-Validierung und -Degradierung — **31 von 31 Repos geprüft, fertig**](#err-50err-22-config-validierung-und-degradierung-31-von-31-repos-geprft-fertig)
    - [Die 313 `recommended`/`nice-to-have`-Regeln — **Breitenpass über alle 11 Gruppen abgeschlossen**](#die-313-recommendednice-to-have-regeln-breitenpass-ber-alle-11-gruppen-abgeschlossen)
  - [Teil 6 — Nachgelagerter Bug/Security/Performance-Review der Kampagnen-Commits](#teil-6-nachgelagerter-bugsecurityperformance-review-der-kampagnen-commits)
    - [Runde 1 — Review der 4-Kritisch-Regeln-Kampagne (~76 Commits, 20 Repos)](#runde-1-review-der-4-kritisch-regeln-kampagne-76-commits-20-repos)
    - [Runde 2 — Review der 313-Regeln-Kampagne (18 Repos)](#runde-2-review-der-313-regeln-kampagne-18-repos)
    - [Zusammenfassung: beide Runden im Vergleich](#zusammenfassung-beide-runden-im-vergleich)
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
   `ERR-11` (fertig), `LUA-01` (fertig, drei kleine Nacharbeiten aus dem
   adversarialen Verify), `ERR-50`/`ERR-22` (**fertig, 31 von 31 Repos** —
   durchweg auffällig hohe Trefferquote über alle drei Runden, bei rund der
   Hälfte aller Repos deckte der adversariale Verify zusätzliche, vom
   Fix-Agent übersehene Lücken auf), sowie die 313
   `recommended`/`nice-to-have`-Regeln (**Breitenpass über alle 11 Gruppen
   abgeschlossen** in zwei Runden à 6 parallelen Agenten — ~25 echte Fixes
   über ~20 Repos, fünf ausgelagerte Folge-Tasks, eine offene Policy-Frage;
   viele Einzelregeln je Gruppe bleiben bewusst ungeprüft, da reine
   Ermessensfragen). Im Anschluss liefen zusätzlich **zwei Runden** eines
   nachgelagerten Bug/Security/Performance-Reviews der eigenen
   Kampagnen-Commits — Runde 1 für die 4-Kritisch-Regeln-Kampagne (8 von 20
   Repos mit echten Funden), Runde 2 für die 313-Regeln-Kampagne (12 von 18
   Repos mit echten Funden) — siehe
   [Teil 6](#teil-6-nachgelagerter-bugsecurityperformance-review-der-kampagnen-commits).

Zahlenbasis des Gesamt-Audits: 421 Regeln, 38 Repos, ~390.000 LOC Lua.

---

## Teil 1 — Ursprünglicher Audit (2026-09-18): Methode und automatische Regeln

Lauf über alle 38 Repos gegen den vollständigen Regelkatalog aus
`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists`, über die programmatische
API von `rules.nvim` (`check_family_json`) für automatisierbare Regeln, plus eine
Agent-Runde für den Rest.

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln" — **30 von 30 Repos geprüft, fertig**

Durchgeführt am 2026-09-19 als Multi-Agent-Runden: pro Repo ein Fix-Agent
(frischer Audit gegen aktuellen Code, dann Fix + lokaler Lint/Test + Push),
danach ein adversarialer Verify-Agent pro Repo. 48 Agents in der Hauptrunde,
0 Fehler, 0 Refutationen.

- **15 Repos mit echten Verstößen**, gefunden/gefixt/gepusht: `ai`,
  `buffer-ctx` (2 Stellen), `cascade`, `casedesk`, `cmdlog`, `filetree`
  (`.order.json`-Backup, per Sabotage-Gegenprobe bestätigt), `insights`,
  `lib`, `markdown`, `my`, `pdfport`, `recommender`, `reposcope`
  (2 Stellen), `runtime-analysis`, `spotlight`.
- **15 Repos bereits sauber**: `dap`, `debugging`, `diff`, `documentation`,
  `fileops`, `github_stats`, `hover`, `images`, `language`, `lsp`, `media`,
  `pickers`, `replacer`, `rules`, `ui`.

**Nachtrag für die 6 anfänglich ausgeklammerten Repos** (`fileops`,
`filetree`, `hover`, `media`, `pickers`, `ui` — waren beim Start der
Hauptrunde aktiv von einer parallelen Session belegt) ist inzwischen
durchgeführt: 1 echter Fund (`filetree.nvim`), 5 bereits sauber. Der
adversariale Gegen-Check (1 gründlicher Verify für den echten Fund, 1
gebündelter Sanity-Check für die 5 „nichts gefunden"-Verdikte) fand keinen
einzigen übersehenen Bug — nur bei 3 der 5 sauberen Repos kleinere
Zitat-Ungenauigkeiten in der Prosa (behauptete Code-Kommentare, die es so
nicht gab; das zugrundeliegende Verhalten war in jedem Fall trotzdem
korrekt).

---

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

---

### `ERR-50`/`ERR-22` — Config-Validierung und -Degradierung — **31 von 31 Repos geprüft, fertig**

`ERR-50` (Validierung unbekannter Keys vor dem Merge) und `ERR-22`
(Degradierung ungültiger Werte auf den Default) werden pro Repo gemeinsam
geprüft, da beide oft im selben `config/init.lua` hängen. Zusammen betroffen
(Vereinigungsmenge der 2026-09-18-Repolisten): 31 Repos. Bekannte Abweichung:
`ai.nvim`s `ERR-50`-Fund (`DEFAULTS.lua:64`) war schon vor Rundenstart durch
eine parallele Session behoben.

**Zwischenstand 2026-09-19 (Runde 1, 10 Repos, alle adversarial verifiziert):**
Ungewöhnlich hohe Trefferquote — **9 von 10 Repos hatten mindestens einen
echten, bis dahin ungefixten Verstoß**, nur `ai.nvim` war komplett sauber
(CONFIRMED per unabhängigem Gegen-Audit, 265/265 Tests).

- `buffer-ctx` — ERR-22: `format.command`/`mark.command` als Zahl crashten
  den gesamten Plugin-Start (`6018519`). Der adversariale Verify fand danach
  **3 weitere Crash-Pfade**, die der erste Fix übersah (leerer String bei
  denselben zwei Feldern, `mark.keymaps` als Zahl) — Nachfix `7a71d2e`,
  danach CONFIRMED.
- `cascade` — ERR-50 (Validierung ging nur eine Ebene tief) + ERR-22 (3
  reproduzierte Crashes: `lists.types`/`lists.unordered_markers`/
  `cycle.groups` als `false`) — `bf227c3`, `5bf592f`, CONFIRMED.
- `casedesk` — ERR-50 (verschachtelte `sla`/`sla_business_hours`-Keys
  ungeprüft) + ERR-22 (5 Felder ohne Guard) — `2a6b1d2`. Verify fand einen
  **weiteren, direkt benachbarten Crash** (`sla_stale_days`, dieselbe
  Fehlerklasse wie das gerade gefixte `stale_days_default`) — Nachfix
  `9ce3e1e`, CONFIRMED (585/585 Tests).
- `cmdlog` — ERR-22: ungültiger `picker`-Wert crashte trotz
  `:checkhealth`-Meldung (`b96e05e`), CONFIRMED.
- `color_my_ascii` — ERR-22: `language_detection_threshold` ohne jede
  Validierung crashte pro ASCII-Block (`5d0c7b3`), CONFIRMED.
- `dap` — ERR-22: `adapters`/`configurations` hatten keinen Typ-Default,
  rutschten unvalidiert durch (`a777815`), CONFIRMED.
- `debugging` — ERR-50: Validierung ging nur 2 Ebenen tief (`71194eb`),
  CONFIRMED.
- `diff` — ERR-22: `default_view`/`default_output`/`default_orig_view`
  brachen `:Diff` dauerhaft, bis die Config erneut geändert wurde (`6d48e1b`),
  CONFIRMED.
- `documentation` — ERR-50 (Known-Keys-Liste war von den echten Optionen
  abgedriftet) + ERR-22 (4 Felder ohne Guard) — `38ba192`, `19ef5f3`. Verify
  fand einen **weiteren Crash** im selben Muster (`core/quicks.lua`s
  `limit_good`/`limit_bad`/`thresholds`) — Nachfix `7debecd`.

**Zwischenstand 2026-09-19 (Runde 2, 10 Repos, alle adversarial verifiziert):**
Noch höhere Trefferquote — **alle 10 von 10 Repos hatten mindestens einen
echten Verstoß.** Bei 6 der 10 fand der adversariale Verify zusätzliche,
vom ersten Fix übersehene Crashes — jeder davon nachgefixt und erneut
bestätigt.

- `fileops` — ERR-50 sauber (bereits vor der Runde gefixt), ERR-22:
  `retry.attempts`/`backoff_ms` (crashten `lib.nvim`s `mutate.lua`) und
  `on_hold.modes` (crashte schon bei `setup()`) — `24e1a58`, CONFIRMED.
  Verify fand einen weiteren Fund (`on_hold.ignore_buftypes`, wiederholte
  sich bei jedem `CursorHold`) — Nachfix `71f4bf3`.
- `filetree` — ERR-50 (Validierung war „bewusst flach" dokumentiert, ging
  nicht in Feature-Bodies/`menu` hinein) + ERR-22 (7 Felder ohne Guard) —
  `9355522`, CONFIRMED. Verify bestätigte den `cwd_mode`-Scope-Ausschluss
  als vertretbar (dort bereits anderweitig pcall-geschützt) und fand
  dasselbe Muster in ~50 weiteren, feature-eigenen Configs verteilt —
  als eigene künftige Runde vermerkt, nicht sofort gefixt.
- `gopath` — ERR-50 (Validierung ging nur eine Ebene tief) + ERR-22 (5
  Crashes, zwei davon crashten `setup()` selbst synchron) — `102cdee`,
  CONFIRMED. Verify fand einen direkt benachbarten Crash im selben
  Code-Pfad (`truncated.excluded_dirs`) — Nachfix `e33160b`.
- `images` — ERR-50 sauber, ERR-22: **8 Crashes** über 5 Commits (u. a.
  `extensions = "png"` statt Tabelle, betraf fast jede Cursor-Bilderkennung).
  Verify fand eine **dritte, noch erreichbarere Stelle** für dasselbe Feld
  (`convert.lua`, crashte schon bei `setup()`) — Nachfix `bc7fdb3`.
- `insights` — ERR-50 sauber, ERR-22: **5 Crashes** über 3 Commits (u. a.
  ein `compress.engine`-Wert, der `:checkhealth insights` selbst zum
  Absturz brachte). Verify fand **6 weitere** Stellen desselben Musters
  (`imports.engine`, `symbols.default_scope`, `conflicts.diff_filter`,
  `metrics.output_file`, `tree.outfile_fmt`/`outdir`,
  `imports.output_file`) — zwei Nachfix-Runden, `e4161fa` + `327f070`.
- `lib.nvim` — beide Regeln in `telemetry/init.lua` verletzt (ein im
  August entferntes, im September ohne den mittlerweile üblichen
  ERR-50/ERR-22-Schutz wiederbelebtes Modul, vorher null Testabdeckung) —
  `2e9ae88`, CONFIRMED inkl. fleet-weiter Blast-Radius-Prüfung (aktuell
  kein einziger produktiver Aufrufer).
- `markdown` — ERR-50 sauber, ERR-22: 5 Crashes (`table.wrap.*`,
  `hover.max_lines`) — `bf7f7d5`, CONFIRMED. Verify fand eine weitere
  Stelle (`refs.debounce_ms`) — Nachfix `7ae34e8`.
- `my` — 2 Funde außerhalb des offensichtlichen Config-Moduls: `indent_per_ft`
  hatte gar keine Key-Validierung (ERR-50), `cword_occurrences` fehlte der
  pcall-Schutz beim Extmark-Aufruf, den der Schwester-Code hatte (ERR-22) —
  `d96123a`, `bcf0a37`, CONFIRMED.
- `open` — ERR-50 sauber (Rekursionstiefe zwar begrenzt, aber aktuell nicht
  ausnutzbar), ERR-22: 2 Crashes (`handlers`/`office_open.extensions`-
  Listenelemente, `filemanager.command`) — `5784d3c`, CONFIRMED.
- `pdfport` — ERR-50 + ERR-22 (`terminal_size_ratio`, Crash in einem async
  Callback außerhalb des normalen pcall-Schutzes) — `a191978`. **Verify
  deckte auf, dass der Fix einen strukturell unerreichbaren Config-Pfad
  absicherte** (der `setup()`-Merge passiert für den Terminal-Modus gar
  nicht), während der tatsächlich erreichbare Pfad
  (`pdfport.open({mode="terminal", ...})`) weiterhin exakt so crashte wie
  vorher — Nachfix direkt an der Verwendungsstelle in `terminal.lua`
  (`c5b3b6f`), diesmal über den echten Dispatch-Pfad verifiziert.

**Zwischenstand 2026-09-19 (Runde 3, die finalen 11 Repos, alle adversarial
verifiziert):** Erneut bestätigt hohe Trefferquote — **alle 11 von 11 Repos
hatten mindestens einen echten Verstoß.** Bei 5 der 11 fand der adversariale
Verify zusätzliche, vom ersten Fix übersehene Lücken — jede davon nachgefixt
und erneut bestätigt.

- `pickers.nvim` — ERR-50 war schon vorher gefixt; ERR-22: 2 Fixes für
  `smart`/`quickfix.preview`-Werte (`6efeda3`).
- `recommender.nvim` — ERR-22: Degradierung für ungültige
  `threshold`/`cwd_max_files`/`blacklist`/`custom_aliases`/`cwd_ignore`
  (`c8458c5`).
- `replacer.nvim` — ERR-50: unbekannte `keymaps.*`-Keys abgefangen, bevor sie
  stillschweigend verschwanden (`3b27e84`).
- `reposcope.nvim` — ERR-50 (`f57fd0d`) + ERR-22 (`3632416`), beide echte
  Funde.
- `rules.nvim` — ERR-50 war bereits am selben Tag von einer parallelen
  Session gefixt worden (`5a608ef`); diese Runde ergänzte den ERR-22-Fix:
  `setup()` gegen ein Nicht-Tabellen-Argument abgesichert (`5af41db`). Ein
  späterer Bug/Security-Review (siehe
  [Teil 6](#teil-6-nachgelagerter-bugsecurityperformance-review-der-kampagnen-commits))
  fand danach noch einen Randfall: `setup(false)` umging den neuen Guard,
  weil Luas `opts or {}`-Idiom `false` genauso behandelt wie „nicht
  angegeben", also wie `nil` (`2e1ed1b7`).
- `runtime-analysis.nvim` — ERR-50 bereits sauber bestätigt (rekursiv
  validiert, entspricht der echten Verschachtelung). ERR-22: 5 echte Crashes
  in `telemetry/init.lua`, `telemetry/reminder.lua` und `init.lua`s
  `open_request` gefixt (`8387c7b`, `9ecf929`). Der adversariale Verify fand
  danach eine DRITTE, komplett ungeprüfte Config-Fläche, die der Fix-Agent
  übersehen hatte: `startup/init.lua`s `M.start()` (der
  Main-Loop-Stall-Detector) hatte überhaupt keine Validierung — 3 weitere
  echte Crashes reproduziert und gefixt, darunter ein wiederkehrender
  Per-Tick-Fehlersturm, im Nachfix `653cff2`.
- `sandbox.nvim` — ERR-22: `list_size` crashte
  `nvim_win_set_width`/`height` bei einem Nicht-Integer-Wert über alle 7
  List-View-Module hinweg, gefixt (`885770e`). Der Fix-Agent hatte ERR-50 als
  „N/A" eingestuft, weil es überhaupt keinen Unknown-Key-Validator gab —
  diese Begründung wurde als verdächtig markiert (dieselbe Situation bei
  `reposcope.nvim` galt zu Recht als schlimmste Ausprägung des Verstoßes,
  nicht als Freifahrtschein) und neu untersucht: ein sauberer,
  handgeschriebener KNOWN-Key-Validator wurde von Grund auf gebaut, unter
  sorgfältiger Vermeidung der „`DEFAULTS[key] ~= nil`"-Falle (4 Config-Keys
  dieses Repos defaulten auf `nil` und wären fälschlich als unbekannt
  gemeldet worden), mit eigenem Regressionstest dafür. Der adversariale
  Verify des ERR-22-Fixes fand zusätzlich eine übersehene Grenze:
  `math.huge` besteht die „ist das ein Integer"-Prüfung
  (`math.floor(math.huge) == math.huge` in IEEE-754), crasht aber trotzdem
  `nvim_win_set_width` — gefixt. Alles im Nachfix `54df9e7`.
- `sessions.nvim` — ERR-50 (`e2e3a0d`) + ERR-22 (`36ef788`), beide echte
  Funde.
- `spotlight.nvim` — ERR-22 war am selben Tag bereits durch einen früheren
  Commit gefixt. ERR-50: es gab überhaupt keinen Validator, einen gebaut mit
  einer `keymaps = false`-Kurzform-Ausnahme (`1c0b115`). Der adversariale
  Verify fand diese Ausnahme zu breit — sie akzeptierte JEDEN
  Nicht-Tabellen-Wert für `keymaps`, nicht nur das dokumentierte `false`
  (z. B. crashte `keymaps = "toggle"` ohne jede Diagnose) — gefixt im
  Nachfix `510f68d`.
- `emojis.nvim` — ERR-50: eine Regression aus einem FRÜHEREN Fix derselben
  Kampagne gefunden und gefixt — eine `NESTED_OPTS.keymaps`-Allowlist war zu
  eng und entfernte stillschweigend legitime, dokumentierte
  Per-Action-Keymap-Overrides, bevor sie die eigentliche Validierung weiter
  unten überhaupt erreichten (`f595633`). ERR-22:
  `search.cmd`/`command`-Crashes gefixt (`0b94c04`). Der adversariale Verify
  fand, dass der `command`-Guard nur „nicht-leerer String" prüfte, nicht
  Neovims echte Ex-Command-Namensgrammatik (z. B. crashte
  `command = "1Emojis"` immer noch `nvim_create_user_command`), plus eine
  verwandte Lücke im Unicode-Modul (`reg`-Parameter schützte nur das
  „="-Register, nicht die volle von `setreg` akzeptierte Menge) — beide
  gefixt im Nachfix `bfb58ba`.
- `ui.nvim` — ERR-50 bereits sauber bestätigt. ERR-22: 3 echte Crashes
  gefixt (`statusline`s `responsive_width` ohne jeden `pcall` im eigenen
  Call-Pfad, LSP-Breadcrumb-`config.set()` ohne jede Validierung trotz
  „strict typing"-Docstring, `tabline`-`bufwidth`-Vergleiche) — gelandet in
  `c804ac7` wegen einer Kollision mit einer parallelen Session in einem
  geteilten (Nicht-Worktree-)Checkout, Tests separat nachgereicht in
  `85d88a8`. Der adversariale Verify fand eine weitere Lücke
  (`since_last_save`-Modul, `warn`/`critical`-Schwellwerte) und beim
  Mitprüfen der LSP-Config-Delegation zwei weitere echte Bugs: einen
  „unbekannter Key"-Guard, der nicht zwischen „nie gültig" und „ein
  gültiges, aktuell auf `nil` stehendes Feld" unterscheiden konnte (sodass
  `path_max_chars` nie wieder gesetzt werden konnte, sobald es einmal
  geleert war), sowie `M.set(key, nil)`, das stillschweigend nichts tat,
  weil ein Lua-Tabellenkonstruktor `nil`-wertige Keys verwirft. Alles
  gefixt plus ein flakiger, zeitbasierter Test verschärft, im Nachfix
  `31c18e7`.

Muster über Runde 3 hinweg: bei rund der Hälfte dieser Repos fand der
adversariale Verify etwas, das der ursprüngliche Fix-Agent übersehen hatte —
entweder eine engere Validierungslücke, eine komplett ungeprüfte dritte
Config-Fläche, oder einen Bug, den der Fix selbst eingeführt hat. Das deckt
sich mit dem Muster aus Runde 1/2 und bestätigt erneut, dass der
Verify-Schritt keine Formsache ist.

**`ERR-50`/`ERR-22`-Fleet-Status: 31/31 Repos abgeschlossen, Fix +
adversarialer Verify für alle erledigt.**

---

### Die 313 `recommended`/`nice-to-have`-Regeln — **Breitenpass über alle 11 Gruppen abgeschlossen**

Der Katalog hat 421 Regeln, geprüft (manuell) waren zunächst nur die 76
`critical`-Regeln der review-relevanten Familien. Die übrigen 313 —
`recommended`/`nice-to-have` plus die `critical`-Regeln der Gate-Familien
NEW/REL außerhalb ihres automatisierten Teils — sind jetzt in zwei Runden
mindestens einmal breitenorientiert geprüft worden: alle 11 Regelgruppen
(TS, XP, DEP, CMT, SEC, LLS, LLS-31 als eigener Durchgang, PRIN, UI, LUA,
PERF sowie die restlichen kritischen NEW-*/REL-*-Regeln ohne automatischen
Check) wurden mindestens einmal angefasst.

**Wichtige Einordnung**: anders als die frühere 4-Kritisch-Regeln-Kampagne
(`ERR-11`/`LUA-01`/`ERR-50`/`ERR-22`) war das hier bewusst ein
**Breitenpass, keine erschöpfende Prüfung jeder Regel in jedem Repo**. Ein
großer Teil der Regeln je Familie ist schlicht nicht mechanisch prüfbar —
reine Ermessens-/Design-Entscheidungen — und wurde korrekt ungeprüft
gelassen statt zwangsweise „gefixt". Dieses Muster zieht sich durch fast
jede Familie unten und erklärt, warum „0 Funde" dort der erwartete Normalfall
ist, nicht ein Zeichen für einen oberflächlichen Durchgang.

#### Runde 1 (6 parallele Agenten, einer je Familie)

- **`TS-*`** (5 Regeln, Treesitter): über alle 17 Repos mit `vim.treesitter`
  100 % sauber. 3 der 5 Regeln fleet-weit nicht anwendbar (keine
  quantifizierten Captures, keine eigenen `.scm`-Queries, keine
  Threadpool-Nutzung). Null Fixes.
- **`XP-*`** (7 Regeln, Cross-Platform-Fallstricke): 1 echter Fix — der
  LSP-Pfad-Cache der `ui.nvim`-Statusline
  (`lua/ui/statusline/modules/lsp/helpers/paths.lua`) fiel bei einem
  fehlgeschlagenen `fs_realpath` (noch nicht existierende Datei) auf den
  rohen, unaufgelösten Pfad zurück, ohne spätere Re-Invalidierung, sobald die
  Datei existierte — gefixt via `lib.nvim.fs.normkey`, Commit `62e06b6`. Die
  übrigen 6 Regeln waren aus früheren Kampagnen bereits fleet-weit sauber
  (frisch nachgeprüft, nicht nur angenommen).
- **`DEP-*`** (7 Regeln, veraltete Neovim-APIs): komplett sauber, keine neuen
  Funde. Alle Kandidatenstellen bereits gefixt, korrekt versionsgegated oder
  über dokumentierte `.rules-waivers.json`-Einträge abgedeckt. Zwei Regeln
  (`vim.tbl_flatten`, `nvim_buf_get_option`) haben fleet-weit null Treffer.
- **`CMT-*`** (16 Regeln, Kommentarhygiene): 41 echte Fixes über 4 Repos, alle
  unter CMT-03 (veraltete `@module`-Doc-Kommentarpfade nach
  Verzeichnisumbauten) — filetree.nvim (33 Dateien, Commit `3f8d31c`),
  reposcope.nvim (6 Dateien, `2b7fb72`), sessions.nvim (1 Datei, `4d1cc27`),
  sandbox.nvim (1 Datei, `d993407`). Die ermessenslastigen Regeln
  (Kommentarqualität/-veraltung/Geschmacksfragen) wurden laut expliziter,
  konservativer Vorgabe bewusst nicht angefasst — keine pauschalen
  Kommentar-Rewrites. Ein Fund außerhalb des Scopes wurde als Folge-Task
  ausgelagert: `mdview.nvim/lua/mdview/adapter/browser/probe_plattform_paths.lua`
  trägt einen Tippfehler im Dateinamen („plattform", deutsches Doppel-t),
  während der Rest der Datei korrekt „platform" schreibt (Task
  `task_8e2905c7`, läuft).
- **`SEC-*`** (29 Regeln, Security): **5 echte, ausnutzbare Verstöße gefunden
  und gefixt** — die schwerwiegendsten Funde dieser ganzen Runde:
  - `lsp.nvim` (`509d7c2`, SEC-01): `dart.lua` startete `flutter run` als
    Shell-String statt als Argv-Liste.
  - `open.nvim` (`defe7da`, SEC-34): `viewer/scan.lua` rief `vim.fn.expand()`
    auf einem Pfad auf, der aus dem eigenen Linktext eines Markdown-Links
    beim Scannen eines Buffers geparst wurde — ein präparierter Link wie
    `[x](./\`touch /tmp/pwned\`)` konnte beim normalen Buffer-Scan ausgeführt
    werden, ganz ohne explizite „führe das aus"-Aktion.
  - `markdown.nvim` (`03429dd`, SEC-34, 9 Dateien/12 Stellen),
    `diff.nvim` (`8b6b8ba`, SEC-34), `sessions.nvim` (`b46974b`, SEC-34) —
    allesamt Geschwister eines bereits gefixten
    `vim.fn.expand()`-auf-ungeprüftem-Text-Musters, die an genau diesen
    Call-Sites übersehen worden waren.
  Alle fünf: Lint/Tests sauber, gepusht. Die übrigen 24 SEC-Regeln waren
  entweder aus früheren Kampagnen bereits gefixt (gegen den echten Code
  gegengeprüft, nicht nur gegen Git-Log-Behauptungen) oder laut Regeltext
  selbst legitim nicht per Grep fleet-weit prüfbar.
- **`LLS-*`** (37 Regeln, LuaLS-Diagnosen): die größte Breitenpass-Ausbeute —
  - LLS-03 (fehlender `.claude`/`.deps`-Ausschluss in
    `workspace.ignoreDir`) in **13 Repos** gefixt: cascade, cmdlog, diff,
    documentation, fileops, gopath, lib.nvim, lsp.nvim, markdown, mdview,
    pdfport, pickers, runtime-analysis.
  - LLS-11 (`fun(): T` in einem Inline-Tabellentyp verschluckt das nächste
    Feld) gefixt in casedesk, diff, media (3 Repos, 22 echte Diagnosen
    behoben).
  - LLS-40 (fehlerhafter `@diagnostic disable-next-line`, fehlendes
    Pflicht-`:`, unterdrückte dadurch nichts) gefixt in gopath, mdview,
    sandbox (15 tote Kommentare entfernt).
  - LLS-10 (pickers.nvim, 3 Dateien), LLS-17 (lib.nvim), LLS-13
    (cmdlog.nvim, Beispiel-Fix; ~20 weitere Stellen über ~12 Repos markiert,
    aber nicht pauschal editiert, da an ihren Call-Sites bereits defensiv
    abgesichert).
  - **LLS-31 als eigener, dedizierter Durchgang markiert** (siehe unten), da
    es die einzige `critical`-Regel in einer sonst
    recommended/nice-to-have-Familie ist und semantisches Urteilsvermögen
    statt Grep braucht.

#### Runde 2 (6 parallele Agenten/Agenten-Gruppen)

- **LLS-31, dedizierter Durchgang** (kritisch: ein `pcall` um einen
  fehlerhaften Aufruf kann den Bug still verschlucken statt ihn
  sichtbar zu machen) — ein fleet-weiter statischer Scanner wurde gebaut und
  fand mitten im Lauf seinen eigenen Scan-Fenster-Bug (False-Positive-Rate
  fiel von 274 auf 23 Kandidaten, dann nach manueller Durchsicht auf 0),
  danach wurde jede bare-`pcall`-Closure und jedes „verworfene `ok`" fleet-weit
  vollständig gelesen, zusätzlich ~740 weitere Einzel-Call-Sites per
  Muster-Clustering. **3 echte Fixes**:
  - `gopath.nvim` (`e741998`): eine fehlgeschlagene Subject-Suche fiel still
    auf das Öffnen von `:help vim.api` zurück — nicht von einem echten
    Treffer unterscheidbar. Der Code selbst trug bereits einen Kommentar,
    der diese Unsicherheit markierte. Warnt jetzt unter Nennung des
    gesuchten Begriffs.
  - `lsp.nvim` (`a068a24`): die zentrale Pro-Server-Schleife
    `pcall(vim.lsp.enable, name)` verwarf ihr Ergebnis, während jeder
    Schwester-Fehlerpfad in derselben Funktion bereits über
    `:checkhealth`/notify sichtbar gemacht wird — eine klare Asymmetrie.
    Fügt sich jetzt in dasselbe Idiom ein.
  - `cascade.nvim` (`c45685a`, 4 Dateien, 7 Call-Sites): jede
    `renumber.tree/run/all`-Call-Site verwarf ihr pcall-Ergebnis ohne
    rechtfertigenden Kommentar, ungewöhnlich für eine sonst disziplinierte
    Codebasis. Warnt jetzt über das bestehende notify-Idiom.
  Die große Mehrheit der ~900 fleet-weiten Kandidaten für verworfene pcalls
  wurde korrekt unangetastet gelassen als legitimes Best-Effort-Verhalten
  (Timer-/Prozess-/Buffer-Teardown, kosmetische Einstellungen, optionale
  Drittanbieter-Integrationsguards, weiche Dependency-Checks) — viele davon
  bereits selbst als bewusst dokumentiert.
- **`PRIN-*`** (37 Regeln, Prinzipien): nur die mechanisch prüfbaren Regeln
  wurden verfolgt. 3 Fixes, 20 Dateien, alle unter PRIN-50 (jede Datei
  braucht einen `---@module`-Header) — sandbox.nvim (17 Dateien, `ed57128`),
  mdview.nvim (2 Dateien, `d54c476`), runtime-analysis.nvim (1 Datei,
  `a0fc940`). PRIN-02 („ein Funktionsname mit „and" signalisiert zwei
  Verantwortlichkeiten") fand ~30 echte Kandidaten über ~15 Repos, keiner
  wurde angefasst — ein Splitten wäre ein API-Oberflächen-Redesign mit echtem
  Caller-seitigem Risiko und ohne konkreten Bug dahinter, explizit außerhalb
  des Scopes eines opportunistischen Fix-Durchgangs. Als Liste für eine
  spätere, bewusste Entscheidung belassen, nicht gefixt.
- **`UI-*`** (41 Regeln, UI/UX): Breitenpass deckte ungefähr die Hälfte der
  Familie ab (der Rest — Picker-/Completion-UX — ist laut Quelldokument
  selbst explizit manuelles Ermessen); null Fixes nötig, die Familie war
  bereits durch eine frühere Kampagne gut abgedeckt.
- **`LUA-*`** (58 Regeln exkl. LUA-01, allgemeine Lua-/Neovim-Sicherheit):
  null Fixes — alles mechanisch Prüfbare kam sauber oder bereits gefixt
  zurück. **Ein bedeutender Policy-Fund, dediziert nachbearbeitet**: LUA-54
  („keine Emojis, keine fetten Überschriften in Docs") wurde fleet-weit,
  durchgängig, über fast jedes Repo hinweg verletzt (tausende
  `.md`-Dateien nutzten Emoji-Section-Header oder fett gesetzten
  Pseudo-Überschriften-Text) — klar ein etablierter, bewusster
  Dokumentationsstil statt verstreute Fehler. Dem Nutzer mit drei Optionen
  vorgelegt (Regel an die Praxis anpassen / als bekannte Lücke stehen
  lassen / dedizierter Cleanup-Durchgang); Entscheidung: dedizierter
  Cleanup. Lief anschließend über alle 38 Repos (6 parallele Agenten, je
  ein Batch von ~6 Repos): dekoratives Emoji entfernt, fett gesetzter
  Pseudo-Text in echte Markdown-Überschriften umgewandelt — insgesamt rund
  470 Überschriften-Konvertierungen und rund 345 entfernte Emoji. Emoji,
  die reale Plugin-Ausgabe oder Config-Werte wortgetreu dokumentieren,
  blieben bewusst unangetastet, z. B. bei emojis.nvim und
  color_my_ascii.nvim (deren Doku-Beispiele selbst aus Emoji bestehen),
  bei runtime-analysis.nvim (Emoji sind byte-genaue Rückgabewerte aus dem
  eigenen Code) und bei sessions.nvim (`pin_marker = "📌 pin"` als echter
  Config-Default). Jeder Batch prüfte danach die Stabilität der
  GitHub-Anchor-Slugs; einzig bei github_stats.nvim (mit 272
  Konvertierungen und ~49 entfernten Emoji der größte Einzel-Batch) hätte
  das tatsächlich einen bestehenden Inhaltsverzeichnis-Link stillschweigend
  umgeleitet — gefixt. Nebenbefund bei media.nvim: eine andere,
  unabhängige Session bearbeitete parallel dieselbe README.md; sauber per
  `git checkout` aufgelöst, bevor der Cleanup dort weiterlief. Lint
  (stylua/luacheck je nach Repo-CI) blieb überall grün — bei einer
  reinen Doku-Änderung ohne Verhaltensrisiko, aber aus Disziplin trotzdem
  geprüft.
- **`PERF-*`** (64 Regeln, die größte Familie) — über alle 38 Repos geprüft
  (intern in Repo-Gruppen aufgeteilt, aus Gründen der Handhabbarkeit).
  **9 echte Fixes**:
  - `reposcope.nvim` (`cc8df58`, PERF-46): README-Cache war nur nach
    `owner/repo_name` geschlüsselt, ohne den aktiven Provider
    (GitHub/GitLab/Codeberg) — ein Providerwechsel für denselben Namen
    konnte still ein README vom falschen Forge servieren.
  - `images.nvim` (`cbd63d1`, PERF-25): eine Closure wurde bei jeder Zeile
    der Sextant-Rendering-Hot-Loop neu erzeugt (bis zu 12×/s), jetzt über die
    Schleife hinausgehoben.
  - `images.nvim` (`cd6099d`, PERF-42, kritisch): der Remote-Image-Disk-Cache
    hatte keinerlei Invalidierung — eine URL wurde unabhängig von
    Remote-Änderungen für immer mit denselben Bytes serviert. TTL ergänzt.
  - `sessions.nvim` (`1c8c1f6`, PERF-93, kritisch): das Marks-Edit-Menü las
    `pins.json` bei jedem Tastendruck in einem `TextChanged`-Handler neu von
    der Platte und löste jeden Default-Realpath erneut auf, obwohl sich
    nichts ändern konnte, solange der transiente Buffer offen war. Jetzt
    einmalig beim Öffnen berechnet.
  - `ui.nvim` (`87122f4`, PERF-92, kritisch): das Screenkey-Tastendruck-HUD
    berechnete seine Geometrie einmalig beim ersten Öffnen und nie wieder,
    solange es lebte (unbegrenzt — überdauert Tastendrücke) — ein
    `VimResized` mitten in der Session ließ es an veralteten Koordinaten
    kleben. Gefixt mit einer durch `VimResized` ausgelösten Neuberechnung.
  36 der 38 Repos kamen komplett sauber zurück (bereits durch die frühere
  Kritisch-Kampagne gut gehärtet — viele Dateien tragen explizite,
  sich selbst zitierende `PERF-xx`-Kommentare). Zwei Folgearbeiten wurden als
  separate Tasks ausgelagert statt inline gefixt: die zwei unbegrenzten
  Caches von `lsp.nvim` (`files_cache`, `buf_symbol_cache`) konnten nicht
  angefasst werden, weil das Repo zum Audit-Zeitpunkt einen fremden, unfertig
  dirty Working Tree hatte (Task `task_855b612a`, läuft); `ui.nvim`s
  `kit/compare.lua`/`kit/picker.lua`/`kit/chooser.lua` haben denselben
  Stale-Geometrie-Bug wie der Screenkey-Fix, aber diese Dateien sind
  byte-für-byte an eine eingefrorene Kopie in `lib.nvim` gebunden (durch
  einen Drift-Test) — der Fix muss also in beiden Repos gleichzeitig landen
  (Task `task_ea884b81`, läuft).
- **Restliche kritische `NEW-*`/`REL-*`** (Regeln ohne automatischen
  `rules.nvim`-Check): von ~20 solchen Regeln sind die meisten
  Prozess-/GitHub-Metadaten-/manuelles-Ermessen-Regeln und nicht
  fleet-prüfbar. Eine Regel (REL-35, keine `wkdbook`-/`WKDBooks`-Referenzen)
  war echt code-prüfbar: 3 verschleppte Referenzen gefunden und gefixt
  (color_my_ascii.nvim `61a94b4`, gopath.nvim `75e36da`, media.nvim
  `b362350`). Zwei Repos (`casedesk.nvim`, `pickers.nvim`) haben WKDBooks
  tief in ihre tatsächliche Architektur/Quelle eingebaut, keine
  verschleppten Strings — korrekt nicht angefasst, als separate
  Review-Tasks ausgelagert (`task_de751049`, `task_c7944df3`, beide laufen).
  Ebenfalls aufgefallen: NEW-39 („TESTS/ braucht minimal_init.lua +
  scripts/test.sh") basiert auf einer veralteten Konvention, die der
  Großteil der Fleet inzwischen durch ein gleichwertiges
  `harness.lua`/`run.lua`-Muster ersetzt hat — korrekt nicht als ~25
  Verstöße gewertet.

#### Zusammenfassung dieses Abschnitts

Beide Runden zusammen: alle 11 Regelgruppen des 313er-Katalogs mindestens
einmal breitenorientiert geprüft. ~25 echte, adversarial nachvollziehbare
Fixes über ~20 Repos, keine erzwungenen Fixes bei Ermessensfragen. Fünf
Nachfolge-Tasks für Fälle, die Koordination über mehrere Repos oder eine
bewusste Design-Entscheidung brauchen, laufen unabhängig weiter. Die eine
Policy-Frage (LUA-54, Emoji-Konvention) ist entschieden und per
dediziertem Cleanup über alle 38 Repos abgearbeitet.

---

## Teil 6 — Nachgelagerter Bug/Security/Performance-Review der Kampagnen-Commits

Zwei unabhängige Review-Durchgänge, jeweils von einem anderen Agenten als dem,
der den jeweiligen Original-Fix geschrieben hat: nicht die Kampagnen-Arbeit
selbst, sondern eine gezielte Suche nach Bugs, Security- oder
Performance-Problemen, die die Kampagnen-Commits selbst eingeführt oder
übersehen haben könnten. Runde 1 deckte die ursprüngliche
4-Kritisch-Regeln-Kampagne (`ERR-11`/`LUA-01`/`ERR-50`/`ERR-22`) ab, Runde 2
folgte nach Abschluss des vollständigen 313-Regeln-Breitenpasses (siehe oben)
samt dem `LUA-54`-Emoji-/Fett-Überschriften-Cleanup und deckte gezielt die
davon neu erzeugten Commits ab, die bis dahin noch nie adversarial
gegengeprüft worden waren.

---

### Runde 1 — Review der 4-Kritisch-Regeln-Kampagne (~76 Commits, 20 Repos)

Nach Abschluss der `ERR-50`/`ERR-22`-Fleet-Fix-Arbeit lief die erste Runde
dieses Review-Durchgangs: die ~76 Commits, die diese Kampagne selbst
hervorgebracht hat (über die Regelfamilien `ERR-11`/`LUA-01`/`ERR-50`/`ERR-22`,
20 Repos, die vom eigenen Verify aus Runde 3 oben nicht bereits mitabgedeckt
waren), wurden auf Bugs, Performance- oder Security-Probleme durchsucht, die
die Fixes selbst eingeführt haben könnten. Muster: Review pro Repo →
adversarialer Verify pro Fund → Fix bestätigter Funde → Commit/Push.

**Ergebnis: 12 von 20 Repos sauber** (`filetree.nvim`, `buffer-ctx.nvim`,
`pdfport.nvim`, `images.nvim`, `pickers.nvim`, `recommender.nvim`,
`replacer.nvim`, `sessions.nvim`, `markdown.nvim`, `ai.nvim`, `dap.nvim`,
`hover.nvim`). **8 von 20 Repos hatten echte, adversarial bestätigte
Probleme, alle gefixt:**

- **`lib.nvim`** (`ec105e47`) — `first_run.show_once()` rief `load_seen()`
  zweimal pro Aufruf auf (über `M.seen()` dann `M.mark_seen()`), sodass ein
  einziges Corrupt-Store-Event zwei doppelte Nutzer-Warnungen statt einer
  erzeugte. Umgebaut auf einmaliges Laden mit Wiederverwendung der Tabelle.
- **`insights.nvim`** (`656f93dc`) — `health.lua`s `check_config()` hatte das
  alte, crash-anfällige `x or default`-Idiom für `metrics.output_file`/
  `tree.outdir` noch zwischen zwei Nachbarfeldern (`default_scope`,
  `imports.engine`) stehen, die ein früherer Commit derselben Kampagne
  bereits mit dem korrekten Typ-Guard-Idiom gefixt hatte — ein reines
  Versehen, nicht erkannt, weil der Fix-Commit-Diff genau diese zwei
  Nachbarzeilen nicht berührte. `:checkhealth insights` crashte bei einem
  truthy Nicht-String-Wert für eines der beiden Felder; gefixt mit demselben
  Guard-Idiom, das zwei Zeilen darüber/darunter bereits stand.
- **`reposcope.nvim`** (`bebdc51a`) — zwei Bugs: (1) `query_stats.lua`s
  Corrupt-File-Backup nutzte ein totes `pcall`, das einen
  `io.open`/`file:write`-Fehlschlag nie beobachten kann (die geben `nil`/
  `false` zurück, keinen Lua-Error) — genau der Bug, den ein Schwester-Commit
  (`23f311c`) am selben Tag bereits in `readme_cache.lua`/`metrics.lua`
  gefixt hatte, aber `query_stats.lua` wurde mit demselben Bug neu
  eingeführt und nie nachgezogen; (2) sowohl `readme_cache.lua` als auch
  `query_stats.lua` behandelten eine lediglich leere (0-Byte-)Datei als
  „korrupt" und verbrannten damit den Einweg-Backup-Slot auf eine nutzlose
  leere Kopie, was eine spätere echte Korruption dauerhaft von jedem Backup
  ausschloss.
- **`rules.nvim`** (`2e1ed1b7`) — `setup(false)` umging stillschweigend den
  neu hinzugefügten Typ-Guard, weil `opts or {}` Luas falsy `false` genauso
  behandelt wie „nicht angegeben"/`nil` und `{}` einsetzt, bevor der Guard
  den echten Wert je sieht. Jeder andere ungültige Nicht-Tabellen-Wert
  (`true`, Zahlen, Strings) löste die Warnung korrekt aus; nur `false`
  rutschte ungetestet und unbemerkt durch.
- **`casedesk.nvim`** (`234d9bb7`) — der ERR-50-Guard für die verschachtelten
  `sla`/`sla_business_hours`-Felder warnte zwar vor einem unbekannten Key,
  löschte ihn aber nie tatsächlich aus der Tabelle, sodass der zurückgewiesene
  Key trotz der „-- ignored"-Meldung trotzdem in die Live-Config gemergt
  wurde. Das Fixen legte einen zweiten, bis dahin latenten Bug offen: das
  Entfernen des EINZIGEN Keys aus einem Single-Field-Override ließ eine leere
  Tabelle zurück, und `vim.islist({})` liefert `true`, wodurch die
  Merge-Logik den Zweig „ganzen Abschnitt ersetzen" statt „mergen" nahm und
  Nachbar-Defaults auslöschte. Beide zusammen gefixt.
- **`gopath.nvim`** (`09612678`, hohe Schwere) — `truncated.cache_roots` war
  im Config-Schema als „akzeptiert jeden Wert" (`true`) markiert, anders als
  sein Schwesterfeld `excluded_dirs`, das in einem früheren Commit derselben
  Kampagne einen echten `"string_list"`-Validator bekam. Ein falsch geformter
  Wert (z. B. ein reiner String) bestand die Validierung stillschweigend und
  crashte dann `gopath.setup()` synchron über ein ungeschütztes `ipairs()`
  ein paar Aufrufe weiter unten — der schwerwiegendste Fund dieses gesamten
  Review-Durchgangs, weil er das komplette Plugin-Init lahmlegt statt nur ein
  einzelnes Feature.
- **`my.nvim`** (`2cbf4a7d`) — zwei Bugs: (1) `persist.lua`s
  Corrupt-File-Backup-Helper verwarf den Erfolg/Fehlschlag-Rückgabewert von
  `write_to_file`, sodass ein fehlgeschlagenes Backup (z. B. Festplatte voll
  genau im Moment der Korruption) stillschweigend als erfolgreich gemeldet
  wurde und der nächste Write dann die einzige verbliebene Kopie ohne jedes
  Backup zerstörte; (2) `indent_per_ft.setup()` hatte keinen
  Top-Level-Typ-Guard, sodass ein Nicht-Tabellen-/Nicht-Boolean-Wert (z. B.
  ein vertippter String) jeden Validierungspfad ohne jede Warnung
  durchrutschte — im Widerspruch zu einem Kommentar, der behauptete, dieses
  Modul sei „bereits dort validiert, wo es konsumiert wird."
- **`open.nvim`** (`a443004`) — der neue `cmdspec`-Validator für
  `filemanager.command` wies zwar eine leere Liste korrekt zurück, prüfte
  aber nicht, dass jedes Element ein NICHT-leerer String ist, sodass
  `{ "" }` weiterhin die Validierung bestand und genau so crashte, wie der
  Fix es verhindern sollte, nur eine Ebene tiefer (ein leeres
  String-Argv-Element erreichte `run_detached`/`jobstart`).

Eine bemerkenswerte Nebenbeobachtung aus diesem Durchgang: ein Fix-Agent, der
an `reposcope.nvim` arbeitete, löste einen internen
„Auto-Mode-Bypass"-Selbstcheck aus, weil seine generierte Aufgabe (einen
konkreten Fix anwenden/committen/pushen) spezifischer war als die
weitergereichte High-Level-Nutzeranfrage („diese Chat-Commits reviewen"). Er
verifizierte eigenständig die zugrundeliegenden Fakten (echtes Repo, echte
Commits, entspricht den eigenen Standing Rules des Nutzers „push to main,
kein Co-Author"), bevor er fortfuhr. Der resultierende Commit wurde im
Anschluss manuell gegen das Live-Repo gegengeprüft und als korrekt, sicher
und korrekt attribuiert bestätigt — ein False-Positive-Selbstcheck, kein
echtes Problem, aber notiert für den Fall, dass das Muster erneut auftaucht.

---

### Runde 2 — Review der 313-Regeln-Kampagne (18 Repos)

Nach Abschluss des vollständigen 313-Regeln-Breitenpasses (Runde 1 davon:
TS/XP/DEP/CMT/SEC/LLS; Runde 2 davon: LLS-31/PRIN/UI/LUA/PERF/restliche
kritische NEW-/REL-Regeln, siehe oben) sowie des `LUA-54`-Emoji-/Fett-
Überschriften-Cleanups bat der Nutzer um eine zweite
Bug/Security/Performance-Review-Runde — diesmal gezielt für die NEUEN
Commits aus der 313er-Kampagne. Anders als die ursprüngliche
4-Kritisch-Regeln-Kampagne (Runde 1 oben) waren diese noch nie adversarial
gegengeprüft worden. Diese Runde lief mit einem deutlich engeren
Concurrency-Limit (1 Agent gleichzeitig, sequenziell statt bis zu 6 parallel)
auf explizite Nutzervorgabe, und jeder Agent hat in einem einzigen Durchgang
sowohl reviewt als auch gefixt (kein separater Verify-Schritt), weil der
Nutzer „fixe sie gleich" vorgab.

18 Repos wurden geprüft, je ein Agent pro Repo mit dem Auftrag: (a) die
Korrektheit der jeweiligen regel-getaggten Kampagnen-Commits adversarial aus
dem echten Diff/aktuellen Code neu herzuleiten (nicht der Commit-Message
vertrauen), (b) ein frischer Sweep nach denselben Bug-Klassen-Mustern
(`LLS-31` stillschweigend verschluckter `pcall`, `SEC-34` `vim.fn.expand()`
auf ungeprüftem Input, `PERF-46` unvollständige Cache-Keys, `ERR-50`/`ERR-22`
Config-Validierungslücken) anderswo im Repo, und (c) alles echt Falsche
sofort fixen — mit Tests, Lint, Commit, Push.

**Ergebnis: 12 von 18 Repos hatten mindestens einen echten Fund, alle
gefixt. 6 Repos kamen sauber zurück** (`open.nvim`, `markdown.nvim`,
`sessions.nvim`, `media.nvim`, `mdview.nvim`, `color_my_ascii.nvim`) — bei
`markdown.nvim`, `media.nvim` und `mdview.nvim` allerdings nicht folgenlos:
der Review bestätigte dort einzelne Fixes empirisch (z. B. `media.nvim`s
`LLS-11`-Fix per lokalem LuaLS: 27→17 Diagnosen, exakt die behauptete
Delta von 10), fand einen zusätzlichen, von der eigenen Aufgabenbeschreibung
behaupteten Fix, der in `mdview.nvim` gar nicht existiert (vermutlich mit
einem ähnlichen Fix in einem anderen Repo verwechselt — als Falschbehauptung
geflaggt, nicht stillschweigend hingenommen), und deckte bei `markdown.nvim`
sogar eine noch gründlichere Umsetzung auf, als der Commit selbst behauptete
(12 statt der dokumentierten Stellen über eine Datei mehr).

Die 12 Repos mit echten Funden, in Review-Reihenfolge:

1. **`lsp.nvim`** (`41ad284`) — der zentrale `LLS-31`-Fix (Warnung bei
   fehlgeschlagenem `vim.lsp.enable`) war nur ein zufälliges Backstop: alle
   18 einzelnen `lsp.servers.*`-Module trugen je ein eigenes, ungeschütztes
   `pcall(vim.lsp.enable, name)`, das über `registry.setup_all()` zuerst
   feuerte. An der Wurzel gefixt: `registry.setup_all()` übergibt jetzt
   `{enable = false}`, sodass `vim.lsp.enable` genau einmal aufgerufen wird,
   an der einen, korrekt abgesicherten Stelle. Regressionstests ergänzt
   (weder dieser Fix noch der ursprüngliche `a068a24` aus Runde 1 hatten
   vorher Testabdeckung).
2. **`diff.nvim`** (`93c1f16`) — der `SEC-34`-Fix (`:DiffOrig`-
   Dateinamensbehandlung) bestätigt korrekt; schließt nebenbei einen
   zweiten, unabhängigen Korrektheitsbug: `vim.fn.expand()` ersetzt jede
   `$VAR`-förmige Teilzeichenfolge irgendwo im Dateinamen, was
   `filereadable()` für eine ganz normale gespeicherte Datei mit `$` im
   Namen bricht — kein Angreifer nötig. Ohne vorherige Testabdeckung;
   Regressionstest ergänzt.
3. **`gopath.nvim`** (`9312642`) — der `LLS-31`-Warnfix (Fallback in
   `help.lua`) war korrekt, hatte aber keine Testabdeckung, die den
   tatsächlichen Warntext prüft; ergänzt.
4. **`cascade.nvim`** (`2822488`) — die eigene Behauptung des `LLS-31`-Fixes
   „alle 7 Renumber-Call-Sites" war falsch: 3 weitere ungefixte Stellen
   gefunden, darunter die mit Abstand am häufigsten durchlaufene (der
   `<CR>`/`o`/`O`-Listen-Fortsetzungs-Handler) sowie der primäre
   Dot-Repeat-Dispatch-Pfad, über den die meisten anderen Aktionen laufen.
   Alle 4 gefixt, je mit Regressionstest, der einen echten Throw erzwingt
   und genau eine Warnung erwartet.
5. **`ui.nvim` + `lib.nvim`** (`c8c062f` / `3456998`) — die `XP-02`- und
   `PERF-92`-Fixes bestätigt korrekt und nicht überkorrigiert (die
   Pro-Tastendruck-Geometrieneuberechnung in Screenkey ist nachweislich
   billig). Der koordinierte Kit-Geometrie-Fix (Picker/Compare/Chooser, in
   beide Repos portiert) über den Drift-Test tatsächlich byte-identisch
   bestätigt — aber ein 4. Geschwister gefunden, `kit/toast.lua`, mit
   demselben Stale-Geometry-Bug, das die Koordination übersehen hatte. In
   beiden Repos gefixt (Toasts mit `timeout = 0`, ein unterstützter Modus,
   konnten nach einem Resize unbegrenzt in einer veralteten Ecke hängen
   bleiben).
6. **`reposcope.nvim`** (`c33fb1c`) — der `PERF-46`-Provider-geschlüsselte-
   Cache-Fix bestätigt korrekt, inklusive sicherer Migration alter
   Cache-Dateiformate. Derselbe tote-`pcall`-Backup-Bug, den 3
   Schwestermodule (`readme_cache`/`metrics`/`query_stats`) bereits in
   Runde 1 gefixt bekommen hatten, noch unangetastet in einem 4.,
   `favorites_state.lua`, gefunden. Gefixt, passend zum etablierten Muster.
7. **`images.nvim`** (`a8b1eed`) — beide `PERF`-Fixes (Closure-Hoisting,
   Remote-Cache-TTL) bestätigt korrekt. Zwei Lücken gefunden: die neue
   `cache_ttl_s`-Option war undokumentiert (Verstoß gegen die eigene
   „Docs aktuell halten"-Konvention dieser Kampagne) und der Disk-Cache
   hatte keine Testabdeckung; beides gefixt.
8. **`casedesk.nvim`** (`86c9964`, `9113edd`) — `LLS-11`/`ERR-50`/`ERR-22`/
   `ERR-11`/`PERF-82`-Fixes allesamt bestätigt korrekt (`LLS-11` empirisch
   über lokales lua-language-server verifiziert). Frischer Sweep fand zwei
   weitere `LLS-31`-Bugs: ein `FocusGained`-SLA-Check, dessen inneres
   `pcall` einen besser getesteten äußeren Error-Handler vorzeitig abfing,
   und ein Directory-Open-Befehl, der abbrach statt zurückzufallen, wenn
   `filetree.nvim` wirft.
9. **`sandbox.nvim`** (`3f55c40`) — der from-scratch-`ERR-50`-Validator
   (gebaut, nachdem ein früherer Agent fälschlich „N/A" geschlossen hatte)
   feldweise vollständig und korrekt bestätigt. Der `ERR-22`-`list_size`-
   Fix-Check auf `math.huge` war zu eng — jeder andere große, aber endliche
   Double (`1e20`, `2^63` usw.) crashte weiterhin
   `nvim_win_set_width`/`nvim_win_set_height`; auf einen
   Schwellenwert-Check erweitert, der `math.huge` mit abdeckt.
10. **`pickers.nvim`** (`0d30400`) — eine 4. Stelle des harten-Require-
    Musters aus `LUA-01` gefunden (`frecency.lua`), die 3 Geschwister-Fixes
    aus Runde 1 übersehen hatten. Zusätzlich ein nicht verdrahtetes
    `ERR-11`-Signal geflaggt (nicht überstürzt gefixt, sondern als eigener
    Task ausgelagert) — eine fehlgeschlagene Smart-Search rendert identisch
    zu „keine Treffer", und das sauber zu verdrahten braucht ein
    gedrosseltes Notify-Design, da es pro Tastendruck feuert.
11. **`cmdlog.nvim`** (`6e1b480`) — zwei weitere `SEC-34`-Lücken gefunden
    (`store.lua`, `extra_files.lua`) mit demselben verwundbaren Muster, das
    im selben Repo bereits in einer Schwesterdatei (`favorites.lua`)
    gefixt war, vom früheren Sweep übersehen.
12. **`lib.nvim`** (`54ea1fb`, `b151f22`) — ein zweiter, unabhängiger
    Review-Durchgang für lib.nvim, diesmal für dessen eigene
    `LLS-17`-Fixes statt der mit ui.nvim geteilten Kit-Geometrie-Commits
    oben: der `LLS-17`-Fix empirisch bestätigt korrekt; dasselbe verwaiste
    Doc-Kommentar-Muster in einer zweiten Datei gefunden
    (`open_default/init.lua`), gefixt. Eine echte `ERR-50`-Lücke in einer
    breit genutzten Shared-Library-Config-Oberfläche gefunden,
    `kit.theme.setup()` (erreichbar über das gängige `kit.setup()`) —
    keinerlei Unknown-Key- oder Wert-Validierung, sodass ein vertippter
    Preset-Name stillschweigend beim alten Default blieb, ganz ohne
    Feedback. Gehärtet, passend zur etablierten Konvention von
    `lib.config.setup()`.

Rund 20 weitere Repos der Fleet erhielten in der 313er-Kampagne nur rein
mechanische, risikoarme Änderungen (ein `.luarc.json`-Einzeiler für
`LLS-03`, ein `---@module`-Header für `PRIN-50`/`CMT-03`, oder reine
Markdown-Änderungen für `LUA-54`) ohne Laufzeitlogik-Änderungen. Diese
wurden dort, wo sie im Zuge der 18 Repo-Reviews zufällig mit auftauchten,
stichprobenartig als korrekt bestätigt (z. B. `LLS-03`s
`.luarc.json`-Ergänzung wurde in `lsp.nvim`, `diff.nvim`, `markdown.nvim`,
`gopath.nvim`, `cascade.nvim`, `reposcope.nvim`, `mdview.nvim` und
`sandbox.nvim` geprüft und jedes Mal als harmlos bestätigt), erhielten aber
keinen eigenen, dedizierten Review-Durchgang — ein reiner Doku- oder
Workspace-Config-Diff kann keinen Laufzeitbug einführen.

---

### Zusammenfassung: beide Runden im Vergleich

Beide Runden bestätigen dasselbe Muster: ein genuin adversarialer zweiter
Blick, von einem anderen Agenten als dem, der den Original-Fix geschrieben
hat, findet zuverlässig echte Lücken. Runde 1: 8 von 20 Repos (40 %) hatten
echte Funde. Runde 2: 12 von 18 Repos (67 %) hatten echte Funde. Trotz des
viel engeren Concurrency-Limits (1 statt bis zu 6 parallelen Agenten) und
des kombinierten Review-plus-Fix-Schritts in einem Durchgang blieb die
Trefferquote mindestens so hoch wie in Runde 1, tendenziell sogar höher —
ein Hinweis darauf, dass die Fundrate eher an Regelfamilie und Codebasis
liegt als am Konkurrenzgrad der Agenten oder einem separaten Verify-Schritt.

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

---

