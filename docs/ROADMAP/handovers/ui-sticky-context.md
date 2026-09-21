# ui.nvim Sticky-Context — Handover (nur offene Punkte)

> Stand 2026-09-21 (abends). `:UI sticky` (Alias `:UI context`) mit Heading-Tiefe
> und Zeilenlimit ist **fertig, gemergt und gepusht** (ui.nvim `fa2dfa9`). Die
> Scope-Lücken (Rust und andere Sprachen), die gemeinsame Heading-Erkennung und
> die fehlenden Specs sind seit ui.nvim `ae95e7f` erledigt. Diese Akte hält nur,
> was danach übrig ist: eine Sichtprüfung im echten Fenster, ein paar
> Entscheidungen von dir und einige Sprachen, die nur per Query, nicht per
> echtem Parser geprüft sind.

## Table of content

- [Regeln für diese Session](#regeln-für-diese-session)
- [Orte](#orte)
- [Ausgangslage](#ausgangslage)
- [Offene Punkte](#offene-punkte)
  - [1. Sichtprüfung im echten Fenster](#1-sichtprüfung-im-echten-fenster)
  - [2. Entscheidungen, noch nicht getroffen](#2-entscheidungen-noch-nicht-getroffen)
  - [3. Sprachen ohne echten Parser-Test](#3-sprachen-ohne-echten-parser-test)
  - [4. Markdown-Varianten: mdx, quarto, rmd](#4-markdown-varianten-mdx-quarto-rmd)
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
  (`git commit -F`), keine großen Literale durch die Shell (auch kein großer
  Python-Heredoc: Testblöcke per Datei schreiben und einspleißen), Wegwerf-Skripte
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
| Specs | `E:\repos\ui.nvim\TESTS\context_spec.lua` (62 Tests), dazu `config_spec.lua` (`opts.sticky / opts.context`) und `health_spec.lua` (Abschnitt Context) |
| Plugin-Docs | `ui.nvim/docs/configuration.md` (Abschnitt Context inkl. Tabelle „was pro Sprache gepinnt wird“), `docs/BINDINGS.md`, `docs/health.md`, `docs/scope.md` |
| Verdrahtung in dieser Config | `lua/config/ui_statusline/init.lua`, Schlüssel `sticky = { … }` |
| Bindings-Notiz | `docs/NOTES/ExternPlugins/Bindings/Autocmds/Treesitter.md`, Abschnitt `ui.context` |
| CI-Verdikt | `bash scripts/ci_status.sh ui.nvim` (braucht `gh`) |

## Ausgangslage

Die Anzeige ist ein Float pro Fenster über den ersten Zeilen: Tree-sitter läuft
vom ersten sichtbaren Knoten die Vorfahren hoch, jeder Vorfahre, dessen Typ auf
`cfg.node_types` passt (Lua-Patterns) und nicht auf `cfg.exclude_node_types`,
liefert seine Startzeile. Ausnahme seit `ae95e7f`: ein `node_types`-Eintrag mit
Anker an beiden Enden (`^name$`) benennt genau einen Typ und wird vom Exclude
nicht überstimmt. Ohne Parser (Plain Text) erscheint nichts. In Markdown ist der
Knoten `section`, also die Heading-Kette. `require("ui.context").is_scope_type(t)`
beantwortet die Frage für einen Typnamen.

Zwei getrennte Tiefen-Limits:

- `headings.max_level` (1..6): tiefere Markdown-Headings fallen aus der Kette.
- `max_lines`: Zahl oder Tabelle je Filetype, z. B. `{ default = 3, markdown = 6 }`.

Der Level-Deckel läuft zuerst, danach das Zeilenlimit. `:UI sticky up` sieht
weiterhin jede Sektion. Deckel und Zeichnung lesen eine ATX-Heading jetzt über
dieselbe Funktion (`atx_heading`, CommonMark: bis 3 Leerzeichen Einrückung, leeres
`##` zählt).

## Offene Punkte

### 1. Sichtprüfung im echten Fenster

Alles wurde headless getestet, nichts visuell. Einmal von Hand ansehen:

1. Große Markdown-Datei öffnen, `:UI sticky status`, in eine H4/H5-Sektion scrollen.
2. `:UI sticky depth 3`: Kette endet bei H3, Anzeige zeichnet sofort neu.
3. `:UI sticky lines markdown 2`, danach `lines markdown 6`.
4. Kleines Fenster (unter 6 Zeilen oder Cursor in den obersten Zeilen): kein
   Overlay, der Cursor wird nie verdeckt. Bei 6 Zeilen Markdown-Limit prüfen, dass
   das Overlay ein kleines Fenster nicht aufzehrt (`min_window_height = 6`).
5. Zusammenspiel mit dem lspsaga-Winbar aus lsp.nvim: der Winbar schneidet
   Markdown auf `winbar_max_symbols = { markdown = 1 }` (eine Heading). Das
   Sticky-Overlay zeigt bis zu sechs. Doppelt sich das? Siehe Punkt 2.
6. Neu seit `ae95e7f`: eine lange Rust-Funktion (oder ein Python-`elif`-Zweig)
   scrollen: erscheinen `if`/`for`/`match`/`elif` als Zeilen, und ist das Bild
   ruhig genug, oder pinnt es jetzt zu viel? Ein eingerückter Markdown-Heading
   (` ## x`) trägt Band und Icon auf dem `#`.

### 2. Entscheidungen, noch nicht getroffen

- **Filetype-Schalter.** Es gibt nur ein globales an/aus. Falls das Overlay nur
  in Markdown oder nur in Code laufen soll: `filetypes`-Include-Liste oder
  `enable = { markdown = true }`. Heute geht nur `exclude_filetypes`.
- **Session-Werte dauerhaft.** `:UI sticky depth` und `lines` gelten nur bis
  zum Neustart. Dauerhaft nur über `ui_statusline/init.lua`. Falls gewünscht:
  Persistenz (State-Datei) oder ein Hinweis im Notify-Text.
- **Winbar-Duplikat** (Punkt 1.5): Entweder `winbar_max_symbols.markdown`
  in lsp.nvim erhöhen und das Overlay auf Code beschränken, oder umgekehrt.
- **JSON/YAML/TOML pinnen nichts.** Kein Knotentyp dort ist ein Scope. Für
  tief verschachteltes YAML wäre eine Kette der Eltern-Schlüssel nützlich:
  `"^block_mapping_pair$"` in `node_types` (YAML-Parser ist installiert, also
  echt prüfbar). Nicht gebaut, weil es Verhalten ist, das du nicht verlangt hast.
- **Lambdas/Closures** (Java, C#, Rust, Kotlin) bleiben draußen, obwohl
  `arrow_function`/`function_expression`/`func_literal` (JS/TS/Go) gepinnt
  werden. Begründung: dort sind Callbacks Testrümpfe, in den anderen Sprachen
  meist Einzeiler. Falls anders gewünscht, `^lambda_expression$` /
  `^closure_expression$` ergänzen.
- **Usercmds-Cheatsheet.** `docs/NOTES/BINDINGS-FORMAT.md` sieht je Plugin eine
  Datei unter `Usercmds/` vor. Für die `:UI`-Familie gibt es keine
  (nur `Usercmds/NvChadUI.md`), die Sticky-Befehle stehen ausschließlich in der
  Treesitter-Notiz. Nicht geprüft, ob das Absicht ist.

### 3. Sprachen ohne echten Parser-Test

Echt am Parser geprüft sind nur Lua, Markdown, Rust und Python (nur diese Parser
sind hier installiert). Go, Java, C#, JavaScript, TypeScript, Kotlin, Bash, C,
JSON, YAML, TOML sind gegen die Knotennamen in
`nvim-treesitter/runtime/queries/<lang>/*.scm` geprüft, nicht an einem Buffer.
Wer eine dieser Sprachen benutzt und ein Fehlverhalten sieht: `:lua
=vim.treesitter.get_node():type()` am Cursor, dann `is_scope_type("<typ>")`.

Bekannte Restlücken (bewusst nicht angefasst):

- Rusts `x?` und Kotlins `try` heißen beide `try_expression` und bleiben wegen
  `_expression$` ausgeschlossen (sonst pinnt jedes `?` eine Zeile).
- Zsh-Queries nennen `elif_clause` nicht; Bash schon.
- Nix und OCaml nutzen `function_expression` für das dateiweite Lambda: eine
  Nix-Datei behält ihren `{ pkgs, ... }:`-Kopf dauerhaft gepinnt (Nix ist hier
  nicht im Einsatz; in `docs/configuration.md` vermerkt).
- Ruby (`if`, `elsif`, `when`, `begin`/`rescue`), PHP und übrige Sprachen sind
  nicht abgedeckt; `node_types` ist der Hebel.

### 4. Markdown-Varianten: mdx, quarto, rmd

Level-Deckel und Heading-Zeichnung gelten nur für `filetype == "markdown"`.
`mdx`, `quarto`, `rmd` haben eigene Filetypes und werden wie Code behandelt.
Ungeprüft: welche Parser dort greifen und ob es überhaupt `section`-Knoten gibt.
Nur anfassen, wenn du diese Dateitypen benutzt.

## Was schon erledigt ist

| Was | Wo |
|---|---|
| Heading-Zeichnung im Overlay (Farben, Band, Icon je Level) | ui.nvim `784e83c` |
| `:UI sticky`, `depth`, `lines`, `status`, Completion, `headings.max_level`, `max_lines` je Filetype, `ui.setup({ sticky })`, Health | ui.nvim `fa2dfa9` |
| Verdrahtung `sticky = { max_lines = { default = 3, markdown = 6 }, headings = { max_level = 6 } }` und Bindings-Notiz | Config `630e883c2` |
| Self-Review: eingerückte ATX-Heading, stilles Löschen bei ungültigem `set_max_lines`, fehlende Completion | in `fa2dfa9` enthalten |
| Rust: `if`/`for`/`while`/`loop`/`match`/`mod` gepinnt (Exact-Name-Regel), am echten Rust-Parser bestätigt | ui.nvim `ae95e7f` |
| Andere Sprachen: Python `elif`/`except`/`finally`, Go `type_declaration`/`*_case`/`func_literal`, Java `enhanced_for`/`switch_expression`/`record`, Bash `c_style_for`, Kotlin `when`/`do_while`, TS `namespace`, JS `function_expression`; Java `method_invocation` nicht mehr als Methode. Tabelle je Sprache in `docs/configuration.md` | ui.nvim `ae95e7f` |
| Audit über 11423 (Sprache, Typ)-Paare der nvim-treesitter-Queries: Lua, C, Markdown, JavaScript unverändert | ui.nvim `ae95e7f` |
| Eine gemeinsame `atx_heading()`: eingerückte und leere Headings werden gezeichnet, Icon sitzt auf dem `#` | ui.nvim `ae95e7f` |
| Specs: `ui.setup` sticky/context-Vorrang, Health-Zeile mit Tabellen-`max_lines`, Scope-Tabellen für 12 Sprachen, Rust-/Python-Buffer | ui.nvim `ae95e7f` |
| Testleck behoben: `after_each` stellt Icons und Node-Listen wieder her (ein Test mit `icons = false` verfälschte die folgenden) | ui.nvim `ae95e7f` |
| Self-Review von `ae95e7f`: die längere Pattern-Liste machte `is_scope_type` 4× langsamer (108 statt 26 µs je Vorfahrenkette, bei jeder Cursorbewegung); jetzt Cache pro Typname (0,11 µs). Kaputtes Pattern oder Nicht-String in `node_types` wirft nicht mehr (eine Warnung), `is_scope_type(nil)` auch nicht | ui.nvim `8379ca7` |

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
bash scripts/test.sh                            # alle (47 Spec-Dateien, 495 Tests)
stylua --check . && luacheck .                  # die beiden CI-Gates
```

Node-Typ am Cursor lesen: `:lua =vim.treesitter.get_node():type()`. Ob ein Typ
gepinnt wird: `:lua =require("ui.context").is_scope_type("if_expression")`.
Welche Knotennamen eine Sprache kennt, steht in
`$LOCALAPPDATA/nvim-data/lazy/nvim-treesitter/runtime/queries/<lang>/*.scm`
(`folds.scm` und `locals.scm` sind die ergiebigsten). Eine Suche über alle Repos,
bevor man ein Feature für „nicht vorhanden“ hält:
`grep -rIl "<begriff>" E:/repos --include=*.lua --include=*.md` (ausgenommen
`.git`, `.claude/worktrees`, `.deps`).

Headless-Probe gegen die installierten Parser (Wegwerf, nicht einchecken):
`nvim -n --headless -u NONE -l probe.lua <lang> <datei>` mit
`vim.opt.rtp:append(stdpath("data") .. "/site")`; `-n` ist nötig, sonst bricht
`E326` (zu viele Swap-Dateien) die Probe ab.

Nach dem Push: `bash scripts/ci_status.sh ui.nvim`, und mit
`gh run list --repo StefanBartl/ui.nvim --commit <sha>` prüfen, dass der Lauf
wirklich zum gepushten Commit gehört.
