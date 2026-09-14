# Glossar: Nvim-UI-Begriffe rund um Statusline/Winbar/Breadcrumb

| Begriff | Was es ist |
| --- | --- |
| **`statusline`** | Die Zeile am unteren Rand eines *Fensters* (bzw. global, je nach `laststatus`). Zeigt üblichen Editor-Status: Modus, Datei, Git, Diagnostics, Cursor-Position. In Neovim: `vim.o.statusline` / `vim.wo.statusline`. |
| **`tabline`** | Die Zeile ganz oben im Editor (über allen Fenstern), zeigt normalerweise offene Tabs/Buffer. `vim.o.tabline`. In diesem Ökosystem: `ui.nvim`s Buffer-Chips (die "Tabs" mit Datei-Icon + "x"). |
| **`winbar`** | Eine Zeile direkt **über** einem einzelnen Fenster (zwischen Tabline und Fenster-Inhalt), pro Fenster einstellbar. `vim.wo.winbar`. Der Ort für **Breadcrumbs**. Seit Neovim 0.8. |
| **`breadcrumb(s)`** | Kein Neovim-Fachbegriff, sondern ein UI-Muster: eine Pfad-/Kontext-Kette ("Ordner › Datei › Funktion"), meist im Winbar gezeigt. Zeigt "wo bin ich" hierarchisch. |
| **`winfixbuf`** | Fenster-Option (seit 0.10): sperrt ein Fenster auf seinen aktuellen Buffer — `:buffer`/`:edit`/`:next` etc. darin schlagen mit `E1513` fehl. Typisch für Sidebar-/Tree-Fenster. |
| **`source_selector`** | Neo-tree-spezifisch: die Tab-Leiste *oben in der Sidebar* zum Umschalten zwischen "Filesystem/Buffers/Git" — nicht dasselbe wie ein Breadcrumb, auch wenn es technisch ebenfalls über `winbar` läuft. |
| **`document symbol`** | LSP-Konzept (`textDocument/documentSymbol`): die vom Sprachserver gemeldete Struktur einer Datei (Funktionen, Klassen, …), meist hierarchisch. Basis fast jedes Breadcrumbs/Outline-Features. |
| **`SymbolKind`** | Der feste Enum-Wertebereich, den ein LSP-Server einem Symbol mitgibt (File, Class, Function, **String**, …) — 26 feste Werte, kein "Heading" darunter, daher melden Markdown-Server Überschriften oft als `String`. |
| **`kind icon` / "kind badge"** | Das kleine Icon/Glyph, das ein Plugin pro `SymbolKind` anzeigt (Symbol-Outline, Completion-Menü, Breadcrumb). Reine Konvention des jeweiligen Plugins, nicht Teil des LSP-Protokolls. |
| **`devicon`** | Datei-Icon nach Dateiendung (via `nvim-web-devicons`), unabhängig von LSP — das Icon vor Dateinamen in Tabs/Trees/Pickers. |
| **`foldtext`** | Der Text, der eine eingeklappte (`fold`) Codezeile ersetzt — anderes Konzept, wird gern verwechselt, hat aber nichts mit Winbar/Breadcrumb zu tun. |
