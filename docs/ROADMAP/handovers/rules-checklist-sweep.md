# Handover — RULES.md Checklist-Familien-Sweep

Fortlaufende Arbeit an
[`docs/ROADMAP/personal/All/FINISH/RULES.md`](../personal/All/FINISH/RULES.md):
die 9 Regel-Familien aus `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/`
(`PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) werden Familie für Familie
gegen alle 32 Personal-Plugin-Repos geprüft. `RULES.md` selbst ist die
laufende Quelle der Wahrheit für den Stand — diese Datei ist nur der
Einstiegspunkt für eine neue Session.

## Stand bei Übergabe (2026-09-07, neunte Aktualisierung — UI-* fertig)

| Familie | Status |
|---|---|
| `LLS-*` (34) | ✅ fertig |
| `SEC-*` (23) | ✅ fertig |
| `DEP-*` (7) | ✅ fertig |
| `TS-*` (5) | ✅ fertig |
| `ERR-*` (34) | ✅ fertig — 32/32 Repos, 17 echte Bugs gefixt |
| `UI-*` (34) | ✅ **fertig** — 32/32 Repos, **0 echte Bugs** |
| `PRIN-*` (37) | ⬜ offen |
| `LUA-*` (45) | ⬜ offen |
| `PERF-*` (57) | ⬜ offen |

## UI-* — Abschlussnotiz

`UI-*` ist die erste Familie, die **ganz ohne Fund** durchläuft (0 Bugs in
allen 32 Repos gegen alle 34 Regeln — 5 davon, `UI-57`..`61`, waren schon
vorher durch einen separaten Checkhealth-Audit erledigt). Plausible
Erklärung: mehrere `UI-*`-Regeln im Katalog zitieren Repos aus genau
diesem 32er-Bestand als *positive* Referenzbeispiele in ihren eigenen
Belegen — der Katalog wurde also mindestens teilweise aus der Beobachtung
dieses Fleets geschrieben. Die einzigen im Katalog als Lücke vermerkten
Fälle (`UI-21`/`UI-22`) liegen außerhalb der 32 Repos (nvim-config,
learn-cli.nvim).

**Einzige Beobachtung, bewusst nicht gefixt:** `lib.nvim.bindings.keymap.which_key`s
Gruppen-Label hängt am deklarierten `spec.prefix`, nicht an den nach
Nutzer-Remapping tatsächlich aufgelösten `lhs`-Werten (`UI-27`). Kein
demonstrierbarer Bug — which-key zeigt jede Zuordnung ohnehin über ihr
eigenes `desc` an, ein remapptes Item verliert nur die
Submenü-Gruppierung, keine Funktion. Fleet-weit über `lib.nvim` geteilt.

**Wichtige Kalibrierung für künftige Familien:** `UI-36` (Quickfix-Export
für Trefferlisten) fehlt laut Katalog-Beleg fast im ganzen Fleet — das ist
ein bekannter, dokumentierter Feature-Gap, kein Bug, und wurde bewusst
nicht nachgerüstet (wäre Feature-Entwicklung über 30 Repos). Dieselbe
Kalibrierung (Bug vs. Feature-Lücke) lohnt sich als Leitplanke für
`PRIN-*`/`LUA-*`/`PERF-*`.

Volle Details zur Methodik (fleet-weite Mechanik-Checks, Repo-für-Repo-
Ergebnisse) stehen in `RULES.md` selbst unter „✅ UI-* (34 Regeln) —
fertig" — nicht hier dupliziert.

## Nächster Schritt

Laut `RULES.md` §"Vorschlag für die Reihenfolge": **`PRIN-*`** (37 Regeln,
Grundprinzipien: Modularität, API-Design, Namenskonventionen,
Dokumentationspflichten) als Nächstes → `LUA-*` (45) → `PERF-*` (57,
größte, da sie am meisten Kontext pro Fund braucht — Hotpath-Beurteilung
statt reinem Pattern-Matching). Keine feste Vorgabe, nur eine
Einschätzung nach Größe.

Für `PRIN-*` sind noch keine repo-spezifischen Vorarbeiten gemacht — bei
Sitzungsstart zuerst den Regelkatalog (`PRINCIPLES.md`) lesen und prüfen,
ob (wie bei `UI-*`) Teile davon schon aus Fleet-Beobachtung entstanden
sind (Belege-Abschnitte mit Repo-Zitaten durchsuchen), bevor blind
angefangen wird.

## Standing Rules für diese Arbeit

- Antworten deutsch, Code/Kommentare englisch.
- Docs/README des jeweiligen Plugins mitpflegen, wenn ein echter Fund
  gefixt wird.
- Sofort auf `main` committen/pushen, sobald etwas in einem Repo gefixt
  wurde — nicht sammeln.
- Kein Claude-Co-Autor in Commit-Messages (weder in diesem Repo (nvim-config)
  noch in den einzelnen Plugin-Repos) — siehe Claudes Memory
  `no-coauthor-commits`.
- Diese Handover-Datei bei jedem weiteren Fortschritt aktualisieren, nicht
  nur einmalig anlegen.
- **1 Agent gleichzeitig, mehrere Runden zu je 1**, falls ein Subagent
  gebraucht wird — direktes Lesen in der Unterhaltung ist der Normalfall.
- **Erst grep-/mechanik-basierte Vorprüfung über alle 32 Repos**, bevor ein
  Repo einzeln gelesen wird — hat sich bei `ERR-*` und `UI-*` beide Male
  bewährt (spart Zeit, findet trotzdem die konkreten Fälle).
- **Bug vs. Feature-Lücke unterscheiden**: nur echte, demonstrierbare
  Defekte fixen (falsches Ergebnis, Datenverlust, Absturz, fehlende
  Completion für eine geschlossene Menge). Eine im Katalog selbst schon
  als fleet-weit fehlend dokumentierte Verbesserungsmöglichkeit (wie
  `UI-36`) nicht einzeln nachrüsten oder pro Repo wiederholt vermerken.
