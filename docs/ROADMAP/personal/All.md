# Alle Custom Plugins

1. Module und Plugins durchgehen und
  1. CHEATSHEETS schreiben
  2. Jedes repo soll auch eigene `/docs/BINDINGS.lua` haben mit allen keymaps, usrcmds aber auch die autocmds!
  3. Checklisten anwenden
  4. Funktionen/Module die man in der nvim config mit ffi c perfomranter machen könnte?
  5. Weitere features, usrcmds, keymaps, autocmds für jedes Plugin erstellen
    - `/nvim/lua/` alle Modle durchgehene nd checken, ob sie wo hineinpassen
  6. `README.md` überprüfen auf
        - badges & ASCII implementieren und toc
        - dir = vime.env... raus aus den READMEs
        - license
2. `README.md` && `/doc/**.txt` Spec anpasse:
        - entweder `lazy = false` oder `event = "VeryLazy",` im Insatallationsblock angeben: [spec](./spec.md)
3. `:checkhealth` sollten alle module haben -> check!
  8. Einen `/config` Folder mit `/config/DEFAULTS.lua` in jedem Module und Plugin wo es sinn macht
  9. `lib.nvim` auf alle plugins anwenden (als dependency)
  10. Sind alle Plugins `lazy`?
  11. In allen Modulen  `/bindings` und dort dann
    - `usrcmds`
    - `keymaps`
    - `autocmds`
    unterbringen.

1. `objtrack` - Analysieren (merge mit anderen Plugin? Ausbau notwendig?)
2. `monkeypatch` noch sinnvoll? besser ausbauen
3. `migrate.nvim` fertig stellen
4. `mdlink` vs `mdlinks`? Migration nach `markdown.nvim`
5. `config.lua` für pluginseitige defaults, aber möglichst viele Features sollen vom user aus ebenfalls einstellbar sein, also zb.:

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

1. `sessions.nvim`

---

## Finish

1. Wenn fertig: alles auf remote stellen statt lokal
2. Alle Plugins auf .nvim umstellen
3. Alle `.nvim` plugins eine `.vim` version erstellen (bzw.: wie würde das aussehen, wenn man das im gleichen Plugin macht? Vorteil wäre, dass man wrsch einige funktionen teilen könnte)
4. Alle Plugins auf implementierte NVIM-Filetree-Features checken, diese
      - jedenfalls so ausbauen, dass es in Neotree, NvimTree, Netrw...
      - aus den gesammelten Features und aus `/(nvim/lua/config/neotree` ein eigenes Plugin `neotee-features.nvim` erstellen

### 5. Alle features testen Verifikation für jedes feature jedes plugins

**Beispiel:**
- **A**: `:Debug module reload` auf einer Lua-Datei → Modul wird neu geladen; `:checkhealth debugging` grün
- **B**: `:ProjectInsight archive` → Archiv in `~/temp/`; auf Windows mit PowerShell; `:checkhealth project-insight` grün
- **C**: `:Open` auf URL → Browser öffnet; auf Datei → Explorer/Finder; `:checkhealth open_nvim` grün
- **D**: `:Format trim`, `:Format sort`, `:Format column 40` auf Testbuffer; `:checkhealth buffer_ctx` grün
- **E**: `:Format markdown headline_separators` (falls API-Redirect) oder komplett gestrichen; markdown.nvim-Test
- **F**: require-Pfad in Config testen, `MarkLineToggle` + `MarkLinesYank` funktionieren
- **G**: `:Pickers notes files` → Picker öffnet; `NotesFiles` als Compat-Command; prefix-Collection listet Unterordner; `:checkhealth pickers` grün; alle alten `:Nvim*Files`-Commands funktionieren als Compat-Aliases

---
