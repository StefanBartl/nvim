# Roadmap

## Table of content

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

## Cdx

| Account  |    Sub Bis    | Week Reset Date |  Next 5h Reset  | Actual/Insgesamt |
| -------- | ------------- | --------------- | --------------- | ---------------- |
| **main** |   ~ 28. Sep   |   Fr., 11:00    |     21:20       |    30% /100%     |
| **work** |   21. Sept    |   Sa., 06:00    |     22:30       |   100% /100%     |
| **free** | 22. Juli 2027 |   So., 09:00    |     00:00       |    47% / 92%     |
| **dev**  |    04. Sep    |   Sa., --:--    |     --:--       |    --% / --%     | !!!

- checke alle commits dieses chats auf Bugs, Securitx / Performance Optimierungen und fixe sie gleich.

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
- Neue Features ggf. im Plugin-eigenen /TESTS/ folder testen

`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/PERFORMANCE.md`
`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/LUA_NVIM.md`
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/`

---

## Claude Tasks

- [ ] docmap-desktop: docs/AGENT_CHECKLIST_RUNNER.md — dazu PLAN.md's L6-Zeile mit einem Verweis versehen.
  loomAI: docs/Guides/docmap-checklist-agent.md
  Kernaussage in beiden: /ask//ask/stream sind bei loomAI fertig und reichen für den einfachen Fall schon heute (Aufwand dort: 0). Was L6 architektonisch eigentlich braucht — die DecisionQueue, die "Vorschlag, kein Ergebnis" durchsetzt — ist in /decision nur eine Log-Zeile ohne echte Warteschlange; Phase 3/4 aus deinem eigenen Architekturplan sind komplett offen. Empfehlung in beiden Dateien: jetzt gegen /ask bauen (~2,5–3 Sessions auf documentation.nvim/docmap-desktop-Seite, 0 bei loomAI), die Anbindung an eine echte DecisionQueue erst mitnehmen, wenn Phase 3 dort ohnehin angegangen wird.
  - neue gh feature tag release
  - setup.exe file, zum download anbieten

- [ ] Jedes Plugin aus sicht eines endusers/developers "durchspielen" - von Beginn an, also vom ankommen auf der github seite, ssagne wikr dealerweiße kommend von derr wkd seite. DAnn möchte m an mal als erstes normalerweiße die instsalltion + optionen sehen. ist am flow etwas nicht in ordnung? stört oder fehlt etwas? Ist die Dokumentation gut nachvollziehbar und ansprechend, modern aufbereitet? Ist die Dokumentation an Stellen verwirrend? Gib es docs, die mich als enduser/dev nicht betreffen? ([alte] Telemetry daten, Deutsche dokumentation, backlogs,..)

- `:Git [options?]` srcmds

- [ ] mdview: Auf der workstation funktinrt cursor section nicht, also die sektion wird nicht hl, caret funktionert gut, line auch; standalone gar nichts

- wkd:
  - startseite.: commitsanzahl alle plugins sllte nicht als prominente kachel stehen, das ist keinalitätsmerkaml, tasuche es auus gegen eine kachel wie "+500 features" also die ungghefähre gheschätze features zahl ode<F, auch vimdoc als eoigene kachelk finde ich nicht gut, inde eine bessere metrik die für user geeignet ist; last push auch ersetzen- #
  - die indexlöeiste All 36 AI EEditing Files & Navigaet usw... hier auch beim hovern zufallsfarben wie beiu den kachel
  - 	every tagline, status and commit below is read from the source, not written here. -- das , not wriitten here. - streichen
  - bottom leiste das "Generated from the plugin repositories — nothing here is written twice." streichen u8nd "a famili of neoivim plugins" in die mitte.- darunter MIT Livemncse
  - tapes:
    - images.nvim:

      ```markdown
      9. TROUBLESHOOTING  *images-troubleshooting*

      Nothing is drawn
          Verify the terminal itself first, outside Neovim:
          wezterm imgcat picture.png
          If that shows nothing, the terminal does not do OSC 1337 — with
          ImageMagick installed, :Image show/hover already fall back to a
          block-character rendering instead (|images-ascii-config|); without it,
          this plugin cannot help. If OSC 1337 works but Neovim does not, run
          :checkhealth images.
      ```

    Hier wird spezifisch wezterm genannt, weil ich es verwende. Es geht aber um das kitty protocolö wenn ich richtig liege, alsao sollte man das abcheken, nicht wahr? Das slllten wir auch in den anderen repos in den docs checken, ob wezterm oder typiache ähnliche fälle findet. wenn euin bestimtes tool zwingend hnotwendig ist, dann kann kan das schon verwenden als namen

    - kacheln im normalen skin, beim hovern könnte man zufäälige fgarben verwenden statt nur weiß, zb diessese pink, oder giftgrün, alsos ehr grelle farben, so ein higllight marker leuctendes gelb und ein kjmnalliges orange..-.

---

### lib.nvim

#### B7 — lib.nvim: the autocmd dispatcher

```
Aufgabe: lib.nvim — den autocmd-dispatcher bauen (ein Autocmd, viele
Handler).

Konzeptdokument: E:/repos/WKDBooks/Development/wkdbook-myplugins/lib.nvim/
ROADMAP/autocmd-dispatcher.md, verlinkt aus ROADMAP/ROADMAP.md unter "Open
concepts (not implemented)".

Das Konzept ist bereits gegen die Realität geprüft — 17 echte
FileType-Registrierungen über die Flotte — und die Empfehlung lautet: bauen,
generisch über das Event. Zwei Fixes sind beim Lesen des Config-Prototyps
schon gefunden und stehen im Dokument:
  1. Sortieren bei der Registrierung, nicht bei jedem Feuern
  2. eine eigene ID pro Registrierung statt tostring(handler.load) für "once"

Lies das Dokument ganz, bevor du anfängst, und halte dich an seine
Empfehlung statt neu zu entwerfen.

Danach zu klären und mir zu berichten: wer wird der erste echte Konsument?
Ein generischer Dispatcher ohne Umstellung eines echten Call-Sites ist
unbewiesener Code. Die 17 gefundenen Registrierungen sind die Kandidaten —
schlag mir eine oder zwei vor, an denen sich der Nutzen zeigen lässt.

Repo: E:/repos/lib.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen — lib.nvim-Module haben eine eigene
README je Modul, das ist Hausstil. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen, und das Konzeptdokument aus
der "Open concepts"-Liste in lib.nvim/ROADMAP/ROADMAP.md herausnehmen.
```

---

### casedesk

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

#### A4 — casedesk: `:Case timeline` reports git pulls as work sessions

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

### Nice-to-Have wenn Limit über ist

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

