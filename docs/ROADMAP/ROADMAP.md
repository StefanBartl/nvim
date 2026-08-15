# Roadmap

In `documentation.nvim` && `runtime-analysis.nvim` sind noch offen zu implementieren:
  E:\repos\runtime-analysis.nvim\docs\IDEAS.md
  E:\repos\documentation.nvim\docs\ROADMAP\IDEAS
  E:\repos\documentation.nvim\docs\ROADMAP\V1_EXTENSION
  E:\repos\documentation.nvim\docs\ROADMAP\MULTILANG.md
Knnst du einen implementierungsplan ausarbeiten, wi es sinnj maccht, dass zu ijmplementieren
dabei muss t du vor al em in documentaion.nvim ausmisten, denn zb in der desktop_weebapp file, das wurd eschon mit er der app docmaü-desktop (auch unter e:\repos) scho umgestze, aber abklären ob alles umgest wurde, wenn nein,. dann in diee roadmap doprt schireben

- nvim performance optimeren: startup modul, runtime analysis, docmap, usw...


E:/repos/docmap-desktop/docs/ROADMAP.md abarbeiten + einmal hbrainstomren fpr weeitere features bzw optionen, ui, usw...

## (AN CLAUDE: NOCH NIHCT IMPLEMENTIEREN: EINFACH IGNORIEREN!)

- [ ] spotlight: warum `leader mk`? Und nicht `leader s*`? itte umstelen. sofdern nichts dagegen spricht (andere mappings). update doe docs und auch C:/Users/bartl/AppData/Local/nvim/docs/NOTES/BINDINGS  (hier kajnn man auch checken ob eine keymaps schon besetzte ist=)
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
- Alle claud ebranches in allen plugins entfernen

---

## Implementieren

- [ ] `nvim/lua/autocmds` analysieren:
  - [ ] Refactoring?
    - [ ] `nvim/lua/autocmds` nach `nvim/lua/Bindings`
  - [ ] Welche automcds gehören in ein projet von  einen in C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\IDEAS?

- wenn man eine ganzeu zeile markiert, also shiift v im nomralmode, und dann diese in backticks umhüllen will, dabn macht man danach `` aber es umhült nicht sonder macht:
    C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/documentation.nvim.md
    ```
  also hängt in der nächsten zeile eiunfach dreio backticks an.
- [ ] strg+v soll trimmen

- [ ] `lua/config/menu` nach `lua/wkdnvchad`?
- [ ] Autocompletion beim schreiben funktiert schon mit zusätzlichen dictionary bvon mir, jetzt wäre es noch toll, wenn oft verwendete höher geranked werden bei den vorschlägen

## ZIEL

1. Alle plugin fähigen Module augliedern
2. Funktionen/Module/ganze Custom Plugins, die man mit ffi über vc performanter machen könnte?
  1.  Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufen lassen, die mit nvim gemeinsam gestartet wir Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufe n lassen, die mit nvim gemeinsam gestartet wirdd
-2. `BINDINGS.lua`: In der Descrtiptionder Keymaps und Usrcmds: Das plugin selbst nicht nennen,, wie zb.: "[iletree]:" in fileteree.nvim keymap descreiption
3. `/autcmds`
  1. passt zu `/bindings` ?
  2. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt.

---

