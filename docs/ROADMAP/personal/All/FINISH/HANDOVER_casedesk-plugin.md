# Handover — casedesk als eigenes Plugin (`casedesk.nvim`)

**Stand: 2026-09-04, Phase 0 und Phase 1 abgeschlossen. Als Nächstes:
Phase 2 (`config.setup(opts)` plus Bereichs-Datenmodell).**

Auftrag: `lua/bindings/usrcmds/case/` aus der nvim-Config nach
`StefanBartl/casedesk.nvim` auslagern (privat), dabei naheliegende Features
ergänzen und passende Schwesterplugins einbinden.

**Der Plan ist die Quelle, nicht diese Datei:**
[`docs/ROADMAP/casedesk/PLUGIN.md`](../../casedesk/PLUGIN.md) — Ausgangslage
mit Messwerten, Zielstruktur, sieben Phasen, Entscheidungen mit Begründung,
Bereichs-Konzept (§7), Schwesterplugins (§8), Feature-Backlog (§9).
Diese Datei sagt nur: **wo stehen wir gerade, was kommt als Nächstes.**

---

## Orte

| Was | Wo |
| --- | --- |
| Zielrepo (GitHub, privat) | <https://github.com/StefanBartl/casedesk.nvim> |
| Checkout | `$REPOS_DIR/casedesk.nvim` |
| Quelle (noch aktiv!) | `nvim/lua/bindings/usrcmds/case/` |
| Plan | `nvim/docs/ROADMAP/casedesk/PLUGIN.md` |
| Konzept-Docs | `nvim/docs/ROADMAP/casedesk/` |
| Bindings-Docs | `nvim/docs/NOTES/casedesk/` |
| Verbindliche Regeln | `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists` |
| Notizen/Messungen | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/` |
| Echte Case-Daten | `$REPOS_DIR/WKDBook-Tricentis/Cases/{SAP_Support,CS,Solutions}` |

---

## Erledigt

- [x] **GitHub-Repo angelegt** (2026-09-04) — privat, ohne Auto-Init.
- [x] **Bestandsaufnahme, gemessen** — 39 Lua-Dateien, 11.295 Zeilen,
      17 `lib.nvim`-Module als einzige Abhängigkeit, exakt 3 externe
      Konsumenten in der Config. Details: PLUGIN.md §1.
- [x] **Plan geschrieben** — PLUGIN.md, sieben Phasen.
- [x] **Datenlage gesichtet** — dabei drei für casedesk unsichtbare Cases
      gefunden (s. „Befunde" unten).
- [x] **Vorgaben eingearbeitet** — `gates/NEW_PROJECT.md` in Phase 0/2,
      Parallelbetrieb statt Löschen (§3.8), Schwesterplugins (§8),
      Feature-Backlog (§9).
- [x] **`wkdbook-casedesk` angelegt** — `wkdbook-myplugins/casedesk.nvim/`
      mit `README.md`, `ROADMAP/`, `Messungen/`. Committet und gepusht.
- [x] **`:Cases doctor`-Baseline aufgenommen** (2026-09-04, **vor**
      Phase 1) — 20 Funde, gesichert unter
      `wkdbook-myplugins/casedesk.nvim/Messungen/doctor-baseline-2026-09-04.md`
      samt Kommandozeile zum Wiederholen. Das ist das Regressionsnetz für
      den Umzug.
- [x] **Phase 0 — Repo-Skelett steht** (Commits `da2a7fe`, `dc168a4`,
      gepusht). Details unten.

## Phase 0 im Einzelnen — was steht

- Struktur nach NEW-07/08/09/10: `config/{init,DEFAULTS}.lua`,
  `bindings/{usrcmds,keymaps,autocmds}.lua`, `@types/init.lua`,
  `health.lua`. Alles Gerüste mit `TODO(phase N)` — Phase 1 zieht die 39
  echten Module hinein.
- Keine `LICENSE` (NEW-06), `docs/map/` gitignored und kein
  `gen_map --check` in CI (NEW-20), `scripts/gen_map.lua` übernommen und
  auf casedesk angepasst (inklusive zweier Layer-Regeln: `extract/*` und
  `config` dürfen nicht auf `ui` zugreifen).
- `README.md` englisch mit ASCII-Art, Badges, Schwesterplugin-Absatz
  (NEW-11/12). `doc/casedesk.txt`, `docs/{ROADMAP,BINDINGS,installation,
  configuration}.md` als Gerüste; `docs/ROADMAP.md` ist bereits echt und
  trägt den Feature-Backlog.
- `gh repo edit` mit Beschreibung und Topics (NEW-04/05).
- Tests: `TESTS/minimal_init.lua` + `scripts/test.sh` (plenary/busted,
  NEW-39/40), `TESTS/smoke_spec.lua` mit vier grünen Zusicherungen. CI:
  drei Jobs (stylua, luacheck, tests mit `lib.nvim` und `plenary.nvim`
  als `.deps/`-Checkouts).
- **Nullmessung: 0 Befunde** (NEW-44), dreimal gemessen, `worse: nothing`
  über alle Läufe.

## Phase 1 im Einzelnen — was steht

Commits `b91ac49` (Umzug), `160f7ed` (Lint + ein echter Bug), `9f8...`
(busted-Globals).

- 39 Module, 11.295 Zeilen umgezogen. Namespace-Rewrite
  `bindings.usrcmds.case` → `casedesk` und `bindings/usrcmds/case` →
  `casedesk` über `.lua` **und** `.md` in einem Durchgang — deckt
  requires, `---@module`-Annotationen und Pfade in Doc-Kommentaren
  zugleich. 0 Reste.
- Zwei Dateien wechseln die Rolle, nicht nur den Ort:
  `case/init.lua` → `bindings/usrcmds.lua` (es **ist** der Kommandobaum;
  `M.enable` → `M.setup`), `case/config.lua` → `config/DEFAULTS.lua`
  (es **ist** die Defaults-Tabelle). Das Gerüst-`init.lua` bleibt der
  `setup()`-Einstieg und treibt beide.
- `bindings/autocmds.lua` bleibt bewusst leer: den einen Autocmd
  (`FocusGained` für die SLA-Uhr) erzeugt `sla/notify.lua` neben dem
  Zustand, der entscheidet, ob er feuert. Die Datei sagt das jetzt,
  statt ein TODO zu tragen.
- `docs/FEATURES.md` mitgezogen, relative Links repariert.
- Verifiziert: alle 45 Module laden headless, Smoke-Suite grün, stylua
  und luacheck sauber.
- **Die Config-Kopie ist unangetastet und weiterhin die aktive.**

## Als Nächstes

- [ ] **Phase 2 — `config.setup(opts)`.** `config/init.lua` reicht die
      Defaults derzeit nur durch (`TODO(phase 2)` steht drin). Zu bauen:
      Deep-Merge plus `rebuild_derived()` für `root`, `cases_root`,
      `workflow_templates_dir`, `sla_doc_path` — **nur** für Schlüssel,
      die der User nicht explizit gesetzt hat. Dazu `@types/init.lua`
      (`Casedesk.Config` mit allen 30 Feldern) und `health.lua`.
- [ ] **Phase 2 mit: Bereichs-Datenmodell** (PLUGIN.md §3.6/§7.6
      Schritt 1) — `config.areas`, `state_dir(area, state)`,
      `RegistryEntry.area`. Macht die drei unsichtbaren Cases sichtbar,
      ohne dass sich ein Kommando ändert.
- [ ] Phase 3 — Umschalten, Config-Kopie einfrieren (nicht löschen!).

---

## Befunde, die den Plan geformt haben

**1. Drei Cases sind heute für jedes `:Case`-Kommando unsichtbar.**
`registry.lua` scannt nur `config.cases_root` = `Cases/SAP_Support/Cases`.
Nicht gefunden werden: die zwei Cases unter `Cases/CS/Open/` und der eine
unter `SAP_Support/Cases/T2/` (`T2` steht nicht in `config.states`). Kein
Umzugsproblem — ein bestehender Zustand. Konzept: PLUGIN.md §7.

**2. `Cases/CS/` ist flacher als `Cases/SAP_Support/`** — ohne die
`Cases/`-Zwischenebene. Deshalb bekommt jeder Bereich einen eigenen `dir`
statt eines abgeleiteten Pfadmusters.

**3. Die Kopplung ist klein.** `config.state_dir()` hat vier echte
Aufrufer; die anderen zwölf Registry-Konsumenten lesen `e.dir` aus dem
Eintrag und laufen unverändert weiter.

**4. `gates/NEW_PROJECT.md` widerspricht dem ersten Entwurf an vier
Stellen** — keine `LICENSE` (NEW-06), `docs/map/` nicht committen und
kein `--check` in CI (NEW-20), `bindings/`-Ordner (NEW-08),
cross-plattform statt Windows-only (NEW-30/31). PLUGIN.md §2.1.

**4b. Die Checkliste hat einen neuen Abschnitt 3** (NEW-36..NEW-46,
seit der LuaLS-Erhebung vom 2026-09-02), der beim ersten Phase-0-Commit
noch nicht vorlag — ein `git pull` im Checklisten-Repo brachte ihn
mitten in der Arbeit. Nachgebessert in `dc168a4`: `workspace.ignoreDir`
in `.luarc.json`, Tests auf plenary statt eigenem Harness, Nullmessung.
PLUGIN.md §2.2. **Vor dem nächsten größeren Schritt lohnt ein Blick, ob
sich dort wieder etwas geändert hat.**

**5. `spotlight.nvim` und `replacer.nvim` sind die stärksten
Integrationskandidaten** — Ersteres für hervorgehobene Fakten in
Activity Streams (die Extraktion existiert bereits), Letzteres als das
fehlende Werkzeug für die Anonymisierung vor KI-Übergaben. PLUGIN.md §8.1.

**6. Ein echter Bug, den luacheck beim Umzug gefunden hat** (Phase 1):
`similar.lua` deklariert `MIN_SHARED_TERMS = 2` mit einem Kommentar, der
ein am echten Bestand beobachtetes Problem beschreibt — und hat die
Konstante **nie angewendet**. Die Bedingung war ein blankes `dot > 0`,
das genau den Ein-Term-Treffer zulässt, den der Kommentar ausschließen
will. `:Case similar` hat also die ganze Zeit dünne Summaries mit einem
geteilten Allerweltswort nahe 1.0 gerankt. Gefixt in `160f7ed`.
Bemerkenswert ist, warum es nicht auffiel: ohne Tests scheitert ein
Ähnlichkeitsranker mit plausiblen, aber falschen Treffern nicht sichtbar.

**7. Der reguläre LuaLS-Scan ist bis Phase 7 unbrauchbar.** Er meldet
nach dem Umzug 231 Befunde, davon 230 in einer Regel — alle
`duplicate-doc-field` gegen die eingefrorene Zwillingskopie in der
Config, die der Scan als injizierte Library mitliest (`LLS-03`/`LLS-04`).
Eine Kontrollmessung ohne die Config in `workspace.library` ergibt **0**.
Weg und Beleg:
`wkdbook-myplugins/casedesk.nvim/Messungen/luals-phase1-messartefakt-2026-09-04.md`.
Bis Phase 7 ist die Kontrollmessung die gültige Zahl.

---

## Arbeitsregeln für diesen Auftrag

- **Die Config-Kopie bleibt aktiv nutzbar, bis das Plugin trägt.** Ab
  Phase 3 ist das Plugin die aktive Quelle und die alte Kopie ein
  auskommentiertes Rückfallnetz — **ab dann wird nur noch im Plugin-Repo
  geändert** (PLUGIN.md §3.8, Risiko §5.5).
- Verbindlich: `gates/NEW_PROJECT.md` beim Anlegen, `gates/REVIEW.md` vor
  jedem Merge, `regeln/` beim Schreiben.
- Commit/Push **immer auf `main`**, pro Repo einzeln, **ohne**
  `Co-Authored-By: Claude`.
- Code, Kommentare und Repo-Doku **englisch**; Konversation und
  Roadmap-/Handover-Dateien **deutsch**.
- Vor jedem Commit im Plugin-Repo: `stylua lua && luacheck lua`, dann der
  Test-Runner. **`stylua` nie über die nvim-Config laufen lassen** — sie
  ist nicht stylua-formatiert; dort nur geänderte Dateien einzeln.
- In der nvim-Config **nicht** `git add -A` — es arbeiten mehrere
  Sitzungen parallel daran. Nur explizit stagen.
- Keine Emojis, in Code wie in Doku.
