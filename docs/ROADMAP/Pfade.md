# Pfade

## Dokumentation

- Wird ein Binding aktualisiert, ggf. auch `vim.fn.stdpath('config') .. /docs/NOTES/BINDINGS` aktualisieren.
- Reports sowie Original-Handover-Files kommen nach `$NVIM_CONFIG_DIR/docs`; in den wkdbooks liegen dann nur Symlinks darauf.
- Feature-/Backlog-/Roadmap-Notizen (alles, was Endnutzer nicht betrifft) gehören nach `$REPOS_DIR/tasks-vault/`.

## Pfade

- Installations-Specs meiner Plugins: `vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua`
- Alle `.nvim`-Plugins (falls nötig): `$REPOS_DIR/repos`

## Regeln

- Tool bauen vs. Wegwerf-Skript, Ablageort: `$REPOS_DIR/tasks-vault/TOOLS/TOOL-PLACEMENT.md` und `$REPOS_DIR/tasks-vault/TOOLS/lua-plugin-tools.md`
  - Wird im Zuge einer Task ein Tool gebaut, das für künftige User/Devs/Agents interessant sein könnte: an geeigneter Stelle im `TOOLS/`-Ordner sichern.
- Keine großen/escapehaltigen Literale durch die Shell schleusen: `$REPOS_DIR/tasks-vault/HEREDOC.md`
- Performance-Optimierungen: `$RULES_VAULT/rulesets/lua/regeln/PERFORMANCE.md`
- Lua-Projekte für Neovim: `$RULES_VAULT/rulesets/lua/regeln/LUA_NVIM.md`
- Ruleset Lua-Projekte: `$RULES_VAULT/rulesets/lua/regeln/LUA_NVIM.md`
- Ruleset für native Apps: `$RULES_VAULT/rulesets/native`
