# Roadmap

## Table of content

  - [cdx](#cdx)
  - [do](#do)
  - [TOP interessant gerade](#top-interessant-gerade)
  - [Misc](#misc)
  - [true check](#true-check)
  - [Plugin-Liste](#plugin-liste)
  - [stdpaths](#stdpaths)

---

## cdx

| Account  |    Sub Bis    | Week Reset Date |  Next 5h Reset  | Actual/Insgesamt |
| -------- | ------------- | --------------- | --------------- | ---------------- |
| **main** |   ~ 27. Sep   |   Fr., 11:00    |     23:45       |   100% / 49%     | X
| **work** |   20. Sept    |   Sa., 06:00    |     00:40       |    05% / 13%     | X
| **free** | 21. Juli 2027 |   So., 09:00    |     21:40       |    56% / 89%     | X
| **dev**  |    03. Sep    |   Sa., --:--    |     --:--       |    --% / --%     | !!!

- never start more than 1 agents simultaneously; if more are needed, run multiple rounds of up to 1 agents each
- antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden
- Die Installations-Specs meiner Pluigns findest du in: vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua
- Gib immer aus was du gerade machst / ob es interessante unde gab - damit ich Bescheuid weiß.
- Docs / README.md des Plugins updaten sofern es Sinn macht
- Keine Co-Authorenschaft von Claude in den Commits
- Wenn du mit etwas fertig bist committe / pushe / pulle so dass das uupdate sofort im main branch, sodass ich es gleich verwenden kann.
- Beachte ein "Lesson learned": [Heredoc for ai - lesson learned - in nvim config](./docs/ROADMAP/CDX/Heredoc.md)

---

## do

- [ ] leader fg -   Error  16:14:50 msg_show.emsg E492: Not an editor command: FzfLua live_grep

- [ ] start vim optimieren

- [ ] C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH\ERLEDIGT - Alles files durchgehen, ob etwas nach $REPOS_DIR/WKDBooks/Development/wkdbook-myplugins, $REPOS_DIR/WKDBooks/Development/wkdbook-lua/Checklists oder woanders (zb.: bei den Tools wie C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH\ERLEDIGT\roadmap-tools-analysis.md)

---

## TOP interessant gerade

- [ ] ai: mit slaude code die beste für den rechner lokale llm installieren, soll ein paar modelle auspropoeren,  vpn hängen nicht offen ins netz, opencode usw / ollame alternativen verwenden: https://www.youtube.com/watch?v=M1j_uRqKMKI
    Wichrig: genau lernen, wie da sfunkitnert, llm, auch wuantisierung usw... graka _> iwe aerbeiten di egnau, ram upgrde treiber erstllen usw....

- [ ] TAKT -> aai impllementierung von anfang an mitbauen

---

## Misc

- [ ] plugins/personal/ -> kommentare und docs prüfen / alles was in den plugins gecheckt wurde hier auch

- [ ] Anticheat knacken

---

## true check

Ein Freund von mir, mitdem ich gemiensam nvim gelernt habe, hat ~ 30 nvim (+ ein natives docmap-desktop) plugins geschrieben und mir angeboten, dass ich alle üebrhnehmen kann. ich bin daran interessiert, will aber zuerst wissen, wie die codequalität ist, inahltlich ist mir alles klar, also was die plugins machen, aber ich will keine schlechte codebase übernehmen. kannst du die plugins analysieren und diese einschätzug machen. bitte ehrlich, keine honig ums maul oder so. ich will wissen, was gut ist, was außergewöhnlich ist (gut als auch schlecht), was schlecht ist, wo noch viel arbeit rein gesteckt werden muss, overall zustand, usw...
  Ich hoffe, du kannst das trotzdem so effizient managen, dass dies keine mega aufgabe wird, dass soll es nämlich auch nicht sein, leider ist mir klar das dass ein wenig meine wünsche konterkariert. Ich denke, du must da einen goldenen Zwischenweg finden.
  Wenn dir Logikfehler, offensichtliche Bugs oder docs Probleme auffallen in einen Plugin, dann notiere diese gleich.

---

## Plugin-Liste

Hier die Liste meiner Plugins - du findest sie unter `c:\repos` bzw `e:\repos` - und du hast Zugriff darauf:

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

und das native: docmap-desktop

---

## stdpaths

```vim
:lua print(vim.fn.stdpath("config"))
:lua print(vim.fn.stdpath("data"))
:lua print(vim.fn.stdpath("state"))
:lua print(vim.fn.stdpath("cache"))
:lua print(vim.fn.stdpath("log"))
:lua print(vim.fn.stdpath("run"))
```

| Pfad     | Inhalt                                                  |
| -------- | ------------------------------------------------------- |
| `config` | `init.lua`, Plugins, Keymaps, eigene Lua-Module         |
| `data`   | Lazy.nvim-Repositories, Mason-Pakete, Treesitter-Parser |
| `state`  | Shada, Sessions, Swap-Informationen, Statusdaten        |
| `cache`  | Parser-Cache, Plugin-Caches, generierte Dateien         |
| `log`    | `lsp.log`, Plugin-Logs, Debug-Ausgaben                  |
| `run`    | Sockets, RPC-Pipes, temporäre Runtime-Dateien           |

---
