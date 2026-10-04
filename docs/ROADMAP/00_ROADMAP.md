# Roadmap

## Table of content

  - [Cdx](#cdx)
  - [Claude Tasks](#claude-tasks)
    - [Generell](#generell)
    - [wkd](#wkd)
    - [https://github.com/StefanBartl updaten - schon relativ alt](#httpsgithubcomstefanbartl-updaten-schon-relativ-alt)
    - [Cross-Plugin](#cross-plugin)
      - [Konkurrenzanalyse](#konkurrenzanalyse)
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
| **main** |   ~ 28. Sep   |   Fr., 11:00    |     14:50       |    94% /346%     |
| **work** |   21. Sept    |   Sa., 06:00    |     10:45       |    10% / 53%     |
| **free** | 22. Juli 2027 |   So., 09:00    |     18:20       |    00% / 74%     |

---

## Claude Tasks

- filetree.nvim: Usrmcd, mit dem ich checken, ob und wie oft eine file referenziert wird. Wenn mehrer picker? Usecase; /assets ist voll mit screenhsot, die keiner mehr referenziert,
  Eun ähnliches vorgehen haben wir mit symlink ja bereits implementiert.
  -> Task: `filetree.nvim/orphaned-asset-report` (Entscheidung 2026-10-04: filetree besitzt es; `images.nvim :Image orphans` bleibt bildspezifisch).

- Fehler wird auf der worjstation ausgegeben;  `10:41:18 AM msg_show.echomsg [lib.nvim.progress] style #1 failed to update, disabling it for this handle: C:/repos/lib.nvim/lua/lib/nvim/progress/styles/kit.lua:39: E5560: nvim_win_is_valid must not be called in a fast event context`
  -> erledigt: der Fix steht seit 2026-09-28 in lib.nvim (`e9e7b5c`, `progress/styles/kit.lua`: `vim.in_fast_event()`-Zweig, Render per `vim.schedule`); die Zeile stammt von einem älteren Stand auf der Workstation (`C:/repos/lib.nvim`). Tritt es nach einem `git pull` dort noch auf, als Bug-Task in `lib.nvim` anlegen.

- spotlight.nvim, wie mehrere hl machen, lernen! [note]($NVIM_CONFIG_DIR/docs/NOTES/Notes.md)

-  -Editing-Primitive (autopairs, autotag, matchup, visual-multi, mini.ai/targets) bleiben dauerhaft extern> Anylse, wir aufwendig ist es,d iese zu erstetzen, welche vorteile? könnte man alle features der plugins zu einen zusmmenoen=
  -> Task: `nvim-config/external-deps-replacement-assessment`

- nvim -> omarchy ascii style umbau - was ist alles möglich um den look hinzubekommen beside themes?
  -> Task: `nvim-config/omarchy-look-beyond-themes`

- claude api ai.nvim / loomai checks erstellen, um features ich damit checken kann
  -> die Checks gibt es (`Final_Checks/ai/claude-account-live-testing-schlachtplan.md`); Ausführung: Task `ALL/claude-account-live-test-session`

- mappings durchchecken
  -> Tasks: `nvim-config/bindings-checklist-update`, danach `nvim-config/bindings-checklist-run`

- C:/Users/Bernhard/AppData/Local/nvim/lua/bindings/usrcmds/context_open -> mal ein wenig ausprobieren, und solte es erweitert werden? seit der implementierung sind einige plugins dazu gekommen + features innerhalb der damlas schon bestehenden
  -> Task: `nvim-config/context-open-review`

---

### Generell

### wkd

**Offene Tasks im wkd-Repo:**
  - **T2** — 38 knackige Kurzbeschreibungen für die Plugin-Kacheln schreiben (Technik fertig, wartet nur auf deinen Text).
    - Docmap-desktop Kachel: `The kind of shell Tosca Commander or Blender put in front of a project`
  - **T11** *(zurückgestellt)* — zweiter Schalter nvim ↔ native, pausiert bis mehr als 2 native Einträge da sind.
  - **T6** — 3 (später 4) echte `ui.nvim`-Screenshots liefern (Rechtsklickmenü, Filetree, Tabline — Composite-Komponente ist fertig vorgebaut).
  - **T12** *(zurückgestellt)* — Theme-Schalter über Demo-Videos, bewusst eine der letzten Aufgaben.

- mobile optimierung
- umschalten zwische featureviews optimieren

---

### https://github.com/StefanBartl updaten - schon relativ alt

### Cross-Plugin

- `lib.nvim` Module -> ALle Plugins nochmal checken, ob Module/Funktionen implementieren, welche die `lib.nvim` beretis bereitsetellt oder bereitstellen sollte. Das wurde vor ein/zwei Monaten schonmal gemacht, in der Zwischnezit wurde aber viel neu gemacht. Report hierher schreiebn: $NVIM_CONFIG_DIR/docs/ROADMAP/reports
  -> Task: `ALL/lib-nvim-adoption-sweep`

- Von welchen meiner `.nvim`-Plugins ist eine CLI-Version denkbar? `reposcope.nvim`, `gitsuite.nvim`,...
  -> Task: `ALL/cli-versions-of-plugins`

- Jedes plugin ein eigener Kreuzfeature durchgang
  -> Task: `ALL/per-plugin-cross-feature-pass` (Rückfrage: was ist gemeint?)

- Alle Plugins, die ein Window mit Cheatsheet haben, sollen die gleiche Strukut / Formatzierung ders CHeatsheets aufweißen:
  - Gleiches Layout
  - `?` und `q` beenden das Cheatsheets
  - Neben Usrcmds können, wenn sinnvoll und nicht zu viele, auch uscmds angegeben werden (Vorbild: `filetree.nvim`)
  - Die Bindings sollen in Kategorien eingeteilt werden, die in Pages angeordnet sind und über `Tab` erreichbar sind (Vorbild: `filetree.nvim`)
  - Einiges deutet darauf hin, dass ein `lib.nvim ui.kit`-Cheatsheet Modul hilfreich sein könnte
  -> Task: `ALL/cheatsheet-window-unification` (Modulschnitt: `ui.nvim/messages-module-cut`)

---

#### Konkurrenzanalyse

- [ ] **Feature-Scan:** Bei Plugins, die meinen ähneln (z. B. gitsigns → gitsuite.nvim, 3rd/images.nvim → images.nvim, tabufline → ui.nvim, lspsaga.nvim → lspo.nvim), die Repos mit hoher bzw. mittlerer Ähnlichkeit **und** hoher Reichweite/Nutzerzahl nach Features abgrasen, die ich noch nicht implementiert habe. Gibt es bei „mittlerer Ähnlichkeit" nur wenige Treffer, nur die reichweitenstärksten davon berücksichtigen.
  -> Task: `ALL/competitor-feature-scan`
- [x] **Analyse (geklärt: nur Feature-Check, kein aktiver Ersatz geplant):** noice.nvim & übrige externe Plugins auf Feature-Abdeckung prüfen — was ist durch eigene Plugins schon abgedeckt, was fehlt noch? Nur dokumentieren, keine Ersatz-Entscheidung treffen. Diesn reportanalyse hierhin schreiben: $NVIM_CONFIG_DIR/docs/ROADMAP/reports — erledigt 2026-10-01: [noice](./reports/NOICE_ERSATZ/noice-feature-abdeckung-2026-10-01.md), [übrige externe Plugins](./reports/externe-plugins-feature-abdeckung-2026-10-01.md), [ext_messages-Spike](./reports/NOICE_ERSATZ/ext-messages-tui-spike-2026-10-01.md)

---

### interessant

- [ ] AI: Mit Claude Code das für den Rechner beste lokale LLM installieren, dabei ein paar Modelle ausprobieren. Nicht offen ins Netz hängen (VPN), opencode bzw. Ollama-Alternativen verwenden: https://www.youtube.com/watch?v=M1j_uRqKMKI
    Wichtig: genau lernen, wie das funktioniert — LLMs, auch Quantisierung usw. Wie arbeitet dabei genau die Grafikkarte, RAM-Upgrade, Treiber erstellen usw.

- [ ] [TAKT]($REPOS_DIR/takt) -> KI-Implementierung von Anfang an mitbauen; ins Konzept mit aufnehmen

- [ ] Gaming-Anticheat-Systeme aus Red-/Blue-Team-Cybersec-Sicht lernen

- [ ] Mobile App entwickeln

---

## Tasks

### Nice-to-Have wenn Limit über ist

1. ultracode auf alle plugins drüber gehen. auch mal zuerste sonnet, findet dann opus noch was und umgekehrt
   -> Task (parked): `ALL/ultracode-pass-all-plugins`
2. alle bindings und features durchegehen und einen wunderbaren workflow doc machen, in der ich auch "fragen" nacheghen kann, also "ich wil xyy" -> dann hiehrin
   -> Task (parked): `ALL/workflow-guide-doc`
3. $NVIM_CONFIG_DIR/docs\ROADMAP\LONG_RUN
   -> den Ordner gibt es im Baum nicht (geprüft 2026-10-04); gemeint? (siehe Task `nvim-config/docs-roadmap-pointers-catch-up`)
4. Repos abchecken, ob
  6. Design-Patterns gezielt eingestzt werden können
    7. Auflistung, wo welche Design Patterns eingestzt wurden
  7. co-routinen langsamere implementierungen erstetzen könnten.
   -> Tasks (parked): `ALL/design-patterns-audit`, `ALL/coroutine-audit`

---

### Live-Testing (braucht laufende, interaktive nvim-Session)

  - [ ] $NVIM_CONFIG_DIR/docs\ROADMAP\personal\All\FINISH
  - [ ] vim.fn.stdpath('config') .. /docs/ROADMAP/personal/All/PLUGIN_ROADMAPS_TESTPLAN.md
  - [loom.ai + ai.nvim](./Final_Checks/ai/live-testing-plan.md)
  - [media.nvim](./Final_Checks/media/live-testing-plan.md)

  Die zwei Pfade oben (`personal/All/FINISH`, `.../PLUGIN_ROADMAPS_TESTPLAN.md`) gibt es seit `729a2ff5` nicht mehr; die Listen liegen in `Final_Checks/`. Tasks dazu:
  - `Final_Checks/Running-Tasks_Checklist.md` -> `ALL/ux-backlog-live-checklist-run`
  - `Final_Checks/PLUGIN_ROADMAPS_TESTPLAN.md` -> `ALL/plugin-roadmaps-testplan-run` (Config-Teil: `nvim-config/live-check-structure-jump-and-bindings-check`)
  - `Final_Checks/BINDINGS-RUNTIME-CHECKLIST.md` -> `nvim-config/bindings-checklist-update`, `nvim-config/bindings-checklist-run`
  - `Final_Checks/ai/` -> `ai.nvim/release-v1-tag` (Alltagsdurchlauf), `ALL/claude-account-live-test-session`
  - `Final_Checks/media/live-testing-plan.md`: kein Task im Bereich `media.nvim` (dort fehlt einer; Abschnitt 9 des Plans steht auf "ungeprüft", obwohl der echte whisper.cpp-Lauf am 2026-09-17 stattfand, `a2adf38`)
  - `Final_Checks/ui.nvim.md` (Sichtprüfung Sticky-Context, 9 Punkte): kein Task im Bereich `ui.nvim`

---

### Ganz zum Schluss erst erledigen - wenn alles fertig ist

Tasks zu diesem ganzen Abschnitt (alle `parked`, bis alles fertig ist): `ALL/readme-final-review`, `ALL/docs-features-linked-to-bindings`, `ALL/option-optin-optout-audit`, `ALL/enduser-walkthrough-per-plugin`, `ALL/release-showcase-umbrella`; `ALL/strip-claude-coauthor-from-history` ist nicht geparkt.

- [ ] Alle Plugin-Root-README.md-Dateien Abschnitt für Abschnitt durchgehen: Das ist der Einstiegspunkt für Devs, die das Plugin nutzen, aber auch für normale User. Die Sprache soll daher so sein, dass User sie gut verstehen — muss nicht low-level sein, aber die Readme soll auch nicht überladen sein, usw.
  - [ ] Reale Beispiele (bitte fixen):
    - [ ] ...
  - [ ] Check ob es wichtige Features gib die nicht prominent genug als Feature dargestell werden
  - [ ] Zur fariness gehört wie ich finde, dass ich bei meinen entwickelten Plugins auch die Vorbilder nenne. also zb.: in ui.nvim tabufline oder statusline (war glaub ich eins) usw... Das möchte ich am Ende der Root-Reamde.md angeben und honorieren
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

