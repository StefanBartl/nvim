- checke alle commits dieses chats auf Bugs, Securitx / Performance Optimierungen und fixe sie gleich.

- never start more than 1 agents simultaneously; if more are needed, run multiple rounds of up to 1 agents each
- antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden
- Gib immer aus was du gerade machst / ob es interessante unde gab - damit ich Bescheuid weiß.
- Docs / README.md des Plugins updaten sofern es Sinn macht
- Keine Co-Authorenschaft von Claude in den Commits
- Wenn du mit etwas fertig bist committe / pushe / pulle so live-testing-braucht-laufende-interaktive-nvim-sessionass das uupdate sofort im main branch, sodass ich es gleich verwenden kann.
- code der implementiert wurde muss luacheck / stylua grün sein
- Die Installations-Specs meiner Pluigns findest du in: vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua
- Wenn nötig: Alle meine `.nvim` Plugins findest du unter `$REPOS_DIR\repos`
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/TOOL-PLACEMENT.md` (Tool bauen vs. Wegwerf-Skript, wohin damit) und `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/lua-plugin-tools.md`
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md` (keine großen/escapehaltigen Literale durch die Shell)
- Neue Features ggf. im Plugin-eigenen /TESTS/ folder testenV

`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/PERFORMANCE.md`
`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/LUA_NVIM.md`
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/`
