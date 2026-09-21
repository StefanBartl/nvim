# ui.nvim Sticky-Context — Handover (nur offene Punkte)

> Stand 2026-09-21 (spätabends). `:UI sticky` (Alias `:UI context`), die Scope-
> Erweiterungen (Rust, andere Sprachen, YAML), gespeicherte `depth`/`lines` mit
> `:UI sticky reset` und das Befehlsblatt sind fertig, gemergt und gepusht; die
> CI ist auf allen drei Systemen grün. Alles Erledigte samt Entscheidungen und
> Commits liegt archiviert unter
> `WKDBooks/Development/wkdbook-myplugins/ui.nvim/handovers/ERLEDIGT/ui-sticky-context.md`.
> Diese Akte hält nur, was danach übrig ist: eine Sichtprüfung im echten Fenster
> (die auch das Winbar-Duplikat entscheidet) und einige Sprachen, die nur per
> Query, nicht per echtem Parser geprüft sind.

## Table of content

- [Regeln für diese Session](#regeln-für-diese-session)
- [Orte](#orte)
- [Kurz zur Anzeige](#kurz-zur-anzeige)
- [Offene Punkte](#offene-punkte)
  - [1. Sichtprüfung im echten Fenster](#1-sichtprüfung-im-echten-fenster)
  - [2. Sprachen ohne echten Parser-Test](#2-sprachen-ohne-echten-parser-test)
  - [3. Markdown-Varianten: mdx, quarto, rmd](#3-markdown-varianten-mdx-quarto-rmd)
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
| Modul | `E:\repos\ui.nvim\lua\ui\context\init.lua`, gespeicherte Werte in `lua\ui\context\state.lua` |
| Command | `E:\repos\ui.nvim\lua\ui\bindings\usrcmds\init.lua`, Funktion `ui_sticky` |
| Specs | `E:\repos\ui.nvim\TESTS\context_spec.lua` (74 Tests), dazu `config_spec.lua` und `health_spec.lua` (Abschnitt Context) |
| Plugin-Docs | `ui.nvim/docs/configuration.md` (Abschnitt Context inkl. Tabelle „was pro Sprache gepinnt wird“), `docs/BINDINGS.md`, `docs/health.md`, `docs/scope.md` |
| Verdrahtung in dieser Config | `lua/config/ui_statusline/init.lua`, Schlüssel `sticky = { … }` |
| Bindings-Notizen | `docs/NOTES/ExternPlugins/Bindings/Autocmds/Treesitter.md` (Abschnitt `ui.context`), `Usercmds/UiSticky.md` |
| State-Datei (mit `persist = true`) | `C:\Users\bartl\AppData\Local\nvim-data\ui.nvim\sticky.json` |
| CI-Verdikt | `bash scripts/ci_status.sh ui.nvim` (braucht `gh`) |

## Kurz zur Anzeige

Ein Float pro Fenster über den ersten Zeilen: Tree-sitter läuft vom ersten
sichtbaren Knoten die Vorfahren hoch, jeder, dessen Typ auf `cfg.node_types`
passt (Lua-Patterns, `^name$` = genau ein Typ, vom Exclude nicht überstimmt) und
nicht auf `cfg.exclude_node_types`, liefert seine Startzeile. Ohne Parser
erscheint nichts; in Markdown ist der Knoten `section`, also die Heading-Kette.
Zwei Deckel: `headings.max_level` (1..6, zuerst) und `max_lines` (Zahl oder
Tabelle je Filetype, in dieser Config `{ default = 3, markdown = 6 }`).
`:UI sticky up` sieht weiterhin jede Sektion. Details im Archiv (Ausgangslage).

## Offene Punkte

### 1. Sichtprüfung im echten Fenster

Alles wurde headless getestet, nichts visuell. Einmal von Hand ansehen:

1. Große Markdown-Datei öffnen, `:UI sticky status`, in eine H4/H5-Sektion scrollen.
2. `:UI sticky depth 3`: Kette endet bei H3, Anzeige zeichnet sofort neu.
3. `:UI sticky lines markdown 2`, danach `lines markdown 6`.
4. Kleines Fenster (unter 6 Zeilen oder Cursor in den obersten Zeilen): kein
   Overlay, der Cursor wird nie verdeckt. Bei 6 Zeilen Markdown-Limit prüfen, dass
   das Overlay ein kleines Fenster nicht aufzehrt (`min_window_height = 6`).
5. Zusammenspiel mit dem Winbar-Breadcrumb aus lsp.nvim (seit 2026-09-21
   lsp.nvims eigener, lspsaga ist entfernt): der Winbar schneidet Markdown auf
   `winbar.max_symbols = { markdown = 1 }` (eine Heading), das Sticky-Overlay zeigt
   bis zu sechs. Doppelt sich das? **Entscheidung 2026-09-21: so lassen**, beides
   ergänzt sich (Winbar = H1, Overlay = Kette); nur ändern, wenn es beim Ansehen
   stört. Dann zwei Wege: das Overlay nur für Code (`markdown` in
   `exclude_filetypes`) und den Winbar in lsp.nvim auf mehr Ebenen erhöhen, oder
   den Winbar für Markdown abschalten und dem Overlay die Kette allein lassen.
6. Eine lange Rust-Funktion (oder ein Python-`elif`-Zweig) scrollen: erscheinen
   `if`/`for`/`match`/`elif` als Zeilen, und ist das Bild ruhig genug, oder pinnt
   es zu viel? Ein eingerückter Markdown-Heading (` ## x`) trägt Band und Icon
   auf dem `#`.
7. Neu seit `ef5c8e2`: eine tief verschachtelte YAML-Datei (CI-Workflow) scrollen:
   die Eltern-Schlüssel (`jobs:` > `build:` > `steps:`) sollten oben stehen, nicht
   die Listeneinträge. Und `:UI sticky depth 3`, Neovim neu starten,
   `:UI sticky status` zeigt den gespeicherten Wert; `:UI sticky reset` räumt ihn ab.

### 2. Sprachen ohne echten Parser-Test

Echt am Parser geprüft sind Lua, Markdown, Rust, Python und YAML. Im Ordner
`nvim-data/site/parser` liegen außerdem `json.so` und `toml.so`, sie sind nur
nicht per Spec eingebunden. Go, Java, C#, JavaScript, TypeScript, Kotlin, Bash,
C, JSON, TOML sind gegen die Knotennamen in
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
- TOML: `table` wäre der passende Scope (`[a.b]`-Kopfzeilen) und der Parser liegt
  vor, ist aber nicht gebaut (Entscheidung: nur YAML). JSON pinnt bewusst nichts,
  `pair` würde jeden Schlüssel pinnen.
- Ruby (`if`, `elsif`, `when`, `begin`/`rescue`), PHP und übrige Sprachen sind
  nicht abgedeckt; `node_types` ist der Hebel.

### 3. Markdown-Varianten: mdx, quarto, rmd

Level-Deckel und Heading-Zeichnung gelten nur für `filetype == "markdown"`.
`mdx`, `quarto`, `rmd` haben eigene Filetypes und werden wie Code behandelt.
Ungeprüft: welche Parser dort greifen und ob es überhaupt `section`-Knoten gibt.
Nur anfassen, wenn du diese Dateitypen benutzt.

## Handwerkszeug

Specs aus einem Worktree laufen lassen (die Geschwister-Suche in
`scripts/minimal_init.lua` findet `lib.nvim` und plenary dort nicht; das Skript
nimmt eine Spec-Datei pro Aufruf):

```bash
cd E:/repos/ui.nvim
export LIB_NVIM_DIR=/e/repos/lib.nvim PLENARY_DIR="$LOCALAPPDATA/nvim-data/lazy/plenary.nvim"
bash scripts/test.sh TESTS/context_spec.lua    # eine Spec
bash scripts/test.sh                            # alle (52 Spec-Dateien)
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
