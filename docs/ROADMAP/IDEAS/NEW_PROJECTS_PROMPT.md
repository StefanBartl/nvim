## Orte

| Was | Wo |
|---|---|
| Konzept (Quelle dieses Plans) | `nvim/docs/ROADMAP/IDEAS/ai.nvim.md` |
| Öffentliches Repo | `github.com/StefanBartl/ai.nvim` → `E:\repos\ai.nvim` |
| Privat (Roadmap/Notes, nicht fürs öffentliche Repo) | `E:\repos\WKDBooks\Development\wkdbook-myplugins\ai.nvim\{ROADMAP,NOTES}` |
| Diese Handover-Datei | `nvim/docs/ROADMAP/handovers/ai.nvim.md` |
| Transport-Erweiterung | `E:\repos\lib.nvim\lua\lib\nvim\net\curl` |
| loomAI (nativ, Referenz für späteren Provider) | `E:\repos\loomAI` |
| Regelwerk für neue Projekte | `E:\repos\WKDBooks\Development\wkdbook-Lua\Checklists\gates\NEW_PROJECT.md` (+ `PRINCIPLES.md`, `LUA_NVIM.md`) |





wir implementieren jetzt __.nvim - fdazu musst du ein lffentlich gh repo stefanbartl/__.nvim anlegen und in E:\repos\ anlegen

Hier die konzept:
C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/IDEAS/__.nvim.md

zu begin auch ein `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/__.nvim` anelgen - doirt komten roadmapm, notes und alles rein, was nicht in da slffentliche repo docs gehört

Außérdem von anfang an eine handover file führen, diese ausnahsmweiß0e nach C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\handovers schreiebn

in `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/` gibt es eine ruleslist für neue projekte - lese dir bitte eram anfan an auch durch, damit wir sie einhalten. wir klnnen auch immer weider mit rules.nvim arbeiten, aein weteres meiner nivm polugin sdie die ruleslisten ach integfriert andausführen kann

hier bekommst du eine übersiucht üpber nützliche tools: E:/repos/WKDBooks/Development/wkdbook-myplugins/TOOLS/lua-plugin-tools.md

du wirst auf mein naties pluginm loomai stoßen, hier wäöre es git. wenn du in die roamdap fr diese plugin gleich mit eiin den iomplementierunplan einbaust, wann wo welches feature implementiert sein muss, jedoch sollte es auch imer ein fallvbakck geben ohne looma i

- never start more than 1 agents simultaneously; if more are needed, run multiple rounds of up to 1 agents each
- antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden
- Die Installations-Specs meiner Pluigns findest du in: vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua
- Wenn nötig: Alle meine `.nvim` Plugins findest du unter `$REPOS_DIR\repos`
- Gib immer aus was du gerade machst / ob es interessante unde gab - damit ich Bescheuid weiß.
- Docs / README.md des Plugins updaten sofern es Sinn macht
- Keine Co-Authorenschaft von Claude in den Commits
- Wenn du mit etwas fertig bist committe / pushe / pulle so dass das uupdate sofort im main branch, sodass ich es gleich verwenden kann.
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/TOOL-PLACEMENT.md` (Tool bauen vs. Wegwerf-Skript, wohin damit) und `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/lua-plugin-tools.md`
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md` (keine großen/escapehaltigen Literale durch die Shell)
- code der implementiert wurde muss luacheck / stylua grün sein


Erste.lle als erstes einen implemntierungpülan , oit den ganzen infs heir, und schreibe in in die handover file, dann starten wir weg
