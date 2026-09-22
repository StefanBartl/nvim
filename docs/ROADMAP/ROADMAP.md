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
  - [Plugin-Liste](#plugin-liste)
    - [die nativen](#die-nativen)
    - [docs](#docs)
    - [Web](#web)
    - [MISC](#misc-1)

---

## Cdx

| Account  |    Sub Bis    | Week Reset Date |  Next 5h Reset  | Actual/Insgesamt |
| -------- | ------------- | --------------- | --------------- | ---------------- |
| **main** |   ~ 28. Sep   |   Fr., 11:00    |     01:43       |    90% / 82%     |
| **work** |   21. Sept    |   Sa., 06:00    |     04:45       |    03% / 80%     |
| **free** | 22. Juli 2027 |   So., 09:00    |     03:10       |    26% / 79%     |

---

## Claude Tasks

- markdown.nvim: brreadrumbs statt linksbündig rectsbündig machen - auch ohne "underline" testen, wenn rechts brauh tes das vl gar nicht

- - gitsuite.nvim:
  - wkd
  - rules.nvim (eventuell gleich mit agent aus document-explrer / documentation.nvim / loomAI / ai.nvim)

- [ ] Jedes Plugin aus sicht eines endusers/developers "durchspielen" - von Beginn an, also vom ankommen auf der github seite, ssagne wikr dealerweiße kommend von derr wkd seite. DAnn möchte m an mal als erstes normalerweiße die instsalltion + optionen sehen. ist am flow etwas nicht in ordnung? stört oder fehlt etwas? Ist die Dokumentation gut nachvollziehbar und ansprechend, modern aufbereitet? Ist die Dokumentation an Stellen verwirrend? Gib es docs, die mich als enduser/dev nicht betreffen? ([alte] Telemetry daten, Deutsche dokumentation, backlogs,..)

- [ ] mdview: Auf der workstation funktinrt cursor section nicht, also die sektion wird nicht hl, caret funktionert gut, line auch; standalone gar nichts

- noice & restliche externe plugins erstzen ?
- plugins die meinen ähneln auf features abgrasen, die ich noch nicht imlpementiert habe

---

## Nice-to-Have wenn Limit über ist

1. ultracode auf alle plugins drüber gehen. auch mal zuerste sonnet, findet dann opus noch was und umgekehrt
2. alle bindings und features durchegehen und einen wunderbaren workflow doc machen, in der ich auch "fragen" nacheghen kann, also "ich wil xyy" -> dann hiehrin
3. C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\LONG_RUN

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
- [ ] autocmds, usrcmds, keymaps -> bindings cheinen ein guter zeiger für features eines opklugins zu sein, arbeiten wird iese durch im sinne, dass in den dcos ach alle features des plugins dargestellt werden, aksi zb können usrcmds 1 und zwqeiu sowie keymapo x,y,z und autocmd drei -> ein feature des polugins darstellen; so hääte man die bindings docs auf der einen seite, und auf der andererrn seite die features, die dann in ihrer beschreibung mit den bindings verknüpft werden.
- [ ] Alle Features der Plugins als opt-in/opt-out auflisten (und auch in die docs/FEATURES al Note anmerken) unddann nochmal entscheiden für ejde einzelne option, onb opt-in oder opt-out

---

#### Git & Repo-Hygiene / Docs, Comments,...

- [ ] Git-Release pro Repo, sobald fertig.

- [ ] README.md mit Video-Demo oder GIF ausstatten (Aufnahme/Schnitt nur durch dich).
  - [ ] Core-Features + Ablauf des Video/Gifs kann aber con claude vorbereitet werden
  - [ ] Logo / Bild für repo (socal prview card aber auch images.nvim hover)
    - [ ] diese logo soll dann auch in ui.nvim menu angezeigt werden
  - [ ] docmap-desktop app icon desktop
- [ ] feaure highlichts auf der root readme
- [ ] claude co author aus allen commits löschen

---

## Misc

- [ ] Anticheat knacken

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

