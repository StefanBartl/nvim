# Roadmap

## Table of content

  - [Cdx](#cdx)
  - [Claude Tasks](#claude-tasks)
    - [Nice-to-Have wenn Limit über ist](#nice-to-have-wenn-limit-ber-ist)
    - [Live-Testing (braucht laufende, interaktive nvim-Session)](#live-testing-braucht-laufende-interaktive-nvim-session)
  - [Tasks](#tasks)
    - [TOP interessant gerade](#top-interessant-gerade)
    - [Ganz zum Schluss erst erledigen - wenn alles fertig ist](#ganz-zum-schluss-erst-erledigen-wenn-alles-fertig-ist)
      - [Git & Repo-Hygiene / Docs, Comments,...](#git-repo-hygiene-docs-comments)
  - [Misc](#misc)
  - [True check](#true-check)
  - [Plugin-Liste](#plugin-liste)

---

## Cdx

| Account  |    Sub Bis    | Week Reset Date |  Next 5h Reset  | Actual/Insgesamt |
| -------- | ------------- | --------------- | --------------- | ---------------- |
| **main** |   ~ 28. Sep   |   Fr., 11:00    |     21:20       |    30% / 90%     |
| **work** |   21. Sept    |   Sa., 06:00    |     22:30       |    85% / 86%     |
| **free** | 22. Juli 2027 |   So., 09:00    |     00:00       |    84% / 77%     |
| **dev**  |    04. Sep    |   Sa., --:--    |     --:--       |    --% / --%     | !!!

- never start more than 1 agents simultaneously; if more are needed, run multiple rounds of up to 1 agents each
- antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden
- Gib immer aus was du gerade machst / ob es interessante unde gab - damit ich Bescheuid weiß.
- Docs / README.md des Plugins updaten sofern es Sinn macht
- Keine Co-Authorenschaft von Claude in den Commits
- Wenn du mit etwas fertig bist committe / pushe / pulle so dass das uupdate sofort im main branch, sodass ich es gleich verwenden kann.
- code der implementiert wurde muss luacheck / stylua grün sein
- Die Installations-Specs meiner Pluigns findest du in: vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua
- Wenn nötig: Alle meine `.nvim` Plugins findest du unter `$REPOS_DIR\repos`
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/TOOL-PLACEMENT.md` (Tool bauen vs. Wegwerf-Skript, wohin damit) und `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/lua-plugin-tools.md`
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md` (keine großen/escapehaltigen Literale durch die Shell)

`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/PERFORMANCE.md`
`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/LUA_NVIM.md`
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/`

---

## Claude Tasks


- offene Taks in den roamdaps aller plugins nochmal durchegehen - Aufwand/Nutzen Analyse: E:/repos/WKDBooks/Development/wkdbook-myplugins/
  - schreibe den report hjierher: C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\reports

- casedesk
  - problems / solutions matrix us den cases erstellen
  - casedesk file im wkdbook implementieren
  - keuzfeatures data.nvim

---

### Nice-to-Have wenn Limit über ist

1. rules.nvim: media.nvim
2. C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/reports/TESTS-Abdeckung.md
3. ultracode auf alle plugins drüber gehen. auch mal zuerste sonnet, findet dann opus noch was und umgekehrt
4. alle bindings und features durchegehen und einen wunderbaren workflow doc machen, in der ich auch "fragen" nacheghen kann, also "ich wil xyy" -> dann hiehrin
5. Alle externen plugins auflisten und prüfen, welche davon in meine bestehenden plugins
voll bze features davon nachgeaut werden sollen/könnten
6. C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\LONG_RUN

---

### Live-Testing (braucht laufende, interaktive nvim-Session)

  - [ ] C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH
  - [ ] vim.fn.stdpath('config') .. /docs/ROADMAP/personal/All/PLUGIN_ROADMAPS_TESTPLAN.md
  - [loom.ai + ai.nvim](C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/FINISH/Final_Checks/ai/live-testing-plan.md)
  - [media.nvim](C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/FINISH/Final_Checks/media/live-testing-plan.md)

---

## Tasks

### TOP interessant gerade

- [ ] ai: mit slaude code die beste für den rechner lokale llm installieren, soll ein paar modelle auspropoeren,  vpn hängen nicht offen ins netz, opencode usw / ollame alternativen verwenden: https://www.youtube.com/watch?v=M1j_uRqKMKI
    Wichrig: genau lernen, wie da sfunkitnert, llm, auch wuantisierung usw... graka _> iwe aerbeiten di egnau, ram upgrde treiber erstllen usw....

- [ ] TAKT -> aai impllementierung von anfang an mitbauen

---

### Ganz zum Schluss erst erledigen - wenn alles fertig ist

- [ ] Alle Plugin-Root-README.md files Abschnitt für Abschnitt durchgehen: Dies ist der entry für devs die da s plugin nutzen, aber auch für normale user. Daher sollte die Sprache auch so sein, dass User sie gut verstehen. Das muss nicht low-level sein, aber edie Readme soll nciht überladen sein, usw..
  - [ ] reale Beispiele: (bitte fixen):
    - [ ] ...

---

#### Git & Repo-Hygiene / Docs, Comments,...

- [ ] Git-Release pro Repo, sobald fertig.

- [ ] README.md mit Video-Demo oder GIF ausstatten (Aufnahme/Schnitt nur durch dich).
  - [ ] Core-Features + Ablauf des Video/Gifs kann aber con claude vorbereitet werden
  - [ ] Logo / Bild für repo (socal prview card aber auch images.nvim hover)
    - [ ] diese logo soll dann auch in ui.nvim menu angezeigt werden
  - [ ] docmap-desktop app icon desktop
- [ ] feaure highlichts auf der root readme

---

## Misc


- [ ] Anticheat knacken

---

## True check

- [ ] 4rd/image.nvim vs. snacks.nvim image vs meine .nvim image related plugins (Verbund: images.nvim, hover.nvim, pdfport.nvim, markdown.nvim, gopath.nvim, lib.nvim, pickers.nvim, filetree.nvim, open.nvim, media.nvim; language.nvim, nvzone/menu (solange nicht eigenes right click ui plugin geschrieben ist))
  - [ ] Wie ist die image implemntierung in diesen verschiedenen Projekten bereitgestellt?
    - [ ] Architektur
    - [ ] Welche CLI-Tools werden genutzt? Wie werden sie implemenitert?
    - [ ] Wie wird sichergestellt, dass auch tatsächlich iages in nvim angezeigt werden (Ich hbae sowohl 4rd als auch snacks mehrmals eingerichtet gehab, eshatte nie funkltienrt, obwohl deren chechealth alle grün waren, mappings korrekt aufgerufen wurden usw...)
    - [ ] Welche Vorteile/Nachteile hat die jedweilige implementierung?
  - [ ] Welche Features werden jeweils bereitgestellt? (Vergleich)
  - [ ] Security Features?
  - [ ] Performance relevante umgesaetzte Ideen / patterns?
  - [ ] ...
  - [ ] (Verbund: images.nvim, hover.nvim, pdfport.nvim, markdown.nvim, gopath.nvim, lib.nvim, pickers.nvim, filetree.nvim, open.nvim, language.nvim, nvzone/menu (solange nicht eigenes right click ui plugin geschrieben ist)) -> Würde es sinn machen, ein "Bundle-plugin" zusätzlich anzubieten, dass alles diese imßlementiert und man sozusagenm eine "Image-Suite"-Implementieren könnte?

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

und das native: docmap-desktop

---

