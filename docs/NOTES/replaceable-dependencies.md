# Welche Fremd-Dependencies durch `lib.nvim` ersetzbar wären

Roadmap-Task: *"Analyse: welche Plugin-Dependencies (z. B. nvzone menu) durch
eigene `lib.nvim`-Module ersetzbar wären."*

Stand 2026-08-26. Ermittelt aus den tatsächlichen `require("<fremd>…")`-Stellen
in allen `*.nvim`-Repos, nicht aus den Spec-Deklarationen — eine deklarierte
Dependency, die nie gerufen wird, ist ein anderes Problem.

---

## Die Datenbasis

| Fremd-Modul | wird gerufen von |
|---|---|
| `telescope` | buffer-ctx, cmdlog, filetree, insights, lsp, migrate, open, pdfport, pickers, sandbox, sessions |
| `fzf-lua` | cmdlog, pdfport, pickers, replacer |
| `snacks` | pickers |
| `menu` (nvzone) | **filetree, github_stats** |
| `lualine` | filetree, sandbox |
| `nvim-treesitter` | debugging, gopath |
| `trouble` | language |
| `cmp` | lsp |
| `noice` | lsp |

---

## Ersetzbar — und zwar heute

### `nvzone/menu` → `lib.nvim.ui.kit.menu`

**Das Beispiel aus dem Task, und die Antwort ist ja.**

`lib.nvim.ui.kit.menu` existiert bereits: eine cursor-verankerte Aktionsliste,
gebaut auf `ui.kit.chooser`, mit derselben Navigation, die nvzone/menu bietet
(`j`/`k`/Pfeile, `<CR>`, `<Esc>`/`q`) — und mit `ui.kit`s Theme-Engine, die
nvzone/menu nicht hat. Getestet in `TESTS/ui_kit_spec.lua` („menu opens",
„menu float valid").

Was heute noch fehlt, ist nicht das Rendern, sondern die Brücke:
`lib.nvim.contextmenu` baut zwar die Einträge (`entry`/`group`/`submenu`) und
bindet den Maus-Trigger, **rendert aber weiterhin über nvzone/menu** — das
`require("menu")` dort ist die einzige verbleibende Stelle.

**Vorgeschlagene Umsetzung**, klein und rückwärtskompatibel:

1. `lib.nvim.contextmenu` bekommt einen Renderer-Schalter mit Default `"auto"`:
   `ui.kit.menu`, wenn `menu` (nvzone) nicht installiert ist, sonst weiter
   nvzone — oder explizit `"kit"` / `"nvzone"`.
2. Die beiden Konsumenten (`filetree.features.ui.context_menu`,
   `github_stats`) ändern sich **gar nicht**: sie bauen Items über
   `contextmenu.entry`/`group` und wissen vom Renderer nichts. Genau dafür ist
   die Schicht da.
3. Wenn sich `"kit"` bewährt, wird es der Default und nvzone/menu fällt als
   Dependency weg.

**Offene Frage, die vor Schritt 3 zu klären ist:** unterstützt
`ui.kit.menu` verschachtelte Submenüs so wie nvzone? `contextmenu.submenu`
existiert, `kit/menu.lua` ist 47 Zeilen und delegiert an den Chooser — das
sieht nach *flach* aus. Falls ja, ist das der einzige echte Implementierungs­
aufwand an der ganzen Ablösung.

### `nvim-treesitter` → `vim.treesitter`

`debugging.nvim` und `gopath.nvim` rufen `require("nvim-treesitter…")`.

Seit Neovim 0.9/0.10 ist der Parser-Kram im Core: `vim.treesitter.get_parser`,
`get_string_parser`, `vim.treesitter.query`. `nvim-treesitter` ist im
Wesentlichen noch **Parser-Installer** plus ein paar Module (textobjects,
context). Wer nur parst und Queries laufen lässt, braucht das Plugin nicht zur
Laufzeit — nur die installierten Parser.

Das ist keine `lib.nvim`-Ablösung im Wortsinn, aber es zählt zur selben Frage
(„welche Dependency ist verzichtbar") und ist billiger als jede andere hier.
Aufwand: die konkreten Aufrufstellen ansehen; wenn es Queries/Parser sind,
eins zu eins ersetzbar.

---

## Nicht ersetzbar — und warum das die richtige Antwort ist

- **`telescope`, `fzf-lua`, `snacks`.** Ein Fuzzy-Picker ist keine
  UI-Komponente, sondern ein Teilsystem: Matcher, Sorter, Previewer,
  Multi-Select, Async-Quellen. `lib.nvim.ui.kit.picker` deckt den Fall
  „wähle eins aus dieser Liste" ab, und `pickers.nvim` ist bereits die
  Abstraktion, die die drei austauschbar macht — das ist die richtige
  Antwort auf diese Dependency und braucht keine zweite.
- **`cmp` / `blink`.** Completion-Engines. Dasselbe Argument, eine Größenordnung
  darüber.
- **`noice`.** Ersetzt Neovims Message-/Cmdline-UI. Nichts, was ein
  Utility-Modul leistet.
- **`trouble`** (nur `language.nvim`). Ersetzbar *im Prinzip* durch die
  Quickfix-Liste, aber der Aufruf ist bereits `pcall`-geschützt und optional —
  die Dependency kostet nichts, wenn sie fehlt. Kein Handlungsbedarf.

## Der Grenzfall

- **`lualine`** (filetree, sandbox). Interessant, weil diese Config eine
  **eigene** Statusline hat (`wkdnvchad/ui/statusline`) und `lib.nvim` ein
  `ui/statusline`-Modul mitbringt. Zwei Statusline-Systeme im selben Setup ist
  eine Dopplung, die niemand gewählt hat, sondern die entstanden ist.

  Vor einer Ablösung ist aber zu klären, *was* die beiden Plugins von lualine
  eigentlich wollen — eine eigene Sektion registrieren, oder nur dessen
  Highlight-Gruppen mitbenutzen. Das ist ein Blick in zwei Dateien, keine
  Analyse. **Notiert als nächster Schritt, nicht hier entschieden.**

---

## Zusammenfassung

| Dependency | Urteil | Aufwand |
|---|---|---|
| `nvzone/menu` | **ersetzbar**, `ui.kit.menu` existiert und ist getestet | klein — ein Renderer-Schalter in `lib.nvim.contextmenu`; Konsumenten unverändert. Vorher klären: Submenü-Tiefe |
| `nvim-treesitter` (debugging, gopath) | **wahrscheinlich verzichtbar** zur Laufzeit | klein — Aufrufstellen auf `vim.treesitter` umstellen |
| `lualine` (filetree, sandbox) | **unklar**, erst prüfen was genutzt wird | erst Analyse, dann Urteil |
| `telescope`/`fzf-lua`/`snacks` | nein — Teilsystem, und `pickers.nvim` ist bereits die Abstraktion | — |
| `cmp`/`blink`, `noice` | nein | — |
| `trouble` | nein, aber optional und `pcall`-geschützt — kostet nichts | — |
