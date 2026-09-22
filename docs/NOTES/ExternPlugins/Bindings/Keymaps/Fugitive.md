# Fugitive — Keymaps

> **Entfernt, ersetzt durch gitsuite.nvim.** `tpope/vim-fugitive` (und
> `vim-rhubarb`) sind aus [lua/plugins/git.lua](../../../../../lua/plugins/git.lua)
> raus; `<leader>gb` ruft jetzt gitsuite.nvims `:Git blame full`. Die
> Fugitive-Objektbuffer (Abschnitt 2 unten, `fugitive-maps`) hat gitsuite.nvim
> **nicht** nachgebaut -- anderes UI-Konzept (`:Git`-Composer statt
> Summary-Buffer). Blatt bleibt als historischer Extern-Korpus-Eintrag stehen.

Zwei Quellen:

1. Globale, config-eigene Maps, die einen Fugitive-Command aufrufen —
   registriert im Lazy-Spec
   [lua/plugins/git.lua](../../../../../lua/plugins/git.lua) (`keys`-Tabelle
   des `tpope/vim-fugitive`-Eintrags).
2. Die Maps, die **vim-fugitive selbst** in Fugitive-Objektbuffern
   (`:Git`-Summary-Fenster, Blob-/Blame-Buffer, …) setzt — dokumentiert in
   `doc/fugitive.txt` (`fugitive-maps`) des installierten Plugins
   (`nvim-data/lazy/vim-fugitive/doc/fugitive.txt`). Diese Config setzt
   `g:fugitive_no_maps` **nicht**, die globalen Maps sind also aktiv und
   unverändert — alle Einträge in Abschnitt 2 sind daher **[default]**.

---

## 1. Globale Maps (außerhalb von Fugitive-Buffern)

| Mapping | Aktion | = Command | Status |
|---|---|---|---|
| `<leader>gb` | Git-Blame der aktuellen Datei | `:Git blame` | [custom] |

Ein reiner `<cmd>…<cr>`-Wrapper ohne zusätzliche Logik, gesetzt über die
`keys`-Spezifikation des Lazy-Plugin-Specs (lazy-loaded via
`event = "VeryLazy"`).

`<leader>gd` (`:Gdiffsplit`, Diff gegen den Index) lag bis 2026-09-18 ebenfalls
hier — und gleichzeitig auf snacks' Hunk-Picker, wer zuletzt registrierte,
gewann. Die Taste gehört jetzt diff.nvim (`:Diff target=git:HEAD`, Spec in
`lua/plugins/personal/init.lua`); der Hunk-Picker ist auf `<leader>gD`
gewandert. Blame ist damit das einzige noch benutzte Fugitive-Feature
(Externe-Plugins-Nachbau-Analyse, Git-Tabelle).

`tpope/vim-rhubarb` (GitHub-Provider für `:GBrowse`) ist als Dependency
mitgeladen, bringt aber selbst keine zusätzlichen Keymaps — nur die
`:GBrowse`-Erweiterung für vim-fugitive.

---

## 2. Maps in Fugitive-Objektbuffern (Plugin-Default, `fugitive-maps`)

Gelten in der `:Git`-Summary/Status-Ansicht und in weiteren
Fugitive-Objektbuffern (Blob, Commit, …), sofern dort sinnvoll. Alle
**[default]** — unverändert von dieser Config übernommen.

### Stage/Unstage

| Taste | Aktion | Status |
|---|---|---|
| `s` | Datei/Hunk unter Cursor stagen | [default] |
| `u` | Datei/Hunk unter Cursor unstagen | [default] |
| `-` | Stage/Unstage toggeln | [default] |
| `U` | Alles unstagen | [default] |
| `X` | Änderung unter Cursor verwerfen (`checkout`/`clean`); `2X`/`3X` bei Merge-Konflikt = ours/theirs | [default] |
| `=` | Inline-Diff der Datei unter Cursor togglen | [default] |
| `>` / `<` | Inline-Diff einfügen / entfernen | [default] |
| `gI` | `.git/info/exclude` (bzw. mit Count `.gitignore`) im Split öffnen und Datei eintragen | [default] |
| `I` / `P` | `:Git add --patch` bzw. `reset --patch` (bei untracked: `add --intent-to-add`) | [default] |

### Diff

| Taste | Aktion | Status |
|---|---|---|
| `dp` | `:Git diff` auf Datei unter Cursor (deprecated zugunsten Inline-Diff) | [default] |
| `dd` | `:Gdiffsplit` auf Datei unter Cursor | [default] |
| `dv` | `:Gvdiffsplit` auf Datei unter Cursor | [default] |
| `ds` / `dh` | `:Ghdiffsplit` auf Datei unter Cursor | [default] |
| `dq` | Alle Diff-Buffer außer dem fokussierten schließen, `:diffoff!` | [default] |
| `d?` | Hilfe zu den Diff-Maps | [default] |

### Navigation

| Taste | Aktion | Status |
|---|---|---|
| `<CR>` | Datei/Objekt unter Cursor öffnen | [default] |
| `o` / `gO` / `O` | … in neuem Split / vertikalem Split / Tab öffnen | [default] |
| `p` | … im Preview-Fenster öffnen (im Status-Buffer: `1p`) | [default] |
| `~` / `P` | Zum n-ten Vorfahren / n-ten Parent der aktuellen Datei | [default] |
| `C` | Commit öffnen, der die aktuelle Datei enthält | [default] |
| `(` / `)` | Zur vorherigen/nächsten Datei, Hunk oder Revision | [default] |
| `[c` / `]c` | Zum vorherigen/nächsten Hunk (expandiert Inline-Diffs automatisch) | [default] |
| `[/`, `[m` / `]/`, `]m` | Zur vorherigen/nächsten Datei (kollabiert Inline-Diffs) | [default] |
| `i` | Zur nächsten Datei/Hunk, expandiert Inline-Diffs automatisch | [default] |
| `[[` / `]]` | n Abschnitte zurück/vor | [default] |
| `[]` / `][` | n Abschnittsenden zurück/vor | [default] |
| `*` / `#` | Auf `+`/`-`-Diffzeile: korrespondierende Zeile suchen (vorwärts/rückwärts) | [default] |
| `gu` / `gU` | Zur Datei n in „Untracked“/„Unstaged“ bzw. „Unstaged“ | [default] |
| `gs` / `gp` / `gP` / `gr` | Zur Datei n in „Staged“/„Unpushed“/„Unpulled“/„Rebasing“ | [default] |
| `gi` | `.git/info/exclude` (Count: `.gitignore`) im Split öffnen | [default] |

### Commit / Checkout / Stash / Rebase (Präfix-Maps)

| Taste(n) | Aktion | Status |
|---|---|---|
| `cc`, `cvc`, `ca`, `cva`, `ce`, `cw`, `cW`, `cf`, `cF`, `cs`, `cS`, `cn`, `c<Space>`, `c?` | Commit-Varianten (neu, amend, reword, fixup, squash, …) | [default] |
| `crc`, `crn`, `cr<Space>` | Commit unter Cursor reverten / Command-Line mit `:Git revert ` vorbelegen | [default] |
| `cm<Space>` | Command-Line mit `:Git merge ` vorbelegen | [default] |
| `coo`, `cb<Space>`, `co<Space>`, `cb?`, `co?` | Checkout/Branch-Maps | [default] |
| `czz`, `czw`, `czs`, `czA`, `cza`, `czP`, `czp`, `cz<Space>`, `cz?` | Stash-Maps | [default] |
| `ri`/`u`, `rf`, `ru`, `rp`, `rr`, `rs`, `ra`, `re`, `rw`, `rm`, `rd`, `r<Space>`, `r?` | Rebase-Maps | [default] |

### Sonstiges

| Taste | Aktion | Status |
|---|---|---|
| `gq` | Status-Buffer schließen | [default] |
| `.` | `:`-Kommandozeile mit Datei unter Cursor vorbelegt starten | [default] |
| `g?` | Hilfe zu `fugitive-maps` | [default] |
| `<C-R><C-G>` (Command-Line, global) | Pfad zum aktuellen Fugitive-Objekt einfügen | [default] |
| `y<C-G>` (global, Normal-Modus) | Pfad zum aktuellen Fugitive-Objekt yanken. Ein vorangestelltes Register wirkt wie überall (`"xy<C-G>` yankt nach `x`) — `fugitive.txt` schreibt das als `["x]y<C-G>`. | [default] |

### In `:Git blame`

| Taste | Aktion | Status |
|---|---|---|
| `g?` | Hilfe | [default] |
| `A` / `C` / `D` | Spalte Autor/Commit/Datum bis Ende resizen | [default] |
| `gq` | Blame schließen, `:Gedit` zurück zur Work-Tree-Version | [default] |
| `<CR>` | Blame schließen, zum Patch springen, der die Zeile hinzufügte | [default] |
| `o` / `O` / `p` | Patch/Blob im horizontalen Split / neuen Tab / Preview-Fenster öffnen | [default] |
| `-` | An Commit unter Cursor reblamen | [default] |

Deaktivierbar insgesamt über `g:fugitive_no_maps = 1` — in dieser Config
nicht gesetzt.
