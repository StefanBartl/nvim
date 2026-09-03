Roadmap

Table of content

  - [cdx](#cdx)
  - [TOP interessant gerade](#top-interessant-gerade)
  - [Misc](#misc)
  - [true check](#true-check)
  - [Plugin-Liste](#plugin-liste)

---

cdx

| Account  |    Sub Bis    | Week Reset Date |  Next 5h Reset  | Actual/Insgesamt |
| -------- | ------------- | --------------- | --------------- | ---------------- |
| **main** |   ~ 27. Sep   |   Fr., 11:00    |     04:00       |    95% / 49%     |
| **work** |   20. Sept    |   Sa., 06:00    |     11:10       |   100% / 47%     |
| **free** | 21. Juli 2027 |   So., 09:00    |     20:50       |    --% / 47%     |
| **dev**  |    03. Sep    |   Sa., --:--    |     --:--       |    --% / --%     |

- never start more than 3 agents simultaneously; if more are needed, run multiple rounds of up to 3 agents each
- antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden
- Die Installations-Specs meiner Pluigns findest du in: C:/Users/bartl/AppData/Local/nvim/lua/plugins/personal/init.lua
- Gib immer aus was du gerade machst / ob es interessante unde gab - damit ich Bescheuid weiß.
- Docs / README.md des Plugins updaten sofern es Sinn macht
- Wenn ein binding updatent wird, dann gggf. auch C:/Users/bartl/AppData/Local/nvim/docs/NOTES/BINDINGS updaten
- Keine Co-Authorenschaft von Claude in den Commits
- Wenn du mit etwas fertig bist committe / pushe / pulle so dass das uupdate sofort im main branch, sodass ich es gleich verwenden kann.
- Beachte ein "Lesson learned": [Heredoc for ai - lesson learned - in nvim config](./docs/ROADMAP/CDX/Heredoc.md)

---

TOP interessant gerade

- [ ] ai: mit slaude code die beste für den rechner lokale llm installieren, soll ein paar modelle auspropoeren,  vpn hängen nicht offen ins netz, opencode usw / ollame alternativen verwenden: https://www.youtube.com/watch?v=M1j_uRqKMKI
    Wichrig: genau lernen, wie da sfunkitnert, llm, auch wuantisierung usw... graka _> iwe aerbeiten di egnau, ram upgrde treiber erstllen usw....

hover.nvim kann verwenbdet werden
- [ ] TAKT -> aai impllementierung von anfang an mitbauen

---

Misc

- [ ] plugins/personal/ -> kommentare und docs prüfen / alles was in den plugins gecheckt wurde hier auch

- [ ] Casedesk auslagern; WKDBook-Tricentis/EngineLab/Cases;

- [ ] Anticheat knacken

---

true check

Ein Freund von mir, mitdem ich gemiensam nvim gelernt habe, hat ~ 30 nvim (+ ein natives docmap-desktop) plugins geschrieben und mir angeboten, dass ich alle üebrhnehmen kann. ich bin daran interessiert, will aber zuerst wissen, wie die codequalität ist, inahltlich ist mir alles klar, also was die plugins machen, aber ich will keine schlechte codebase übernehmen. kannst du die plugins analysieren und diese einschätzug machen. bitte ehrlich, keine honig ums maul oder so. ich will wissen, was gut ist, was außergewöhnlich ist (gut als auch schlecht), was schlecht ist, wo noch viel arbeit rein gesteckt werden muss, overall zustand, usw...
  Ich hoffe, du kannst das trotzdem so effizient managen, dass dies keine mega aufgabe wird, dass soll es nämlich auch nicht sein, leider ist mir klar das dass ein wenig meine wünsche konterkariert. Ich denke, du must da einen goldenen Zwischenweg finden.
  Wenn dir Logikfehler, offensichtliche Bugs oder docs Probleme auffallen in einen Plugin, dann notiere diese gleich.

---

Plugin-Liste

Hier die Liste meiner Plugins - du findest sie unter `c:\repos` bzw `e:\repos` - und du hast Zugriff darauf:

buffer-ctx.nvim
cascade.nvim
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

