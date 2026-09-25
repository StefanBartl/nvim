# Nvim-Plugin (Lua)

## Konventionen

- Installations-Specs meiner Plugins:
  `$NVIM_CONFIG/lua/plugins/personal/init.lua`
- Alle eigenen `.nvim`-Plugin-Repos liegen unter `$REPOS_DIR/repos`.
- Code muss luacheck- und stylua-clean sein, bevor er als fertig gilt (wird
  zusätzlich per globalem Hook `check-hook.js` erzwungen).
- Neue Features nach Möglichkeit im plugin-eigenen `/TESTS/`-Ordner testen.
- Lua-Tools: `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/lua-plugin-tools.md`
- Performance: `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/PERFORMANCE.md`
- Lua-Projekte für Neovim: `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/LUA_NVIM.md`

## Bindings

- Wird ein Keybinding geändert/hinzugefügt, ggf.
  `$NVIM_CONFIG/docs/NOTES/BINDINGS` aktualisieren.
