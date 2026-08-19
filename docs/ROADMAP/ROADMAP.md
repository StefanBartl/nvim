# Roadmap

## docmap-desktop / documentaion.nvim browser

- in der menüleiste eine Möglichkeit feedack auszuwählen, dann kann jemand eines schreiben und absenden, dass oll idealerweiiße in github auf der doksusions thread oder so posted werden
  - einen dropdown einabuen, bei den man das thema sa´asuwählne kann, dort sol ein optione "Featurewunsch" sein
- Wäre es denkbar, eine api zu schreiben, damit man erweiterungen für docmap-desktop schreiben könnte?

## markdown.nvim, images.nvim

Beispiel:

```markdown
![Start Screen](assets/Device_und_TMA_READY-1787133625.png)

<figure>
  <img src="assets/Device_und_TMA_READY-1787133625.png" alt="Start Screen">
  <figcaption>Abbildung 1: Start Screen</figcaption>
</figure>
```

Mir geht es darum für images schlne captions amrkdown zu haben wenn sie gerendert werdne, diese 2 möglichkeiten beiten sich an neben der `@fig:startscreen` syntax.

Jetzt ist es aber so, dass ich mit images.nvimi in coop mit markdown.nvim hinbekommen habe, dass ich endlich in amrkdown dateien die images mvia hover usw.. direkt innvim anzeigen kann. Das verliere ich aebr, wenn ich html captions mache, denn der link darin wird icht als image link markdown aufgelst .
entweder binden wir das mit ein, dass auch diese html links aufelöst werdne können?=

## casedesk

### Solution(s)

hierzu äwre ein temlate gut, dass ich dann von einer ai ausfpllen lassen kann, wenn der case solved ist. kannst du das erstellen, mit keywords ausfüllen us.w... so das süäter die solutions files von einer ai zw ohne ai nur mit der heuritsik durcsucht werden können.
:Case solution bzw solve sold ann das gleich auch höandlen zum eingeben der solution
dazu braucht es ein workflow udn ein konzept. das ollte an auch in C:\users\StefanBartl\AppData\Local\nvim\docs\NOTES\casedesk  stehen...

### update der \nvim\docs

alle neune commands usw..
use cases ersellen, so dass ich suchen kann " ich will eine xy im case" -> dann so

### ai implemeniterung

endlich die ai implementierung angehen. claude code wäre ideal ich hbe einen pro account, aber ich weioß nicht, ob es damit überhauüt geht. gemini nehmen ich bisher üner die web ui das funkt auch ganz gut inhaltlich

## Misc

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

