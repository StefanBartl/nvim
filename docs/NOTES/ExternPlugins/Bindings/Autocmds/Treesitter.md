# nvim-treesitter — Autocmds

Registriert im `config`-Block des `nvim-treesitter/nvim-treesitter`-Specs in
[lua/plugins/treesitter.lua](../../../../../lua/plugins/treesitter.lua) (modernes
`main`-Branch-Setup, keine deprecated `:TSInstall`/`configs`-API). Alle drei
sind **[custom]** — der moderne `nvim-treesitter`-Branch installiert selbst
keine Autocmds mehr, das Aktivieren von Highlight/Fold/Indent ist explizit
Aufgabe der Config (siehe Plugin-README, Abschnitt "Quickstart").

Alle drei Autocmds sind ungruppierte `FileType`-Autocmds (`lib.nvim.autocmd`,
kein eigener Augroup) und teilen sich dieselbe Guard-Bedingung
`guards.is_enabled(args.buf)` aus `lib.nvim.treesitter.guard`
(`lua/lib/nvim/treesitter/guard/init.lua` im `lib.nvim`-Repo, `E:\repos\lib.nvim`)
— ist der Buffer/Filetype über den Guard ausgeschlossen, greift keiner der drei.

| Event | Quelle | Zweck |
|---|---|---|
| `FileType` | treesitter.lua | `parser_policy.ensure(lang, {...})` (s.u.) dann `vim.treesitter.start(args.buf)` — aktiviert Treesitter-Highlighting für den Buffer. |
| `FileType` | treesitter.lua | Setzt `vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"` und `vim.wo.foldmethod = "expr"` — Treesitter-basiertes Folding. |
| `FileType` | treesitter.lua | Setzt `vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"` — experimentelle Treesitter-Indentation. |

## Parser-Install-Policy (2026-08-01)

Die "moderne" `nvim-treesitter`-API (s.o.) installiert von sich aus **nie**
einen Parser — nur die drei Autocmds oben aktivieren, was bereits auf der
Platte liegt. Ohne einen expliziten Installationsschritt degradiert ein
fehlender Parser stillschweigend zu "kein Highlighting", ohne jede
Fehlermeldung. Genau das ist passiert: `luadoc.so` fehlte, wodurch
`---@module`-Annotationen unhighlighted blieben (kein LSP-Problem — `lua_ls`
war korrekt attached, s. Konzept-Chat 2026-08-01).

Zwei unabhängige Mechanismen in `plugins/treesitter.lua`:

1. **Injection-Parser-Bootstrap** (unbedingt, bei jedem Start): `luadoc` und
   `vimdoc` sind nie der Filetype eines Buffers — sie tauchen nur über
   Treesitter-*Injections* auf (LuaCATS-Doc-Kommentare, `:help`-Syntax) und
   lösen daher nie das `FileType`-Event für sich selbst aus. Diese beiden
   werden deshalb bedingungslos beim Plugin-`config()` geprüft und bei Bedarf
   installiert (`INJECTION_PARSERS` in `plugins/treesitter.lua`).
2. **`lib.nvim.treesitter.parser_policy`** (im `FileType`-Autocmd): für
   normale Filetype-Parser (rust, go, …). Drei Modi, per `:TSParserPolicy`
   umschaltbar — s. [Usercmds/Treesitter.md](../Usercmds/Treesitter.md).
   Modul-Doku: `lua/lib/nvim/treesitter/parser_policy/README.md` im
   `lib.nvim`-Repo (`E:\repos\lib.nvim`), Vimdoc `:h lib.nvim-treesitter-parser_policy`.

## `lua/lsp/core/treesitter.lua` existiert nicht mehr

Frühere Fassungen dieser Doku verwiesen hier auf eine (angeblich tote,
`pcall`-abgesicherte) zweite Treesitter-Konfiguration in
`lua/lsp/core/treesitter.lua`. Stand 2026-08-01 existiert diese Datei nicht
mehr im Repo — vermutlich beim Aufräumen entfernt. `lua/lsp/init.lua` enthält
weiterhin einen `pcall(require, "lsp.core.treesitter")`-Aufruf, der seither
still ins Leere läuft (kein Fehler, kein Effekt — das ist der Zweck des
`pcall`). Die tatsächlich wirksame Aktivierung läuft ausschließlich über die
drei `FileType`-Autocmds oben.

## `nvim-treesitter-context`

Kein Autocmd, aber themengleich: [lua/plugins/treesitter.lua](../../../../../lua/plugins/treesitter.lua)
lädt `nvim-treesitter/nvim-treesitter-context` lazy on `BufReadPost` mit
`opts = { enable = true, max_lines = 3 }` — Sticky-Context-Fenster oben im
Buffer, keine eigenen Keymaps/Usercmds in dieser Config.

## `nvim-treesitter-textobjects`

Der Plugin-Spec (`lazy = false`) lädt `nvim-treesitter/nvim-treesitter-textobjects`,
aber es gibt in diesem Repo **keine** Konfiguration dafür (kein
`textobjects`-Block, keine `select_textobject`/`move`-Keymaps) — das Plugin ist
installiert, aber praktisch ungenutzt. Textobjects laufen stattdessen über
`echasnovski/mini.ai` und `wellle/targets.vim`
([lua/plugins/textobjects.lua](../../../../../lua/plugins/textobjects.lua)), die
funktional dieselbe Rolle übernehmen. Siehe dazu ggf. eine eigene
Mini.ai/Targets-Doku außerhalb dieses Bindings-Ordners.
