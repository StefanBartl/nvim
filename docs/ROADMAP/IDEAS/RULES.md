# `rules.md`

EIn Plugin, dass die Regelsammlung unter
`E:\repos\WKDBooks\Development\wkdbook-Lua\Checklists` (`regeln/`, `gates/`:
NEW_PROJECT, REVIEW, RELEASE, PERFORMANCE, usw...) gegen ein Plugin prüft.

> Stand 2026-08-18: `nvim/docs/ROADMAP/RULES` ist dort hineingemergt, es gibt nur
> noch diesen einen Ort. Jede Regel hat eine stabile ID (`SEC-03`, `PERF-07`, …) —
> die ist die Verankerung, an der ein Report seine Befunde festmachen kann.
> Struktur und ID-Schema: `Checklists/README.md`, Ablauf: `Checklists/WORKFLOW.md`.

Features:

- dry-run / Report
- Detaileirtes durchgehen einzelner listen
- automatisches implementieren vs. Tasks zusammenschreiben
- ...

- [ ] dazu wäre es super, wenn man den user eine möglihkreit gibt, nach einem besitmmten scchema/dsyntax eigene checkls und rules eizufügen, die dann mit gecheckt wren.
  Das muss natürlich alles aufeinander abgestimmt sein...
- [ ] Analyse: Bringt es was,dem plugin ein C++/c/Rust/Go wsa auch immer, programm bereitsstellen, dass dann optimert darauf it, die checklists/rukes check usw... effizient udn sicher in einen projekt drzuziehen; sowas wie eine "runtime" die darauf wartee, eteas effizient zu recvhnen, solange das polugin aktiv aisrt
  - [ ] Die idee: die checksa werden üer eine bestimmte sysnax dfin fies geschireben, das plugin lauft mit nvim/lua, alles was aber perfomance bracht/threads/agenten usw.. wäre aber wrsch performanter mit eigenen dezifierten binary dabei oder?
- [ ] Eine übersicht/die wichtigsten viewsw bzw notes daraus, würden sich als weitere tab / reister / unterpnkt in `docuemnation.nvim ` browser bview zb sein

---

## Erkenntnisse aus einem echten Testlauf (2026-09-05, P5-Wiederholungsläufe)

Genau das hier skizzierte Szenario — „neues Projekt → Tools XY, Review →
Tools XY" — wurde händisch durchgespielt, bevor es dieses Plugin gibt: siehe
[`docs/ROADMAP/handovers/P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md`](../handovers/P5_WIEDERHOLUNGSLAEUFE_2026-09-05.md).
Drei Dinge, die das Konzept schärfen:

1. **Ein Teil der Werkzeuge existiert bereits, ist aber nicht angeschlossen.**
   `lib.nvim.bindings.audit` (`:LibBindingsAudit[Gaps]`) und
   `lib.nvim.dev.duplicates` (`:LibDuplicateScan`) sind fertige Module mit
   eigenem `create_usercmd()` — der aber in keiner Config je aufgerufen wird
   (siehe Nachtrag in
   [`roadmap-tools-analysis.md`](../personal/All/FINISH/ERLEDIGT/roadmap-tools-analysis.md)).
   **Bevor dieses Plugin neue Prüfungen baut, sollte es die vorhandenen
   zuerst real anschließen** — sonst entsteht ein zweiter, konkurrierender
   Weg zu denselben Daten.
2. **Die `LLS-*`-Familie (LuaLS-Diagnosen) braucht dieses Plugin nicht.**
   Sie wird bereits durch einen eigenen, aktiven Prozess (LuaLS + `luacheck`,
   siehe die `fix(luals): … zu 0`-Commits quer über die Sammlung) auf 0
   gehalten. Der Mehrwert dieses Plugins liegt in den **übrigen** ~250
   Regeln (`PRIN-`/`LUA-`/`ERR-`/`SEC-`/`UI-`/`TS-`/`DEP-`/`PERF-`), die
   keine mechanische Diagnose hat.
3. **Ein Repo komplett gegen alle Familien zu prüfen ist keine Kommando-
   Antwort in Sekunden.** Der Pilot an `buffer-ctx.nvim` (45 Dateien, nur
   ein Bruchteil der Regeln gezielt geprüft) hat bereits spürbare Zeit
   gebraucht. Für „neues Projekt"/„Review" realistisch: das Plugin sollte
   **wellenweise pro Regel-Familie** anbieten (`:Rules check --family=SEC`),
   nicht zwingend „alles auf einmal" — sonst ist der Dry-Run-Report so lang,
   dass ihn niemand liest, und die erste Anwendung scheitert an der eigenen
   Vollständigkeit.

---

