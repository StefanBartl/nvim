# casedesk — Autocmds — umgezogen

Liegt seit 2026-09-04 im Plugin-Repo:

- lokal: `$REPOS_DIR/casedesk.nvim/docs/BINDINGS.md`
- remote: <https://github.com/StefanBartl/casedesk.nvim/blob/main/docs/BINDINGS.md>

casedesk hat genau einen Autocmd (`FocusGained`, Gruppe `CasedeskSlaNotify`,
aus `sla/notify.lua`). Er steht jetzt im `Autocommands`-Abschnitt von
`docs/BINDINGS.md` im Plugin-Repo.

Diese Seite behauptete bis 2026-09-04 „None". Der zitierte Grep war echt, lief
aber vor dem SLA-Notifier — eine Seite, die ein Negativum behauptet, veraltet,
ohne dass je etwas fehlschlägt.

Für den Bindings-Index dieser Config (den `:Bindings` liest) ist weiterhin
[`docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/casedesk.nvim.md`](../PersonelPlugins/BINDINGS/Usercmds/casedesk.nvim.md)
zuständig — das ist ein anderer Korpus als dieser Ordner.
