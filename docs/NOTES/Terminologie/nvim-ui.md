# Glossar: Nvim-UI-Begriffe rund um Statusline/Winbar/Breadcrumb/Sticky-Context

Auslöser: Verwechslung zwischen dem **Winbar-Breadcrumb** (`lsp.nvim`, oben
rechts/links im Fenster, eine Zeile: `Ordner › Datei › Symbol`) und dem
**Sticky-Context-Overlay** (`ui.nvim`, `:UI sticky`, die Zeilen, die beim
Scrollen "hängen bleiben" — in Markdown z. B. die zuletzt gesehenen
Headlines). Beides sitzt optisch am oberen Fensterrand, sind aber zwei
getrennte Plugins/Module mit unterschiedlicher Technik (Statusline-String vs.
echtes Floating-Window). Position beider ist konfigurierbar, siehe
[UiSticky.md](../ExternPlugins/Bindings/Usercmds/UiSticky.md) für die
Sticky-Command-Referenz.

| Begriff | Was es ist | Implementiert in |
| --- | --- | --- |
| **`statusline`** | Die Zeile am unteren Rand eines *Fensters* (bzw. global, je nach `laststatus`). Zeigt üblichen Editor-Status: Modus, Datei, Git, Diagnostics, Cursor-Position. In Neovim: `vim.o.statusline` / `vim.wo.statusline`. | `ui.nvim/lua/ui/statusline/**` (Layout, Module, Highlights) |
| **`tabline`** | Die Zeile ganz oben im Editor (über allen Fenstern), zeigt normalerweise offene Tabs/Buffer. `vim.o.tabline`. In diesem Ökosystem: `ui.nvim`s Buffer-Chips (die "Tabs" mit Datei-Icon + "x"). | `ui.nvim/lua/ui/tabline/**` |
| **`winbar`** (die Neovim-Option) | Eine Zeile direkt **über** einem einzelnen Fenster (zwischen Tabline und Fenster-Inhalt), pro Fenster einstellbar. `vim.wo.winbar`. Seit Neovim 0.8. Zwei Dinge teilen sich diese eine Zeile in dieser Config: der Breadcrumb (unten) und `source_selector` (Neo-tree). | **Frame** (nur das `vim.wo.winbar = ...`-Schreiben, debounced/re-validiert): `ui.nvim/lua/ui/winbar/init.lua` (`M.set()`). **Content** (der eigentliche String): `lsp.nvim`, s. u. Ohne `ui.winbar` schreibt `lsp.nvim` direkt selbst — die Trennung ist optional, keine harte Abhängigkeit. |
| **`breadcrumb(s)`** | Kein Neovim-Fachbegriff, sondern ein UI-Muster: eine Pfad-/Symbol-Kette ("Ordner › Datei › Funktion"), **eine Zeile**, gebaut aus LSP-`documentSymbol`s (in Markdown: die Überschrift, in der der Cursor gerade steht, per `winbar.max_symbols = { markdown = 1 }` auf eine gekürzt). Zeigt "wo bin ich", nicht "was habe ich zuletzt gesehen". | `lsp.nvim/lua/lsp/core/winbar/init.lua` (Lifecycle, `:Lsp winbar …`), `.../render.lua` (baut den `'winbar'`-String: Chips oder flach, `align` = `left`\|`right`\|`center`), `.../kinds.lua` (Icon/Highlight je `SymbolKind`). Config: `require("lsp").setup({ winbar = {...} })` in [init.lua](../../../init.lua) (`startup.now("lsp", ...)`). |
| **`sticky context` / "die gepinnten ***"** | Ein **eigenständiges Floating-Window** pro Fenster (nicht die `winbar`-Option!), das die *umschließenden* Scopes über den ersten sichtbaren Zeilen fixiert, während der Rest weiterscrollt — in Markdown die Kette der Überschriften, in Code die `function`/`class`/`if`/`for` …-Zeilen, die man gerade "innerhalb" ist. Kann **mehrzeilig** sein (`max_lines`), anders als der einzeilige Breadcrumb. Kommt von Tree-sitter, nicht von LSP. Ersetzt seit 2026‑09‑19 `nvim-treesitter-context`. | `ui.nvim/lua/ui/context/init.lua` (Scope-Erkennung, Zeichnen, `:UI sticky …`), `.../state.lua` (Persistenz). Eingeschaltet über `require("ui").setup({ context = {...} })` (bzw. `sticky = {...}`, derselbe Schalter) in [ui_statusline/init.lua](../../../lua/config/ui_statusline/init.lua). Seit 2026‑09‑24 mit `position` (Anker `top`/`bottom`/`top-left`/`top-right`/`top-center`/`bottom-left`/`bottom-right`/`bottom-center`, plus exaktes `row`/`col`) und `style` (`mimic` = wie Pufferzeilen, Standard; `chips` = eine Zeile abgerundeter Chips wie der Winbar-Breadcrumb) konfigurierbar — s. `ui.nvim/docs/configuration.md`, Abschnitt Context. |
| **`winfixbuf`** | Fenster-Option (seit 0.10): sperrt ein Fenster auf seinen aktuellen Buffer — `:buffer`/`:edit`/`:next` etc. darin schlagen mit `E1513` fehl. Typisch für Sidebar-/Tree-Fenster. | Neovim-Core-Option, kein eigenes Plugin-Modul |
| **`source_selector`** | Neo-tree-spezifisch: die Tab-Leiste *oben in der Sidebar* zum Umschalten zwischen "Filesystem/Buffers/Git" — nicht dasselbe wie ein Breadcrumb, auch wenn es technisch ebenfalls über `winbar` läuft. | `neo-tree.nvim` selbst (`source_selector.winbar = true` in [neotree.lua](../../../lua/plugins/neotree.lua)) |
| **`document symbol`** | LSP-Konzept (`textDocument/documentSymbol`): die vom Sprachserver gemeldete Struktur einer Datei (Funktionen, Klassen, …), meist hierarchisch. Basis des Breadcrumbs (LSP) — **nicht** des Sticky-Context-Overlays (das ist Tree-sitter, braucht keinen laufenden LSP-Client). | `lsp.nvim/lua/lsp/core/symbols.lua` |
| **`SymbolKind`** | Der feste Enum-Wertebereich, den ein LSP-Server einem Symbol mitgibt (File, Class, Function, **String**, …) — 26 feste Werte, kein "Heading" darunter, daher melden Markdown-Server Überschriften oft als `String`. | `lsp.nvim/lua/lsp/core/winbar/kinds.lua` (`M.get()`, Sonderfall `String` + `filetype == "markdown"` → Heading-Icon) |
| **`kind icon` / "kind badge"** | Das kleine Icon/Glyph, das ein Plugin pro `SymbolKind` anzeigt (Symbol-Outline, Completion-Menü, Breadcrumb). Reine Konvention des jeweiligen Plugins, nicht Teil des LSP-Protokolls. | `lsp.nvim/lua/lsp/core/winbar/kinds.lua` |
| **`devicon`** | Datei-Icon nach Dateiendung (via `nvim-web-devicons`), unabhängig von LSP — das Icon vor Dateinamen in Tabs/Trees/Pickers. | extern (`nvim-web-devicons`), referenziert u. a. von `lsp.nvim/lua/lsp/core/winbar/render.lua` (Datei-Chip) |
| **`foldtext`** | Der Text, der eine eingeklappte (`fold`) Codezeile ersetzt — anderes Konzept, wird gern verwechselt, hat aber nichts mit Winbar/Breadcrumb/Sticky-Context zu tun. | Neovim-Core-Option |

## Breadcrumb vs. Sticky-Context — die eigentliche Verwechslung

|  | Breadcrumb (`lsp.nvim`) | Sticky-Context (`ui.nvim`) |
| --- | --- | --- |
| Zeilen | genau 1 | 1..`max_lines` (Standard 3), oder 1 bei `style = "chips"` |
| Datenquelle | LSP `documentSymbol` | Tree-sitter-Baum, kein LSP nötig |
| Technik | String in `vim.wo.winbar` | eigenes Floating-Window (`nvim_open_win`) über dem Fenster |
| Zeigt | Pfad + Symbol am **Cursor** | Scopes, die den **sichtbaren oberen Fensterrand** umschließen |
| Position (seit 2026‑09‑24) | `winbar.align`: `left`\|`right`\|`center` (nur horizontal, da an die eine `winbar`-Zeile gebunden) | `context.position.anchor`: `top`\|`bottom`\|`top-left`\|`top-right`\|`top-center`\|`bottom-left`\|`bottom-right`\|`bottom-center`, plus exaktes `row`/`col` |
| Ein-/Ausschalten | `:Lsp winbar [on\|off\|toggle]` | `:UI sticky [on\|off\|toggle]` |
