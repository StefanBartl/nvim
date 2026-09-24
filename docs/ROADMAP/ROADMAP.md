# Roadmap

## Table of content

  - [Cdx](#cdx)
  - [Claude Tasks](#claude-tasks)
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

- grats guthaben 250 dolar beommen, daher idealer zeitpunkt um ai.nvim bz loomai mit claude accout live u testen; rulers. auch checken mit agent

. rechsklickmenu im bnrmaln bffer w3enn auf ienen freitext pfad/ markdown linkusw... rechtsklick uwrde bzw ein teil eines links markiert wurde, dann sol e einen eigenen entry "paths " geben von gopath, und dann halt aufmachen können. die idee, dass man von einen pfad auch nur einen teil msaarkieren kann um idesen dan z uöffenn, wäre en neues feature in goapth auch zu implementieren bzw auch ein feature, u den pfad ob ganz oder teilmarkeirt auch in filetree zu öffnen wäre auch ein neues featrue glaub ich. und noch was: wenn man auf einen folder, nicht filepath goapth gF/usw ausführt, dsann zigt e mopmentan n, ob man diese file erstellen will. es ollte aber so esein, dass es frat, ob man in den folder eine neue file erstlellen will und wnen ja dann den namen, oder ob man im im filetree.nvim öffnen möchte (nur wen installiert) das macht mehr sinn. und: wenn man mit gopath keymap eine file öffnet un dder filetee ist offen, dann rereshed der nicht autoamtisch. dass dsollte imer sein, also sobald der buffer wechselt zu einer anderen file, alo nee buffer file fksuert, sollte der filetree refreshen.

- ui.nvi m statusline, hoverüber ien stauslne modul soll ein kleines popup öffnen das bescheibt, was das modul macht/anzeigt auc him rechtklick auf ein stausline modul wrd gerade ien menu abgezeigt, das passt, aber da wäre es ch cool, wenn eine kurze description steht, nur zweiu dre wörtwr

- gitsuite.nvim:
  - implemtniert es lazygit bzw die anderen externen git plgins nur, oder ersetzt es diese tatsächlich? Wenich zb leader lg aufrufe, dann bekomme ich lazygit ui, bzw die gleiche ausschauende ui sogar mit "lazygit" als überschrift; Idealerewiße würde es die funktinen von lazyghit + neogit als eine uzi verbnidnen im lazygit look.
  - `:Git ui ` hat als options auch nicht installierte plugins zb neogit ist nbei mir nicht installiert das nvim plugin, ist aber in der options list

- lsp.nvim / blin / nvim-cmp -> Es fehlt $REPOS_DIR - egal auch wenn ich es schonmal geschireben habe, ist es nicht in der autocompletoin list. fixen

- hover.nvim:
  - wenn pfad oder markdownlink path auf einen folder fällt, dann im hver den ordner anzeigen mit seinen subfolder + fles, abr ssrtamal nur root ebnene des folders, eventuell dann mit keyxs / linksklickl im hover auf/zu klappen der folder. cool wäre dann auch, wenn man mit deem curtor ins hover gehen kölnte bzw mit linksklick auf eine file im hover diese dann als neuen buffer nrmnal n nvim öfnen kann. ein bschen wie ein mini filetree -> eventuell wenn nötig sol filetree.nvim dafür eine api anbieten, dieknnte später auch hilfeich sein; zb fürs rendern oder für die actions usw...

- plugins die meinen ähneln (zb gitsigns -> gitsuite.nvim oder 3rd/images.nvim -> images.nvim oder tabufline -> uinvim oder lspsaga.nvim -> lspo.nvim ,also repos vopn andren dvs die direkt, sehr oviel, vile oder mittel ähnmlcihelkt haben, aber nuciht alle sondern nur die mit virl reichweite/hohr nutzerzahl um das ein wengnig abzugrenzen; wenn es wenige ähnlichke gibt, sondren nur vueke ab "mittel-ähnlcihketi" dann drt auch nur die reichweitenstärksten usw...) auf features abgrasen, die ich noch nicht imlpementiert habe
  - noice & restliche der externe plugins ersetzen ? Was macht SIn, was nicht?

---

### interessant

- [ ] ai: mit slaude code die beste für den rechner lokale llm installieren, soll ein paar modelle auspropoeren,  vpn hängen nicht offen ins netz, opencode usw / ollame alternativen verwenden: https://www.youtube.com/watch?v=M1j_uRqKMKI
    Wichrig: genau lernen, wie da sfunkitnert, llm, auch wuantisierung usw... graka _> iwe aerbeiten di egnau, ram upgrde treiber erstllen usw....

- [ ] [TAKT](./$REPOS_DIR/takt) -> ai impllementierung von anfang an mitbauen; ins konzept mit aufnehmen

- [ ] Gaming-Anticheat systeme lernen aus red/blue team cyber sec sicht

---

## Tasks

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

### Ganz zum Schluss erst erledigen - wenn alles fertig ist

- [ ] Alle Plugin-Root-README.md files Abschnitt für Abschnitt durchgehen: Dies ist der entry für devs die da s plugin nutzen, aber auch für normale user. Daher sollte die Sprache auch so sein, dass User sie gut verstehen. Das muss nicht low-level sein, aber edie Readme soll nciht überladen sein, usw..
  - [ ] reale Beispiele: (bitte fixen):
    - [ ] ...
- [ ] autocmds, usrcmds, keymaps -> bindings cheinen ein guter zeiger für features eines opklugins zu sein, arbeiten wird iese durch im sinne, dass in den dcos ach alle features des plugins dargestellt werden, aksi zb können usrcmds 1 und zwqeiu sowie keymapo x,y,z und autocmd drei -> ein feature des polugins darstellen; so hääte man die bindings docs auf der einen seite, und auf der andererrn seite die features, die dann in ihrer beschreibung mit den bindings verknüpft werden.
- [ ] Alle Features der Plugins als opt-in/opt-out auflisten (und auch in die docs/FEATURES al Note anmerken) unddann nochmal entscheiden für ejde einzelne option, onb opt-in oder opt-out
- Jedes Plugin aus sicht eines endusers/developers "durchspielen" - von Beginn an, also vom ankommen auf der github seite, ssagne wikr dealerweiße kommend von derr wkd seite. DAnn möchte m an mal als erstes normalerweiße die instsalltion + optionen sehen. ist am flow etwas nicht in ordnung? stört oder fehlt etwas? Ist die Dokumentation gut nachvollziehbar und ansprechend, modern aufbereitet? Ist die Dokumentation an Stellen verwirrend? Gib es docs, die mich als enduser/dev nicht betreffen? ([alte] Telemetry daten, Deutsche dokumentation, backlogs,..)

---

#### Git & Repo-Hygiene / Docs, Comments,...

- [ ] Git-Release pro Repo, sobald fertig.

- [ ] README.md mit Video-Demo oder GIF ausstatten (Aufnahme/Schnitt nur durch dich).
  - [ ] Core-Features + Ablauf des Video/Gifs kann aber con claude vorbereitet werden
  - [ ] Logo / Bild für repo (socal prview card aber auch images.nvim hover)
    - [ ] diese logo soll dann auch in ui.nvim menu angezeigt werden
  - [ ] docmap-desktop app icon desktop
- [ ] feaure highlichts auf der root readme
- [ ] claude co author aus allen commits löschen

---

