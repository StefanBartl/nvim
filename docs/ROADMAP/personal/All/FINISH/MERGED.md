# Merged Roadmap — CDX.md + CHECKLIST.md + FINISH_ME.md + Meins.md

Gilt für "alle Plugins" = alle Einträge in `lua/plugins/personal/source.lua` - außer spezifisch es Plugin ist in der Task angegeben.

## Table of content

  - [Liste A — Braucht dich](#liste-a-braucht-dich)
    - [Live-Testing (braucht laufende, interaktive nvim-Session)](#live-testing-braucht-laufende-interaktive-nvim-session)
  - [Ganz zum Schluss erst erledigen - wenn alles fertig ist](#ganz-zum-schluss-erst-erledigen-wenn-alles-fertig-ist)
    - [Git & Repo-Hygiene](#git-repo-hygiene)
    - [Docs, Comments,...](#docs-comments)
  - [Liste B - Claude Tasks](#liste-b-claude-tasks)
    - [MISC](#misc)
    - [My `.nvim`-Plugins](#my-nvim-plugins)

---

## Liste A — Braucht dich

### Live-Testing (braucht laufende, interaktive nvim-Session)

- [ ] vim.fn.stdpath('config') .. /docs/ROADMAP/personal/All/PLUGIN_ROADMAPS_TESTPLAN.md
- [ ] CDX: jedes Keymap/Usrcmd/Autocmd in echter nvim-Instanz durchtesten, ob Fehler geworfen werden. (Claude kann einen Testrunner vorbereiten, das Beobachten in Echtzeit ist deine Domäne — außer wir bauen dafür einen headless-Test.)
  - [ ] Gleich mitchecken, o die usrmd optionen wirklich gut bennant sind. Zb `:LspDoctor deep` wurde gennant für eine aktion, die ausgegebn hat, welcher formatter gerade aktiv ist.... daher wurde es umbenannt auf `LspDoctor fmt_check`
- [ ] `:Recommender perf` durch alle Module laufen lassen und Ergebnisse sichten. (Ausführen + Sichten = du; die daraus resultierenden Fixes = delegierbar, siehe Liste B.)

---

## Ganz zum Schluss erst erledigen - wenn alles fertig ist

- [ ] Diagnostics ncohmal drüber laufen lassen, es gab noch das ein oder andere zu implementieren.
- [ ] lib.nvim - alle module durcgehen und checken, ob docs, @types, als auch aggregatoren noch korrekt sind. Die lib.nvim ist für mich umso mehr wert, umso besser die docs sind. Dabei auch gleich feature ideen einbringenh, sprich bei jedem modul am ende auch checken "fehlt etwass sinnvolles?"
- [ ] nochmal alle keymaps checken, ob kein keymap doppelt vergeben ist, über alles repos hinweg + nvim-config
- [ ] claude: "Eine Sache habe ich ins Handover als Arbeitsregel geschrieben, weil sie mir zweimal passiert ist: stylua lua nie über die nvim-Config laufen lassen — sie ist nicht stylua-formatiert, ein Lauf formatiert 141 Dateien nebenbei um." - sollten sie aber schoin sein, also dem nachgehen
- [ ] Merged_Finished.md in die Rules einbauen: Dsa sind alles Dinge, die wr gefixed haben, daher am besten in Regeln / Checklisten mitaufnehmen
- [ ] C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH\checkhealt_conventions.md
- [ ] C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/FINISH/RULES.md weiter machen

---

### Git & Repo-Hygiene

- [ ] ci workflows -> ausbauen wenn notig, alle grün "machen"
- [ ] Alle Features/Bugfixes committen & pushen (Commit-Message ausgeben, falls Push nicht möglich). — **Zuletzt geprüft 2026-08-26: alle 31 Repos + Config sauber und gepusht; Claude-Branches und `.claude/worktrees/` überall abgeräumt (siehe `Merged_Finished.md`).** Wiederkehrend, bleibt daher stehen. Alle Claude Branches löschen (außer den aktuellen), vorher noch checken, ob comitts enthalten sind ie noch nnicht in mian sind.
- [ ] Git-Release pro Repo, sobald fertig.

---

### Docs, Comments,...

- [ ] Logo / Bild für repo (socal prview card aber auch images.nvim hover)

- [ ] Eventuell selbst alle repos - jede file - durchgehen und bei auffälligen (Zu langer/unnötiger Kommnentar, Code strange, Docs fehlen/anders struktuiren, usw) einen Tag setzen, zb.: `--- CDX:` oder selbst gleich fixen

- [ ] README.md mit Video-Demo oder GIF ausstatten (Aufnahme/Schnitt nur durch dich).
  - [ ] Core-Features + Ablauf des Video/Gifs kann aber con claude vorbereitet werden

[ ] in den plugins docs immer
  - [ ] $REPOS_DIR schreiben anstelle von C:\repos oder $REPOS_DIR\
  - [ ] für angaben innerhalb der nvim-config, immer ~/ oder vim.fn.stdpath("config")
  - [ ] Wobei aebri n den plugins, anders als der nvim-config, die frage istz, warum sollte dort ein Pfad auf c:\repos oder e:\repos sinn machen - andere user haben wvielleicht garn keine $REPOS_DIR env var. daher muss das geklärt wreen. ioch weiß zumindest von einen vorkomen, wo woir in der implementiert haebn, dass nach $REPOS_DOIR akiv gersucht wird, das haben wir dann abe in der readme.md auchangtegeben und müsste ein ausnahemfall sien. daher -> teilvon docs clearing, sich die vokrommen näöher anzuaschauen, es knnte aien anzeigersein für fehlannehmen/zeiger dass diese infos zu nmotizen gehölren, nicht in das polguins erpo docs, usw... siehst du da sähnlich?

- [ ] C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH\ERLEDIGT - Alles files durchgehen, ob etwas nach $REPOS_DIR/WKDBooks/Development/wkdbook-myplugins, $REPOS_DIR/WKDBooks/Development/wkdbook-lua/Checklists oder woanders (zb.: bei den Tools wie C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH\ERLEDIGT\roadmap-tools-analysis.md)

---

## Liste B - Claude Tasks

### MISC

### My `.nvim`-Plugins

- [ ] `docmap-desktop`
  - [ ]  `docmap-desktop/docs/PLAN.md` — 17 offene Punkte für drei Repos: E:/repos/docmap-desktop/docs/PLAN.md
    - [ ] docmap-desktop app icon desktop

- [ ] `github_stats.nvim`
  - [ ] auswerten / backupen / Stats zusammenziehen

---

