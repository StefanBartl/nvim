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

