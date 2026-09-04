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

Für den Bindings-Index dieser Config (den `:Bindings` liest) ist weiterhin
[`docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/casedesk.nvim.md`](../PersonelPlugins/BINDINGS/Usercmds/casedesk.nvim.md)
zuständig — das ist ein anderer Korpus als dieser Ordner.
