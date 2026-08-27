# Roadmap

## Table of content

  - [Misc](#misc)
  - [filetree.nvim](#filetreenvim)
  - [color_my_ascii.nvim](#color_my_asciinvim)
  - [wezterm padded nvim - bottom padding ist unverhältniossmäßig groß](#wezterm-padded-nvim-bottom-padding-ist-unverhltniossmig-gro)
  - [images.nvim erweiterung](#imagesnvim-erweiterung)
  - [workflow + usecases in allen plugins](#workflow-usecases-in-allen-plugins)
  - [runtime-analysis.nvim](#runtime-analysisnvim)
  - [true check](#true-check)
    - [Plugin-Liste](#plugin-liste)
  - [cdx](#cdx)

---

## Misc

- [ ] Anticheat knacken
- [ ] Merge_Finished
- [ ] stylua nvim-config
- [ ] Keymap, mit der sich das letzte echte cmd/vimmotioon/keymap/usw.. nochmals ausführen lässt. Dabei müssen die hjkl/UpDownLefRight-Arrow sinnvoll weggelassen werden. Beispiel: j,j,k,`3 M-Right` (indente die aktuelle Zeile * 3 count = indente die näxhsten 3 Zeilen) - dann gehe ich 5 zeilen runter, also j,j,j,j,j oder 5j - wenn ich jetzt das neuen Keymap ausführe soll es nochmal `3 M-Right` ausführen, die 5j asl reine bewegung wegfilterm (das ist auch der unterschied zu nvims default `.` wenn ich es richtg verstanden habe).
  Es soll immer den letzen echten command nehmen, also wenn man: j,j,k,`3 M-Right`,  dann 5 zeilen runter, also j,j,j,j,j oder 5j, dann zb.: `M-c` (neues bulletpopint cascade.nvim), dann j,j,j dann das Super Keymap, dann ereugt es eiwieder einen Bullet Point, weil das der letzte cmd war, nicht das `3 M-Right` indent.

  Dies könnte ebenfalls ein neues `Super-Keymap` sein so wie wir in der lib.nvim bereits zwei haben
  Abseits davon gib mir bit te auch ncoh aus, ob es ähnlixhes beretis default in nvim gibt bzw obn es einen weg gibt, das default nachustellen.

- [ ] `M-CR` soll ein normales enter  sein im insert mode, also `cascade.nvim`s next bullet generieren überspringen - oder gbtes dazu schon einen anderen?
- [ ] **All usrcmds wie :DocMap**All, RATelemetryAll oder :LibAutocmdDocsAll -> grundsätzlkich sollten die jeseileigen ursprünglichen usrcmds für single repos zumindest eine option haben, mit der durch ein dir iterriert werden und daraug angewendet werden kann, sodasds man das *All dort surchführen kann.
- [ ] lib.nvim menu: wir haben einen einziges icon - delete files - drinnen. entweder haben alle bzw der überweältigende mehrehit ein icon oder gar keines
- [ ]alle keymaps der nvim config durcsheen ob die wirlich gebraucht werden
- [ ] `O` sollte ein bulletin ereugen, wenn darüber eines bullet ist (`cascade.nvim`)

---

## filetree.nvim

Ich atte einen rfolder docs/Telemetry unfd wolte ihn auf docs/TELEMTRY mit `r` umenbenenen,. ich bekam eine prompt das es den ordner TELEMTRY bereits gibt, obewohl ich sah dass das nicht der fall ar. ich habe auf Trotzdem umbenenen geklickt, dann hat es einfach den ordner kopeirt und ich hatte einemal docs/Telemetry und docs/TELEMTRY mit dne gleichen inhalt. Für mich sieht das nach einen bug aus.

---

## color_my_ascii.nvim

Ein eingerücter fence hl trotzdem die ganze breiote, also zb wenn ich mit dme gesamten ence um 4 rowas einrücke, dann asollten in jeder zeile des fendces die ersten 4 rows nicht hl sein, am rechten rand ist es so, dass nvim generell ein klienes padding hat, als nicht ganz nach rechts schreibt,. auch dass sollte das oppadding eingehalten werden. am screenshot erkennt man was ich meine, ich habe das mit rot angezevhnet. das soll eine option sein, die der user auch opt-out ausschalten kann

Screenshot: nvim\docs\ROADMAP\assets\fence_left_right.png

---

## wezterm padded nvim - bottom padding ist unverhältniossmäßig groß

wezterm macht ein pasdding rund um nvim. mögloichewerweiße ahben wir das bei image.nvim bei den letzten commites der letzten 4 tage bverändert damit images inline hover angezegit werden korrekt, oder als ich das Configs  repo uopdatet habe, da habe ich auch die wezterm config umgeschrieben.
vorallem das padding unteneren rand ist ziemlich viel und störend, screenshot:  docs/ROADMAP/assets/wezterm_padding.png
vor allme, weil her ja 2 statuslines aufeinenader kommen, das von wezetm und dass von nvim....

---

## images.nvim erweiterung

image/pdf/file hover nicht nur in markdown links, sondern auch bei ganz normalen pfaden wie:

docs/ROADMAP/assets/wezterm_padding.png

das dieses feature auh toll zu gopath.nvim passen würde, wäre das ein feines feature - ich würd darauf plädieren, dass gopath.nvim images.nvim als soft cedep einbindent. wenn es nicht installiert ist, weil der user es nicht möchte, dann würde gopath.vim das einfach nicht anbieten, denn doppelte implementierung ist nicth mein wuindsch  und das hocer preview von files ist ach nicht gopaths ern feature. es soll dennochj opt-out sein, als  der user soll auch wenn images.nvim installiert ist die wahl haben, es nicht zu vewrendem

---

## workflow + usecases in allen plugins

Checked the stray German lines in the two English docs
MENUBARs Deutsch sind die lokalisierten Menü-Labels — bleiben. WORKPLAN hat zwei Stellen. Los mit ROADMAP.


Ran 7 commands, created 2 files
+204
-209

Ran 3 commands, created head.md
+156
-0
Now the tail section.


Created 6 files, ran 17 commands
+1096
-0
docmap-desktop ist erledigt und gepusht. Jetzt zum nächsten Task in der Liste.


Ran 21 commands
Jetzt schreibe ich die fehlende WORKFLOW.md für lsp.nvim.


Created WORKFLOW.md, ran 20 commands
+153
-0
Jetzt aktualisiere ich documentation.nvim's WORKFLOW.md um die Lücke seit dem 15.08.


Ran 20 commands, created 2 files
+150
-0
Ich ergänze die fehlenden Zeilen in KEYMAPS.md und füge dann die WORKFLOW-Abschnitte ein.


Ran 4 commands
Jetzt die WORKFLOW-Abschnitte einfügen und den gp-Abschnitt um den Picker-Modus ergänzen.


Ran 25 commands, created 2 files
+124
-0
DASHBOARD.md und BINDINGS.md sind aktuell — nur WORKFLOW.md hinkt hinterher.


Ran 18 commands, created mv.md
+54
-0
Jetzt die WORKFLOW-Abschnitte für runtime-analysis.nvim.


Created ra.md, ran 35 commands
+75
-0
Der Tabellen-Form braucht ein benanntes lhs, nicht positional — ich korrigiere mein Beispiel.


Ran 14 commands
Fixed the keymap example
Verified fzf key name and committed
sessions WORKFLOW + commit tail
Updated and committed sessions WORKFLOW
recommender WORKFLOW + commits
Read the -c and analyzer sections
Updated recommender WORKFLOW
Committed recommender WORKFLOW
pdfport WORKFLOW + commits
Read batch summary part
Updated and committed pdfport WORKFLOW
cmdlog WORKFLOW + commits
Read the notes section and risky test
Checked for stale notes references
grep -rn 'opts.notes\|notes_picker\|per-command note' docs/*.md README.md 2>/dev/null | head -5
(Bash completed with no output)
Session limit reached
Auto-resuming at 5:31 PM
Auto-continue when limits reset

---

## runtime-analysis.nvim

`:RATelemetry export-all` hat auch repos "exportiert" bzw eine file angelegt, die gar kein lua plugin sind: WKDBook-Tricentis zb. aber nicht für WKDBooks. Hängt das miot $REPOS_DIR zusammen oder ? Ich dneke mir das desewegen, weil im e:\repos als $REPOS_DIR auf der Workstation WKDBooks und WKDBook-Tricentis benfals im repoo ordner waren. auf dieser maschien hier sind viele anderen ordner mehr darin aber da habe ich es nicht getestet.

  Kannst duz das checken? Beide WKDBooks und WKDBook-Tricentis repos sidn beides repos mit .git folder, ansosnten nmur markdonw files oder assets, ich versthe auch nicht warum nur einer

---

## true check

Ein Freund von mir, mitdem ich gemiensam nvim gelernt habe, hat ~ 30 nvim (+ ein natives docmap-desktop) plugins geschrieben und mir angeboten, dass ich alle üebrhnehmen kann. ich bin daran interessiert, will aber zuerst wissen, wie die codeualität ist, inahltlich ist mir aklles klar, also was die plugins machen, aber ich will keinen schlechten codebase übernehmen. kannst du die plugins analysieren und diese einschätzug machen. bitte ehrlich, keine honig ums maul oder so. ich will wissen, was gut ist, was außergewöhnlich ist (gu t als auch schlecht) was schlecht ist, wo noch viel arbeit rein gesteckt werden muss, overall zustand
Ich hoffe, du kannst das trotzdem so effizient managen, dass dies keine mega aufgabe wird, dass doll es nä,lich auh nicht sein, leider ist mir klar ds das konterkariert meine wüsnche. ckch denke, du must da einen goldenen Zwischenweg finden.

---

### Plugin-Liste

Hier die Liste meiner Plugins - du findest sie unter `c:\repos` - und du hast Zugriff darauf:

buffer-ctx.nvim
cascade.nvim
cmdlog.nvim
color_my_ascii.nvim
dap.nvim
debugging.nvim
diff.nvim
documentation.nvim
emojis.nvim
fileops.nvim
filetree.nvim
github_stats.nvim
gopath.nvim
images.nvim
insights.nvim
language.nvim
lib.nvim
lsp.nvim
markdown.nvim
mdview.nvim
migrate.nvim
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

und das native: docmap-desktop

---

## cdx

free: So., 09:00 98% - Subscription bis   21. Juli 2027
work: Sa., 06:00 98% - Subscription bis   20. Sept
dev:  Sa., 22:00 99% - Subscription bis   03. Sep
main: Fr., 11:00 10% - Subscription bis ~ 27. Sep

---

