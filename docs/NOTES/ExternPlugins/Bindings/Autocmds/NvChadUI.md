# nvchad/ui — Autocmds

`nvchad/ui` ist die NvChad-Basis (Statusline, Tabufline, Themes, Base46). Ihre
eigenen Autocmds stammen aus `lua/nvchad/au.lua` im Plugin-Repo, werden aber in
dieser Config **überschrieben**: der Runtimepath dieser Nvim-Config legt
[lua/nvchad/au.lua](../../../../../lua/nvchad/au.lua) vor das gleichnamige
Modul im Lazy-Plugin (`.../lazy/ui/lua/nvchad/au.lua`), d. h. `require("nvchad.au")`
lädt immer die lokale, eigene Version. Damit sind alle folgenden Autocmds
formal **[default]** (gleiches Feature-Set wie Upstream), aber mit einer
**[custom]** Performance-Optimierung an einer Stelle (siehe unten).

| Gruppe | Event(s) | Quelle | Zweck |
|---|---|---|---|
| — (kein Autocmd, direkter Check beim Laden) | — | au.lua | Öffnet `nvchad.nvdash` beim Start, wenn `config.nvdash.load_on_startup` gesetzt ist und der aktuelle Buffer leer/ein Verzeichnis und unmodifiziert ist. |
| — | `LspAttach` | au.lua | Signature-Help-Setup via `nvchad.lsp.signature`, sofern der Server `signatureHelpProvider.triggerCharacters` meldet. Nur aktiv wenn `config.lsp.signature` (aus `nvconfig`) gesetzt ist. |
| `ReloadNvChad` | `BufWritePost` | au.lua | Reload des gespeicherten Lua-Moduls dieser Config beim Schreiben (`require("nvchad.utils").reload(module)`). |
| — (kein Autocmd) | — | au.lua | `:MasonInstallAll`-Usercmd — siehe [Usercmds/NvChadUI.md](../Usercmds/NvChadUI.md). |

## [custom] Performance-Fix am `ReloadNvChad`-Autocmd

Die Upstream-Variante baut das `pattern` des `BufWritePost`-Autocmds **eager**
beim Start: `vim.fn.glob(stdpath("config") .. "/lua/**/*.lua", ...)` plus
`vim.uv.fs_realpath` pro Treffer — in dieser Config ca. 450 Dateien, ca. 450
synchrone Syscalls, gemessen ca. 600 ms zusätzliche Startupzeit
(`nvim --startuptime`), unabhängig davon ob überhaupt je gespeichert wird.

Die lokale Version in [lua/nvchad/au.lua](../../../../../lua/nvchad/au.lua)
ersetzt das durch ein einfaches `pattern = "*.lua"` plus einen Callback-Filter,
der den absoluten Pfad erst beim tatsächlichen Save gegen
`stdpath("config")/lua/` prüft (`abs:sub(1, #config_lua_dir) ~= config_lua_dir`
→ früher Return). Funktional identisch (Reload bei jedem Save einer Config-
Lua-Datei), aber ohne den Startup-Glob.

## Weitere au.lua-Effekte (kein Autocmd im engeren Sinn)

- `config.colorify.enabled` → `require("nvchad.colorify").run()` beim Laden.
- Einmaliger Hinweis-Screen (`nvchad.winmes`) beim allerersten Start nach
  Update, Marker-Datei `stdpath("data")/nvnotify1`.

## Sonstige Autocmds im `wkdnvchad`-Layer

Kein weiterer Autocmd-Hookup außerhalb von `au.lua` gefunden — Themes/Mappings/
Usercmds in [lua/wkdnvchad/](../../../../../lua/wkdnvchad) sind reine Setup-
Aufrufe (`wkdnvchad.setup({ all = true })` aus
[lua/chadrc.lua](../../../../../lua/chadrc.lua)), keine eigenen `FileType`/
`BufWritePost`-o.ä.-Hooks.
