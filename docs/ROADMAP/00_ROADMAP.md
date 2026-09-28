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
| **main** |   ~ 28. Sep   |   Fr., 11:00    |     13:20       |    91% / 55%     |
| **work** |   21. Sept    |   Sa., 06:00    |     10:45       |    21% / 28%     |
| **free** | 22. Juli 2027 |   So., 09:00    |     18:20       |   100% / 36%     |

---

## Claude Tasks
E:\repos\images.nvim\.claude\worktrees\image-paste-performance-d063fc\lua\images\config\DEFAULTS.lua:

```lua
pdf = {
    enabled = true,
    -- Which page. There is no paging in a preview window -- the first page is    === REVIEW -> Das ist komisch geschreiben
    -- what says "this is that document", which is the whole question a
    -- preview answers.
    page = 1,
    -- Rasterization resolution. 120 puts an A4 page at ~1000x1400 px, which
    -- is more than a preview window (a few hundred pixels across) can show,
    -- and about a third of the bytes of the 216 hover.nvim rasterizes a
    -- full-screen float at. Raise it if you read pages in a large preview.
    dpi = 120,
  },

  -- Right-click context menu (nvzone/menu, soft dependency; entries from    === REVIEW -> nvzone/menu verewnde ich nicht mehr, sondern ui.nvim menu!
  -- images.integrations.menu). Automatically inactive without nvzone/menu
  -- installed -- this only controls whether M.items()/M.submenu() return any
  -- entries at all.
  menu = {
    enable = true,
  },
```


- Auch so ausgaben wie `:Hover all off` geben jetzt einen chip rechts oben aus, aber aucheine noirmale `more` Benachrichtigung unten am bldschirm. es sollte aber nur das chip sein, oder nicht?schau dir da sbitte an, weir haben kja jetzt erst lib.nvim output implementierte, bei dem man das silent angeben kann - es sollte default sein - und daher iegntlich auch diese ausgabe unterdrücken, wenn maer die message in :messages hineinscheribt, dafür aber den chip ausgibt. Warum ist das ncht der Fall? Wenn es dabei ein generelles problem gitb -> Das Plugin `noice` kann das auch, eventuell etwas "abgucken"?

- replacer.nvim bzw pickers.nvim / lib.nvim: Wenn ich replacer ausfphre, dann habe ich ja ein dreigeteilrtes     ui, die resultatslioste und darunter die prompt, nebenbei das preview. das preciew ist aber deutlich zu schjamal um bei langen links zb den trefer zu zeigen. daher mpssen wir . und das gilt füpr alle -
  1. eine key einführen, um im previerw zu moven, also nach rechts/link und unten oben, am besten buffer lokal C-Arrowes/hjkl; page/up pageDown soll auch klaopoen, da halt dann nicht zeilenweiße sonder immer ganze seiten
  2. eine legende : untere kante, zentriert;
  3. ein chewatsheet `C-?` ereichbasr, erstmal nur mit den arrows und wenn es schon andre gibt.

- lib.nvim output: wenn man einj popup gewählt hat uns es in die :messges geschrieben wird, dann soll default es aber nicht nochmal als 'more' unten am bildschirm angeeigt werden, also default soll da silent hineingeshreiben werden. das soll auch konfuigurierebrar sien. DAS IST AUCH ZB WICHTIG WERNN MAN .gIT DASHBOARD HAT; UND DORT DANN EIN PULL ALS BEISPIEL AUSGEFÜHRT WIRD; DANN MOMENTAN WIRD DASS SOWOHL ALS CHIOP RECHTS OBEN ALS AUCH ALS MORE DAN ANGEZEIGT; DAS IST EXTREM VERWEIRREND: eine sache aber ncoh: wir mpssen was einbauen, dein konzept, denn wenn zb eine fehlermeldung ausgegeben wird, und didese dann rechts oben im chip hienin angezgit wird, dann ist es schlecht wenn einafach eine lange wurst an text angezeigt wird. idealer werße wäre es so, dass ein "titel" angezeigt wird und dann darunter im gleichen chip der text, aber dann ... als forsetzung angezeigt wird, also sprich, wenn man dass aganz lesen will, uss man in :mersages oder in ":noice" rein. wenn der text fgür dne chip über normalesouput kommt, dann könnten wir hier zumindest einen optionalen, aber bniesser ppflicht, ein "titel" feld dazu geben, dass man ausfüllen muss als dev. aber was ist, wenn man von nvim als beipiel eine fehler meldung bekomment wie

```vim
11:51:27 msg_show.echomsg [gitsuite] docmap-desktop: push failed - To https://github.com/StefanBartl/docmap-desktop.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to 'https://github.com/StefanBartl/docmap-desktop.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
   Error  11:51:41 msg_show.emsg E354: Invalid register name: '^@'
```

dann mpsste zb [gitsuite] docmap-desktop: der titel sein und der rest dann als vcneetne abgeschnitten.
und bei:
  Error  11:51:41 msg_show.emsg E354: Invalid register name: '^@'

wre es cool wenn man auf einmkalk sehen würde, dass es ein error keine debugnotiz ist, (fabre macht das gleuch ich eh schon) dann E354: Invalid register name als titel und  '^@' diue mesage sein, aber weil dja das aus nvim kommt nicht voneinen plugin, mpsste das autoatisch sein. und es gibt ja noch beilöe andere beispeile
Wir brauchen da ein gutres kponzeopt


 runtime-analysis.nvim: Das 7 Tages reminder wird als notify ausgegebn, dass sollte auch popup sein, dass aber in die :messages schreibt. lib.nvim nvim.output ist es denke ich das richtige dafür.

  - `:MyPlugins reclone` ein weiteres besiopeil., das promt, ob man den reclone übher x plugins machen will oder nicht wer auch als popup besser mit summary, dann mit ja / nein buttons - also lib.nvim selection/prompt

- bei längeren prozesse, die über die statusline pugin modul abgewockt werden, wäre es sinnvoll, wenn im hover über das statsuline modul auch der progress dargestellt wid. also zb
  `:MyPlugins reclone` -> wenn man über das statuline modul hovert, soll nicht nur eine beschreibung, sondern der aktuelle state angezeigt werden. und: generell wäre es cgut, wenn man progress über das statusline modul "versteckt"/anzeigt, dass man das auch über einen normalen popup float oder so aufrufen kann, idealerweiße sowas wie `:Ui statusline **` und da eine option. denn ich habe in mehreren plugins statusline module, ich will nicht jedes einzeln updaten dass es neben den statsuline noch ein toggle popup oder so aufrufbar macht, eleganter wäre, wenn das über sas Ui statusline modul angezigt werden könntew
   Also sprich: Wenn ein pluginj progress über statusline modul anzeigt, dann soll an mit einen allgemeinen usercmd wie `:Ui statusline [**/showProgess]` o.ä. ein popup bekommen, dass eine ausführlichere ansicht des progreess aufeigt + im hover über dem statsuline progress modul soll der state des oprgress angezeigt werden

- claude api ai.nvim / loomai checks erstellen, um features ich damit checken kann

- mappings durchchecken

- C:/Users/Bernhard/AppData/Local/nvim/lua/bindings/usrcmds/context_open -> mal ein wenig ausprobieren, und solte es erweitert werden? seit der implementierung sind einige plugins dazu gekommen + features innerhalb der damlas schon bestehenden

---

### Generell

### wkd

- mobile optimierung
- umschalten zwische featureviews optimieren
- Docmap-desktop Kachel: `The kind of shell Tosca Commander or Blender put in front of a project`

---

### https://github.com/StefanBartl updaten - schon relativ alt

### Cross-Plugin

- `lib.nvim` Module -> ALle Plugins nochmal checken, ob Module/Funktionen implementieren, welche die `lib.nvim` beretis bereitsetellt oder bereitstellen sollte. Das wurde vor ein/zwei Monaten schonmal gemacht, in der Zwischnezit wurde aber viel neu gemacht. Report hierher schreiebn: $NVIM_CONFIG_DIR/docs/ROADMAP/reports

- Von welchen meiner `.nvim`-Plugins ist eine CLI-Version denkbar? `reposcope.nvim`, `gitsuite.nvim`,...

---

#### Konkurrenzanalyse

- [ ] **Feature-Scan:** Bei Plugins, die meinen ähneln (z. B. gitsigns → gitsuite.nvim, 3rd/images.nvim → images.nvim, tabufline → ui.nvim, lspsaga.nvim → lspo.nvim), die Repos mit hoher bzw. mittlerer Ähnlichkeit **und** hoher Reichweite/Nutzerzahl nach Features abgrasen, die ich noch nicht implementiert habe. Gibt es bei „mittlerer Ähnlichkeit" nur wenige Treffer, nur die reichweitenstärksten davon berücksichtigen.
- [ ] **Analyse (geklärt: nur Feature-Check, kein aktiver Ersatz geplant):** noice.nvim & übrige externe Plugins auf Feature-Abdeckung prüfen — was ist durch eigene Plugins schon abgedeckt, was fehlt noch? Nur dokumentieren, keine Ersatz-Entscheidung treffen. Diesn reportanalyse hierhin schreiben: $NVIM_CONFIG_DIR/docs/ROADMAP/reports

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
4. Repos abchecken, ob
  6. Design-Patterns gezielt eingestzt werden können
    7. Auflistung, wo welche Design Patterns eingestzt wurden
  7. co-routinen langsamere implementierungen erstetzen könnten.

---

### Live-Testing (braucht laufende, interaktive nvim-Session)

  - [ ] $NVIM_CONFIG_DIR/docs\ROADMAP\personal\All\FINISH
  - [ ] vim.fn.stdpath('config') .. /docs/ROADMAP/personal/All/PLUGIN_ROADMAPS_TESTPLAN.md
  - [loom.ai + ai.nvim](./Final_Checks/ai/live-testing-plan.md)
  - [media.nvim](./Final_Checks/media/live-testing-plan.md)

---

### Ganz zum Schluss erst erledigen - wenn alles fertig ist

- [ ] Alle Plugin-Root-README.md-Dateien Abschnitt für Abschnitt durchgehen: Das ist der Einstiegspunkt für Devs, die das Plugin nutzen, aber auch für normale User. Die Sprache soll daher so sein, dass User sie gut verstehen — muss nicht low-level sein, aber die Readme soll auch nicht überladen sein, usw.
  - [ ] Reale Beispiele (bitte fixen):
    - [ ] ...
  - [ ] Check ob es wichtige Features gib die nicht prominent genug als Feature dargestell werden
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

