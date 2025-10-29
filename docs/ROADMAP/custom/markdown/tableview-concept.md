
## Konzept: Markdown TableView für Neovim

Ziel: Ein modularer, erweiterbarer Table-Viewer für Markdown in Neovim, der Markdown-Tabellen im Editor möglichst „gerendert“ (ausgerichtet / gut lesbar) in einem Floating Window anzeigt und optional eine Browser-Preview (Markdown -> HTML) unterstützt. Der Workflow umfasst: kontextsensitives Anzeigen (Cursor in Tabelle), manuelle Auswahl aller Tabellen im Dokument, Anzeige entweder in Floating Window oder Browser, sowie ein CLI-/UserCommand-API und konfigurierbare Keymaps/Autocmds.

---

## MVP-Funktionalität (priorisiert)

1. Robusterekennung von Pipe-Style Markdown-Tabellen (standard GitHub-Flavored Markdown).
2. Parser: Spaltenbreiten berechnen, Zellen-Trimming, Alignment (links/zentriert/rechts) aus Separator-Zeile ableiten.
3. Floating Window Renderer: Erstelle eine monospaced, aligned-Text-Ansicht (nicht HTML) in einem schwebenden Fenster; scrollbar, kopierbar.
4. UserCommand `:TableViewToggle` — wenn Cursor in Tabelle: toggle Floating Window; ansonsten Fehlermeldung.
5. UserCommand `:TableViewSelect` — sammelt alle Tabellen, zeigt Auswahl (builtin `vim.ui.select`) und rendert die gewählte Tabelle.
6. Option `prefer_browser = false` (default); wenn true, öffnet Browser-Preview via temporäre HTML-Datei + `xdg-open`/`open`/`start`.
7. Debounce/auto-on-cursor (optional): nur wenn Cursor eine bestimmte Zeit in Tabelle bleibt (z. B. 200ms), Fenster öffnen.

---

## Erweiterte Features (voraussichtlich Phase 2)

* Unterstützung für Grid-Tables (reStructuredText style) und simple CSV-Import.
* Inline-Editing: Änderungen in Floating Window zurückschreiben in Buffer (optional, bidirektional).
* Sort/Filter-Spalten UI in Floating Window (keine heavy GUI — minimal keystrokes).
* Column wrap / soft-wrap options und max-width config.
* MarkdownPreview-Integration: rendern mit existing plugin when prefer_browser true; fallback to own HTML generator.
* Caching & incremental re-rendering (für große Dateien).
* LSP-like virtual text hints for column indices.

---

## Architektur und Modulaufteilung

Vorschlag: `lua/custom/markdown/tableview/` mit folgenden Dateien:

* `init.lua` — public API: `setup(opts)`, `toggle_at_cursor()`, `select_and_show()`, `show_table(tbl, opts)`.
* `parser.lua` — Markdown-Table parser: `find_table_at_cursor(bufnr, row)`, `find_all_tables(bufnr)`, `parse_table(lines) -> {headers, rows, align}`.
* `render_text.lua` — renderer für Floating Window: `render_as_text(table_struct, opts) -> lines`.
* `render_html.lua` — optionaler HTML-Renderer: `table_struct -> html`, writes temp file, returns path.
* `ui.lua` — floating window helpers: create/destroy/focus buffer & window, sizing, keymaps inside float.
* `commands.lua` — usercommands registration (buffer-local via FileType autocommand).
* `mappings.lua` — keymap definitions (buffer-local) that call `toggle_at_cursor()` / `select_and_show()`.

---

## Parsing-Strategie (technisch)

1. Detect table start: a line containing `|` or that matches pipe-table header (e.g. `| a | b |` or `a | b`).
2. Verify separator line exists next (regex): `^%s*[:%-]+%s*|?` with colons for alignment markers (`:--`, `--:` `:--:`).
3. Collect contiguous lines until blank line or non-pipe line (ignoring code fences / fenced blocks).
4. parse_table(lines):

   * Split each line by top-level `|` (ignore leading/trailing if absent).
   * Trim whitespace from cells.
   * For separator line, detect alignment per column:

     * `^:%s*-+%s*:$` → center
     * `^:%s*-+%s*$` → left
     * `^%s*-+%s*:$` → right
   * Compute column widths = max len of content across rows+headers.
   * Produce normalized table struct:

     ```
     {
       headers = {"H1","H2"},
       rows = { {"a","b"}, {"c","d"} },
       align = {"left","center"},
       col_widths = {10, 6},
       raw_lines = {...}, -- optional for roundtrip
       start_row = N, end_row = M
     }
     ```

---

## Floating Window Rendering

* Use a dedicated scratch buffer (`nvim_create_buf(false, true)`) set to `filetype = "markdown-tableview"` or plain `nofile`.
* Display `render_as_text(table_struct, opts)` output lines.
* Text rendering:

  * Combine cells using `|` separators or visual box-drawing chars if user prefers (config option `use_box_chars`).
  * Pad cells by `col_widths`.
  * Optional highlight: use extmarks / buffer highlights to color header row, separators and alignment indicators.
* Window size:

  * width = min(max_width, sum(col_widths)+3*cols)
  * height = min(max_height, #lines)
  * center or relative to cursor (config `anchor = "cursor"` vs `center`).
* Keymaps inside float:

  * `q` or `<Esc>` → close
  * `<CR>` → copy current row to clipboard / insert into buffer
  * `g` / `G` → scroll top / bottom
  * `s` → sort by selected column (Phase 2)

---

## Browser Preview (Markdown -> HTML)

* Options:

  * Use existing plugin (e.g. `iamcco/markdown-preview.nvim`) if installed.
  * Else implement minimal HTML generator:

    * Generate a small HTML table, include simple CSS to style table, write to temp file (`vim.fn.tempname() .. ".html"`), open via `xdg-open`.
* User option `prefer_browser` toggles behavior in `select_and_show()` and `toggle_at_cursor()`.

---

## UX / Commands / Keymaps

UserCommands:

* `:TableViewToggle` — toggle floating view for table under cursor.
* `:TableViewSelect` — collect all tables in buffer, `vim.ui.select` choices like `Table @line 10 (3 cols, 5 rows)`; open selected.
* `:TableViewOpenBrowser` — open active table in browser (or last selected).
* `:TableViewClose` — close float.

Default keymaps (buffer-local, created via FileType autocommand):

* `gT` — `:TableViewToggle` (example)
* `<leader>tt` — `:TableViewSelect`
* `gtb` — `:TableViewOpenBrowser`

Config options (setup):

```
{
  prefer_browser = false,
  auto_on_cursor = false,       -- open float automatically when cursor in table
  float = {
    width = 0.75,               -- fraction of editor width
    height = 0.4,               -- fraction of editor height
    anchor = "cursor" | "center",
    border = "rounded",
    use_box_chars = false,
  },
  max_col_width = 80,
  highlight = {
    header = "Title",
    separator = "Comment",
  },
  debounce_ms = 200,
}
```

---

## API / Public Functions

* `setup(opts)` — registers autocommands, usercommands and default keymaps (configurable).
* `toggle_at_cursor()` — toggles floating window for table at cursor (MVP).
* `select_and_show()` — show selection list of tables in buffer.
* `show_table(table_struct, opts)` — show a prepared table struct (for programmatic use).
* `get_all_tables(bufnr)` — returns array of table_struct for external consumption.

---

## Integration / Autocmds

* On `FileType` markdown: register buffer-local usercommands and keymaps (like other custom.markdown modules).
* If `auto_on_cursor = true`:

  * Create `CursorHold` autocmd (buffer-local) with debounce to call `toggle_at_cursor()` or `show_table` in non-blocking manner.
  * Ensure `CursorMoved` cancels the pending timer.

---

## Implementation Plan (concrete steps)

1. Create module skeleton files (parser, render_text, ui, commands, init).
2. Implement parser for pipe tables + unit tests (via simple `:lua print` checks).
3. Implement `render_as_text` and the floating window UI; ensure buffer is scratch and ephemeral.
4. Wire `toggle_at_cursor()` and `select_and_show()`; register usercommands & keymaps in FileType autocmd.
5. Implement HTML renderer and `prefer_browser` flow (use temp file).
6. Add extras: highlights, box chars, sorting, editing sync.
7. Polish: configuration validation, documentation, help text, examples.

---

## Beispiel: Minimal render algorithm (pseudocode)

```text
-- parse_table(lines):
for each line in lines:
  cells = split_on_top_level_pipes(line)
  trim each cell
compute align from separator_line
for each column i:
  col_width[i] = max(len(cell[i]) for all rows+header)
build output_lines:
  header_line = join_with(" | ", pad_cells(headers, col_width))
  sep_line = join_with("-|-", fill_align_markers)
  for each row:
    row_line = join_with(" | ", pad_cells(row, col_width))
return output_lines
```

---

## Testfälle / Beispiele zum Testen

* Small table:

  ```
  | Name | Age |
  |------|----:|
  | Alice | 30 |
  | Bob | 25 |
  ```
* Table with spaces/angle brackets:

  ```
  | Path | Note |
  |------|------|
  | ./Figures/7.1_Addressing-Requirements-for-a-Process.png | figure 7.1 |
  ```
* Large table (many columns) to test wrapping and max_col_width behaviour.

---

## Risiken / Entscheidungen

* Parser choice: Tree-sitter bietet robustere AST-based detection (recommended if table grammars supported), but regex parser is simpler and suffices for pipe-tables.
* Rendering in floating window as text is simpler and well-integrated in Neovim; full HTML rendering in float would require an embedded browser (complex). Browser preview is sufficient for HTML rendering.
* Editing inside float requires mapping and round-trip logic; postpone to Phase 2.

---
