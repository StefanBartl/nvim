# Vorgaben/Richtlinien/Guiding

## Allgemeines Verhalten

- Nie mehr als 1 Agent gleichzeitig starten; werden mehrere benötigt, nacheinander in mehreren Runden ausführen.
- Immer auf Deutsch antworten; im Quellcode (Code, Kommentare usw.) immer Englisch verwenden.
- Immer ausgeben, was gerade gemacht wird / ob es etwas Interessantes gab – damit ich Bescheid weiß.
- Wenn Chip-Tasks angelegt werden, diese bitte ebenfalls auf Deutsch verfassen.

## Git-Workflow

- Wenn eine Aufgabe fertig ist: sofort committen / pushen / pullen im main-Branch, sodass ich es gleich verwenden kann.
- Keine Co-Autorenschaft von Claude in den Commits.
- Am Ende jeder Ausgabe gibst du eine laufende Liste aller Commits des Chats aus mit kurzer Beschreibung + welches Repository. Jedes bekomtm einen grünen Haken, wenn das Commit durch einen `ultracode`-Agenten reviewd wurden - oder explizit durch mich wenn ich das reasoning auf ultracode gestellt habe. Ausgenommen sind Commits, die reine Dokumentationen upgedatet haben - diese bekommen einen grünen Haken auch ohne ultracode review.

## Code-Qualität

- Implementierter Code muss luacheck / stylua-grün sein.
- Neue Features ggf. im plugin-eigenen `/TESTS/`-Ordner testen.

## Dokumentation

- Docs / README.md aktualisieren, sofern es Sinn ergibt.
- Wird ein Binding aktualisiert, ggf. auch `vim.fn.stdpath('config') .. /docs/NOTES/BINDINGS` aktualisieren.
- Reports sowie Original-Handover-Files kommen nach `$NVIM_CONFIG_DIR/docs`; in den wkdbooks liegen dann nur Symlinks darauf.
- Feature-/Backlog-/Roadmap-Notizen (alles, was Endnutzer nicht betrifft) gehören nach `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/`.
- Die Plugin-Repo-Docs (README, Feature-Beschreibungen für Endnutzer usw.) bleiben für die echte Endnutzer-Dokumentation reserviert. Im Zweifelsfall nachfragen – es sind aber bereits genug Dateien vorhanden, um Ableitungen zu treffen.

## Pfade

- Installations-Specs meiner Plugins: `vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua`
- Alle `.nvim`-Plugins (falls nötig): `$REPOS_DIR/repos`

## Regeln

- Tool bauen vs. Wegwerf-Skript, Ablageort: `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/TOOL-PLACEMENT.md` und `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/lua-plugin-tools.md`
  - Wird im Zuge einer Task ein Tool gebaut, das für künftige User/Devs/Agents interessant sein könnte: an geeigneter Stelle im `TOOLS/`-Ordner sichern.
- Keine großen/escapehaltigen Literale durch die Shell schleusen: `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md`
- Performance-Optimierungen: `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/PERFORMANCE.md`
- Lua-Projekte für Neovim: `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/LUA_NVIM.md`
- `$REPOS_DIR/lib.nvim` verwenden, wo möglich und simnnvoll. Dies ist wichtig, um maintainance für mich zu ermöglichen.

---
