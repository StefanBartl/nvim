# Roadmap

## Table of content

  - [Cdx](#cdx)
  - [Claude Tasks](#claude-tasks)
    - [Generell](#generell)
    - [Ideen](#ideen)
    - [nvim-config](#nvim-config)
    - [wkd](#wkd)
    - [sessions.nvim:](#sessionsnvim)
    - [Cross-Plugin](#cross-plugin)
      - [Konkurrenzanalyse](#konkurrenzanalyse)
    - [AI / Claude (zeitlich begrenzt)](#ai-claude-zeitlich-begrenzt)
    - [interessant](#interessant)
  - [Tasks](#tasks)
    - [Nice-to-Have wenn Limit über ist](#nice-to-have-wenn-limit-ber-ist)
    - [Live-Testing (braucht laufende, interaktive nvim-Session)](#live-testing-braucht-laufende-interaktive-nvim-session)
    - [Ganz zum Schluss erst erledigen - wenn alles fertig ist](#ganz-zum-schluss-erst-erledigen-wenn-alles-fertig-ist)
      - [Git & Repo-Hygiene / Docs, Comments,...](#git-repo-hygiene-docs-comments)

---

## Cdx


| Account  |    Sub Bis    | Week Reset Date |  Next 5h Reset  | Actual/Insgesamt |
| -------- | ------------- | --------------- | --------------- | ---------------- |
| **main** |   ~ 28. Sep   |   Fr., 11:00    |     02:30       |    94% / 95%     |
| **work** |   21. Sept    |   Sa., 06:00    |     04:45       |    03% / 80%     |
| **free** | 22. Juli 2027 |   So., 09:00    |     03:10       |    98% / 98%     |

---

## Claude Tasks

### Generell

- Wir haben ein Klick-Problem: JHeder KLcik in den BUfer, freezed nvim für mehrere sekunden ein. das ist nicht gut. Wir haben viel miot mausklickdssinplementiert inden eltzen tagen, da swird wohl damit zu tun haben. Das Problem ist aber offensichtlich nicht ur ein klick problem, auch so bei editieren mit keyboard hatte ich jetzt merhamls einen freeze.

---

### Ideen

- Zeiger-Mode: KExymap um den Mode zu toggeln, wenn on, dann kann man den Mauszeiger innerhalb nvims mit den keyboard tasten steuern, klciken, und die egschwindigkeit mit ändern, zb schnell mit shift und sehr schnell mit ctrl+shift lnagsm alt und sehr langsam ctrl+akt - oder so -> die idee ist eher ein "Scherz"-Feature, weil es absurd ist, gerade in nvim den masuzeiger mit dem keyboard steuern u wollen

---

### nvim-config

- startup time  optimieren
- config optimieren

---

### wkd

- mobile optimierung
- umschalten zwische featureviews optimieren

---

### sessions.nvim:

- sesion loaded neu designen also das notify weude schon gemacht, aber bei ir ist es so wie immer. fehlt eine option key in der instaltions spec ?

---

### Cross-Plugin

- `lib.nvim` Module -> ALle Plugins nochmal checken, ob Module/Funktionen implementieren, welche die `lib.nvim` beretis bereitsetellt oder bereitstellen sollte. Das wurde vor ein/zwei Monaten schonmal gemacht, in der Zwischnezit wurde aber viel neu gemacht. Report hierher schreiebn: $NVIM_CONFIG_DIR/docs/ROADMAP/reports

---

#### Konkurrenzanalyse

- [ ] **Feature-Scan:** Bei Plugins, die meinen ähneln (z. B. gitsigns → gitsuite.nvim, 3rd/images.nvim → images.nvim, tabufline → ui.nvim, lspsaga.nvim → lspo.nvim), die Repos mit hoher bzw. mittlerer Ähnlichkeit **und** hoher Reichweite/Nutzerzahl nach Features abgrasen, die ich noch nicht implementiert habe. Gibt es bei „mittlerer Ähnlichkeit" nur wenige Treffer, nur die reichweitenstärksten davon berücksichtigen.
- [ ] **Analyse (geklärt: nur Feature-Check, kein aktiver Ersatz geplant):** noice.nvim & übrige externe Plugins auf Feature-Abdeckung prüfen — was ist durch eigene Plugins schon abgedeckt, was fehlt noch? Nur dokumentieren, keine Ersatz-Entscheidung treffen. Diesn reportanalyse hierhin schreiben: $NVIM_CONFIG_DIR/docs/ROADMAP/reports

---

### AI / Claude (zeitlich begrenzt)

- [ ] $250 Guthaben bekommen → guter Zeitpunkt, um ai.nvim bzw. loom.ai live mit einem echten Claude-Account zu testen (inkl. Rulers), auch im Agent-Modus checken.

---

### interessant

- [ ] AI: Mit Claude Code das für den Rechner beste lokale LLM installieren, dabei ein paar Modelle ausprobieren. Nicht offen ins Netz hängen (VPN), opencode bzw. Ollama-Alternativen verwenden: https://www.youtube.com/watch?v=M1j_uRqKMKI
    Wichtig: genau lernen, wie das funktioniert — LLMs, auch Quantisierung usw. Wie arbeitet dabei genau die Grafikkarte, RAM-Upgrade, Treiber erstellen usw.

- [ ] [TAKT](./$REPOS_DIR/takt) -> KI-Implementierung von Anfang an mitbauen; ins Konzept mit aufnehmen

- [ ] Gaming-Anticheat-Systeme aus Red-/Blue-Team-Cybersec-Sicht lernen

- [ ] Mobile App entwickeln

---

## Tasks

### Nice-to-Have wenn Limit über ist

1. ultracode auf alle plugins drüber gehen. auch mal zuerste sonnet, findet dann opus noch was und umgekehrt
2. alle bindings und features durchegehen und einen wunderbaren workflow doc machen, in der ich auch "fragen" nacheghen kann, also "ich wil xyy" -> dann hiehrin
3. $NVIM_CONFIG_DIR/docs\ROADMAP\LONG_RUN

---

### Live-Testing (braucht laufende, interaktive nvim-Session)

  - [ ] $NVIM_CONFIG_DIR/docs\ROADMAP\personal\All\FINISH
  - [ ] vim.fn.stdpath('config') .. /docs/ROADMAP/personal/All/PLUGIN_ROADMAPS_TESTPLAN.md
  - [loom.ai + ai.nvim](./personal/All/FINISH/Final_Checks/ai/live-testing-plan.md)
  - [media.nvim](./personal/All/FINISH/Final_Checks/media/live-testing-plan.md)

---

### Ganz zum Schluss erst erledigen - wenn alles fertig ist

- [ ] Alle Plugin-Root-README.md-Dateien Abschnitt für Abschnitt durchgehen: Das ist der Einstiegspunkt für Devs, die das Plugin nutzen, aber auch für normale User. Die Sprache soll daher so sein, dass User sie gut verstehen — muss nicht low-level sein, aber die Readme soll auch nicht überladen sein, usw.
  - [ ] Reale Beispiele (bitte fixen):
    - [ ] ...
- [ ] Autocmds, Usercmds, Keymaps → Bindings scheinen ein guter Indikator für die Features eines Plugins zu sein. Damit so arbeiten, dass in den Docs auch alle Features des Plugins dargestellt werden: z. B. können Usercmds 1 und 2 sowie Keymaps x, y, z und Autocmd 3 zusammen ein Feature des Plugins darstellen. So hätte man die Bindings-Docs auf der einen Seite und auf der anderen Seite die Features, die dann in ihrer Beschreibung mit den Bindings verknüpft werden.
- [ ] Alle Features der Plugins als Opt-in/Opt-out auflisten (auch in docs/FEATURES als Notiz anmerken) und dann nochmal für jede einzelne Option entscheiden, ob Opt-in oder Opt-out sinnvoller ist.
- Jedes Plugin aus Sicht eines Endusers/Developers „durchspielen" — von Beginn an, also vom Ankommen auf der GitHub-Seite (idealerweise kommend von der wkd-Seite). Dann zuerst normalerweise Installation + Optionen ansehen. Ist am Flow etwas nicht in Ordnung? Stört oder fehlt etwas? Ist die Dokumentation gut nachvollziehbar, ansprechend und modern aufbereitet? Ist die Dokumentation an manchen Stellen verwirrend? Gibt es Docs, die mich als Enduser/Dev nicht betreffen ([alte] Telemetriedaten, deutsche Dokumentation, Backlogs, ...)?

---

#### Git & Repo-Hygiene / Docs, Comments,...

- [ ] Git-Release pro Repo, sobald fertig.

- [ ] README.md mit Video-Demo oder GIF ausstatten (Aufnahme/Schnitt nur durch dich selbst).
  - [ ] Core-Features + Ablauf des Videos/GIFs kann von Claude vorbereitet werden.
  - [ ] Logo/Bild für Repo (Social-Preview-Card, aber auch für images.nvim-Hover).
    - [ ] Dieses Logo soll auch im ui.nvim-Menü angezeigt werden.
  - [ ] docmap-Desktop-App-Icon (Desktop).
- [ ] Feature-Highlights auf der Root-README.
- [ ] Claude-Co-Author aus allen Commits löschen.

---

