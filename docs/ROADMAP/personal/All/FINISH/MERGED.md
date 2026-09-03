# Merged Roadmap — CDX.md + CHECKLIST.md + FINISH_ME.md + Meins.md

## Table of content

  - [Notes](#notes)
  - [Liste A — Braucht dich](#liste-a-braucht-dich)
    - [Live-Testing (braucht laufende, interaktive nvim-Session)](#live-testing-braucht-laufende-interaktive-nvim-session)
  - [Ganz zum Schluss erst erledigen - wenn alles fertig ist](#ganz-zum-schluss-erst-erledigen-wenn-alles-fertig-ist)
    - [Git & Repo-Hygiene](#git-repo-hygiene)
    - [Docs, Comments,...](#docs-comments)
  - [Liste B - Claude Tasks](#liste-b-claude-tasks)
    - [MISC](#misc)
    - [My `.nvim`-Plugins](#my-nvim-plugins)

---

## Notes

Gilt für "alle Plugins" = alle Einträge in `lua/plugins/personal/source.lua` - außer spezifisch es Plugin ist in der Task angegeben.

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

## Liste A — Braucht dich

### Live-Testing (braucht laufende, interaktive nvim-Session)

- [ ] E:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/PLUGIN_ROADMAPS_TESTPLAN.md
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

---

## Liste B - Claude Tasks

### MISC

### My `.nvim`-Plugins

- [ ] `sessions.nvim`
  - [ ] Wen ih mit `leader tl/tr` die tableiste neu anordne, dann session speichere und neue lade, dann ist die neue Reihenfolge nicht geseicert/elaaden, sondern la würde die neurodnung mit leader tl/tr gar nicht                     gesdhehen geeesen

- [ ] `docmap-desktop`
  - [ ]  `docmap-desktop/docs/PLAN.md` — 17 offene Punkte für drei Repos: E:/repos/docmap-desktop/docs/PLAN.md
    - [ ] docmap-desktop app icon desktop

- [ ] `github_stats.nvim`
  - [ ] auswerten / backupen / Stats zusammenziehen

---

