# casedesk — Keymaps — umgezogen

Liegt seit 2026-09-04 im Plugin-Repo:

- lokal: `$REPOS_DIR/casedesk.nvim/docs/BINDINGS.md`
- remote: <https://github.com/StefanBartl/casedesk.nvim/blob/main/docs/BINDINGS.md>

casedesk registriert **keine** globalen Keymaps; alles, was es an Tasten gibt,
ist buffer-lokal in seinen `kit.viewer`-Oberflächen und steht jetzt im
`Keymaps`-Abschnitt von `docs/BINDINGS.md` im Plugin-Repo.

Die eine Ausnahme bleibt hier: `<leader>cs` (case-bewusstes Session-Speichern)
wird von [`lua/bindings/mappings/custom.lua`](../../../lua/bindings/mappings/custom.lua)
dieser Config registriert, nicht vom Plugin — es verbindet casedesk mit
`sessions.nvim` und gehört zu keinem von beiden.

`:Bindings` liest seit `BND-01` casedesk.nvims eigene `docs/BINDINGS.md`
direkt (`stdpath("data")/lazy/casedesk.nvim/docs/BINDINGS.md`) — der frühere
Abschrift-Sheet unter `PersonelPlugins/BINDINGS/` ist mit `BND-05` entfernt.
