# ui.nvim / my.nvim

## Notes

Roadmap und hHandover files findest du hier:
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/ui.nvim`
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/my.nvim`

- never start more than 1 agents simultaneously; if more are needed, run multiple rounds of up to 1 agents each
- antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden
- Die Installations-Specs meiner Pluigns findest du in: vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua
- Gib immer aus was du gerade machst / ob es interessante unde gab - damit ich Bescheuid weiß.
- Docs / ../README-New/README.md des Plugins updaten sofern es Sinn macht
- Keine Co-Authorenschaft von Claude in den Commits
- Wenn du mit etwas fertig bist committe / pushe / pulle so dass das uupdate sofort im main branch, sodass ich es gleich verwenden kann.
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOL-PLACEMENT.md` (Tool bauen vs. Wegwerf-Skript, wohin damit)
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md` (keine großen/escapehaltigen Literale durch die Shell)
- code der implementiert wurde muss luacheck / stylua grün sein

## Schritt 7: chadrc.lua im echten Config-Repo umbauen

## lib.nvim integration

 Durchgehedn lib verwendet wo möglich?

## Checke ab, ob kreuzfeatures zu menen andren plugin smöglich/sinnvoll wüären

#### Plugin-Liste

Hier die Liste meiner Plugins - du findest sie unter `$REPOS_DIR\repos` - und du hast Zugriff darauf:

buffer-ctx.nvim
cascade.nvim
casedesk.nvim
cmdlog.nvim
color_my_ascii.nvim
dap.nvim
debugging.nvim
diff.nvim
documentation.nvim
emojis.nvim
fileops.nvim
filetree.nvim
github_stats.nvim
gopath.nvim
hover.nvim
images.nvim
insights.nvim
language.nvim
lib.nvim
lsp.nvim
markdown.nvim
media.nvim
mdview.nvim
open.nvim
pdfport.nvim
pickers.nvim
recommender.nvim
replacer.nvim
reposcope.nvim
runtime-analysis.nvim
sandbox.nvim
sessions.nvim
spotlight.nvim
ui.nvim

## aabklären ob ncoh offen:

### neotest-Config nicht extrahiert
lua/config/neotest/** lebt weiterhin im Host, in nvim.nvim.md als eigenständiges/dap.nvim-Sibling-Kandidat vorgeschlagen. Kein Repo dafür angelegt, unabhängig von ui.nvim/my.nvim.

### Zwei Duplizierungsfunde in der echten Host-Config
Kitty-Padding doppelt in general+terminals, last_loc doppelt in general+text — beide noch nicht bereinigt. Klein, unabhängig von der Plugin-Frage, in der laufenden nvim-Config zu fixen.

---


