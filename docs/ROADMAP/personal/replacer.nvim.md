#  `replacer`

---

## Aus `MyPlugin-Notes/ReplacerRoadmap.md` (Analyse 2026-08-08)

Quelle: `E:/repos/Notes/MyPlugin-Notes/ReplacerRoadmap.md` — 12 nummerierte
Punkte plus eine Feature-Wunschliste mit 22 Einträgen.

**Ergebnis der Gegenprüfung: die Notiz ist abgearbeitet.** Das ist hier das
eigentliche Ergebnis und deshalb dokumentiert — sonst wird die Liste beim
nächsten Durchsehen erneut als offen gelesen.

Belege aus `E:/repos/replacer.nvim/lua/replacer/config/DEFAULTS.lua` und dem
Modulbaum:

| Notiz-Wunsch | Umgesetzt als |
|---|---|
| Case-Preserving Replace | `case_preserve` + `casing.lua` |
| Wortgrenzen / Token-Modus, keine Treffer in Strings/Comments | `word_boundary`, `code_only` + `tscode.lua` |
| Regex-Modus mit Hilfen | `literal` + `regex.lua` |
| Batch-Replaces | `batch.lua` |
| File-Scopes & Filter (`--type`, Globs, Exclude, Grössenlimit) | `file_types`, `globs`, `exclude`, `max_file_size` |
| Monorepo-/Root-Erkennung | `root.lua` |
| Nur-Changed-Modus (git) | `gitfiles.lua` |
| History & Presets | `history.lua`, `presets.lua` |
| Plan/Review ohne Apply, Patch-Export, Quickfix-Export | `export.lua` |
| Per-File-Bestätigung (All/Skip/Only-some/Quit) | `confirm_per_file` + `perfile.lua` |
| Undo-Checkpoint | `checkpoint` + `checkpoint.lua`, `:ReplaceUndo` |
| LSP-Integration (sanft) | `lsp` + `lsp_rename.lua` |
| Encoding / Line-Endings | `encoding.lua` |
| Preview-Highlighting | Extmarks + `ReplacerTarget`/`ReplacerOld`/`ReplacerNew` in `pickers/` |
| Hook-System | `hooks` + `hooks.lua` |
| Status / Progress | `progress_style` über `lib.nvim.progress` |
| Preserves-Whitespace | `preserve_whitespace` |
| Safe-Mode (read-only/binär/gross überspringen) | `safe_mode`, `skip_binary` |
| Rename-Assist | `rename_assist.lua` |
| i18n / Meldungen | `messages` + `messages.lua`, `quiet` |
| Punkt 4: nicht nur ripgrep, auch vimgrep | `search_engine = "auto"` |
| Punkt 8/10: fzf-lua vs. telescope wählen | `engine = "auto"` |
| Punkt 9: bessere Fehlermeldungen | `error.lua` + `messages.lua` |
| Punkt 11: `ext_highlight`, altes Wort rot/durchgestrichen, neues grün | `pickers/utils.lua`, inkl. `strikethrough`-Option |
| Punkt 6: `:h` | `doc/replacer.txt` |
| Punkt 1: Default-Scope aus `init` wird ignoriert | `default_scope = "%"` in DEFAULTS |

---

### Einziger offener Punkt: echte Live-Befüllung des Pickers

`stream = false` schaltet heute den inkrementellen `rg --json`-Parser
(`collect_streaming`) ein — der Picker öffnet aber weiterhin erst, **wenn die
Sammlung fertig ist**. Der Notiz-Wunsch „früh selektieren, während die Suche
weiterläuft" ist damit nicht erfüllt.

Das ist im Repo selbst bereits vermerkt (Docstring von `collect_streaming` in
`rg.lua` und `docs/ROADMAP.md`) — hier nur als Querverweis, **nicht** doppelt
verfolgen.

**Aufwand:** Lang — beide Picker-Backends müssen eine wachsende Quelle
akzeptieren; fzf-lua und Telescope machen das grundverschieden.
**Nutzen:** mittel — spürbar nur bei sehr grossen Suchen.

