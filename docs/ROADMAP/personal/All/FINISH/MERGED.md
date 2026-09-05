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
- [ ] Merged_Finished.md in die Rules einbauen: Dsa sind alles Dinge, die wr gefixed haben, daher am besten in Regeln / Checklisten mitaufnehmen
- [ ] C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH\checkhealt_conventions.md
- [ ] C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/FINISH/RULES.md weiter machen

- [ ] C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/FINISH/RULES.md

---

### Git & Repo-Hygiene

- [ ] ci workflows -> ausbauen wenn notig, alle grün "machen"
- [ ] Git-Release pro Repo, sobald fertig.

---

### Docs, Comments,...

- [ ] Logo / Bild für repo (socal prview card aber auch images.nvim hover)

- [ ] Eventuell selbst alle repos - jede file - durchgehen und bei auffälligen (Zu langer/unnötiger Kommnentar, Code strange, Docs fehlen/anders struktuiren, usw) einen Tag setzen, zb.: `--- CDX:` oder selbst gleich fixen

- [ ] README.md mit Video-Demo oder GIF ausstatten (Aufnahme/Schnitt nur durch dich).
  - [ ] Core-Features + Ablauf des Video/Gifs kann aber con claude vorbereitet werden

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

