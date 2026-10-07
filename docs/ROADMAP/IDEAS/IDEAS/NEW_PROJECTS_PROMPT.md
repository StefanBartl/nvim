## Orte

| Was | Wo |
|---|---|
| Konzept (Quelle dieses Plans) | `nvim/docs/ROADMAP/IDEAS/ai.nvim.md` |
| Öffentliches Repo | `github.com/StefanBartl/ai.nvim` → `$REPOS_DIR/ai.nvim` |
| Privat (Roadmap/Notes, nicht fürs öffentliche Repo) | `$REPOS_DIR/WKDBooks\Development\wkdbook-myplugins\ai.nvim\{ROADMAP,NOTES}` |
| Diese Handover-Datei | `nvim/docs/ROADMAP/handovers/terminal.nvim.md` anlegen alss aymlionk aus den wkdbook |
| Regelwerk für neue Projekte | `$REPOS_DIR/WKDBooks\Development\wkdbook-Lua\Checklists\gates\NEW_PROJECT.md` (+ `PRINCIPLES.md`, `LUA_NVIM.md`) |

wir implementieren jetzt terminal.nvim - dazu musst du ein öffentlich gh repo stefanbartl/terminal.nvim anlegen und in $REPOS_DIR/ anlegen

Hier die konzept:
$NVIM_CONFIG_DIR/docs\ROADMAP\LONG_RUN\IDEAS\terminal.nvim.md

zu begin auch ein `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/terminal.nvim` anelgen - doirt komten roadmapm, notes und alles rein, was nicht in da slffentliche repo docs gehört

Außérdem von anfang an eine handover file führen, diese ausnahsmweiß0e nach $NVIM_CONFIG_DIR/docs\ROADMAP\handovers schreiebn

in `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/` gibt es eine ruleslist für neue projekte - lese dir bitte eram anfan an auch durch, damit wir sie einhalten. wir klnnen auch immer weider mit rules.nvim arbeiten, aein weteres meiner nivm polugin sdie die ruleslisten ach integfriert andausführen kann

Außerdem - wenn möglich - halte bitte auch die performance, security usw... rulesets darin ein. Das sind 400 regelen und mir ist klar das das nicht alles glech einhaltbalr ist, wir egehen dan wenns fertig ist mit rules.nvim sowieso drüber, aber um dann nicht alles umschreiebn zu müssen, wäresn vor allemdie architketur, struktur, usw... fragen wichtiig.

WICHITG: lib.nvim verwenden

hier bekommst du eine übersiucht üpber nützliche tools: $REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/lua-plugin-tools.md

- antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden
- Gib immer aus was du gerade machst / ob es interessante unde gab - damit ich Bescheuid weiß.
- Docs / README.md des Plugins updaten sofern es Sinn macht
- Keine Co-Authorenschaft von Claude in den Commits
- Wenn du mit etwas fertig bist committe / pushe / pulle so dass das uupdate sofort im main branch, sodass ich es gleich verwenden kann.
- code der implementiert wurde muss luacheck / stylua grün sein
- Die Installations-Specs meiner Pluigns findest du in: vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua
- Wenn nötig: Alle meine `.nvim` Plugins findest du unter `$REPOS_DIR\repos`
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/TOOL-PLACEMENT.md` (Tool bauen vs. Wegwerf-Skript, wohin damit) und `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/lua-plugin-tools.md`
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md` (keine großen/escapehaltigen Literale durch die Shell)

