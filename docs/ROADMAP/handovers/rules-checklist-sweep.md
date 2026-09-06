# Handover — RULES.md Checklist-Familien-Sweep

Fortlaufende Arbeit an
[`docs/ROADMAP/personal/All/FINISH/RULES.md`](../personal/All/FINISH/RULES.md):
die 9 Regel-Familien aus `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/`
(`PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) werden Familie für Familie
gegen alle 32 Personal-Plugin-Repos geprüft. `RULES.md` selbst ist die
laufende Quelle der Wahrheit für den Stand — diese Datei ist nur der
Einstiegspunkt für eine neue Session.

## Stand bei Übergabe (2026-09-06)

| Familie | Status |
|---|---|
| `LLS-*` (34) | ✅ fertig |
| `SEC-*` (23) | ✅ fertig |
| `DEP-*` (7) | ✅ fertig |
| `TS-*` (5) | ✅ **gerade fertig geworden** — 0 Befunde, komplett N/A (kein Repo hat eigene Query-Dateien) |
| `PRIN-*` (37) | ⬜ offen |
| `ERR-*` (34) | ⬜ offen |
| `UI-*` (34) | ⬜ offen |
| `LUA-*` (45) | ⬜ offen |
| `PERF-*` (57) | ⬜ offen |

## Nächster Schritt

`RULES.md` §"Vorschlag für die Reihenfolge": `ERR-*`/`UI-*` (je 34,
mittelgroß) → `PRIN-*` (37) → `LUA-*` (45) → `PERF-*` (57, größte). Keine
feste Vorgabe, nur eine Einschätzung nach Größe — bei Bedarf umsortieren.

Methodik siehe `RULES.md` §"Methodik-Hinweise für den nächsten Durchlauf":
mechanisch prüfbare Muster per Grep über alle 32 Repos auf einmal (wie bei
`DEP-*`/`TS-*`), kontextabhängige Regeln (wie die meisten `ERR-*`/`PRIN-*`)
brauchen echtes Lesen — dafür **1 Agent/Repo pro Durchgang, nicht mehrere
parallel** (Session-Limit, siehe Claudes Memory
`feedback_agent_limits_and_language`).

## Standing Rules für diese Arbeit

- Antworten deutsch, Code/Kommentare englisch.
- Docs/README des jeweiligen Plugins mitpflegen, wenn ein echter Fund gefixt
  wird.
- Sofort auf `main` committen/pushen, sobald etwas in einem Repo gefixt
  wurde — nicht sammeln.
- Kein Claude-Co-Autor in Commit-Messages dieses Repos (nvim-config) — siehe
  Claudes Memory `no-coauthor-commits`.
- Diese Handover-Datei bei jedem weiteren Fortschritt aktualisieren, nicht
  nur einmalig anlegen.
