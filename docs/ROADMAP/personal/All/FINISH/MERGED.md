# Merged Roadmap — CDX.md + CHECKLIST.md + FINISH_ME.md + Meins.md

Gilt für "alle Plugins" = alle Einträge in `lua/plugins/personal/source.lua` - außer spezifisch es Plugin ist in der Task angegeben.

---

## Liste A — Braucht dich

### Live-Testing (braucht laufende, interaktive nvim-Session)
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

### Git & Repo-Hygiene
- [ ] ci workflows -> ausbauen wenn notig, alle grün "machen"
- [ ] Alle Features/Bugfixes committen & pushen (Commit-Message ausgeben, falls Push nicht möglich). — **Zuletzt geprüft 2026-08-26: alle 31 Repos + Config sauber und gepusht; Claude-Branches und `.claude/worktrees/` überall abgeräumt (siehe `Merged_Finished.md`).** Wiederkehrend, bleibt daher stehen. Alle Claude Branches löschen (außer den aktuellen), vorher noch checken, ob comitts enthalten sind ie noch nnicht in mian sind.
- [ ] Git-Release pro Repo, sobald fertig.

### Docs, Comments,...


- [ ] Logo / Bild für repo (socal prview card aber auch images.nvim hover)

- [ ] Eventuell selbst alle repos - jede file - durchgehen und bei auffälligen (Zu langer/unnötiger Kommnentar, Code strange, Docs fehlen/anders struktuiren, usw) einen Tag setzen, zb.: `--- CDX:` oder selbst gleich fixen

- [ ] README.md mit Video-Demo oder GIF ausstatten (Aufnahme/Schnitt nur durch dich).

- [ ] Core-Features + Ablauf des Video/Gifs kann aber con claude vorbereitet werden

- [ ] Alle docs/ Files in jedem .nvim repo müssen nochmal überprüft werden, auf aktualitöt & korrektheit - Doppelungen entfernen, stimmt alles was behauptet wird, Referenzen updaten, usw...  docs/README Themenaufteilung / docs Struktur überelgen - einheitiche struktur finden für alle repos; Deutsche docs nur, wenn eine englische Hauptversions der file besteht und explizit eine deutsche version von mir verlangt wird. Weiteres auf das überprüftr werden soll gleich am anfang mit ausfschreiben, man könte für diesen duirchgang eien art docs checklist machen.
  - [ ] Generell soll das Prinzip herrschen: `Nicht "so viel wie möglich" in die docs, sondern nur das, was für User und Devs auch tatsächlich interessant sein kann. Der Rest nach WKDBooks/Deveolpment/wkdbook-myplugins/ - da können auch reine informations docs ausgelagert werden, die entwedet "zu tief" gehen für normale repo docs oder weder für devs noch für user einen naheliegenden Mehrwert haben. wkdbook-myplugins ist kein "Downgrade", sondern meine interne Notizensammlung`
  - [ ] Das gleiche mit den Kommentaren im Source code.
  - [ ] C:/Users/bartl/AppData/Local/nvim/docs/NOTES/BINDINGS muss durch gecheckt werden. Dies soll ja CHeatsheet für bindings sein, in manchen files stehen aber mehr infos drinnen, teilweiese sogar roadmap/handover notes usw... Wenn die infos dort drinnen wichtig sind, dann gehören sie ind die docs des repos nicht zu mienen bindings doc
      - [ ] In jedem PLugin, wenn eine api angeboten wird, dann einen /docs/Usecases/** (oder so ähnlich) dazu erstellen
      - [ ] Folder wir worekflow/usecases könnten eine Overview.md oder so ähnlich haben, die auf alle usecases files vewreist und diese kurz beschreibt., so soll bessere übersicht herrschenn und die README.-md kann auf diese übersicsfiles vewreiesen, anstsatt beispiehaft auf irgendeine file des folders
      - [ ] Die README.md ist wichtig: es ist dass, was die devs/users als erstes sehen und wo wisie priomär iohre informationen beziehen bevor sie sich entscheiden ob die da splugin installieren. daher sollte dort auch ein guters Konzept ver folgt werden:
        - [ ] Alle sollen "Alpha stagge" disclaimer haen, breaking changes müssen erwartet werden
        - [ ] Einmleitend hinweiße auf 2-3 repos aus emeiner plugin sammlung
        - [ ] ASCII-Art Block + passende Badges
        - [ ] Hinweis auf workflow/usecase/api usw... files in der docs um zu zeigen: Wenn du m öchtest, die docs isnf gut ausgebaut, hier kannst du infos bekommen
        - [ ] ....

---

## Liste B - Claude Tasks

- [ ] Nach den Änderungen der letzen Wochen müssen wiederhholt werden:
  - [ ] Tools für nachstehende aufgaben wurden gebaut, aber wieder entfernt als die task fertig  war. aber wir haben eine nptes dile angefertigt, um wenmigsens wissen zu konservieren bez  der tools: C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH\ERLEDIGT\roadmap-tools-analysis.md
  - [ ] `lib.nvim` module verwendet wo sinnvoll und möglich in den neuen Source Code?
    - [ ] C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH\ERLEDIGT\Handover_ERLEDIGT\HANDOVER_dedup.md als note
  - [ ] [Diagnostcs files](C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH\ERLEDIGT\DIAGNOSTICS) Nochmals anwenden aber miz dem, was gelernt wurde aus den letzen Durchläufen
  - [ ] [Magic numbers](C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/FINISH/ERLEDIGT/Handover_ERLEDIGT/zahlen-ohne-namen.md) neu durchchecken
  - [ ] Keymaps müssen auch als usrcmds existieren: C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH\ERLEDIGT\keymap-command-parity.md
  - [ ] alle fetures in denen es sinn macht sollen konfigureirbar sein durch den user, notes: C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\personal\All\FINISH\ERLEDIGT\nicht-konfigurierbare-features.md

- [ ] `docmap-desktop/docs/PLAN.md` — 17 offene Punkte für drei Repos: E:/repos/docmap-desktop/docs/PLAN.md
  - [ ] docmap-desktop app icon desktop

- [ ] deps installer: ewigenes Plugin vl mit lazy installer neuscheriben kombineinre, sodas bei plugin isntall ghleic cli tools checked werdebn?
  - [ ] - [ ] tesseract gehört installiert, also eine notiz in nvim install doc hinzufügem. und: cli tool installer ?
  - [ ] Wenn cli toios in einen meuiner plugins verwendet wird, wie wird es dem use snagezegit wenn es fehlt?

- [ ] Videos transkripten; Überstzung / Zusammenfassung erstellen; Images text extrahieren; usw... ALles was damit zusmmenhängt bzw sinnvoll ist als Features da anzubieten: Konzept machen -> eventuell bestehende plugin api's nutzen und zusammenführen; Dashboard mit allen Mediendateien die gefunden wurden in path/cwd/cfile/ usw..und dann selection, welche aktion man darauf ausführen will;

- [ ] E:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/PLUGIN_ROADMAPS_TESTPLAN.md
- [ ] gopath.nvim: broken loinks öffnen trotzdem einen buffer


- [ ] In C:/Users/StefanBartl/AppData/Local/nvim/docs/ROADMAP/personal/All/Diagnostics.md:
     [`deprecated` (23) -- veraltete Neovim-APIs](#deprecated-23-veraltete-neovim-apis)
  -> das zeigt gut an, was in `migrate.nvim` implementiert werden soll.
    Zusatz Feature: Alle im `h deprecated` implementieren
    - scope `path/cwd` -> damit könnte man dann ein gesamtes repo automatisch ent-deprecaten
    - cool wäre dann eine  Art picker mit den Treffern und im Preview window wird angezeigt, wie es updatet werden soll, dann lann man treffer für treffer entschiedne ob das eh passt. ein `m` - mark feautre wie in `filetree.nvim` wäre ideal um mehrere zu markieren die updatet werden sollen
    - ein test-sheet mit absichtlichen Fehlern, um z utesten und zu belegen, dass dass Plugin funktioniert.

- [ ] Github Stats auswerten / backupen / Stats zusammenziehen

---

