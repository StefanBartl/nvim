# Alle Custom Plugins

auch in docs/list container/cmdlog


## Checklist

2. Module und Plugins durchgehen und
  1. Funktionen/Module die man in der nvim config mit ffi c perfomranter machen könnte?
  2. Weitere features, usrcmds, keymaps, autocmds für jedes Plugin erstellen
    - `/nvim/lua/` alle Modle durchgehene nd checken, ob sie wo hineinpassen
  3. `README.md` überprüfen auf
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
  2. `lib.nvim` auf alle plugins anwenden (als dependency)
    1. Personal Plugins auf `utils`-Folder durchsuchen -> Eventuell Funktionen für die lib dabei?
    2. `Insights stats lib` ausführen über alle repos und eine gesammelte übersicht erstellen
  3. Sind alle Plugins `lazy`?
  4. In allen Modulen  `/bindings` und dort dann
    - `usrcmds`
    - `keymaps`
    - `autocmds`
    unterbringen.

  - alle keymaps müssen
    - vom user einfach modifizeierbar / deaktiviert werden können
    - eine which-key implementierung haben

  1. Wenn es sin macht, hier `docs/TESTS/**` dateien durchfürhen und die ergebnise amit in checkhealth ausgebe. wenn das nicht state of the art ist, dann lassen wir das so-
6. Alle Plugins sollen **Cross-Plattform** sein
7. `DEFAULTS.lua` -> expliziote Datei für Defaults vonm UserConfigurations, also: `/config/init.lua` && `/config/DEFAULTS.lua`
8. `mygrep.nvim` - was machen wir mit demn? Implemeniteren in `pickers.nvim`
9. `migrate.nvim` fertig stellen
10. `mdlink` vs `mdlinks`? Migration nach `markdown.nvim`
11. `config/init.lua` `config/DEFAULTS.lua` für pluginseitige defaults, aber möglichst viele Features sollen vom user aus ebenfalls einstellbar sein, also zb.:

    ```lua
    {
      -- "StefanBartl/insights.nvim",
      dir = vim.env.REPOS_DIR .. "/insights.nvim",
      event = "VeryLazy",
      cmd = "Insights",
      config = function()
        require("insights").setup({
          -- symbols.use_treesitter_for_lua = true,  -- optionale TS-Variante für Lua
          compress = {
              outdir = "C:\temp",
              ---@type Insights.CompressEngine
              engine = "tar",
          },
        })
      end,
    },
    ```

Hier kann man die keys **Output dir** und **Compress Engine** als User explizit setzen und damit die `config.lua` Pluginseitige Defaults überschreiben.

Dazu ist noch eines wichtig: Um dem User ein sehr gutes LSP Erlebnis zu bieten, braucht jeder Key einen Typen, wie zb.:
`--@alias Insights.CompressEngine "auto"|"tar"|"zip"|"powershell"`

Jedes Plugin muss abgeklopft werden, ob es sinnvolle Optionen gibt, die noch nicht User-seitig gesetzt werden können.

13. alles commitet und branche auf main umstellen

---

