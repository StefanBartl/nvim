# Auftrag: RULES-Verzeichnis

**Datum:** 2026-08-08

## Was hier gemacht wurde/wird

Auftrag des Users: die eigene nvim-Config (`C:\Users\bartl\AppData\Local\nvim`) und alle
selbst geschriebenen `*.nvim`-Plugin-Repos unter `E:\repos` systematisch durchgehen -
nicht nur oberflächlich, sondern im echten Source Code - und daraus:

1. **Guidelines / Regeln** ableiten, die für zukünftige Plugins/Config-Arbeit gelten sollen.
2. **Ideen für andere Plugins**, die beim Lesen des Codes entstehen.
3. Stellen markieren, an denen ein **bestimmter Algorithmus**, ein Objekt/eine Funktion ein
   Problem auf **besondere / nicht-standard Art** löst - insbesondere Security- oder
   Performance-Anpassungen, die vom naiven/Standard-Ansatz abweichen.
4. Parallel dazu: **alle Keybindings der Plugins** durchgehen und Regeln ableiten, z.B.
   - Autocompletion für Ex-Commands/Picker-Inputs: Pflicht oder nicht?
   - **Count-Unterstützung**: wird bei jedem relevanten Keymap geprüft, ob neben
     `<leader>xy` auch `2<leader>xy`, `3<leader>xy`, ... `N<leader>xy` sinnvoll wäre
     (analog zu `cascade.nvim`'s transpose-word-swap, s. Erinnerung
     `cascade.nvim word swap + count on transpose`)?
   - Ideen für neue Flags/Optionen, die einem beim Lesen auffallen.

## Woher die Plugin-Liste kommt

`C:\Users\bartl\AppData\Local\nvim\lua\plugins\personal\source.lua` (Quelle der Wahrheit für
aktive personal-Plugins) + alle Ordner unter `E:\repos`, die auf `.nvim` enden (auch wenn sie
in `source.lua` nicht/`disabled` gelistet sind, z.B. `learn-cli.nvim`, `lsp.nvim`,
`neotree-fs-refactor.nvim`).

## Struktur dieses Verzeichnisses

Zwei Schichten:

**Schicht 1 — gegroundete Einzelreports** (Rohbefunde, je mit file:line-Beleg
in den tatsächlichen Plugin-Sourcen):

- `00-TASK.md` - diese Datei (Auftragsbeschreibung).
- `plugins/<name>.md` - ein Report pro Plugin-Repo: Zweck, nicht-standard Patterns/Algorithmen,
  abgeleitete Guidelines, Keybinding-Audit, Ideen für andere Plugins.
- `nvim-config.md` - dasselbe für die Config selbst (Keymaps, Autocmds, Options, Struktur-Patterns).

**Schicht 2 — themenweise Synthese** (`themes/`, siehe `themes/README.md` für
den Index): dieselben Befunde aus Schicht 1, aber nach Thema statt nach Plugin
sortiert, damit man nicht alle 33 Einzelreports lesen muss, um z.B. "alle
Regeln zu Caching" oder "wo fehlt Count-Support" zu finden. Jeder Eintrag
verlinkt zurück auf den/die Plugin-Report(s), aus dem er stammt (relative
Markdown-Links), damit die Herkunft nachvollziehbar bleibt. Additiv - die
Einzelreports aus Schicht 1 werden dabei nicht verändert.

- `themes/README.md` - Index der 9 Themendateien.
- `themes/ui.md`, `themes/performance.md`, `themes/security.md`,
  `themes/error-handling.md`, `themes/module-structure.md` - themenweise
  Synthese der Guidelines/Patterns aus Punkt 1-3 der Auftragsbeschreibung.
- `themes/keybindings-count.md`, `themes/autocompletion.md` - themenweise
  Synthese des Keybinding-Audits (Punkt 4), inkl. je einer allgemeinen Regel,
  wann Count-Support bzw. Autocompletion angebracht ist.
- `themes/flags-options-ideas.md` - gesammelte Flag-/Options-Ideen, nach
  Plugin gruppiert.
- `themes/plugin-ideas.md` - gesammelte Ideen für neue Plugins/lib.nvim-Module,
  nach Thema gruppiert und dedupliziert.

## Stand

**Schicht 1 (Einzelreports):** fertig. Alle 33 Plugin-Repos unter `plugins/*.md`
plus `nvim-config.md` sind erstellt (zwei Repos - `neotree-fs-refactor.nvim`
und `lsp.nvim` - sind leer/ohne Code und entsprechend als solche dokumentiert,
nicht mit erfundenem Inhalt aufgefüllt).

**Schicht 2 (`themes/*.md`):** fertig. Alle 9 Themendateien plus
`themes/README.md` sind aus den 33 Einzelreports + `nvim-config.md` erstellt,
mit Rückverlinkung auf die jeweilige Quelle pro Eintrag.
