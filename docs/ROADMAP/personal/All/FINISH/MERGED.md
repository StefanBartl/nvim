# Merged Roadmap — CDX.md + CHECKLIST.md + FINISH_ME.md + Meins.md
Zusammengeführt und dedupliziert aus den vier Ursprungslisten. Zwei Listen:

- **A — Braucht dich**: Claude Code kann höchstens zuarbeiten/vorschlagen, Entscheidung oder Durchführung liegt bei dir.
- **B — An Claude Code delegierbar**: kannst du als Auftrag geben, wenig bis nichts von dir nötig.

Innerhalb jedes Themenblocks sortiert nach vermutlichem Aufwand/Nutzen-Verhältnis (günstige Quick-Wins zuerst).

Gilt für "alle Plugins" = alle Einträge in `lua/plugins/personal/source.lua`.

---

## Liste A — Braucht dich

### Live-Testing (braucht laufende, interaktive nvim-Session)
- [ ] CDX: jedes Keymap/Usrcmd/Autocmd in echter nvim-Instanz durchtesten, ob Fehler geworfen werden. (Claude kann einen Testrunner vorbereiten, das Beobachten in Echtzeit ist deine Domäne — außer wir bauen dafür einen headless-Test.)
  - [ ] Gleich mitchecken, o die usrmd optionen wirklich gut bennant sind. Zb `:LspDoctor deep` wurde gennant für eine aktion, die ausgegebn hat, welcher formatter gerade aktiv ist.... daher wurde es umbenannt auf `LspDoctor fmt_check`
- [ ] `:Recommender perf` durch alle Module laufen lassen und Ergebnisse sichten. (Ausführen + Sichten = du; die daraus resultierenden Fixes = delegierbar, siehe Liste B.)

---

## Ganz zum Schluss erst erledigen - wenn alles fertig ist

- [ ] lib.nvim - alle module durcgehen und checken, ob docs, @types, als auch aggregatoren noch korrekt sind. Die lib.nvim ist für mich umso mehr wert, umso besser die docs sind. Dabei auch gleich feature ideen einbringenh, sprich bei jedem modul am ende auch checken "fehlt etwass sinnvolles?"
- [ ] Merged_Finished.md in die Rules einbauen: Dsa sind alles Dinge, die wr gefixed haben, daher am besten in Regeln / Checklisten mitaufnehmen
- [ ] nochmal alle keymaps checken, ob kein keymap doppelt vergeben ist, über alles repos hinweg + nvim-config
- [ ] claude: "Eine Sache habe ich ins Handover als Arbeitsregel geschrieben, weil sie mir zweimal passiert ist: stylua lua nie über die nvim-Config laufen lassen — sie ist nicht stylua-formatiert, ein Lauf formatiert 141 Dateien nebenbei um." - sollten sie aber schoin sein, also dem nachgehen

### Git & Repo-Hygiene
- [ ] ci workslows -> ausbauen wenn notig, alle grün "machen"
- [ ] Alle Features/Bugfixes committen & pushen (Commit-Message ausgeben, falls Push nicht möglich). — **Zuletzt geprüft 2026-08-26: alle 31 Repos + Config sauber und gepusht; Claude-Branches und `.claude/worktrees/` überall abgeräumt (siehe `Merged_Finished.md`).** Wiederkehrend, bleibt daher stehen.
- [ ] Git-Release pro Repo, sobald fertig.

### Sonstiges

- [ ] README.md mit Video-Demo oder GIF ausstatten (Aufnahme/Schnitt nur durch dich).
  - [ ] Core-Features + Ablauf des Video/Gifs kann aber con claude vorbereitet werden
- [ ] Alle docs/ Files in jedem .nvim repo müssen nochmal überprüft werden, auf aktualitöt & korrektheit - Doppelungen entfernen, stimmt alles was behauptet wird, Referenzen updaten, usw...  docs/README Themenaufteilung / docs Struktur überelgen - einheitiche struktur finden für alle repos; Deutsche docs nur, wenn eine englische Hauptversions der file besteht und explizit eine deutsche version von mir verlangt wird. Weiteres auf das überprüftr werden soll gleich am anfang mit ausfschreiben, man könte für diesen duirchgang eien art docs checklist machen.
  - [ ] Generell soll das Prinzip herrschen: `Nicht "so viel wie möglich" in die docs, sondern nur das, was für User und Devs auch tatsächlich interessant sein kann. Der Rest nach WKDBooks/Deveolpment/wkdbook-myplugins/ - da können auch reine informations docs ausgelagert werden, die entwedet "zu tief" gehen für normale repo docs oder weder für devs noch für user einen naheliegenden Mehrwert haben. wkdbook-myplugins ist kein "Downgrade", sondern meine interne Notizensammlung`

---
