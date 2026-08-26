# Roadmap

- [ ] Anticheat knacken
- [ ] Merge_Finished
- [ ] in filetree.nvim super keymaps, dass resultate vonactions wie `[a`, `]f` usw... - also alles was einen string zurückgibt..
  - in die zwischenablage kopiert
  - in die zwischenablage kopiert + beim cursor einfügt
  mit "super keymap" meine ich sowas wie zb: vor `[a` das super keymap und es löst das gewümnschte verhalten aus, also es modifiziert das keymap resultatt, also zb.: `\[a` statt `[a` im filetre.nvim -> der absoilute pfad der node wrd nciht nur ausgegeben und die zwischenablaghe kopiert, sondern auch in die zwsichenablage kopiert (blödes beispiel weil bei dem sowieseo in die zwischenablge kopiert wird avber ichdneke du weißt was ich meine) und mit `ß[a` oder wenn ß nicht gut geht dann zb `?[q` und es wird der abolsute pfas ausgsgeb, in die zwischenablage kopiert und am curso eingeseetzt (auc wieder ein blödes beispiel, denn in diesem fall wäre der cursor ja im filetree, nicht in einen buffer...). aber ich dneke, es ict klar was ich miene. wenne s bessere super/modifizierte keympas gitb, gerne vorscvhläöge bringen
  Wie bereits gesgat, ist das filetree.nvim beispiel nicht das beste, wei der curso fja im filetree sein muss dazu und daher das insert unssinig ist + viele meappaings beretrits das resultat in die zwischen ablage kopieren. aer wenn es möglich wäöre,. dass generel für alle mapopings in allen plugins zu setzen, wäre das coool.ichkönnte mir einen wrapper vorstellen der in der lib.nvim implementiert ist, der ausgelöst wird um das resultat alwenn ess ein string ist zu cathcen, das mapping ausgführt. aber vl gbt e sauch hier eine naheliegendere lösung.
  Zusatz feature wäre: wenn das modiufierer mappings bei einen mappings ausgeöst wurde und der cursor nicht in einen beschreibbaren bffer steht, dass eine prompt komt ob mnan das resultsat im fokkusierten buffer oder eiunen anderen offenen buffer ieinfgpen will und in welcher eilennumer.
`[` fügt immer `[]` ein, auch wenn ihc nur die öffnende benötige. bisher war das nie so, erst seit ein paar stunden (sorrounding commit). ich will schoin da sautoclose haben, aber vl gibt es da eine möghlichkeit

## color_my_ascii.nvim

Ein eingerücter fence hl trotzdem die ganze breiote, also zb wenn ich mit dme gesamten ence um 4 rowas einrücke, dann asollten in jeder zeile des fendces die ersten 4 rows nicht hl sein, am rechten rand ist es so, dass nvim generell ein klienes padding hat, als nicht ganz nach rechts schreibt,. auch dass sollte das oppadding eingehalten werden. am screenshot erkennt man was ich meine, ich habe das mit rot angezevhnet. das soll eine option sein, die der user auch opt-out ausschalten kann

Screenshot: nvim\docs\ROADMAP\assets\fence_left_right.png

## true check

Ein Freund von mir, mitdem ich gemiensam nvim gelernt habe, hat ~ 30 nvim (+ ein natives docmap-desktop) plugins geschrieben und mir angeboten, dass ich alle üebrhnehmen kann. ich bin daran interessiert, will aber zuerst wissen, wie die codeualität ist, inahltlich ist mir aklles klar, also was die plugins machen, aber ich will keinen schlechten codebase übernehmen. kannst du die plugins analysieren und diese einschätzug machen. bitte ehrlich, keine honig ums maul oder so. ich will wissen, was gut ist, was außergewöhnlich ist (gu t als auch schlecht) was schlecht ist, wo noch viel arbeit rein gesteckt werden muss, overall zustand
Ich hoffe, du kannst das trotzdem so effizient managen, dass dies keine mega aufgabe wird, dass doll es nä,lich auh nicht sein, leider ist mir klar ds das konterkariert meine wüsnche. ckch denke, du must da einen goldenen Zwischenweg finden.
## runtime-analysis.nvim

`:RATelemetry export` hat auch repos "exportiert" bzw eine file angelegt, die gar kein lua plugin sind: WKDBook-Tricentis zb. aber nicht für WKDBooks. Hängt das miot $REPOS_DIR zusammen oder ?
Es gibt von insights.nvim eine markdown file in den telemetry daten. Was hat es damit auf sich?

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

free: So., 09:00 x - Subscription bis 21. Juli 2027
work: Sa., 06:00 98% - Subscription bis 20.Sept
dev:  Sa., 22:00 99% - Subscription bis 03.Sep

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

