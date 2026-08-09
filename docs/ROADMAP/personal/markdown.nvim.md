# `markdown.nvim`

---

## Aus `MyPlugin-Notes/md_tablewrap/featuremap.md` (Analyse 2026-08-08)

Quelle: `E:/repos/Notes/MyPlugin-Notes/md_tablewrap/featuremap.md` (20 QoL-Punkte)
plus `MyPlugin-Notes/PluginsDoc/underline_headings.md`.

**Umgesetzt (2026-08-09, direkt auf `main` gepusht):** Kernfeature
breitenbegrenztes Umbrechen (`core/table_wrap.lua`) plus die komplette
`:MDTable*`-Befehlsfamilie — Cursor-/Zell-Erhalt, Fortsetzungs-Marker
(virtuell, `↳`), URL-/Code-sicheres Wrapping, Falten der
Fortsetzungsblöcke, Per-Table-Direktiven (`<!-- mdwrap: ... -->`),
Breitenprofile (`:MDTableProfile`), Spalten-Nudges (`:MDTableCol inc|dec`
— Vim-Kommandonamen erlauben kein `+`/`-`), Alignment-Toggle
(`:MDTableAlign`), Flavor-Schalter (`:MDTableFlavor`),
`:MDTableWrapVisual[!]`/`:MDTableWrapVisible[!]`, `:MDTableReflowHeader`,
debounced `VimResized`/`WinResized`-Reflow (`table.wrap.auto_resize`),
`changedtick`-artiger selektiver Reflow on-save (`table.wrap.selective_reflow`),
`:MDTableLint`/`:MDTableFixMissingSeparator`, `:MDTableDebug`,
`:MDTableToCSV`/`:MDTableFromCSV`, API-Hooks (`before_reflow`/`after_reflow`).
Details: `E:/repos/markdown.nvim/docs/table-wrap.md`.

**Wichtige Abweichung von der ursprünglichen Notiz:** `:MDTableUnwrap`
(und die anderen Rückumwandlungen) erkennen Fortsetzungszeilen strukturell
(Zeile mit ≤1 nicht-leerer Zelle direkt nach einer anderen Tabellenzeile),
nicht über einen persistierten Marker im Puffertext — der `↳`-Hinweis ist
reine virtuelle Text-Deko, damit die GFM-Quelle sauber bleibt. Kompromiss:
eine echte Datenzeile mit derselben Form direkt nach einer anderen Zeile
ist von einer Fortsetzung nicht zu unterscheiden und wird mitgemerged.

---

## Randnotiz aus `PluginsDoc/underline_headings.md`

**Umgesetzt (2026-08-09):** `:MarkdownNvimUnderlineHeadings` — siehe
`E:/repos/markdown.nvim/docs/features.md`.

---

## Nicht übernehmen

- **Soft-Hyphenation (`\u00AD`)**: hängt vollständig am Renderer der Gegenseite
  und ist in Plain-Text-Diffs unsichtbar — hohe Verwirrungsgefahr, geringer Nutzen.
