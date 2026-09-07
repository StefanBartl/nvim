# Handover — RULES.md Checklist-Familien-Sweep

Fortlaufende Arbeit an
[`docs/ROADMAP/personal/All/FINISH/RULES.md`](../personal/All/FINISH/RULES.md):
die 9 Regel-Familien aus `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/`
(`PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) werden Familie für Familie
gegen alle 32 Personal-Plugin-Repos geprüft. `RULES.md` selbst ist die
laufende Quelle der Wahrheit für den Stand — diese Datei ist nur der
Einstiegspunkt für eine neue Session.

## Stand bei Übergabe (2026-09-07, elfte Aktualisierung — LUA-* läuft)

| Familie | Status |
|---|---|
| `LLS-*` (34) | ✅ fertig |
| `SEC-*` (23) | ✅ fertig |
| `DEP-*` (7) | ✅ fertig |
| `TS-*` (5) | ✅ fertig |
| `ERR-*` (34) | ✅ fertig — 32/32 Repos, 17 echte Bugs gefixt |
| `UI-*` (34) | ✅ fertig — 32/32 Repos, 0 echte Bugs |
| `PRIN-*` (37) | ✅ fertig — 32/32 Repos, 1 Fund (notiert, nicht gefixt) |
| `LUA-*` (45) | 🔶 **in Arbeit** — `LUA-40`/`41` fleet-weit fertig (4 Repos gefixt), Rest offen |
| `PERF-*` (57) | ⬜ offen |

## LUA-* — Stand im Detail

**Zählung:** 45 Regeln, aber der Katalog selbst hat einen
Formatierungsfehler — `LUA-67`/`LUA-68` in der „`#`-Prefix bei
Kommentaren"-Tabelle sind keine echten Regeln, sondern versehentlich in
die ID-Spalte gerutschte Tabellen-Header-Zellen. Ein blinder Grep findet
47 `LUA-XX`-IDs; die echten 45 ergeben sich erst nach Abzug dieser zwei.

**Zwei im Katalog vermerkte Lücken waren beide schon gelöst** (Katalog
datiert 2026-09-06, nur nicht zurückgeschrieben): `LUA-01` fileops.nvim
(behoben durch `35cdd4b`), `LUA-04` pickers.nvim (behoben durch
`61a97e2`/`ea1ce1c`). Beide verifiziert, nicht erneut angefasst.

**`LUA-40`/`41` (Metatables/Weak-Tables) fleet-weit fertig, 4 Repos
gefixt** — der bisher wichtigste Einzelfund dieser Familie:

Grep nach `__mode` über alle 32 Repos findet 6 Treffer. `__mode = "k"`
(schwache Schlüssel) wirkt **nur** auf Tabellen/Funktionen/Userdata/
Threads, nie auf Zahlen — ein Cache, der mit einer `bufnr` (einer Zahl)
als Schlüssel arbeitet, wird davon **nie** automatisch geleert, egal wie
viele Buffer geschlossen werden.

- **lib.nvim** `buffer/context/init.lua` — **echter, unbegrenzter Leak**
  in geteilter Kern-Infrastruktur (am `FileType`-Autocmd-Dispatcher
  verdrahtet). Moduldoc behauptete fälschlich automatisches GC. Gefixt:
  `BufDelete`/`BufWipeout`-Autocmd ruft jetzt aktiv `invalidate()`.
  Commit `8b176be`, Regressionstest in `TESTS/context_spec.lua`
  (stash/reapply-verifiziert, `LIB_TESTS_OK`).
- **gopath.nvim** `alias_index.lua` + `binding_index.lua` — identischer
  echter Leak, gleicher Fix. Commit `bd10baf`. Kein Testframework in
  diesem Repo (nur manuelle Fixtures) — headless von Hand verifiziert.
- **color_my_ascii.nvim** `cache_manager.lua` — irreführende Doku, aber
  **kein echter Bug**: Cache hat bereits `max_size`-Deckel + einen
  30s-Timer, der real aufräumt, unabhängig von der wirkungslosen
  Metatable. Doku korrigiert, totes `setmetatable` entfernt, keine
  Verhaltensänderung. Commit `6577e66`.
- **filetree.nvim** `util/buffer.lua` — dieselbe irreführende Doku, aber
  ein `BufDelete`-Autocmd existierte schon im selben File und räumt
  bereits aktiv auf. Gleicher folgenloser Doku-Fix. Commit `0c92620`.
- **runtime-analysis.nvim**/**sessions.nvim** — beide korrekt (Schlüssel
  ist eine echte Tabelle, kein bufnr) — kein Fund.

## Nächster Schritt

`LUA-*` weiterführen. Noch offen (siehe RULES.md für den vollen Text):

- `LUA-01`..`05` — restliche lib.nvim-Abhängigkeitskonsistenz fleet-weit
  (nur die 2 Katalog-Lücken wurden bisher verifiziert, kein systematischer
  Durchgang über alle 32 Repos).
- `LUA-10`..`16` — Neovim-API-Sicherheit. **Vermutlich wenig Neues**:
  überschneidet sich stark mit dem bereits abgeschlossenen
  `ERR-32`/`33`/`34` (Handle-Validierung in Deferred Calls) und `SEC-*`.
  Kurzer Abgleich reicht wahrscheinlich, kein Vollaudit nötig.
- `LUA-30`..`34` — State/Datenmodelle: Getter/Setter statt Direktzugriff,
  Ringbuffer/FIFO mit Limit, Snapshot/Restore, Arrays statt Records.
  **Echtes Neuland**, noch nicht geprüft.
- `LUA-42`..`47` — weitere Metatable-Muster jenseits der bereits
  geprüften `40`/`41` (Shared Metatables mit Memoization, Defaultwerte
  über Metatable, `rawget` für „implementiert selbst?"). Ebenfalls
  Neuland, aber vermutlich seltener genutzt als `40`/`41` — lohnt sich
  trotzdem als fleet-weiter Grep-Durchgang (`__index`, `rawget`).
- `LUA-50`..`55` — Code-Stil. Größtenteils schon über die
  fleet-weiten `PRIN-35`/`50`-Checks abgedeckt (Naming, Header) — nur
  `LUA-54` (keine Emojis/fette Überschriften in Markdown-Docs) und
  `LUA-55` (paralleles statt XOR-Tauschen) sind noch nicht geprüft.
- `LUA-60`..`71` — Annotationen. Folgt größtenteils automatisch aus der
  abgeschlossenen `LLS-*`-Familie (0 LuaLS-Diagnostics fleet-weit
  impliziert korrekte `@param`/`@return`/`@type`) — wahrscheinlich nur
  eine kurze Bestätigung nötig, kein Vollaudit.
- `LUA-80`..`83` — Config-Defaults: typisierte Keys, möglichst viel
  user-seitig einstellbar. Neuland, noch nicht geprüft.

**Effiziente Reihenfolge-Empfehlung:** `LUA-30`..`34` und `LUA-42`..`47`
und `LUA-80`..`83` sind das eigentliche Neuland und verdienen die meiste
Aufmerksamkeit; `LUA-10`..`16`/`50`..`55`/`60`..`71` sind wahrscheinlich
schnelle Bestätigungen dank Überschneidung mit bereits abgeschlossenen
Familien.

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
  Repo einzeln gelesen wird — hat bei jeder bisherigen Familie funktioniert,
  zuletzt beim `__mode`-Grep für `LUA-40`/`41`.
- **Nicht jedes Repo hat ein automatisiertes Testframework** — gopath.nvim
  hat nur manuelle, interaktive Test-Fixtures. Bei fehlendem Framework:
  headless von Hand verifizieren statt eines Regressionstests, im Commit
  transparent machen.
- **Ein Fund ohne Verhaltensänderung ist trotzdem einen Fix wert**, wenn
  die Dokumentation eine falsche Garantie behauptet (wie bei
  color_my_ascii.nvim/filetree.nvim) — auch wenn kein echter Bug vorliegt,
  irreführende Kommentare/Docstrings über Speicher-Sicherheit sind ein
  Wartungsrisiko für die Zukunft.
