# Tasks, die wrsch nur ich manuell erledigen kann

## (AN CLAUDE: NOCH NIHCT IMPLEMENTIEREN: EINFACH IGNORIEREN!)

- [ ] README.md mit viedeo demo oder gif ausstatten
- [ ] Was fehlt um ein gesamtes nvchad zu ersetzen?
- [ ] `:Recommender perf` durch alle Module durchlaufen lassen
  - Einzeln über jedes Plugin gehen und
      1. MyChecklists detailiert durchgehen
      2. Opus-Extra mit der Prompt
         1. analysiere das plugin auf performance optimierungen
         2. analysiere das plugin auf vollständige Dokumentation (`.md`-Files und Annotationen mit luals / emmylua tags großzügig verwenden - das kommt dann lib.nvim docmodule zu gute)
           1. docmudule implementieren
         3. analysiere das plugin auf security optimierungen
1. `leader wq`: Alle issues lösen
  1. dass was wq macht in einem `lib.nvim / lib.nvim.ui` ausgeben
2. `/wkdoptions`
  1. UI Linemarker gehört README
  2. `wkdoptions` mit `options.lua` verheiraten (vielleicht als default_options)
3. `nvim/init.lua` durchgehen und optimieren
4. [ ] Funktionen/Module identifizieren, die man mit FFI/C performanter machen könnte
  - nvim performance optimeren: startup modul, runtime analysis, docmap, usw...
- Alle claud ebranches in allen plugins entfernen
- [ ] `nvim/lua/autocmds` analysieren:
  - [ ] Refactoring?
    - [ ] `nvim/lua/autocmds` nach `nvim/lua/Bindings`
  - [ ] Welche automcds gehören in ein projet von  einen in C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\IDEAS?
- [ ] `lua/config/menu` nach `lua/wkdnvchad`?
5. `/autcmds`
  1. passt zu `/bindings` ?
  2. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt. (dispatch lib modul)

---

