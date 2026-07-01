# Alle Custom Plugins

TODO:
- Spellchecking nochmnal durchgehen und notizen machen. Spell Strategie ausarbeiten - entweder Plugin einbindne oder Modul debuggen

1. `ROADMAP.md` durchgehen und Plan zur Implementierungen erstellen
2. Module und Plugins durchgehen und
  1. CHEATSHEETS schreiben
  2. Jedes repo soll auch eigene `/docs/BINDINGS.lua` haben mit allen keymaps, usrcmds aber auch die autocmds!
  3. Checklisten anwenden
  4. Funktionen/Module die man in der nvim config mit ffi c perfomranter machen könnte?
  5. Weitere features, usrcmds, keymaps, autocmds für jedes Plugin erstellen
    - `/nvim/lua/` alle Modle durchgehene nd checken, ob sie wo hineinpassen
  6. `README.md` überprüfen auf
        - badges & ASCII implementieren und toc
        - ist sie auf englisch? GIbt es eine Deutsche Version?
3. `README.md` && `/doc/**.txt` Spec anpasse:
    - für verschiedene nvim Package-Manager ist die installationsweiße interressant, wie zb.; hier [Installations Spec Template](./spec.md)
    - entweder `lazy = false` oder `event = "VeryLazy",` im Insatallationsblock angeben: [spec](./spec.md)
    - dir = vime.env... raus aus den READMEs - das kann jeder Dev sich selbst denken
    - license
4. Wenn sinnvoll, dann `docs/TESTS/**` testdateien für die Features schreiben
5. `:checkhealth` sollten alle module haben -> check!
  1. Einen `/config` Folder mit `/config/DEFAULTS.lua` in jedem Module und Plugin wo es sinn macht
  2. `lib.nvim` auf alle plugins anwenden (als dependency) und `ProjectInsight stats lib` ausführen über alle srepos und eine gesammelte übersicht erstellen
  3. Sind alle Plugins `lazy`?
  4. In allen Modulen  `/bindings` und dort dann
    - `usrcmds`
    - `keymaps`
    - `autocmds`
    unterbringen.
  1. Wenn es sin macht, hier `docs/TESTS/**` dateien durchfürhen und die ergebnise amit in checkhealth ausgebe. wenn das nicht state of the art ist, dann lassen wir das so-
1. Alle Plugins sollen **Cross-Plattform** sein
2. `DEFAULTS.lua` -> expliziote Datei für Defaults vonm UserConfigurations, also: `/config/init.lua` && `/config/DEFAULTS.lua`
5. `mygrep.nvim` - was machen wir mit demn? Implemeniteren in `pickers.nvim`
6. `migrate.nvim` fertig stellen
7. `mdlink` vs `mdlinks`? Migration nach `markdown.nvim`
8. `config.lua` für pluginseitige defaults, aber möglichst viele Features sollen vom user aus ebenfalls einstellbar sein, also zb.:

    ```lua
    {
      -- "StefanBartl/project-insight.nvim",
      dir = vim.env.REPOS_DIR .. "/project-insight.nvim",
      event = "VeryLazy",
      cmd = "ProjectInsight",
      config = function()
        require("project_insight").setup({
          -- symbols.use_treesitter_for_lua = true,  -- optionale TS-Variante für Lua
          compress = {
              outdir = "C:\temp",
              ---@type ProjectInsight.CompressEngine
              engine = "tar",
          },
        })
      end,
    },
    ```

Hier kann man die keys **Output dir** und **Compress Engine** als User explizit setzen und damit die `config.lua` Pluginseitige Defaults überschreiben.

Dazu ist noch eines wichtig: Um dem User ein sehr gutes LSP Erlebnis zu bieten, braucht jeder Key einen Typen, wie zb.:
`--@alias ProjectInsight.CompressEngine "auto"|"tar"|"zip"|"powershell"`

Jedes Plugin muss abgeklopft werden, ob es sinnvolle Optionen gibt, die noch nicht User-seitig gesetzt werden können.

---

## Finish

1. Alle Plugins auf .nvim als Namesendung umstellen (wenn möglich)
2. Für alle `.nvim` plugins eine `.vim` version erstellen bzw.: wie würde das aussehen, wenn man das im gleichen Plugin macht? Vorteil wäre, dass man wrsch einige funktionen teilen könnte. andererseits sollen die Repos so klein wie möglich sein, daher wäre unnötiger Lua code in einem .vim plugin unnötig.
3. Alle Plugins auf implementierte NVIM-Filetree-Features (Neotree, Nvimtree, Netrw...)  checken, diese
      - jedenfalls so ausbauen, dass es in Neotree, NvimTree, Netrw... cross filetree agnostisch funkltienrt oder zumindest so agnostisch wie es geht, eventuell api ? die man dann bei seinem filrtee manager verweden kann.
      - aus den gesammelten Features und aus `/nvim/lua/config/neotree` ein eigenes Plugin `filetree.nvim` erstellen. Diess Plugin soll erkennen, welchen filetree amnager man verwendet (nvimtree, neotree, netrw usw..) und dort dann automatisch seine features andocken können
4. `:Recommender` durch alle Module durchlaufen lassen
5. Auf github.com:
  1. Kurzinfo für jedes Repo schreiben
  2. Keywords für jedes repo eingeben
  3. usw...
6. `vimdoc` von allen PLugins in `:h ***` auffindbar?
7. `.luarc.json` in jedem root

## Alle features testen Verifikation für jedes feature jedes plugins

**Beispiel:**
- **A**: `:Debug module reload` auf einer Lua-Datei → Modul wird neu geladen; `:checkhealth debugging` grün
- **B**: `:ProjectInsight archive` → Archiv in `~/temp/`; auf Windows mit PowerShell; `:checkhealth project-insight` grün
- **C**: `:Open` auf URL → Browser öffnet; auf Datei → Explorer/Finder; `:checkhealth open_nvim` grün
- **D**: `:Format trim`, `:Format sort`, `:Format column 40` auf Testbuffer; `:checkhealth buffer_ctx` grün
- **E**: `:Format markdown headline_separators` (falls API-Redirect) oder komplett gestrichen; markdown.nvim-Test
- **F**: require-Pfad in Config testen, `MarkLineToggle` + `MarkLinesYank` funktionieren
- **G**: `:Pickers notes files` → Picker öffnet; `NotesFiles` als Compat-Command; prefix-Collection listet Unterordner; `:checkhealth pickers` grün; alle alten `:Nvim*Files`-Commands funktionieren als Compat-Aliases

---
