# Handover — Deduplizieren nach `lib.nvim`

Stand: 2026-08-27. **Alles Genannte ist committet und auf `main` gepusht**,
kein Arbeitsstand hängt irgendwo. `lib.nvim`, `filetree.nvim` und die
nvim-Config sind sauber (`dirty=0 unpushed=0`).

Gehört zum Item **„`lib.nvim` konsequent als Dependency nutzen"** in
`FINISH/MERGED.md`, Abschnitt *Healthchecks, Config & Defaults*.

---

## Wo wir stehen

| Teil | Stand |
| --- | --- |
| **1. Markdown-Tabellen-Renderer** | lib-Modul **steht und ist getestet**; die zwei Plugins sind **nicht** umgestellt |
| **2. `deep_merge` + `config.get`** (cascade ↔ spotlight) | nicht angefangen |
| **3. Kleinkram** (`health.check_require`, `version_ok`, HTML-Escaping, `spawn_env.array`) | nicht angefangen |

---

## 1. Markdown-Tabellen-Renderer

### Was schon da ist

`lib.nvim.markdown.table` (`lua/lib/nvim/markdown/table/init.lua`, Typen in
`@types/init.lua`, Spec in `TESTS/markdown_table_spec.lua`, im Runner
registriert). Öffentliche API:

```
display_width  pad_cell  is_table_line  is_separator_line  parse_row
parse  at_cursor  calc_widths  resolve_overrides  render
format_lines  format_buffer  format_at_cursor  format_file
```

`format_lines(lines, opts)` ist der reine Kern; Buffer und Datei sind das
plus I/O.

### Der Befund, der den Zuschnitt bestimmt hat

Die Roadmap nannte **drei** byte-identische Funktionen. Es sind **siebzehn
geteilte**: vier byte-identisch, neun weitere nur in Zeilenumbrüchen
verschieden. Die vier, die wirklich abwichen, sind das eigentliche Argument
— **jede Kopie trug einen Fix, den die andere nicht hatte**:

| | wer war voraus |
| --- | --- |
| `parse_row` | buffer-ctx: `gmatch` statt Zeichen-für-Zeichen-`..` (O(n²) in der Zeilenlänge) |
| `trim` | markdown: delegiert an `lib.lua.strings.core` |
| `resolve_overrides` | buffer-ctx: sammelt Warnungen statt sie zu verschlucken |
| `format_file` | markdown: beachtet `col_overrides` |

Das Modul nimmt je die bessere Hälfte.

### Entscheidungen, die beim Umstellen zu respektieren sind

- **Breite bleibt `vim.fn.strdisplaywidth`.** `lib.lua.strings.width` hat ein
  reines `display_width`, das ist aber **nicht dieselbe Funktion**: es
  entscheidet ambivalente Zeichen aus eigenen Tabellen, Neovim fragt
  `'ambiwidth'` und das Encoding. Beide Plugins haben mit `strdisplaywidth`
  gemessen, und die Tabellen landen in echten Dateien — eine andere Messung
  würde jede Tabelle stillschweigend neu umbrechen. Die reine Variante ist
  der Fallback für Nicht-Neovim, `opts.width_fn` überschreibt beides.
- **Kein notify, kein Config-Zugriff.** Alles wird zurückgegeben. Genau
  deshalb konnten Buffer- und Datei-Ebene mitkommen statt als dritte und
  vierte Kopie liegenzubleiben. Beim Umstellen also: Plugin liest Config →
  ruft lib → notifiet selbst.
- `resolve_overrides` gibt `map, warnings` zurück. markdown.nvim hat bisher
  aus dem Resolver heraus notifiet — das muss jetzt der Aufrufer tun.

### Was noch zu tun ist

- [ ] **`markdown.nvim`** auf das Modul umstellen: `lua/markdown/core/table_fmt.lua`.
      Behalten muss das Plugin: `get_cfg`, den HTML-Import (`parse_html_table`,
      `unescape_html`, `strip_tags`, `rows_to_gfm`), `parse_args`, `complete`
      und die drei öffentlichen `format_*`-Funktionen als dünne Wrapper
      (Config lesen → lib → notify).
- [ ] **`buffer-ctx.nvim`** auf das Modul umstellen:
      `lua/buffer_ctx/format/table_fmt.lua`. Behalten: `new_progress`,
      `collect_md_files`, `report_override_warnings`, `M.setup`.
- [ ] **lib-Doku:** Modul-README (`lua/lib/nvim/markdown/table/README.md`)
      fehlt noch, ebenso der Eintrag in der lib-Übersicht. Das stand
      ausdrücklich in der Roadmap und ist **noch offen**.
- [ ] Nach dem Umstellen `duplicate_functions.py` erneut laufen lassen und
      prüfen, dass die siebzehn weg sind.

Testrunner: markdown.nvim `TESTS/run.lua`, buffer-ctx.nvim — Runner erst
suchen (`docs/ROADMAP/tools/run_all_tests.sh`).

---

## 2. und 3. — unangetastet

Beschreibung steht unverändert in `FINISH/MERGED.md`. Die Begründungen
gegen `config.M.get` (6 Plugins) und `try_require` (4 Plugins) stehen dort
ebenfalls und gelten weiter.

---

## Offene Frage aus diesem Chat, nicht meine Entscheidung

Nichts mehr offen — die vier Keymap-Konflikte sind aufgelöst
(`conflicts()` meldet 0). Siehe `Merged_Finished.md`.

---

## Ein unbestätigter Verdacht, der dokumentiert gehört

Während dieses Chats war die **Cmdline-Autocompletion** einmal weg: `:`
schlug keine Befehle mehr vor, während die Befehle selbst liefen
(`:Reposcope status` ging). Kurz darauf ging es wieder, ohne dass etwas
geändert wurde — der Verdacht des Users war ein Sync-Fehler.

Was ich messen konnte, während es kaputt aussah:

- `vim.fn.getcompletion("", "command")` lieferte **846** Einträge, also
  arbeitete Neovims Completion selbst normal.
- Die Cmdline-Mode-Keymaps waren vollständig und gehören alle **blink.cmp**
  (`<Tab>`, `<C-N>`, `<C-P>`, `<C-Space>`, …) plus `<F1>`.

Ich konnte es headless **nicht reproduzieren**. Falls es wiederkommt: der
erste Blick gehört blink.cmp und seiner Cmdline-Quelle, nicht dem
`usercmd`-Register — dieses erzeugt Kommandos unverändert über
`nvim_create_user_command` und fasst Completion nicht an. Der zweite Blick
gehört dem Umstand, dass der `vim.g.__map_helper`-Fix ~95 Keymaps
*reaktiviert* hat, die vorher nie gesetzt wurden; eine davon könnte etwas
überdecken. Beides ist eine Hypothese, keine Diagnose.

---

## Arbeitsregeln

- Commit/Push/Pull **immer auf `main`**, pro Repo einzeln.
- Commit-Messages **ohne** `Co-Authored-By: Claude`.
- Code, Kommentare und Doku in den Repos **englisch**; Konversation deutsch;
  Roadmap-/Handover-Dateien folgen dem Bestand und sind deutsch.
- Vor jedem Commit: `stylua lua && luacheck lua`, dann der Test-Runner des
  Repos. **`stylua lua` nie über die nvim-Config laufen lassen** — sie ist
  nicht stylua-formatiert, ein Lauf formatiert 141 Dateien nebenbei um. Dort
  nur die tatsächlich geänderten Dateien einzeln formatieren.
- **Kein bare `git stash`** — der Stash-Stack ist über Worktrees geteilt.
