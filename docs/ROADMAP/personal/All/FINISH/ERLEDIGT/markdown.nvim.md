## Fix markdown.nvim CI: rg missing on PATH
markdown.nvim's GitHub Actions CI (StefanBartl/markdown.nvim, workflow "CI", job "tests (headless)") has been failing for at least the last 4 pushes to main, including commits that long predate any recent change: file_refs_spec.lua:192 fails with "this regression needs rg on PATH to exercise the rg path: expected truthy, got false".

This means the CI runner image no longer has ripgrep (rg) on PATH, or something changed in how the test asserts its presence. Check the .github/workflows/ci.yml "tests" job -- it likely needs an explicit rg install step (e.g. sudo apt-get install -y ripgrep, or the GitHub Actions Ubuntu runner image dropped a previously-preinstalled rg). Compare against other StefanBartl/*.nvim repos' CI workflows that also depend on rg (gopath.nvim's cache tests use fd/fdfind/rg too) to see if they install it explicitly or rely on it being preinstalled, and whether they're also failing.

Fix by adding the missing install step (or whatever the actual root cause turns out to be), verify locally isn't sufficient since this is CI-environment-specific -- push a small test commit or use gh run list/gh run view after pushing to confirm the tests job goes green. Commit with no Claude co-authorship line per this project's convention (verify via git log -1 --format='%B' | grep -i "co-authored\|claude" finding nothing) and push directly to main once fixed.


## zweiter task

- markdown.nvim: table: wien in  cascade.nvim glaubeich das `o` und `O` nach bzw vor einen bulletpoint dan einen weteren einfügt, wäre es super, wenn ihcn markdown tables das gleiche implementiert werden würde. wo das genau implementiert wird, weiß ich nicht, markdown.nvim ist die md table implementierung, cascadel,nvim wenn mich nicht alles täucscht aber das o mapping

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


