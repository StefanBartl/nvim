# Roadmap

- [ ] Hrpoon persist paths für UI: Die Checkllists in WKDBpopks-Lua sowie wkdook-neovim als persist paths hinzufügen für nivhgt workstation, alle pfade chekcen ob sie existeren in persist paths

- [ ] casedesk aworkflow optimeiren: Ich eröffne einen caseso: ich kopiere den aactivity stream in die zwischenablage, sdann :Case new, dort gebe ich daten ewie name, tile usw wien, dann legt es automatisch folder usw.. an. es soll ja auch ein ki prompt vorberieten, ibn dieser  soll acuh enthalten sein:
  - [ ] Datenpunkte für activity wstream analyse: welche attachments hat der customer beretis attached? Wenn KI enabled,dann checklisten wie "was haebn wir den cuistomer vorgeschlagen soller achen" und " was hat er zurückgemeldetund wie gemacht";

## (AN CLAUDE: NOCH NIHCT IMPLEMENTIEREN: EINFACH IGNORIEREN!)

- [ ] case: move solved/assigned/unaasiugend/OtherAgent/... -> verschiednt ordner  zum ziel. case delete
- spotlight checken und lernen
- documentation.nvim lernen
- [ ]  Könnte es nicht eine "neue art" software sein, alle meine nvim plugins entweder mit oder ohne einer nvim instanz gemeinesam bündeln und als bnary ausgheben, so das s man es wieder wie normales nvim aber halt mit + verewnden kann.
  - [ ] recommender.nvimmus nicht mitggeshipped werdem; vielleicht verwchiedene ausbaustufen bereitstellen: Base mit lib.nvim und wenigen wichtigen, dann eine versoin wo zusätliche oplugins dabei sind. usw.. als idee
- [ ] `learn-cli.nvim` vielleicht doch ?
- [ ] E:\repos\Notes\ProjectIdeas: Durchgehen und anlysieren lassen
- [ ] finish & checkists & review in nvim config durchjagen

1. `leader wq`: Alle issues lösen
  1. dass was wq macht in einem `lib.nvim / lib.nvim.ui` ausgeben
2. `/wkdoptions`
  1. UI Linemarker gehört README
  2. `wkdoptions` mit `options.lua` verheiraten (vielleicht als default_options)
3. `nvim/init.lua` durchgehen
4. [ ] Funktionen/Module identifizieren, die man mit FFI/C performanter machen könnte
  - [ ] `/nvim/lua/` – alle Module durchgehen und checken, ob sie irgendwo hineinpassen

- `z` - zoxide soll $REPOS_DIR auflösen können; Powershell soll alle meine repo ordner auflösen können. also wkdbooks -> cd $REPOS_DIR/wkdbooks usw..

---

## Implementieren

- [ ] `nvim/lua/autocmds` analysieren:
  - [ ] Refactoring?
    - [ ] `nvim/lua/autocmds` nach `nvim/lua/Bindings`
  - [ ] Welche automcds gehören in ein projet von  einen in C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\IDEAS?

- wenn man eine ganzeu zeile markiert, also shiift v im nomralmode, und dann diese in backticks umhüllen will, dabn macht man danach `` aber es umhült nicht sonder macht:
    C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/documentation.nvim.md
    ```
  also hängt in der nächsten zeile eiunfach dreio backticks an

- [ ] `lua/config/menu` nach `lua/wkdnvchad`?

## nach docs/ROADMAP/RULES integrieren und dann hier ersatzlos entfernen

### ui

| Punkt | Aufwand | Nutzen |
|---|---|---|
| `?` öffnet eine Keybinding-Übersicht | Quick Win | mittel — Muster existiert in `filetree.nvim`s neo-tree-Cheatsheet |

## ZIEL

1. Alle plugin fähigen Module augliedern
2. Funktionen/Module/ganze Custom Plugins, die man mit ffi über vc performanter machen könnte?
  1.  Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufen lassen, die mit nvim gemeinsam gestartet wir Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufe n lassen, die mit nvim gemeinsam gestartet wirdd
-2. `BINDINGS.lua`: In der Descrtiptionder Keymaps und Usrcmds: Das plugin selbst nicht nennen,, wie zb.: "[iletree]:" in fileteree.nvim keymap descreiption
3. `/autcmds`
  1. passt zu `/bindings` ?
  2. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt.
4. Checklisten anwenden
  1. ToDo's duchgehen

---

