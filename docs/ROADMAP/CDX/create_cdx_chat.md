# ___

## notes
Tip: For a deeper cloud-based review, try /ultrareview next time.


checke alle commits dieses chats auf Bugs, Security / Performance Optimierungen und fixe sie gleich.

 never start more than 1 agents simultaneously; if more are needed, run multiple rounds of up to 1 agents each
- antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden
- Die Installations-Specs meiner Pluigns findest du in: vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua
- Gib immer aus was du gerade machst / ob es interessante unde gab - damit ich Bescheuid weiß.
- Docs / README.md updaten sofern es Sinn macht
- Wenn ein binding updatent wird, dann gggf. auch vim.fn.stdpath('config') .. /docs/NOTES/BINDINGS updaten
- Keine Co-Authorenschaft von Claude in den Commits
- code der implementiert wurde muss luacheck / stylua grün sein
- Die Installations-Specs meiner Pluigns findest du in: vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua
- Wenn nötig: Alle meine `.nvim` Plugins findest du unter `$REPOS_DIR\repos`
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/TOOL-PLACEMENT.md` (Tool bauen vs. Wegwerf-Skript, wohin damit) und `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/lua-plugin-tools.md`
  - Solltest du im Zuge der Task ein Tol bauen, das für kpnftige Users/Devs/Agents interessant sein könnte, sichere es an einer geeigneteten Stelle in diesem `TOOLS/`-Folder
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md` (keine großen/escapehaltigen Literale durch die Shell)
- Neue Features ggf. im Plugin-eigenen /TESTS/ folder testenV
- Wenn du mit etwas fertig bist committe / pushe / pulle sofort im main branch, sodass ich es gleich verwenden kann.

`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/PERFORMANCE.md`
`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/LUA_NVIM.md`
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/`

---

## error meldungen

```vim

```

---

##  Erste Task

---

## Plugin-Liste

Hier die Liste meiner Plugins - du findest sie unter `$REPOS_DIR\repos` - und du hast Zugriff darauf:

ai.nvim
buffer-ctx.nvim
cascade.nvim
casedesk.nvim
cmdlog.nvim
color_my_ascii.nvim
data.nvim
dap.nvim
debugging.nvim
diff.nvim
documentation.nvim
emojis.nvim
fileops.nvim
filetree.nvim
github_stats.nvim
gitsuite.nvim
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
my.nvim (privates repo)
open.nvim
pdfport.nvim
pickers.nvim
recommender.nvim
replacer.nvim
reposcope.nvim
rules.nvim
runtime-analysis.nvim
sandbox.nvim
sessions.nvim
spotlight.nvim
ui.nvim

---

### die nativen

docmap-desktop
loomAI

---

### docs

Kurse
Notes (privates repo)
WDBooks (privates repo)
WKDBook-Tricentis (privates repo)

---

### Web

wkd
FightingGame

---

### MISC

Configs
my-zsh

---

