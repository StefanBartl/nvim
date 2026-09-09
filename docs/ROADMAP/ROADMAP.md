# Roadmap

docmap-desktop: Neuies feaure, merhere repos s anne, alos zb $REPOS_DIR mit 32 plugins, die darsatellen können und auch die verbiundungen zu einander, zumindest inlua, das wäre extrem spanndedn, das darzustellen, wenn ncht anders möglich, in einer spehziellen ansicht -ganz ´losgelöst vom Default

## Table of content

  - [Cdx](#cdx)
  - [Claude Tasks](#claude-tasks)
  - [Tasks](#tasks)
    - [media.nvim](#medianvim)
    - [Ganz zum Schluss erst erledigen - wenn alles fertig ist](#ganz-zum-schluss-erst-erledigen-wenn-alles-fertig-ist)
      - [Live-Testing (braucht laufende, interaktive nvim-Session)](#live-testing-braucht-laufende-interaktive-nvim-session)
      - [Git & Repo-Hygiene / Docs, Comments,...](#git-repo-hygiene-docs-comments)
  - [Misc](#misc)
  - [True check](#true-check)
  - [Plugin-Liste](#plugin-liste)

---

## Cdx

| Account  |    Sub Bis    | Week Reset Date |  Next 6h Reset  | Actual/Insgesamt |
| -------- | ------------- | --------------- | --------------- | ---------------- |
| **main** |   ~ 28. Sep   |   Fr., 11:00    |     xx:xx       |    xx% / xx%     | X
| **work** |   21. Sept    |   Sa., 06:00    |     xx:xx^      |    xx% / xx%     | X
| **free** | 22. Juli 2027 |   So., 09:00    |     23:50       |    97% / 78%     | X
| **dev**  |    04. Sep    |   Sa., --:--    |     --:--       |    --% / --%     | !!!

- never start more than 2 agents simultaneously; if more are needed, run multiple rounds of up to 1 agents each
- antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden
- Die Installations-Specs meiner Pluigns findest du in: vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua
- Gib immer aus was du gerade machst / ob es interessante unde gab - damit ich Bescheuid weiß.
- Docs / README.md des Plugins updaten sofern es Sinn macht
- Keine Co-Authorenschaft von Claude in den Commits
- Wenn du mit etwas fertig bist committe / pushe / pulle so dass das uupdate sofort im main branch, sodass ich es gleich verwenden kann.
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOL-PLACEMENT.md` (Tool bauen vs. Wegwerf-Skript, wohin damit)
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md` (keine großen/escapehaltigen Literale durch die Shell)
- cdode der imßlementiert wurde muss luacheck / stylua grün sein

---

## Claude Tasks

- [ ] `docmap-desktop`
  - [ ]  `docmap-desktop/docs/PLAN.md` — 18 offene Punkte für drei Repos: E:/repos/docmap-desktop/docs/PLAN.md

- [ ] E:/repos/casedesk.nvim/docs/HANDOVER.md
  - [ ] RULES

- [ ] pickers.nvim's plugin/pickers.lua materialisiert beim Start die volle Default-Config. Nach dem lib.nvim-Fix kostet das nur noch ~3 ms statt 19 — das Muster bleibt aber diskutabel, falls du dort mal aufräumen willst.

---

## Tasks

### media.nvim

```markdown
Was jetzt läuft: <CR> auf einem Video-Hover versucht in dieser Reihenfolge:

mpv-Fenster (wie bisher, Standard).
Ohne mpv: Standard-App deiner Maschine — dieselbe Funktion, die auch gf schon nutzt (media.play()). Echtes Bild+Ton, nichts extra zu installieren. Kann nur nicht gestoppt werden (kein Prozess-Handle) — <CR> legt den Hover nur aufs Standbild zurück, der Player läuft weiter bis du ihn selbst schließt.
Fällt beides aus, die stumme Blockgrafik (wie schon vorher).

Bonus-Experiment (video.system_player_align = true, Default aus): versucht, das neue Player-Fenster zu zentrieren — auf Windows (PowerShell/Win32), macOS (AppleScript) und Linux (xdotool/wmctrl), nicht nur Windows. Echt getestet auf deinem Rechner: Übergabe klappt, das Skript läuft nachweislich durch — bewegt aber nichts, weil deine Windows-Standard-App für Video eine UWP-App ("Filme & TV") ist,
```

---

### Ganz zum Schluss erst erledigen - wenn alles fertig ist

- [ ] Alle Plugin-Root-README.md files Abschnitt für Abschnitt durchgehen: Dies ist der entry für devs die da s plugin nutzen, aber auch für normale user. Daher sollte die Sprache auch so sein, dass User sie gut verstehen. Das muss nicht low-level sein, aber edie Readme soll nciht überladen sein, usw..
  - [ ] reale Beispiele: (bitte fixen):
    - [ ] ...

---

#### Live-Testing (braucht laufende, interaktive nvim-Session)

- [ ] vim.fn.stdpath('config') .. /docs/ROADMAP/personal/All/PLUGIN_ROADMAPS_TESTPLAN.md
  - [ ] aktualisieren /

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

- [ ] alle bindings und features durchegehen und einen wunderbaren workflow doc machen, in der ich auch "fragen" nacheghen kann, also "ich wil xyy" -> dann hiehrin

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

- [ ] Ein Freund von mir, mitdem ich gemeinsam nvim gelernt habe, hat ~ 31 nvim (+ ein natives docmap-desktop) plugins geschrieben und mir angeboten, dass ich alle üebrhnehmen kann. ich bin daran interessiert, will aber zuerst wissen, wie die codequalität ist, inahltlich ist mir alles klar, also was die plugins machen, aber ich will keine schlechte codebase übernehmen. kannst du die plugins analysieren und diese einschätzug machen. bitte ehrlich, keine honig ums maul oder so. ich will wissen, was gut ist, was außergewöhnlich ist (gut als auch schlecht), was schlecht ist, wo noch viel arbeit rein gesteckt werden muss, overall zustand, usw...
  Ich hoffe, du kannst das trotzdem so effizient managen, dass dies keine mega aufgabe wird, dass soll es nämlich auch nicht sein, leider ist mir klar das dass ein wenig meine wünsche konterkariert. Ich denke, du must da einen goldenen Zwischenweg finden.
  Wenn dir Logikfehler, offensichtliche Bugs oder docs Probleme auffallen in einen Plugin, dann notiere diese gleich.

---

## Plugin-Liste

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

und das native: docmap-desktop

---

