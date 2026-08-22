# perf-tools

Messwerkzeuge für Startup- und Laufzeit-Blockaden. Hintergrund und Befunde:
[../PERF-Startup-Analyse.md](../PERF-Startup-Analyse.md).

Alle drei werden per `--cmd "luafile <pfad>"` **vor** der Config geladen,
laufen ~12 s mit, zeigen dann eine Notification und schreiben eine Logdatei
ins aktuelle Verzeichnis.

| Datei | Prinzip | Ausgabe |
|---|---|---|
| `stall.lua` | Timer misst seine eigene Verspätung | `stalls.log` |
| `lspprof.lua` | wrappt `vim.lsp.handlers` + `vim.diagnostic.set`, loggt `lsp.start` / `LspAttach` / `LspProgress` | `lspprof.log` |
| `luaprof.lua` | LuaJIT-Stack-Sampling alle 2 ms | `luaprof.log` |

## Wann welches

- **„Ruckelt es überhaupt, und wann?"** → `stall.lua`
- **„Hängt es am LSP, und an welchem Server?"** → `lspprof.lua`
- **„Welche Codezeile blockiert?"** → `luaprof.lua`

## Benutzung

```powershell
nvim --cmd "luafile C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/perf-tools/stall.lua" C:/Users/bartl/AppData/Local/nvim/init.lua
```

~12 s warten bis der Report erscheint, dann `:qa!`.

Isolierungen ohne Config-Änderung:

```powershell
# ohne LSP
nvim --cmd "lua vim.lsp.start=function() end; vim.lsp.enable=function() end" <datei>

# ohne ein Plugin
nvim --cmd "lua package.preload['gopath']=function() return {setup=function() end} end" <datei>

# einen LSP-Server aussparen (nur lspprof.lua)
nvim --cmd "lua vim.g.lspprof_skip='lua_ls'" --cmd "luafile .../lspprof.lua" <datei>

# lua_ls Library-Profil
$env:LUA_LS_PROFILE='minimal'; nvim ...
```

## Warum nicht die Standardwerkzeuge

- `nvim --startuptime` endet beim ersten Screen-Update. Blockaden danach —
  also alles, was VeryLazy, Timer oder LSP auslösen — sind unsichtbar.
- `:profile` erfasst nur Vimscript-/Lua-Funktionsaufrufe und ist blind für
  libuv-Callbacks, also für Dateisystem-Operationen und LSP-Verarbeitung.

## Fallstrick

Instrumentierung darf nicht `vim.defer_fn` benutzen, um sich zu installieren:
auf einem blockierten Loop kommt der Callback zu spät. Die erste Version von
`lspprof.lua` wrappte per `defer_fn(1200)` und lief real erst bei +4,57 s —
nach dem Stall, den sie erklären sollte. v2 wrappt sofort, bei jedem
`LspAttach` und per Wiederhol-Timer, idempotent.

Alle drei Werkzeuge sind gegen künstlich erzeugte Blockaden gegengetestet und
melden diese korrekt.
