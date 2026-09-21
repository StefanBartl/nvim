Roadmap

# Table of content

  - [Cdx](#cdx)
  - [Claude Tasks](#claude-tasks)
    - [lib.nvim](#libnvim)
      - [B7 — lib.nvim: the autocmd dispatcher](#b7-libnvim-the-autocmd-dispatcher)
    - [casedesk](#casedesk)
      - [A4 — casedesk: `:Case timeline` reports git pulls as work sessions](#a4-casedesk-case-timeline-reports-git-pulls-as-work-sessions)
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

# Cdx

| Account  |    Sub Bis    | Week Reset Date |  Next 5h Reset  | Actual/Insgesamt |
| -------- | ------------- | --------------- | --------------- | ---------------- |
| **main** |   ~ 28. Sep   |   Fr., 11:00    |     14:10       |    16% / 14%     |
| **work** |   21. Sept    |   Sa., 06:00    |     22:30       |    71% / 74%     |
| **free** | 22. Juli 2027 |   So., 09:00    |     14:50       |    96% / 25%     |
| **dev**  |    04. Sep    |   Sa., --:--    |     --:--       |    --% / --%     | !!!


---

# Claude Tasks

- [ ] Jedes Plugin aus sicht eines endusers/developers "durchspielen" - von Beginn an, also vom ankommen auf der github seite, ssagne wikr dealerweiße kommend von derr wkd seite. DAnn möchte m an mal als erstes normalerweiße die instsalltion + optionen sehen. ist am flow etwas nicht in ordnung? stört oder fehlt etwas? Ist die Dokumentation gut nachvollziehbar und ansprechend, modern aufbereitet? Ist die Dokumentation an Stellen verwirrend? Gib es docs, die mich als enduser/dev nicht betreffen? ([alte] Telemetry daten, Deutsche dokumentation, backlogs,..)

- `:Git [options?]` srcmds

- [ ] mdview: Auf der workstation funktinrt cursor section nicht, also die sektion wird nicht hl, caret funktionert gut, line auch; standalone gar nichts

- wkd
  - alle plugins readme.mnd auf wkd verweißen
  - kacheln hover soll kurze beschreibung des plugins, aber cool geschreiben und kurz
  - auch gruppierungen zusätzl9ich machen wie zb die hover/images/pdfport/sw... kombo die wir empfehlen gemienedaam z ulasden weil xy kreuzfeatures...
  - Tapes/Feature hl: auch in der nvim-config isntallations spec checken, was ich dort gesetzt habe, könnte hinweiß sein auf interessantes feature zum hl

## lib.nvim

## casedesk

- problems / solutions matrix us den cases erstellen
- casedesk file im wkdbook implementieren
- keuzfeatures data.nvim
- Research/NN_ActivityStream.md sgleich anlegen und bei :Case new auc gleich abfragen, ob der activiyf stream hineinposten will - dazu braucht es aber mehr als nur einen einzeiler prompt, also zuerst abfragen ob as angehöngt werden soll wenn ja, dann sollte sich ein float window öffnen, in der ich den hineinposten kann, dann specihern und schlie0en -> weiter frage, ob gleich ananomisiert werden soll, wennja, dann geocih de acivity stream ananonmyiseren und so abspeichern (den normalen unter einer level 2 amrkdown headline und darüber der annanomiserungsversuch )
  - warum dinenen wir die datei Research/NN_ActivityStream.md und nicht Research/ActivityStream.md?
  - :Case anonymize . (oder case number) ->   Warn  10:17:30 AM notify.warn [usrcmds.case] 1195796: no Activity Stream found under Research/
- docs/ auf deutsch, alles auf deustch weil sdas nur ein repo fpr mich ist, nicht fpr die öffentlichkeit^
- JQL.md: kein project key, also  `project = "TOSCA"` oder ähnliches, das bringt bei unserer suche nichts. Beispiele:

  **1. Search for 2026.1 Upgrade & UPN Login / 403 Issues:**

  ```jql
  text ~ "403 Forbidden" AND text ~ "UPN" AND text ~ "2026.1" ORDER BY created DESC
  ```

  **2. Search for Active Directory / LDAP Authentication Failures after Upgrade:**

  ```jql
  component in ("User Administration", "Authentication Service") AND text ~ "Active Directory" AND text ~ "upgrade" ORDER BY updated DESC
  ```

  **3. Search for `/tua/api/session` or Identity Server Token Errors:**

  ```jql
  text ~ "tua/api/session" AND (summary ~ "AD" OR summary ~ "LDAP" OR summary ~ "login") ORDER BY created DESC
  ```

---

### A4 — casedesk: `:Case timeline` reports git pulls as work sessions

**Source:** `.../casedesk.nvim/ROADMAP/ROADMAP.md`, section "Workflow", fourth bullet.
**Stand geprüft 2026-09-17:** open — `timeline.lua` still derives sessions
from mtimes (11 `mtime` references).

```
Aufgabe: casedesk.nvim — entscheiden, was ":Case timeline" mit
Git-Pull-Sessions macht. Das Feature liefert derzeit messbar falsche Zahlen.

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Workflow", Punkt ":Case timeline reports git
pulls as work sessions". Der Punkt ist gemessen, nicht vermutet: timeline.lua
rekonstruiert Sessions rein aus Datei-mtimes unter dem Case-Ordner, aber der
Korpus ist ein mit einer zweiten Maschine synchronisierter git-Working-Tree —
und git stempelt jede Datei, die es schreibt. Die Timeline zeigt also die
Pull-Historie:

  case 1135620: 1 session   2026-09-02 20:17 → 2026-09-02 20:17   7 files
  case 988483:  2 sessions  2026-08-19 14:48 → …  /  2026-09-02 20:17 → …

Das sind exakt die git-reflog-Einträge, und jede Session kollabiert auf Dauer
null, weil ein Pull alle Dateien in derselben Sekunde schreibt.

Prüfe ZUERST, ob das noch gilt (Stand 2026-09-17: ja, mtime-basiert).

Das ist ausdrücklich eine ENTSCHEIDUNG, kein Bau-Auftrag. Die Roadmap wiegt
drei Optionen gegeneinander ab, lies sie dort im Original:
  a) Feature fallenlassen — auf einem synchronisierten Korpus nicht tragfähig
  b) behalten, aber eine Session, deren Dateien alle dieselbe Sekunde
     tragen, als "nicht messbar" labeln
  c) Dauern künftig im Usage-Journal mitschreiben und nur zeigen, was es
     abdeckt (kann die Vergangenheit nicht rekonstruieren, startet leer)

Bring mir eine Empfehlung mit Begründung, BEVOR du etwas baust.

Mitbetroffen und im selben Zug anzusehen: detect.last_touched ruht auf
denselben mtimes und verdient denselben Blick.

Repo: E:/repos/casedesk.nvim (lua/casedesk/timeline.lua, 79 Zeilen)
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen.
```

---### A4 — casedesk: `:Case timeline` reports git pulls as work sessions

**Source:** `.../casedesk.nvim/ROADMAP/ROADMAP.md`, section "Workflow", fourth bullet.
**Stand geprüft 2026-09-17:** open — `timeline.lua` still derives sessions
from mtimes (11 `mtime` references).

```
Aufgabe: casedesk.nvim — entscheiden, was ":Case timeline" mit
Git-Pull-Sessions macht. Das Feature liefert derzeit messbar falsche Zahlen.

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Workflow", Punkt ":Case timeline reports git
pulls as work sessions". Der Punkt ist gemessen, nicht vermutet: timeline.lua
rekonstruiert Sessions rein aus Datei-mtimes unter dem Case-Ordner, aber der
Korpus ist ein mit einer zweiten Maschine synchronisierter git-Working-Tree —
und git stempelt jede Datei, die es schreibt. Die Timeline zeigt also die
Pull-Historie:

  case 1135620: 1 session   2026-09-02 20:17 → 2026-09-02 20:17   7 files
  case 988483:  2 sessions  2026-08-19 14:48 → …  /  2026-09-02 20:17 → …

Das sind exakt die git-reflog-Einträge, und jede Session kollabiert auf Dauer
null, weil ein Pull alle Dateien in derselben Sekunde schreibt.

Prüfe ZUERST, ob das noch gilt (Stand 2026-09-17: ja, mtime-basiert).

Das ist ausdrücklich eine ENTSCHEIDUNG, kein Bau-Auftrag. Die Roadmap wiegt
drei Optionen gegeneinander ab, lies sie dort im Original:
  a) Feature fallenlassen — auf einem synchronisierten Korpus nicht tragfähig
  b) behalten, aber eine Session, deren Dateien alle dieselbe Sekunde
     tragen, als "nicht messbar" labeln
  c) Dauern künftig im Usage-Journal mitschreiben und nur zeigen, was es
     abdeckt (kann die Vergangenheit nicht rekonstruieren, startet leer)

Bring mir eine Empfehlung mit Begründung, BEVOR du etwas baust.

Mitbetroffen und im selben Zug anzusehen: detect.last_touched ruht auf
denselben mtimes und verdient denselben Blick.

Repo: E:/repos/casedesk.nvim (lua/casedesk/timeline.lua, 79 Zeilen)
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen.
```

---

## Nice-to-Have wenn Limit über ist

1. ultracode auf alle plugins drüber gehen. auch mal zuerste sonnet, findet dann opus noch was und umgekehrt
2. alle bindings und features durchegehen und einen wunderbaren workflow doc machen, in der ich auch "fragen" nacheghen kann, also "ich wil xyy" -> dann hiehrin
3. C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\LONG_RUN

---

## Live-Testing (braucht laufende, interaktive nvim-Session)

  - [ ] C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH
  - [ ] vim.fn.stdpath('config') .. /docs/ROADMAP/personal/All/PLUGIN_ROADMAPS_TESTPLAN.md
  - [loom.ai + ai.nvim](C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/FINISH/Final_Checks/ai/live-testing-plan.md)
  - [media.nvim](C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/FINISH/Final_Checks/media/live-testing-plan.md)

---

# Tasks

## TOP interessant gerade

- [ ] ai: mit slaude code die beste für den rechner lokale llm installieren, soll ein paar modelle auspropoeren,  vpn hängen nicht offen ins netz, opencode usw / ollame alternativen verwenden: https://www.youtube.com/watch?v=M1j_uRqKMKI
    Wichrig: genau lernen, wie da sfunkitnert, llm, auch wuantisierung usw... graka _> iwe aerbeiten di egnau, ram upgrde treiber erstllen usw....

- [ ] TAKT -> aai impllementierung von anfang an mitbauen

---

## Ganz zum Schluss erst erledigen - wenn alles fertig ist

- [ ] Alle Plugin-Root-README.md files Abschnitt für Abschnitt durchgehen: Dies ist der entry für devs die da s plugin nutzen, aber auch für normale user. Daher sollte die Sprache auch so sein, dass User sie gut verstehen. Das muss nicht low-level sein, aber edie Readme soll nciht überladen sein, usw..
  - [ ] reale Beispiele: (bitte fixen):
    - [ ] ...

---

### Git & Repo-Hygiene / Docs, Comments,...

- [ ] Git-Release pro Repo, sobald fertig.

- [ ] README.md mit Video-Demo oder GIF ausstatten (Aufnahme/Schnitt nur durch dich).
  - [ ] Core-Features + Ablauf des Video/Gifs kann aber con claude vorbereitet werden
  - [ ] Logo / Bild für repo (socal prview card aber auch images.nvim hover)
    - [ ] diese logo soll dann auch in ui.nvim menu angezeigt werden
  - [ ] docmap-desktop app icon desktop
- [ ] feaure highlichts auf der root readme
- [ ] claude co author aus allen commits löschen



---

# Misc

- [ ] Anticheat knacken

---

# Plugin-Liste

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

