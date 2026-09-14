Vorgeschlagene Aufgabe
Fix emojis.nvim picker's dead vim.ui.select fallback claim
In E:\repos\emojis.nvim\lua\emojis\picker.lua, the module doc comment (lines 1-8) says: "telescope.nvim and fzf-lua are optional soft dependencies for a live-search picker over the full catalog (config.picker.engine); vim.ui.select is the built-in fallback and always works."

That claim is false. The actual fallback chain in M.insert() (bottom of the file) ends at a local function select_fallback(picks), which does:

require("ui.kit").select({...})

with no pcall and no further fallback to vim.ui.select. If ui.nvim (which now provides ui.kit, since a recent migration moved it off lib.nvim) is not installed, calling :Emojis insert with picker.engine = "select" (or falling through when telescope/fzf-lua aren't available) throws a hard require error instead of degrading to vim.ui.select as the docs promise.

Fix: either (a) make select_fallback actually pcall ui.kit.select and fall back to vim.ui.select on failure, matching the documented contract, or (b) if a real fallback is judged not worth the complexity, correct the module doc comment (and docs/requirements.md's ui.nvim row, and any other doc referencing this "always works" fallback claim) to state accurately that the select engine depends on ui.nvim being installed. Prefer (a) since the doc comment is quite explicit about the promised behavior. Run luacheck/stylua and the local test suite after, and commit with no Claude co-authorship line per this project's convention (verify via git log -1 --format='%B' | grep -i "co-authored\|claude" finding nothing) and push directly to main.


## Notes

- never start more than 1 agents simultaneously; if more are needed, run multiple rounds of up to 1 agents each
- antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden
- Die Installations-Specs meiner Pluigns findest du in: vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua
- Wenn nötig: Alle meine `.nvim` Plugins findest du unter `$REPOS_DIR\repos`
- Gib immer aus was du gerade machst / ob es interessante unde gab - damit ich Bescheuid weiß.
- Docs / README.md des Plugins updaten sofern es Sinn macht
- Keine Co-Authorenschaft von Claude in den Commits
- Wenn du mit etwas fertig bist committe / pushe / pulle so dass das uupdate sofort im main branch, sodass ich es gleich verwenden kann.
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/TOOL-PLACEMENT.md` (Tool bauen vs. Wegwerf-Skript, wohin damit) und `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/lua-plugin-tools.md`
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md` (keine großen/escapehaltigen Literale durch die Shell)
- code der implementiert wurde muss luacheck / stylua grün sein

## FINISH

- Wenn erledigr, schiebe diese file navch C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH\ERLEDIGT
- Lösche den woktree / feature branch dafür sofern es e9inen gibt
