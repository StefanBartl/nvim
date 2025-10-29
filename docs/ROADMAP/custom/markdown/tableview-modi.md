
## Übersicht: Anzeige-Modi für TableView und Zielsetzung

Ziel: mehrere Darstellungsmodi unterstützen, priorisiert nach Praktikabilität, Wartbarkeit und UX. Für jeden Modus kurz Bewertung (Machbarkeit, Vor-/Nachteile, Abhängigkeiten) und Empfehlung, wie er in das TableView-Plugin integriert werden kann.

---

## Modus 1 — Browser-Preview (z. B. MarkdownPreview oder eigener HTML-Temporär-Renderer)

Beschreibung: Tabelle als Markdown → HTML rendern und im System-Browser oder in einem Browser-Preview-Plugin anzeigen.

Vorteile:

* Vollständig gerendertes Ergebnis (wie auf GitHub / in MarkdownPreview).
* Keine aufwändige Integration in Neovim-UI nötig.
* Unterstützt komplexe Markdown-Features (HTML/CSS, Images).

Nachteile:

* Abhängigkeit zu externem Tool/Plugin (z. B. `markdown-preview.nvim` oder eigener HTML-Generator + `xdg-open`).
* Wechsel in externen Browser; kein direktes Copy/Paste in-editor (außer man implementiert Rückkopplung).
* Latenz beim Erzeugen/Öffnen temporärer Dateien.

Machbarkeit: sehr hoch — einfache Implementierung als MVP (generate temp HTML, open). Wenn `markdown-preview.nvim` vorhanden, kann es delegiert werden.

Integrationsempfehlung:

* Implementieren als Option `prefer_browser = true`.
* API: `render_html_and_open(table_struct)` → schreibt temporäre HTML + `xdg-open/open/start`.
* Optional: detect and prefer installed preview plugin and use its API if available.

---

## Modus 2 — Gerendert in Neovim mit externem Tool (z. B. headless renderer → HTML → DOM → render als text/virt text)

Beschreibung: Externes Tool (z. B. Pandoc, cmark, markown-it CLI) verwendet, Ergebnis in HTML; anschließende Darstellung im Float mit simplen HTML→ANSI/Text-Renderer oder via terminal-emulator-API.

Vorteile:

* Besseres Rendering als reiner Text (z. B. Markdown-features).
* Bleibt in Neovim (Float) — keine Browserkontextwechsel.

Nachteile:

* Sehr aufwändig: braucht zuverlässigen HTML→TTY/Text-Renderer oder eingebetteten Terminal/Browser in Float.
* Terminal-Rendering von HTML ist limitiert (keine echtes CSS/Layout).
* Komplexe Abhängigkeiten; unterschiedliche Ergebnisse auf verschiedenen Systemen.

Machbarkeit: mittel bis schwer. Sinnvoll nur, wenn man bereits eine Terminal-HTML-Renderer-Bibliothek nutzen will oder Terminal-Webview (z. B. mit `w3m`/`lynx`) akzeptabel ist.

Integrationsempfehlung:

* Erst als optionaler Erweiterung (Phase 2). Nur anbieten, wenn User explizit externe Toolchain installiert hat.
* Fallback: Browser-Preview (Modus 1) oder Text-Float.

---

## Modus 3 — Tabelle als gerendertes Image und Anzeige im Buffer

Beschreibung: Markdown → HTML/CSS → rendern als PNG/SVG (Headless browser / wkhtmltoimage / Puppeteer) → Bild in Float (externen Bildviewer) oder inline-Image-Preview-Plugin anzeigen.

Vorteile:

* Pixel-perfect Darstellung, exakt wie Browser.
* Keine CSS/HTML-Parsing-Probleme im Editor.

Nachteile:

* Stark statisch; schwierige Aktualisierung bei Edit; hoher Overhead.
* Benötigt headless browser toolchain (Puppeteer/Chromium) — schwergewichtig.
* Darstellung im Neovim-Buffer erfordert zusätzliche Plugins (z. B. `ueberzug`/`w3mimgdisplay` oder Neovim Image APIs), sehr plattformabhängig.

Machbarkeit: technisch möglich, aber für diesen Use-Case überdimensioniert. Nicht empfohlen als Standard-Modus.

Integrationsempfehlung:

* Nur als experimentelle Option für Nutzer, die Pixel-perfect brauchen; dokumentieren starke Abhängigkeiten.

---

## Modus 4 — Render-Textbuffer mit Syntax- bzw. Markdown-Beautification (z. B. render-markdown.nvim)

Beschreibung: Tabelle in einem separaten Float-Buffer anzeigen; Inhalt ist gerendertes Markdown (textuell), aber mit Syntax-Highlights / Farben durch vorhandene Plugins (z. B. render-markdown.nvim).

Vorteile:

* Leichtgewichtig, bleibt in Neovim.
* Nutzt vorhandene Highlighting-Plugins für bessere Lesbarkeit.
* Einfach zu implementieren; kann HTML-Rendering via plugin intern anbieten.

Nachteile:

* Rendering-Qualität hängt vom Dritt-Plugin ab.
* Kein vollwertiges HTML/CSS-Rendering, aber optisch deutlich besser als plain text.

Machbarkeit: hoch. Empfohlen als zweitbeste Option, wenn Browser nicht erwünscht.

Integrationsempfehlung:

* Detect optional plugin (`render-markdown.nvim`) und benutzen, sonst Fallback auf Text-Renderer.
* API: `open_float_with_markdown_render(table_markdown)`.

---

## Modus 5 — Normaler Textbuffer mit Highlightgruppen + Alignment (monospaced, aligned)

Beschreibung: Konvertiere Tabelle in ASCII/Unicode-Box oder aligned pipe-table, zeige in Float mit passenden highlight-Gruppen (Header, Separator, numbers, links).

Vorteile:

* Komplett in Neovim implementierbar; keine externen Abhängigkeiten.
* Sehr interaktiv: Scrollbar, copy, ggf. editing & roundtrip möglich.
* Geringer Implementationsaufwand im Vergleich zu HTML-Rendering.

Nachteile:

* Kein visuelles HTML-Styling; Limitierung auf monospace Darstellung.
* Manche komplexe Markdown-Zellen (embedded HTML) nicht perfekt darstellbar.

Machbarkeit: sehr hoch. Empfohlen als default MVP-Modus.

Integrationsempfehlung:

* Implementiere `render_as_text(table_struct, { use_box_chars = true/false })`.
* Verwende extmarks/hl groups für Kopfzeile und Separator.
* Binde Keymaps für Copy/Close/Scroll.

---

## Modus 6 — Reiner Textbuffer, aber korrekt aligned (normalize + align in-place)

Beschreibung: Schreibe die formatierte Tabelle zurück in einen temporären buffer (oder optional zurück in Dokument) als aligned Markdown (same syntax but padded), kein Float-Renderer.

Vorteile:

* Sehr einfach; arbeitet auf dem Dokument selbst.
* Ermöglicht Edit/Save im Dokument direkt.
* Nützlich, wenn Anwender Tabellen dauerhaft neu formatieren wollen.

Nachteile:

* Verändert (oder erzeugt) Text im Dokument — nicht nur Anzeige.
* Kein visuelles Rendering wie Browser.

Machbarkeit: sehr hoch. Gut als zusätzliche Feature: "format table" / "align table".

Integrationsempfehlung:

* Implementiere `format_table_in_buffer(start,end)` und `:TableFormat` UserCommand.
* Biete Option, ob Änderung in-place oder in scratch buffer erfolgen soll.

---

## Priorisierung & Empfehlung für MVP und Weiterentwicklung

Empfohlene Reihenfolge für Implementations-Phasen:

* Phase 1 (MVP)

  1. Modus 5 (Text-Float, aligned, highlights) — schnelle, robuste Basis.
  2. Modus 6 (in-place alignment/format) — nützliches Editor-Feature.
  3. UI: `:TableViewToggle`, `:TableViewSelect`, buffer-local keymaps, FileType autocommands.

* Phase 2 (optional / Erweiterung)

  1. Modus 1 (Browser-Preview) — HTML export + open, einfache User-Option.
  2. Modus 4 (render-markdown.nvim integration) — opt. bessere Optik.
  3. Erweiterte Float-Interaktion (sort, filter, copy row, edit & roundtrip).

* Phase 3 (experimentell)

  1. Modus 2 (in-Neovim gerendertes HTML via Terminal-Renderer) — nur falls Bedarf und Toolchain.
  2. Modus 3 (Image render) — nur als experimentelle Sonderfunktion.

Begründung: Modus 5/6 liefert hohen Nutzen bei geringem Aufwand; Browser-Preview als ergänzende Option gibt beste optische Darstellung ohne Neovim-UI-Komplexität.

---

## Abhängigkeiten, Risiken und Empfehlungen

Abhängigkeiten (optional):

* `markdown-preview.nvim` oder lokales `cmark`/`pandoc` für HTML-Export (Modus 1/2).
* `render-markdown.nvim` für bessere in-editor-Renderings (Modus 4).
* Keinerlei Abhängigkeit für Modus 5/6 — nur Neovim API nötig.

Risiken:

* HTML/Browser-Optionen bringen heterogene UX (Plattform-abhängigkeiten).
* Editing-Roundtrip (Float → Buffer) erfordert Care für Koordinaten & Mappings.
* Große Tabellen: Performance & Layout (Spaltenbreiten, Zeilenumbruch) beachten.

Sicherheits-/Performance-Hinweise:

* Beim Export in temp-HTML keine ungeprüften Inhalte automatisch öffnen (XSS-ähnliche Risiken nicht relevant lokal, aber Vorsicht bei remote content).
* Debounce Cursor-Auto-Open (z. B. 100–300ms) damit Floats nicht bei jedem CursorMove aufpoppen.
* Für große Dateien: limitierte Anzahl sichtbarer Spalten / max_col_width config.

---

## API-Design-Vorschlag (öffentliche Funktionen)

* `tableview.setup(opts)` — konfiguriert plugin; registers FileType autocmds.
* `tableview.toggle_at_cursor()` — toggle float for table at cursor.
* `tableview.select_and_show()` — collects all tables, let user pick, show chosen.
* `tableview.show_table(table_struct, opts)` — programmatic render.
* `tableview.format_table_in_place(start_row, end_row)` — align/format in buffer.
* `tableview.get_all_tables(bufnr)` — return list of parsed tables (for other plugins).

Konfigurationsbeispiel:

```lua
require("custom.markdown.tableview").setup({
  prefer_browser = false,
  auto_on_cursor = false,
  float = { width = 0.8, height = 0.4, border = "rounded", anchor = "cursor" },
  use_box_chars = false,
  max_col_width = 80,
  debounce_ms = 200,
})
```

---

## UX-Details & Keymap-Vorschläge

Default keymaps (buffer-local, FileType):

* `<leader>tt` → `:TableViewSelect`
* `gT` → `:TableViewToggle` (toggle at cursor)
* `gtb` → `:TableViewOpenBrowser` (when prefer_browser enabled)
  Inside Float:
* `q` / `<Esc>` → close
* `<CR>` → copy row or jump to source row
* `y` → yank selection

Kontext-Menü (optional):

* Right-click / handler mapping to open small menu: Open in Browser / Copy / Format in Place.

---

## Nächste Schritte (konkrete Implementation Tasks)

1. Implementiere `parser.lua` (tests for basic, alignment lines, edge cases).
2. Implementiere `render_text.lua` + `ui.lua` (Floating buffer, highlights).
3. Implementiere `commands.lua` + `mappings.lua` + FileType autocommands.
4. Implementiere `format_table_in_place` (safe edit + undo-friendly).
5. Add `select_and_show` with `vim.ui.select`.
6. Add optional `render_html.lua` + browser open (simple temp HTML) — Phase 2.
7. Document configuration & usage examples.

---
