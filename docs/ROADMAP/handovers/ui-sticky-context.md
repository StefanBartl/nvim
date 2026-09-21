# ui.nvim Sticky-Context — Handover (nur offene Punkte)

> Stand 2026-09-21. `:UI sticky` (Alias `:UI context`) mit Heading-Tiefe und
> Zeilenlimit pro Filetype ist **fertig, gemergt und gepusht** (ui.nvim
> `fa2dfa9`, Config `630e883c2`, CI grün auf ubuntu/windows/macos). Diese Akte
> hält nur, was danach übrig ist: eine Lücke in der Rust-Scope-Erkennung, zwei
> kleine Inkonsistenzen und ein paar ungeprüfte oder ungetestete Stellen.

## Table of content

- [Regeln für diese Session](#regeln-für-diese-session)
- [Orte](#orte)
- [Ausgangslage](#ausgangslage)
- [Offene Punkte](#offene-punkte)
  - [1. Rust: if/for/while/loop/match/mod werden nie gepinnt](#1-rust-ifforwhileloopmatchmod-werden-nie-gepinnt)
  - [2. Andere Sprachen: Node-Typen ungeprüft](#2-andere-sprachen-node-typen-ungeprüft)
  - [3. Heading-Erkennung: Zeichnen und Level-Deckel lesen verschieden](#3-heading-erkennung-zeichnen-und-level-deckel-lesen-verschieden)
  - [4. Markdown-Varianten: mdx, quarto, rmd](#4-markdown-varianten-mdx-quarto-rmd)
  - [5. Fehlender Spec: ui.setup mit sticky](#5-fehlender-spec-uisetup-mit-sticky)
  - [6. Sichtprüfung im echten Fenster](#6-sichtprüfung-im-echten-fenster)
  - [7. Entscheidungen, noch nicht getroffen](#7-entscheidungen-noch-nicht-getroffen)
- [Was schon erledigt ist](#was-schon-erledigt-ist)
- [Handwerkszeug](#handwerkszeug)

---

## Regeln für diese Session

- Nie mehr als 1 Agent gleichzeitig; bei Bedarf mehrere Runden à 1 Agent.
- Antworten Deutsch, Quellcode (inkl. Kommentare und Commit-Nachrichten) Englisch.
- Keine Co-Autorenschaft von Claude in Commits.
- Nach jedem fertigen Schritt committen, pullen, nach `main` mergen und pushen;
  die laufende Neovim-Config nutzt `E:\repos\ui.nvim` auf `main` direkt.
- Code muss `stylua --check .` und `luacheck .` grün haben (stylua v2.5.2,
  luacheck 1.2.0), neue Features bekommen Specs im eigenen `TESTS/`.
- Plugin-Docs/README mitpflegen, wo es Sinn macht; ändert sich ein Command oder
  Binding, auch die Bindings-Notiz in dieser Config anpassen.
- `TOOL-PLACEMENT.md` / `HEREDOC.md` beachten: Commit-Nachrichten per Datei
  (`git commit -F`), keine großen Literale durch die Shell, Wegwerf-Skripte
  nicht einchecken.
- Vor jedem Commit `git status` lesen, nie `git add -A` in dieser Config: sie
  hat regelmäßig fremde, uncommittete ROADMAP-Dateien.
- Erst das Plugin mergen, dann die Config umstellen. Eine ältere ui.nvim-Version
  liest ein Tabellen-`max_lines` als „kein Limit“.

## Orte

| Was | Wo |
|---|---|
| Modul | `E:\repos\ui.nvim\lua\ui\context\init.lua` |
| Command | `E:\repos\ui.nvim\lua\ui\bindings\usrcmds\init.lua`, Funktion `ui_sticky` |
| Specs | `E:\repos\ui.nvim\TESTS\context_spec.lua` (32 Tests, 2026-09-21) |
| Plugin-Docs | `ui.nvim/docs/configuration.md` (Abschnitt Context), `docs/BINDINGS.md`, `docs/health.md`, `docs/scope.md` |
| Verdrahtung in dieser Config | `lua/config/ui_statusline/init.lua`, Schlüssel `sticky = { … }` |
| Bindings-Notiz | `docs/NOTES/ExternPlugins/Bindings/Autocmds/Treesitter.md`, Abschnitt `ui.context` |
| CI-Verdikt | `bash scripts/ci_status.sh ui.nvim` (braucht `gh`) |

## Ausgangslage

Die Anzeige ist ein Float pro Fenster über den ersten Zeilen: Tree-sitter läuft
vom ersten sichtbaren Knoten die Vorfahren hoch, jeder Vorfahre, dessen Typ auf
`cfg.node_types` passt (Lua-Patterns) und nicht auf `cfg.exclude_node_types`,
liefert seine Startzeile. Ohne Parser (Plain Text) erscheint nichts. In Markdown
ist der Knoten `section`, also die Heading-Kette.

Seit 2026-09-21 gibt es zwei getrennte Tiefen-Limits:

- `headings.max_level` (1..6): tiefere Markdown-Headings fallen aus der Kette.
- `max_lines`: Zahl oder Tabelle je Filetype, z. B. `{ default = 3, markdown = 6 }`.

Der Level-Deckel läuft zuerst, danach das Zeilenlimit. `:UI sticky up` sieht
weiterhin jede Sektion.

## Offene Punkte

### 1. Rust: if/for/while/loop/match/mod werden nie gepinnt

**Für diesen Punkt existiert bereits ein Task** (`Fix Rust scopes in ui.nvim
sticky context`, Chip in der Session vom 2026-09-21). Nicht doppelt anfangen:
zuerst nachsehen, ob er gestartet wurde (`git log --oneline` in `E:\repos\ui.nvim`).

Befund, per Pattern-Test gegen das echte Modul ermittelt (die Node-Namen stammen
aus der Kenntnis der tree-sitter-rust-Grammar und sind **nicht** an einem echten
Rust-Buffer geprüft):

- `is_scope_type()` prüft `exclude_node_types` **vor** `node_types`.
- Das Exclude-Muster `_expression$` trifft `if_expression`, `for_expression`,
  `while_expression`, `loop_expression`, `match_expression`. Der Include-Eintrag
  `^if_expression$` kann deshalb nie greifen.
- `^module` trifft `mod_item` nicht.
- Gepinnt werden in Rust damit nur `function_item`, `impl_item`, `struct_item`,
  `enum_item`, `trait_item` und (über `^match`) `match_arm`.

Vorgehen:

1. An einem echten Rust-Buffer mit dem Parser bestätigen:
   `:lua =vim.treesitter.get_node():type()` mit dem Cursor in einem `if`, `for`,
   `match`, `mod`.
2. Fix wählen, ohne andere Sprachen zu verschlechtern. Naheliegend: ein
   ausdrücklich verankerter Include-Eintrag (`^if_expression$`) schlägt das
   generische Exclude. Alternative: `_expression$` enger fassen. Danach `mod_item`
   ergänzen.
3. Regressionstest in `TESTS/context_spec.lua`, Rust-Snippet, mit Parser-Check
   und `pending` sonst (wie bei Lua und Markdown).
4. `docs/configuration.md`, Abschnitt zu `node_types`, anpassen.

Fertig, wenn: Rust-Snippet pinnt `if`/`for`/`while`/`loop`/`match`/`mod`, Lua,
C, TypeScript und Markdown verhalten sich unverändert, Specs und Lint grün.

### 2. Andere Sprachen: Node-Typen ungeprüft

Nur Lua, C, TypeScript und Markdown wurden per Pattern-Test durchgespielt.
Nicht geprüft: Python, Go, Java, C#, JavaScript, Kotlin, Zsh/Bash, JSON/YAML.
Beim Rust-Fix mitnehmen:

- Python: `function_definition`, `class_definition`, `if_statement`,
  `for_statement`, `while_statement`, `with_statement`, `try_statement`.
- Go: `function_declaration`, `method_declaration`, `if_statement`,
  `for_statement`, `type_declaration`.
- TypeScript: `call_expression` ist ausgeschlossen. Testcode wie
  `describe("x", function () { … })` pinnt deshalb den Callback nicht über die
  Aufrufzeile. Prüfen, ob das gewollt ist.

Vorgehen: pro Sprache einen kleinen Buffer öffnen, Knotentyp am Cursor ablesen,
Ergebnis in eine Tabelle „Sprache, gepinnt, nicht gepinnt“ am Ende von
`docs/configuration.md` schreiben. Kein Scanner bauen (siehe
`TOOL-PLACEMENT.md`: Wegwerf-Probe, Ergebnis ins Doc).

### 3. Heading-Erkennung: Zeichnen und Level-Deckel lesen verschieden

Der Level-Deckel (`section_level`) versteht seit dem Fix CommonMark-konform bis
zu drei Leerzeichen Einrückung und leere Headings (`##` allein). Die
Zeichen-Seite (`heading_level`, färbt und überlagert das Icon) nutzt weiter
`^(#+)%s` ohne Einrückung. Folge: eine eingerückte ATX-Heading wird korrekt
vom Deckel behandelt, aber ohne Band und Icon gezeichnet.

Vorgehen: `heading_level` und `section_level` auf eine gemeinsame Funktion
zurückführen. Achtung beim Icon: es überlagert `level` Zellen ab der Spalte
`from` und geht davon aus, dass dort die `#` beginnen. Bei Einrückung muss die
Überlagerung um die Einrückung verschoben werden, sonst deckt sie Leerzeichen.

Fertig, wenn: eingerückte Heading wird gefärbt, Icon sitzt auf den `#`, Test
im `markdown headings`-Block von `context_spec.lua`.

### 4. Markdown-Varianten: mdx, quarto, rmd

Level-Deckel und Heading-Zeichnung gelten nur für `filetype == "markdown"`.
`mdx`, `quarto`, `rmd` haben eigene Filetypes und werden wie Code behandelt.
Ungeprüft: welche Parser dort greifen und ob es überhaupt `section`-Knoten gibt.
Nur anfassen, wenn du diese Dateitypen benutzt.

### 5. Fehlender Spec: ui.setup mit sticky

Der Alias `sticky` in `ui.setup` (Vorrang vor `context`, `false` lässt es aus)
wurde nur in einer Headless-Probe geprüft, es gibt keinen Spec. Ebenso fehlt ein
Health-Test für die Tabellen-Form von `max_lines` (`ui.health`, Funktion
`check_context`).

Vorgehen: in `TESTS/config_spec.lua` (oder `context_spec.lua`) prüfen:

- `ui.setup({ sticky = true })` schaltet ein, `sticky = false` mit
  `context = true` schaltet **nicht** ein, `sticky = { max_lines = {…} }` wirkt;
- `:checkhealth ui` meldet `max_lines 3 (markdown 6)` und die Tiefe.

### 6. Sichtprüfung im echten Fenster

Alles wurde headless getestet, nichts visuell. Einmal von Hand ansehen:

1. Große Markdown-Datei öffnen, `:UI sticky status`, in eine H4/H5-Sektion scrollen.
2. `:UI sticky depth 3`: Kette endet bei H3, Anzeige zeichnet sofort neu.
3. `:UI sticky lines markdown 2`, danach `lines markdown 6`.
4. Kleines Fenster (unter 6 Zeilen oder Cursor in den obersten Zeilen): kein
   Overlay, der Cursor wird nie verdeckt. Bei 6 Zeilen Markdown-Limit prüfen, dass
   das Overlay ein kleines Fenster nicht aufzehrt (`min_window_height = 6`).
5. Zusammenspiel mit dem lspsaga-Winbar aus lsp.nvim: der Winbar schneidet
   Markdown auf `winbar_max_symbols = { markdown = 1 }` (eine Heading). Das
   Sticky-Overlay zeigt bis zu sechs. Doppelt sich das? Siehe Punkt 7.

### 7. Entscheidungen, noch nicht getroffen

- **Filetype-Schalter.** Es gibt nur ein globales an/aus. Falls das Overlay nur
  in Markdown oder nur in Code laufen soll: `filetypes`-Include-Liste oder
  `enable = { markdown = true }`. Heute geht nur `exclude_filetypes`.
- **Session-Werte dauerhaft.** `:UI sticky depth` und `lines` gelten nur bis
  zum Neustart. Dauerhaft nur über `ui_statusline/init.lua`. Falls gewünscht:
  Persistenz (State-Datei) oder ein Hinweis im Notify-Text.
- **Winbar-Duplikat** (Punkt 6.5): Entweder `winbar_max_symbols.markdown`
  in lsp.nvim erhöhen und das Overlay auf Code beschränken, oder umgekehrt.
- **Usercmds-Cheatsheet.** `docs/NOTES/BINDINGS-FORMAT.md` sieht je Plugin eine
  Datei unter `Usercmds/` vor. Für die `:UI`-Familie gibt es keine
  (nur `Usercmds/NvChadUI.md`), die Sticky-Befehle stehen ausschließlich in der
  Treesitter-Notiz. Nicht geprüft, ob das Absicht ist.

## Was schon erledigt ist

| Was | Wo |
|---|---|
| Heading-Zeichnung im Overlay (Farben, Band, Icon je Level) | ui.nvim `784e83c` |
| `:UI sticky`, `depth`, `lines`, `status`, Completion, `headings.max_level`, `max_lines` je Filetype, `ui.setup({ sticky })`, Health | ui.nvim `fa2dfa9` |
| Verdrahtung `sticky = { max_lines = { default = 3, markdown = 6 }, headings = { max_level = 6 } }` und Bindings-Notiz | Config `630e883c2` |
| Self-Review: eingerückte ATX-Heading, stilles Löschen bei ungültigem `set_max_lines`, fehlende Completion | in `fa2dfa9` enthalten |

Bewusst **nicht** gebaut: ein `:Markdown breadcrumbs` in markdown.nvim. Der Begriff
„Breadcrumbs“ meint bei dir den lspsaga-Winbar aus lsp.nvim, ein gleichnamiger
Befehl für das Sticky-Overlay wäre irreführend.

## Handwerkszeug

Specs aus einem Worktree laufen lassen (die Geschwister-Suche in
`scripts/minimal_init.lua` findet `lib.nvim` und plenary dort nicht):

```bash
cd E:/repos/ui.nvim
export LIB_NVIM_DIR=/e/repos/lib.nvim PLENARY_DIR="$LOCALAPPDATA/nvim-data/lazy/plenary.nvim"
bash scripts/test.sh TESTS/context_spec.lua    # eine Spec
bash scripts/test.sh                            # alle (47 Spec-Dateien)
stylua --check . && luacheck .                  # die beiden CI-Gates
```

Node-Typ am Cursor lesen: `:lua =vim.treesitter.get_node():type()`. Eine
Suche über alle Repos, bevor man ein Feature für „nicht vorhanden“ hält:
`grep -rIl "<begriff>" E:/repos --include=*.lua --include=*.md` (ausgenommen
`.git`, `.claude/worktrees`, `.deps`).

Nach dem Push: `bash scripts/ci_status.sh ui.nvim`, und mit
`gh run list --repo StefanBartl/ui.nvim --commit <sha>` prüfen, dass der Lauf
wirklich zum gepushten Commit gehört.
