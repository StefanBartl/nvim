# Roadmap
shift enter sollte in filetree die ndoe als buffer aufmache ohne z ufokusioern. es wird zwar
  Info  10:18:49 PM notify.info [filetree.open_variants] Added to buffer list: docs\ROADMAP\personal\All\Meins.md
   Info  10:19:06 PM notify.info [filetree.open_variants] Added to buffer list: docs\ROADMAP\personal\All\TelemetryReport.md
ausgegebn ,aber de buffer sind nict offen / in der tabliste wenn ich dann ij einen buffe gehe und versuche mit tab diese zu foksuieren, sie ind nicht da. eigentlichsollte da problemlos funktioeren, das problem habe ich schon lange gelöst gehebt i neotreee und übernommen i filetree - ich verwende auch weiterhin ndie neotree engine in filetee also müsste es funktlienren
## cdx

free: So., 09:00 x - 21. Juli 2027
work: Sa., 06:00 o - 20.Sept
dev:  Sa., 22:00 o - 03.Sep

---

## (AN CLAUDE: NOCH NIHCT IMPLEMENTIEREN: EINFACH IGNORIEREN!)

1. `leader wq`: Alle issues lösen
  1. dass was wq macht in einem `lib.nvim / lib.nvim.ui` ausgeben
2. `/wkdoptions`
  1. UI Linemarker gehört README
  2. `wkdoptions` mit `options.lua` verheiraten (vielleicht als default_options)
3. `nvim/init.lua` durchgehen und optimieren
4. [ ] Funktionen/Module identifizieren, die man mit FFI/C performanter machen könnte
  - nvim performance optimeren: startup modul, runtime analysis, docmap, usw...
- `z` - zoxide soll $REPOS_DIR auflösen können; Powershell soll alle meine repo ordner auflösen können. also wkdbooks -> cd $REPOS_DIR/wkdbooks usw.. und zwaar dynamisch nach dem welche reos in REPOS_DIR enthalten sind beim start der shell
- Alle claud ebranches in allen plugins entfernen

---

## Implementieren

- [ ] `nvim/lua/autocmds` analysieren:
  - [ ] Refactoring?
    - [ ] `nvim/lua/autocmds` nach `nvim/lua/Bindings`
  - [ ] Welche automcds gehören in ein projet von  einen in C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\IDEAS?
- [ ] `lua/config/menu` nach `lua/wkdnvchad`?
3. `/autcmds`
  1. passt zu `/bindings` ?
  2. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt. (dispatch lib modul)

---

