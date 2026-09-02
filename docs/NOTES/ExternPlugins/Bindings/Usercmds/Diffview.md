# Diffview — User-Commands

Alle sieben Commands sind **[default]**, registriert in `plugin/diffview.lua`
des Plugins. Diese Config registriert keinen eigenen; sie wählt nur, welche
davon als Lazy-Trigger dienen
([lua/plugins/git.lua](../../../../../lua/plugins/git.lua)).

Die Keymaps innerhalb der Diffview-Fenster stehen in
[Keymaps/Diffview.md](../Keymaps/Diffview.md) — sie sind der eigentliche
Arbeitsplatz, die Commands nur die Türen dorthin.

## Vier davon sind Lazy-Trigger, drei nicht

`cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles",
"DiffviewFocusFiles" }`. Die drei übrigen — `:DiffviewFileHistory`,
`:DiffviewRefresh`, `:DiffviewLog` — existieren erst, **nachdem** einer der
vier das Plugin geladen hat. Das ist kein Defekt: `:DiffviewRefresh` und
`:DiffviewLog` ergeben ohne offene Diffview nichts, und `:DiffviewFileHistory`
ist der eine Einstieg, den die Liste vergisst.

Wer die Historie einer Datei direkt öffnen will, ohne vorher `:DiffviewOpen`
zu tippen, kann `DiffviewFileHistory` in die `cmd`-Liste aufnehmen.

## [default] Alle sieben

| Command | Wirkung |
|---|---|
| `:DiffviewOpen [revs] [-- pfade]` | Der Einstieg. Ohne Argument: Arbeitsverzeichnis gegen den Index. Mit einer Revision (`HEAD~2`, `main..feature`) gegen diese. `--` trennt die Pfadbeschränkung ab. |
| `:DiffviewClose` | Das aktuelle Diffview-Tab schließen. |
| `:DiffviewToggleFiles` | Das Dateipanel ein-/ausblenden. |
| `:DiffviewFocusFiles` | Den Fokus in das Dateipanel setzen. |
| `:DiffviewFileHistory [pfade]` | Die Commit-Historie der angegebenen Pfade (ohne Argument: der aktuellen Datei) als durchblätterbare Diff-Ansicht. |
| `:DiffviewRefresh` | Die offene Diffview gegen den Plattenzustand aktualisieren — nach einem `git`-Aufruf außerhalb von Neovim. |
| `:DiffviewLog` | Die Logdatei des Plugins öffnen. |

## Eine Notiz zur Familien-Notation

`:DiffviewFocusFiles` und `:DiffviewToggleFiles` sind der dokumentierte Grund
dafür, dass eine Command-Familie im Korpus an ihren **Eigentümer** gebunden
ist und nicht nur an ihr Namensmuster: `pickers.nvim.md`s `:*Files` hat die
beiden früher als „dokumentiert" beansprucht, obwohl das Blatt nichts über
sie sagt. Seit `command_owner` den Eigentümer kennt, greift die Familie nur
noch für die Commands von pickers.nvim. Siehe `drift.lua`,
`records.family_claims`.
